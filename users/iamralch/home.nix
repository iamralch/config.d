{ pkgs, ... }:

{ lib, ... }:

{
  # Support
  xdg.enable = true;

  home = {
    # Home Manager
    stateVersion = "25.11";
    # User Packages
    packages = [ ];
    # User Files
    file = {
      ".claude/settings.json".source = ./.config/claude/settings.json;
      ".gemini/settings.json".source = ./.config/gemini/settings.json;
    };
    # Activation Scripts
    activation.mergeMcpServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      PATH="${pkgs.jq}/bin:$PATH" ${pkgs.bash}/bin/bash ${../../scripts/claude.sh}
    '';
  };
}
