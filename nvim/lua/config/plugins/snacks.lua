local M = {}

-- Shared by search, Git review, and vim.ui.select (including LSP code actions).
local TEST_GLOBS = { '*test*', '*Test*' }
local NATIVE_EXCLUDE = { files = true, grep = true, explorer = true, git_files = true, smart = true }
local NO_FILTER = { git_diff = true }

local function is_test_path(path)
  if type(path) ~= 'string' then return false end
  local name = vim.fs.basename(path)
  return name:find('test', 1, true) ~= nil or name:find('Test', 1, true) ~= nil
end

-- Native globs keep empty directories out of explorer results. Other sources
-- filter parsed items; git_diff must keep its raw lines so hunks can be parsed.
local function sync_test_exclude(opts)
  local source = opts.source or ''
  if opts.show_test then
    if NATIVE_EXCLUDE[source] then opts.exclude = nil end
    if not NATIVE_EXCLUDE[source] and not NO_FILTER[source] then opts.transform = nil end
    -- Nothing is hidden, so allow a lone result to confirm when requested.
    if opts.auto_confirm == false then opts.auto_confirm = nil end
    return
  end

  if NATIVE_EXCLUDE[source] then
    opts.exclude = TEST_GLOBS
  elseif not NO_FILTER[source] then
    opts.transform = function(item)
      if is_test_path(Snacks.picker.util.path(item) or item.file) then return false end
    end
  end
  -- Show the list even with one visible result so users can reveal hidden files.
  opts.auto_confirm = false
end

function M.setup()
  vim.pack.add { 'https://github.com/folke/snacks.nvim' }
  require('snacks').setup {
    explorer = { enabled = true },
    picker = {
      enabled = true,
      -- Start on the result list so j/k work immediately.
      focus = 'list',
      ui_select = true,
      sources = {
        explorer = {
          -- Float over the editor and dismiss after opening a file.
          layout = { preset = 'vertical', preview = false },
          auto_close = true,
          jump = { close = true },
        },
      },
      show_test = false,
      toggles = { show_test = { icon = 'T', value = true } },
      actions = {
        toggle_test_filter = function(picker)
          picker.opts.show_test = not picker.opts.show_test
          sync_test_exclude(picker.opts)
          picker.list:set_target()
          picker:find { refresh = true }
        end,
      },
      win = {
        list = { keys = { ['T'] = 'toggle_test_filter' } },
        input = { keys = { ['T'] = 'toggle_test_filter', ['<a-t>'] = { 'toggle_test_filter', mode = { 'n', 'i' } } } },
      },
      -- Apply filtering before the finder starts its first search.
      config = function(opts)
        sync_test_exclude(opts)
        return opts
      end,
    },
    scroll = { enabled = true },
    indent = { enabled = true },
  }
end

return M
