<#
.SYNOPSIS
One-off migration of the repos directory (gitdir -> repos) on a Windows + WSL machine.

.DESCRIPTION
Windows side of ai_agents/project_logs/migracja_gitdir_repos.md. Checks blockers, stops WSL,
renames the directory, leaves a junction at the old path, updates Obsidian vault paths and then
runs migrate_repos.sh inside WSL (symlinks, Claude Code state, zoxide).
Without -Apply / -Cleanup / -Rollback it changes nothing and prints what it would do.
Run it from a PowerShell tab, not from inside WSL (wsl --shutdown would kill the caller).

.EXAMPLE
powershell -ExecutionPolicy Bypass -File .\migrate_repos.ps1
    Dry run; detects E:\gitdir or %USERPROFILE%\gitdir.
.EXAMPLE
powershell -ExecutionPolicy Bypass -File .\migrate_repos.ps1 -Apply
.EXAMPLE
powershell -ExecutionPolicy Bypass -File .\migrate_repos.ps1 -Cleanup
    Phase 5: removes the junction once nothing points to the old path.
.EXAMPLE
powershell -ExecutionPolicy Bypass -File .\migrate_repos.ps1 -Rollback
#>
param(
    [string]$OldPath,
    [string]$NewName = 'repos',
    [string]$Distro,
    [switch]$Apply,
    [switch]$NoJunction,
    [switch]$Cleanup,
    [switch]$Rollback
)

$ErrorActionPreference = 'Stop'

if (([int]$Apply.IsPresent + [int]$Cleanup.IsPresent + [int]$Rollback.IsPresent) -gt 1) {
    throw 'Use only one of -Apply, -Cleanup, -Rollback'
}

if (-not $OldPath) {
    $OldPath = @('E:\gitdir', (Join-Path $env:USERPROFILE 'gitdir')) |
        Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $OldPath) { throw 'No gitdir found (tried E:\gitdir, %USERPROFILE%\gitdir); pass -OldPath' }
}
$OldPath = $OldPath.TrimEnd('\')
$NewPath = Join-Path (Split-Path $OldPath -Parent) $NewName

$WslBase = @()
if ($Distro) { $WslBase = @('-d', $Distro) }

function Write-Section($text) { Write-Host ''; Write-Host "== $text" }

function Test-Junction($path) {
    $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    return [bool]($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint))
}

function ConvertTo-WslPath($path) {
    $result = & wsl.exe @WslBase -e wslpath -a ($path -replace '\\', '/')
    if ($LASTEXITCODE -ne 0) { throw "wslpath failed for $path" }
    return ([string]$result).Trim()
}

function Invoke-MigrateSh([string]$ShPath, [string[]]$ShArgs) {
    & wsl.exe @WslBase -e bash $ShPath @ShArgs | Out-Host
    return $LASTEXITCODE
}

function Assert-Confirmed($what) {
    Write-Host ''
    $answer = Read-Host "$what Continue? [y/N]"
    if ($answer -notmatch '^(y|yes|t|tak)$') { Write-Host 'Aborted, nothing changed.'; exit 1 }
}

function Assert-AppsClosed {
    Write-Section 'apps holding the directory'
    $busy = Get-Process -Name Obsidian, Code, 'Code - Insiders' -ErrorAction SilentlyContinue
    if ($busy) {
        $busy | Select-Object -ExpandProperty ProcessName -Unique | ForEach-Object { Write-Host "  running: $_" }
        Write-Host '  Close them (and Explorer windows inside the directory) and run again.'
        exit 1
    }
    Write-Host '  none (Obsidian, VS Code)'
}

function Find-WindowsReferences($path) {
    Write-Section "Windows files referencing $path (fix by hand)"
    $needles = @($path, $path.Replace('\', '\\'), $path.Replace('\', '/'))
    $candidates = @(
        (Get-ChildItem "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal*\LocalState\settings.json" -ErrorAction SilentlyContinue),
        (Get-Item "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json" -ErrorAction SilentlyContinue),
        (Get-Item "$env:APPDATA\Code\User\settings.json" -ErrorAction SilentlyContinue),
        (Get-Item "$env:USERPROFILE\.gitconfig" -ErrorAction SilentlyContinue),
        (Get-Item $PROFILE.CurrentUserAllHosts, $PROFILE.CurrentUserCurrentHost -ErrorAction SilentlyContinue)
    ) | Where-Object { $_ } | ForEach-Object { $_ }
    $found = $false
    foreach ($file in $candidates) {
        if (Select-String -LiteralPath $file.FullName -SimpleMatch -Pattern $needles -Quiet) {
            Write-Host "  $($file.FullName)"
            $found = $true
        }
    }
    $userEnv = [Environment]::GetEnvironmentVariables('User')
    foreach ($name in $userEnv.Keys) {
        foreach ($needle in $needles) {
            if ([string]$userEnv[$name] -like "*$needle*") { Write-Host "  user env var $name"; $found = $true; break }
        }
    }
    if (-not $found) { Write-Host '  none' }
}

function Update-ObsidianVaults($from, $to, [bool]$write) {
    Write-Section 'Obsidian vaults'
    $file = Join-Path $env:APPDATA 'obsidian\obsidian.json'
    if (-not (Test-Path -LiteralPath $file)) { Write-Host '  not installed'; return }
    $text = [IO.File]::ReadAllText($file)
    # paths are JSON-escaped (E:\\gitdir\\vault); match the whole segment only
    $pattern = [regex]::Escape($from.Replace('\', '\\')) + '(?=\\\\|")'
    $count = [regex]::Matches($text, $pattern, 'IgnoreCase').Count
    if ($count -eq 0) { Write-Host "  no vaults under $from"; return }
    if (-not $write) { Write-Host "  would update $count vault path(s)"; return }
    if (-not (Test-Path -LiteralPath "$file.pre-repos")) { Copy-Item -LiteralPath $file "$file.pre-repos" }
    $replacement = $to.Replace('\', '\\').Replace('$', '$$')
    [IO.File]::WriteAllText($file, [regex]::Replace($text, $pattern, $replacement, 'IgnoreCase'))
    Write-Host "  updated $count vault path(s), backup: $file.pre-repos"
}

function Rename-WithRetry($from, $to) {
    for ($i = 1; $i -le 5; $i++) {
        try {
            Rename-Item -LiteralPath $from -NewName (Split-Path $to -Leaf)
            Write-Host "  $from -> $to"
            return
        } catch {
            if ($i -eq 5) {
                Write-Host '  Rename failed: something still holds the directory open.'
                Write-Host '  Check Explorer windows, terminals, antivirus; Sysinternals: handle.exe -nobanner gitdir'
                throw
            }
            Write-Host "  in use, retry $i/4 in 3 s..."
            Start-Sleep -Seconds 3
        }
    }
}

function Stop-Wsl {
    Write-Section 'WSL'
    & wsl.exe --shutdown
    Start-Sleep -Seconds 3
    Write-Host '  stopped'
}

# migrate_repos.sh lives in the dotfiles repo, possibly inside the directory being renamed
function Get-ShPathAfter($shWsl, $fromWsl, $toWsl) {
    if ($shWsl.StartsWith("$fromWsl/")) { return $toWsl + $shWsl.Substring($fromWsl.Length) }
    return $shWsl
}

$ShWin = Join-Path $PSScriptRoot 'migrate_repos.sh'
$mode = 'dry run'
if ($Apply) { $mode = 'apply' } elseif ($Cleanup) { $mode = 'cleanup' } elseif ($Rollback) { $mode = 'rollback' }
Write-Host "old: $OldPath"
Write-Host "new: $NewPath"
Write-Host "mode: $mode"

Set-Location -LiteralPath $env:SystemDrive\

$oldIsJunction = Test-Junction $OldPath
$OldWsl = ConvertTo-WslPath $OldPath
$NewWsl = $OldWsl.Substring(0, $OldWsl.LastIndexOf('/')) + "/$NewName"
$ShWsl = ConvertTo-WslPath $ShWin

if ($Cleanup) {
    if (-not $oldIsJunction) { throw "$OldPath is not a junction, nothing to clean up" }
    if (-not (Test-Path -LiteralPath $NewPath)) { throw "$NewPath does not exist" }
    $rc = Invoke-MigrateSh $ShWsl @('leftovers', '--old', $OldWsl, '--new', $NewWsl)
    Find-WindowsReferences $OldPath
    if ($rc -ne 0) { Write-Host ''; Write-Host 'Leftovers above still use the old path, junction kept.'; exit 1 }
    Assert-Confirmed "Remove junction $OldPath (only the link, not the content)?"
    # rmdir removes just the reparse point; Remove-Item may recurse into the target on PS 5.1
    & cmd.exe /c rmdir "$OldPath"
    if ($LASTEXITCODE -ne 0) { throw 'rmdir failed' }
    Write-Host "  removed junction $OldPath"
    Write-Host ''
    Write-Host 'Backups you can delete now:'
    Write-Host "  $env:APPDATA\obsidian\obsidian.json.pre-repos"
    Write-Host '  WSL: ~/.claude.json.pre-repos ~/.claude/settings.json.pre-repos'
    exit 0
}

if ($Rollback) {
    if (-not (Test-Path -LiteralPath $NewPath)) { throw "$NewPath does not exist, nothing to roll back" }
    if ((Test-Path -LiteralPath $OldPath) -and -not $oldIsJunction) { throw "$OldPath is a real directory, resolve by hand" }
    Assert-AppsClosed
    Assert-Confirmed "Runs wsl --shutdown (all distros, Docker Desktop too) and renames $NewPath back to $OldPath."
    Stop-Wsl
    Write-Section 'rename back'
    if ($oldIsJunction) { & cmd.exe /c rmdir "$OldPath"; Write-Host "  removed junction $OldPath" }
    Rename-WithRetry $NewPath $OldPath
    Update-ObsidianVaults $NewPath $OldPath $true
    $ShAfter = Get-ShPathAfter $ShWsl $NewWsl $OldWsl
    $rc = Invoke-MigrateSh $ShAfter @('apply', '--old', $NewWsl, '--new', $OldWsl, '--drop-home-link')
    Write-Host ''
    Write-Host 'Rolled back. Notes already switched to ~/repos (phase 3) will point nowhere until reverted.'
    exit $rc
}

# forward migration
if ($oldIsJunction -and (Test-Path -LiteralPath $NewPath)) {
    Write-Host "Already migrated ($OldPath is a junction). Use -Cleanup or -Rollback."
    exit 0
}
if (Test-Path -LiteralPath $NewPath) { throw "$NewPath already exists" }

if ($Apply) { Assert-AppsClosed }
Find-WindowsReferences $OldPath
Update-ObsidianVaults $OldPath $NewPath $false

$rc = Invoke-MigrateSh $ShWsl @('check', '--old', $OldWsl, '--new', $NewWsl, '--home-link')
if ($rc -ne 0) {
    Write-Host ''
    Write-Host 'Fix the errors above first (from WSL: close Claude Code; phase 1 of the plan).'
    exit 1
}
if (-not $Apply) {
    Write-Host ''
    Write-Host 'Dry run only. Re-run with -Apply.'
    exit 0
}

Assert-Confirmed 'Runs wsl --shutdown (all distros, Docker Desktop too), renames the directory, adds the junction.'
Stop-Wsl

Write-Section 'rename'
Rename-WithRetry $OldPath $NewPath
if (-not $NoJunction) {
    New-Item -ItemType Junction -Path $OldPath -Target $NewPath | Out-Null
    Write-Host "  junction $OldPath -> $NewPath"
}

Update-ObsidianVaults $OldPath $NewPath $true

$ShAfter = Get-ShPathAfter $ShWsl $OldWsl $NewWsl
$rc = Invoke-MigrateSh $ShAfter @('apply', '--old', $OldWsl, '--new', $NewWsl, '--home-link')

Write-Host ''
Write-Host 'Next: open a new WSL terminal and go through the verification checklist in the plan (phase 2.7).'
exit $rc
