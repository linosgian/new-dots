{ pkgs, ... }:
{
  environment.variables = { EDITOR = "vim"; };

  environment.systemPackages = with pkgs; [
    ((vim_configurable.override {  }).customize{
      name = "vim";
      vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
        start = [
          vim-nix
          vim-commentary
          vim-fugitive
          vim-lastplace
          vim-cool
          fzf-vim
          vim-kitty-navigator
          vim-hybrid
          delimitMate
          vim-bufkill
          nerdtree
          vim-toml
          vim-markdown
          vim-hcl
          jsonc-vim
          lightline-bufferline
          lightline-vim
        ];
        opt = [];
      };
      vimrcConfig.customRC = builtins.readFile ./vimrc;
    }
  )];
}
