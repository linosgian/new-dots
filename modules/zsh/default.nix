{pkgs, ...}:
{

  environment.systemPackages = with pkgs; [
    (pkgs.writeShellScriptBin "kube_ps1.sh" (builtins.readFile ./kube_ps1.sh))
    zsh-nix-shell
  ];
  system.userActivationScripts.zshrc = "touch .zshrc";
  programs.zsh = {
    syntaxHighlighting.enable = true;
    enable = true;
    enableCompletion = true;
    interactiveShellInit = "source ${pkgs.zsh-nix-shell}/share/zsh-nix-shell/nix-shell.plugin.zsh";
    autosuggestions.enable = true;
    histSize = 10000000;
    histFile = "/home/lgian/.zsh_history";
    setOptions = [
      "HIST_IGNORE_ALL_DUPS"
      "HIST_IGNORE_SPACE"
      "INC_APPEND_HISTORY"
    ];
    promptInit = builtins.readFile ./initextra.zsh;
  };
}
