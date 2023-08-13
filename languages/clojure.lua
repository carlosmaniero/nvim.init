vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*.clj",
  callback = function()
    vim.api.nvim_set_hl(0, '@lsp.type.macro.clojure', {})
    vim.api.nvim_set_hl(0, 'Special', { link = 'Repeat' })
    vim.fn.matchadd('Define', 's/defn')
  end
})
