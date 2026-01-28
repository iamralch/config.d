_:
let
  setup = ./config.sh;
in
{
  # Determinate uses its own daemon to manage nix
  nix.enable = false;

  # Determinate Nix settings (native Linux builder)
  determinateNix.customSettings = {
    extra-trusted-users = [
      "@admin"
      "@wheel"
      "@staff"
    ];
    keep-outputs = true;
    keep-derivations = true;
    extra-experimental-features = "external-builders nix-command flakes";
  };

  # set all defaults
  system.activationScripts.setup.text = ''
    bash ${setup}
  '';
}
