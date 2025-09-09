{ pkgs, ... }:
let
  vim-github-url = pkgs.vimUtils.buildVimPlugin {
    name = "vim-better-whitespace";
    src = pkgs.fetchFromGitHub {
      owner = "pgr0ss";
      repo = "vim-github-url";
      rev = "fb805c07a652b3ef3c8fecebe46ac16526132848";
      sha256 = "Ax0ry9g8xc1uk5yfx821pZGpDKLgfMSTDox65axVqew=";
    };
  };
in
{
  environment.variables = {
    EDITOR = "vim";
  };

  environment.systemPackages = with pkgs; [
    ((vim_configurable.override { }).customize {
      name = "vim";
      vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
        start = [
          vim-github-url
          vim-nix
          vim-commentary
          vim-fugitive
          vim-lastplace
          vim-cool
          vim-wayland-clipboard
          vim-go
          fzf-vim
          vim-kitty-navigator
          vim-hybrid
          delimitMate
          vim-bufkill
          nerdtree
          Tabular
          vim-toml
          vim-markdown
          Tagbar
          vim-hcl
          jsonc-vim
          ale
          goyo-vim
          vim-gitgutter
          lightline-bufferline
          lightline-vim
        ];
        opt = [ ];
      };
      vimrcConfig.customRC = builtins.readFile ./vimrc;
    })
  ];
}
