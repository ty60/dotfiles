-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
    }, true, {})
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Colorscheme
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        transparent = true,
        terminal_colors = true,
        styles = {
          comments = { italic = false },
          keywords = { italic = false },
          sidebars = "dark",
          floats = "dark",
        },
      })
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- Completion (buffer words + snippets, no LSP)
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/vim-vsnip",
      "hrsh7th/vim-vsnip-integ",
    },
    config = function() require("completion") end,
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", function() require("telescope.builtin").find_files() end },
      { "<leader>fg", function() require("telescope.builtin").live_grep() end },
      { "<leader>fb", function() require("telescope.builtin").buffers() end },
      { "<leader>fs", function() require("telescope.builtin").grep_string() end },
    },
  },

  -- Status / bufferline
  {
    "itchyny/lightline.vim",
    dependencies = { "mengelbrecht/lightline-bufferline" },
    config = function()
      vim.g.lightline = {
        colorscheme = "tokyonight",
        active = {
          left = { { "mode", "paste" }, { "readonly", "filename", "modified" } },
        },
        tabline = {
          left = { { "buffers" } },
          right = { { "close" } },
        },
        component_expand = { buffers = "lightline#bufferline#buffers" },
        component_type = { buffers = "tabsel" },
      }
    end,
  },
})
