local M = {}

function M.setup(actions)
  vim.keymap.set('n', '<leader>e', actions.explorer, { desc = '[E]xplorer' })

  -- Kickstart-compatible search mappings.
  vim.keymap.set('n', '<leader>sh', actions.help, { desc = '[S]earch [H]elp' })
  vim.keymap.set('n', '<leader>sk', actions.keymaps, { desc = '[S]earch [K]eymaps' })
  vim.keymap.set('n', '<leader>sf', actions.files, { desc = '[S]earch [F]iles' })
  vim.keymap.set('n', '<leader>ss', actions.pickers, { desc = '[S]earch [S]elect Picker' })
  vim.keymap.set({ 'n', 'x' }, '<leader>sw', actions.grep_word, { desc = '[S]earch current [W]ord' })
  vim.keymap.set('n', '<leader>sg', actions.grep, { desc = '[S]earch by [G]rep' })
  vim.keymap.set('n', '<leader>sd', actions.diagnostics, { desc = '[S]earch [D]iagnostics' })
  vim.keymap.set('n', '<leader>sr', actions.resume, { desc = '[S]earch [R]esume' })
  vim.keymap.set('n', '<leader>s.', actions.recent, { desc = '[S]earch Recent Files ("." for repeat)' })
  vim.keymap.set('n', '<leader>sc', actions.commands, { desc = '[S]earch [C]ommands' })
  vim.keymap.set('n', '<leader><leader>', actions.buffers, { desc = '[ ] Find existing buffers' })
  vim.keymap.set('n', '<leader>/', actions.lines, { desc = '[/] Fuzzily search in current buffer' })
  vim.keymap.set('n', '<leader>s/', actions.grep_buffers, { desc = '[S]earch [/] in Open Files' })
  vim.keymap.set('n', '<leader>sn', actions.config_files, { desc = '[S]earch [N]eovim files' })

  -- LazyVim-style aliases. <leader>f also formats, so these wait for a second key.
  vim.keymap.set('n', '<leader>ff', actions.files, { desc = '[F]ind [F]iles' })
  vim.keymap.set('n', '<leader>fg', actions.grep, { desc = '[F]ind by [G]rep' })
  vim.keymap.set('n', '<leader>fr', actions.recent, { desc = '[F]ind [R]ecent' })
  vim.keymap.set('n', '<leader>fb', actions.buffers, { desc = '[F]ind [B]uffers' })

  -- Keep LSP pickers global; each picker reports when no server is attached.
  vim.keymap.set('n', 'grr', actions.references, { desc = '[G]oto [R]eferences' })
  vim.keymap.set('n', 'gri', actions.implementations, { desc = '[G]oto [I]mplementation' })
  vim.keymap.set('n', 'grd', actions.definitions, { desc = '[G]oto [D]efinition' })
  vim.keymap.set('n', 'grt', actions.type_definitions, { desc = '[G]oto [T]ype Definition' })
  vim.keymap.set('n', 'gO', actions.document_symbols, { desc = 'Open Document Symbols' })
  vim.keymap.set('n', 'gW', actions.workspace_symbols, { desc = 'Open Workspace Symbols' })
end

return M
