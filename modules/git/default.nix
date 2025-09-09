{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.file.".config/git/gitconfig-work".text = ''
    [user]
      name = Linos Giannopoulos
      email = linos@contextflow.com
      signingkey = /home/lgian/.ssh/work.pub

    [core]
      sshCommand = "ssh -i ~/.ssh/work"
  '';
  programs.git = {
    enable = true;
    userName = "Linos Giannopoulos";
    userEmail = "linosgian00@gmail.com";
    signing = {
      key = "/home/lgian/.ssh/id_ed25519.pub";
      signByDefault = true;
    };

    aliases = {
      cmv = "commit -v";
      cma = "commit --amend -v";
      lg = ''log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'';
      lgg = ''log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset by %C(yellow)%ae%Creset' --abbrev-commit --date=relative'';
      amen = "!git add -A && git commit --amend --no-edit";
      st = "status -sb";
      dfc = "diff --cached";
      co = "checkout";
      cb = "checkout -b";
      br = "branch";
      f = "fetch";
      rbm = "pull --rebase origin master";
      rbc = "rebase --continue";
      rbs = "rebase --skip";
      rba = "rebase --abort";
      brr = ''for-each-ref --sort=committerdate refs/heads/ --format="%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))"'';
    };

    includes = [
      {
        condition = "gitdir:~/cflow/";
        path = "~/.config/git/gitconfig-work";
      }
    ];

    extraConfig = {
      core = {
        sshCommand = "ssh -i ~/.ssh/id_ed25519";
      };
      push = {
        default = "current";
        autoSetupRemote = true;
      };
      init.defaultBranch = "main";
      gpg.format = "ssh";
    };
  };
}
