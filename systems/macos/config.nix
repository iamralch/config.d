{ ... }: 
let
  setup = ./config.sh;
in {
  # Determine uses its own daemon to manage nix
  nix.enable = false;
  # set all defaults
  system.activationScripts.setup.text = ''
    bash ${setup}
  '';
}
