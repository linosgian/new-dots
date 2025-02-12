{pkgs, ...}:
{
  home.packages = with pkgs; [
    (pkgs.writeShellScriptBin "kube_ps1.sh" (builtins.readFile ./kube_ps1.sh))
  ];

  # ZSH / FZF
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = false;
    autosuggestion.enable = true;
    autocd = true;
    dotDir = ".config/zsh";
    history = {
      path = "/home/lgian/.zsh_history";
      size = 10000000;
      save = 10000000;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
    };
    initExtra = builtins.readFile ./initextra.zsh;
  };
}
