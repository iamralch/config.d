_:
let
  setup = ./config.sh;
in
{
  # Determinate uses its own daemon to manage nix
  nix.enable = false;

  # Determinate Nix settings (native Linux builder)
  determinate-nix.customSettings = {
    extra-trusted-users = [ "@admin" "@wheel" "@staff" ];
    keep-outputs = true;
    keep-derivations = true;
    extra-experimental-features = "external-builders nix-command flakes";
    external-builders = builtins.toJSON [
      {
        systems = [ "aarch64-linux" "x86_64-linux" ];
        program = "/usr/local/bin/determinate-nixd";
        args = [ "builder" ];
      }
    ];
  };

  # set all defaults
  system.activationScripts.setup.text = ''
    bash ${setup}
  '';
}
