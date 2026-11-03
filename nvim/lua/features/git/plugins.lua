local M = {}

-- Snacks is shared via config/plugins/snacks.lua; which-key stays in init.lua.
function M.setup()
  vim.pack.add {
    'https://github.com/lewis6991/gitsigns.nvim',
    'https://github.com/nvim-lua/plenary.nvim',
    'https://github.com/sindrets/diffview.nvim',
  }
  require('gitsigns').setup {
    signs = {
      add = { text = '+' }, ---@diagnostic disable-line: missing-fields
      change = { text = '~' }, ---@diagnostic disable-line: missing-fields
      delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
      topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
      changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
    },
  }
  require('diffview').setup {}
end

return M
