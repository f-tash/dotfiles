local M = {}

-- Keep plugin and editor APIs here; shared plugin setup lives in config/plugins.
function M.explorer() Snacks.explorer() end
function M.help() Snacks.picker.help() end
function M.keymaps() Snacks.picker.keymaps() end
function M.files() Snacks.picker.files() end
function M.pickers() Snacks.picker.pickers() end
function M.grep_word() Snacks.picker.grep_word() end
function M.grep() Snacks.picker.grep() end
function M.diagnostics() Snacks.picker.diagnostics() end
function M.resume() Snacks.picker.resume() end
function M.recent() Snacks.picker.recent() end
function M.commands() Snacks.picker.commands() end
function M.buffers() Snacks.picker.buffers() end
function M.lines() Snacks.picker.lines() end
function M.grep_buffers() Snacks.picker.grep_buffers() end
function M.config_files() Snacks.picker.files { cwd = vim.fn.stdpath 'config', follow = true } end

function M.references() Snacks.picker.lsp_references() end
function M.implementations() Snacks.picker.lsp_implementations() end
function M.definitions() Snacks.picker.lsp_definitions() end
function M.type_definitions() Snacks.picker.lsp_type_definitions() end
function M.document_symbols() Snacks.picker.lsp_symbols() end
function M.workspace_symbols() Snacks.picker.lsp_workspace_symbols() end

return M
