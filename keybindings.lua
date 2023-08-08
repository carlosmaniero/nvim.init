local keybindings = {}

local function register_buffer_keybindings()
  vim.keymap.set('n', '<leader>bn', function() vim.cmd("bn") end)
  vim.keymap.set('n', '<leader>bp', function() vim.cmd("bp") end)
  vim.keymap.set('n', '<leader>bd', function() vim.cmd("bd") end)
  -- vim.keymap.set('n', '<leader>bc', require('misc.buffers').buffer_choose)
end

local function register_telescope()
  -- TODO: I still need to implement my own fuzzysearch
  -- vim.keymap.set('n', '<leader>ff', require('misc.file').prompt)
  local builtin = require('telescope.builtin')
  vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
  vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
  vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
  vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
end

local function register_bash_like_navigation_on_command_prompt()
  vim.api.nvim_set_keymap('c', '<C-A>', '<Home>', { noremap = true })
  vim.api.nvim_set_keymap('c', '<C-E>', '<End>', { noremap = true })
  vim.api.nvim_set_keymap('c', '<C-F>', '<Right>', { noremap = true })
  vim.api.nvim_set_keymap('c', '<C-B>', '<Left>', { noremap = true })
  vim.api.nvim_set_keymap('c', '<C-N>', '<Down>', { noremap = true })
  vim.api.nvim_set_keymap('c', '<C-P>', '<Up>', { noremap = true })
end

local function register_system_keybindings()
  vim.keymap.set('n', '<leader>sr', require('sys').reload_all)
end

local function register_paredit()
  local paredit = require('paredit')

  vim.api.nvim_create_autocmd({ "CursorMoved" }, { callback = paredit.highlight_surroundings })
  vim.keymap.set('v', '-', paredit.previous_selection)
  vim.keymap.set('v', '.', paredit.next_selection, { noremap = true })
  vim.keymap.set({ 'n', 'v' }, '<leader>pr', paredit.raise, { noremap = true })
  vim.keymap.set('n', '<leader>>', paredit.swallow, { noremap = true })
  vim.keymap.set('n', '<leader><', paredit.spew, { noremap = true })

  vim.api.nvim_create_autocmd("InsertCharPre", {
    callback = function()
      paredit.on_insert_char(vim.v.char)
    end,
  })

  vim.keymap.set('i', '<BS>', function()
    if paredit.should_remove_block() then
      return "<Esc>x"
    end
    return "<Bs>"
  end, { remap = true, expr = true })

  vim.keymap.set('n', 'x', function()
    if paredit.remove_block() then
      return ""
    end
    return "x"
  end, { remap = true, expr = true })
end

function keybindings.register()
  register_bash_like_navigation_on_command_prompt()
  register_buffer_keybindings()
  register_telescope()
  register_system_keybindings()
  register_paredit()
end

return keybindings
