local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Exclude quickfix from buffer list
local qf = augroup("qf", { clear = true })
autocmd("FileType", {
  group = qf,
  pattern = "qf",
  callback = function() vim.bo.buflisted = false end,
})

-- Exit insert mode when entering quickfix (Telescope sends items there)
autocmd({ "BufWinEnter", "WinEnter" }, {
  pattern = "*",
  callback = function()
    if vim.bo.buftype == "quickfix" then vim.cmd.stopinsert() end
  end,
})

-- Transparent background
autocmd("VimEnter", {
  callback = function() vim.cmd("hi Normal ctermbg=none") end,
})
