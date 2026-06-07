local opt = vim.opt

opt.number = true
opt.title = true
opt.ruler = true
opt.list = true
opt.showmatch = true
opt.cindent = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.scrolloff = 3
opt.expandtab = true
opt.smartindent = true
opt.listchars = { tab = "  ", eol = "↩" }
opt.cursorline = true
opt.hlsearch = false
opt.signcolumn = "yes"
opt.clipboard = "unnamedplus"
opt.completeopt = "menuone,noinsert,noselect"
opt.shortmess:append("c")
opt.showtabline = 2
opt.updatetime = 500

vim.cmd.filetype("plugin indent on")
vim.cmd.syntax("enable")
vim.cmd.language("en_US")

-- Python host
local pynvim = vim.fn.expand("~/venvs/pynvim3/bin/python")
if vim.fn.filereadable(pynvim) == 1 then
  vim.g.python3_host_prog = pynvim
else
  vim.g.python3_host_prog = vim.fn.trim(vim.fn.system("which python3"))
end
