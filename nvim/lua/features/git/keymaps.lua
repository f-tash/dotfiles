local M = {}

function M.setup(actions)
  vim.keymap.set('n', '<leader>gB', actions.choose_base, { desc = '[G]it: set compare [B]ase' })
  vim.keymap.set('n', '<leader>gb', actions.branch_changes, { desc = '[G]it: [B]ranch changes (vs merge-base)' })
  vim.keymap.set('n', '<leader>gt', actions.branch_tree, { desc = '[G]it: branch changes [T]ree (vs merge-base)' })
  vim.keymap.set('n', '<leader>gv', actions.open_diffview, { desc = '[G]it: [V]iew branch diff (vs merge-base)' })
  vim.keymap.set('n', '<leader>gq', actions.close_diffview, { desc = '[G]it diff [Q]uit' })
  vim.keymap.set('n', '<leader>gs', actions.status, { desc = '[G]it: [S]tatus (uncommitted)' })
  vim.keymap.set('n', '<leader>gl', actions.line_history, { desc = '[G]it: [L]og (current line), Enter shows a read-only diff' })
  vim.keymap.set('n', '<leader>tb', actions.toggle_signs, { desc = '[T]oggle git [B]ranch diff base' })
  vim.keymap.set('n', '<leader>gg', actions.lazygit, { desc = '[G]it: Lazy[g]it' })
end

return M
