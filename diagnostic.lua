local diagnostic_ns = {}

function diagnostic_ns.setup()
  local signs = {
    Error = '✗',
    Warning = '',
    Warn = '',
    Info = '!',
    Hint = '✦'
  }

  vim.diagnostic.config({ virtual_text = {
    signs = false,
    spacing = 0,
    prefix = ''
  }})

  for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, {
      text = icon,
      texthl = hl,
      numhl = hl
    })
  end
end
return diagnostic_ns
