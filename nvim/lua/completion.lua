-- nvim-cmp: buffer-word + snippet completion (no LSP sources)
local cmp = require("cmp")
cmp.setup({
  mapping = {
    ["<C-n>"] = function(fallback)
      if cmp.visible() then cmp.select_next_item() else fallback() end
    end,
    ["<C-p>"] = function(fallback)
      if cmp.visible() then cmp.select_prev_item() else fallback() end
    end,
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.close(),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true })
      elseif vim.fn["vsnip#available"](1) == 1 then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>(vsnip-expand-or-jump)", true, true, true), "")
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif vim.fn["vsnip#jumpable"](-1) == 1 then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>(vsnip-jump-prev)", true, true, true), "")
      else
        fallback()
      end
    end, { "i", "s" }),
  },
  sources = cmp.config.sources({
    { name = "vsnip" },
  }, {
    { name = "buffer" },
  }),
  snippet = {
    expand = function(args) vim.fn["vsnip#anonymous"](args.body) end,
  },
  preselect = cmp.PreselectMode.None,
})
