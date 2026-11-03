local logic = require 'features.git.logic'
local M = {}

function M.notify(message) vim.notify(message) end
function M.warn(message) vim.notify(message, vim.log.levels.WARN) end
function M.change_sign_base(ref) require('gitsigns').change_base(ref, true) end
function M.status() Snacks.picker.git_status() end
function M.lazygit() Snacks.lazygit() end

function M.choose_base(branches, current, on_select)
  local items, selected_idx = {}, 1
  for i, branch in ipairs(branches) do
    local selected = branch.name == current
    items[#items + 1] = {
      text = (selected and '● ' or '  ') .. branch.name .. '  (' .. branch.relative .. ')',
      branch = branch.name,
    }
    if selected then selected_idx = i end
  end
  Snacks.picker.pick {
    title = 'Git Compare Base',
    items = items,
    format = 'text',
    layout = { preset = 'select' },
    sort = { fields = { 'idx' } },
    on_show = function(picker) picker.list:view(selected_idx) end,
    confirm = function(picker, item)
      picker:close()
      if item and item.branch then on_select(item.branch) end
    end,
  }
end

-- Filter parsed hunks, not raw process lines (which have no item.file).
local function diff_finder(file)
  return function(opts, ctx)
    local find = require('snacks.picker.source.git').diff(opts, ctx)
    return function(cb)
      find(function(item)
        if file and item.file ~= file then return end
        local line, changes = logic.diff_summary(item.diff, item.pos and item.pos[1])
        item.change = changes
        if file then item.pos = { line, 0 } end
        cb(item)
      end)
    end
  end
end

function M.choose_file(branch, on_select)
  Snacks.picker.git_diff {
    base = branch,
    group = true,
    title = 'Git Branch Changes (vs ' .. branch .. ')',
    sort = { fields = { 'score:desc', 'change:desc', 'file', 'idx' } },
    finder = diff_finder(),
    confirm = function(picker, item)
      picker:close()
      if item and item.file then vim.schedule(function() on_select(item.file) end) end
    end,
  }
end

-- Reuse the branch diff source so deleted files and committed changes stay visible.
local function tree_finder(collapsed)
  return function(opts, ctx)
    local find = diff_finder()(opts, ctx)
    return function(cb)
      local paths, files = {}, {}
      find(function(item)
        if not files[item.file] then paths[#paths + 1] = item.file end
        files[item.file] = item
      end)
      local function emit(nodes, parent)
        for i, node in ipairs(nodes) do
          local item = node.directory and { file = node.path, cwd = ctx:cwd(), dir = true } or files[node.path]
          item.text, item.pos = node.path, nil
          item.parent, item.last = parent, i == #nodes
          item.open = node.directory and not collapsed[node.path]
          cb(item)
          if item.open then emit(node.children, item) end
        end
      end
      emit(logic.file_tree(paths), { root = true })
    end
  end
end

function M.choose_tree(branch, on_select)
  local collapsed = {}
  Snacks.picker.git_diff {
    base = branch,
    group = true,
    title = 'Git Branch Tree (vs ' .. branch .. ')',
    layout = { preset = 'vertical', preview = false },
    format = 'file',
    formatters = { file = { filename_only = true } },
    matcher = { keep_parents = true, sort_empty = false },
    sort = { fields = { 'idx' } },
    finder = tree_finder(collapsed),
    preview = function(ctx)
      local preview = require 'snacks.picker.preview'
      return (ctx.item.dir and preview.none or preview.diff)(ctx)
    end,
    -- The tree includes directory rows, so it only offers browsing operations.
    win = { input = { keys = { ['<Tab>'] = { 'list_down', mode = { 'n', 'i' } }, ['<c-r>'] = false } } },
    confirm = function(picker, item)
      if not item then return end
      if item.dir then
        collapsed[item.file] = not collapsed[item.file]
        picker.list:set_target()
        picker:find { refresh = true }
        return
      end
      picker:close()
      vim.schedule(function() on_select(item.file) end)
    end,
  }
end

-- Confirming jumps in the editor; cancelling returns to the caller's file list.
function M.choose_hunk(branch, file, on_back)
  local jumping = false
  Snacks.picker.git_diff {
    base = branch,
    group = false,
    show_test = true,
    title = 'Hunks: ' .. file .. ' (Esc: back)',
    auto_confirm = true,
    finder = diff_finder(file),
    confirm = function(picker, item, action)
      jumping = true
      require('snacks.picker.actions').jump(picker, item, action or {})
    end,
    on_close = function()
      if not jumping then vim.schedule(on_back) end
    end,
  }
end

function M.open_diffview(branch) vim.cmd.DiffviewOpen { args = { branch .. '...HEAD', '--imply-local' } } end
function M.close_diffview() vim.cmd 'DiffviewClose' end

-- Replace the default checkout action with a callback carrying plain commit data.
function M.choose_commit(on_select)
  Snacks.picker.git_log_line {
    confirm = function(picker, item)
      picker:close()
      if item and item.commit then on_select { commit = item.commit, cwd = item.cwd, file = item.file } end
    end,
  }
end

function M.show_commit(lines)
  vim.cmd 'tabnew'
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.bo.swapfile = false
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.filetype = 'git'
  vim.bo.modifiable = false
  vim.bo.readonly = true
end

return M
