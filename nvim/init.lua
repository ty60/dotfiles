if vim.g.vscode then
  -- VSCode extension
  vim.opt.clipboard = "unnamedplus"
  return
end

require("options")
require("keymaps")
require("autocmds")
require("plugins")
