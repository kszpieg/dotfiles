-- run starship from clink script dir
home = os.getenv('HOME')
starship_cfg = home .. '\\.starship\\starship.toml'
os.setenv('STARSHIP_CONFIG', starship_cfg)
load(io.popen('starship init cmd'):read("*a"))()