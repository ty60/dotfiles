local map = vim.keymap.set

map("n", "<C-j>", "<cmd>bnext<cr>", { silent = true })
map("n", "<C-k>", "<cmd>bprev<cr>", { silent = true })

-- Diagnostics
map("n", "<space>e", vim.diagnostic.open_float, { silent = true })
map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { silent = true })
map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { silent = true })
map("n", "<space>q", vim.diagnostic.setloclist, { silent = true })
