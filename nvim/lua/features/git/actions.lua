local logic = require 'features.git.logic'
local M = {}

-- The entry point supplies repository and view operations; no editor APIs here.
function M.new(deps)
  local repository, view = deps.repository, deps.view
  local actions = {}
  local compare_base
  local on_branch_base = false

  local function current_base()
    if compare_base then return compare_base end
    local branch = repository.remote_default_branch()
    if branch then return branch end
    for _, candidate in ipairs(logic.default_branches) do
      if repository.has_ref(candidate) then return candidate end
    end
  end

  local function merge_base(branch)
    local ref = repository.merge_base(branch)
    if ref then return ref end
    view.warn('git: merge-base with ' .. branch .. ' failed')
  end

  local function resolve_base()
    local branch = current_base()
    if not branch then
      view.warn 'git: could not find a compare base (try <leader>gB)'
      return
    end
    local ref = merge_base(branch)
    if ref then return branch, ref end
  end

  local function set_base(branch)
    local ref = merge_base(branch)
    if not ref then return end
    compare_base = branch
    if on_branch_base then view.change_sign_base(ref) end
    view.notify('compare base: ' .. branch)
  end

  function actions.choose_base()
    local refs = repository.branches()
    local branches = #refs > 0 and logic.compare_branches(refs, repository.current_branch(), repository.remotes()) or {}
    if #branches == 0 then
      view.warn 'git: no comparison branches found'
      return
    end
    view.choose_base(branches, current_base(), set_base)
  end

  function actions.toggle_signs()
    if on_branch_base then
      -- Explicit HEAD includes staged changes as well as unstaged changes.
      view.change_sign_base 'HEAD'
      on_branch_base = false
      view.notify 'gitsigns base: HEAD (uncommitted only)'
      return
    end
    local branch, ref = resolve_base()
    if not ref then return end
    view.change_sign_base(ref)
    on_branch_base = true
    view.notify('gitsigns base: merge-base(' .. branch .. ') - all branch changes')
  end

  local function browse_changes(choose_files)
    local branch = resolve_base()
    if not branch then return end
    local function show_files()
      choose_files(branch, function(file) view.choose_hunk(branch, file, show_files) end)
    end
    show_files()
  end

  function actions.branch_changes() browse_changes(view.choose_file) end
  function actions.branch_tree() browse_changes(view.choose_tree) end

  function actions.open_diffview()
    local branch = resolve_base()
    if branch then view.open_diffview(branch) end
  end

  function actions.line_history()
    view.choose_commit(function(revision)
      local lines, err = repository.show_commit(revision)
      if not lines then
        view.warn('git show failed: ' .. err)
        return
      end
      view.show_commit(lines)
    end)
  end

  function actions.close_diffview() view.close_diffview() end
  function actions.status() view.status() end
  function actions.lazygit() view.lazygit() end

  return actions
end

return M
