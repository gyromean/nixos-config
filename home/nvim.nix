{ config, pkgs, lib, machine, ... }:
{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      lualine-nvim
      nord-nvim
      nightfox-nvim
      nvim-treesitter.withAllGrammars # viz https://nixos.wiki/wiki/Treesitter
      undotree
      nvim-treesitter-context
      telescope-nvim
      telescope-fzf-native-nvim
      vim-gitgutter # git stav jednotlivych radek vlevo; pridava do vim-airline countery zmen
      vim-commentary # keybind na toggle comment radku
      vim-surround # keybinds na zmenu uvozovek, zavorek, tagu, ...
      nvim-ts-autotag
      lsp-zero-nvim
      # dependencies pro lsp-zero-nvim:
        nvim-lspconfig
        nvim-cmp
        cmp-nvim-lsp
        luasnip
        cmp_luasnip
        cmp-path # autocomplete pathu
      lspsaga-nvim
      nvim-dap
      nvim-dap-ui
      nvim-dap-virtual-text
      nvim-dap-python
      todo-comments-nvim
      vimtex
      harpoon2
      oil-nvim
      kanagawa-nvim
      catppuccin-nvim
      leap-nvim
      lazydev-nvim
    ];
  };
}
