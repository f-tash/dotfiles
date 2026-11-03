local M = {}

-- Return data or an error; callers decide how failures should be presented.
local function git(args)
  local output = vim.fn.systemlist(vim.list_extend({ 'git' }, args))
  if vim.v.shell_error == 0 then return output end
  return nil, table.concat(output, '\n')
end

local function first_line(args)
  local output = git(args)
  if output and output[1] and output[1] ~= '' then return output[1] end
end

function M.remote_default_branch() return first_line { 'symbolic-ref', '--short', 'refs/remotes/origin/HEAD' } end
function M.has_ref(ref) return git { 'rev-parse', '--verify', '--quiet', ref } ~= nil end
function M.merge_base(branch) return first_line { 'merge-base', 'HEAD', branch } end
function M.current_branch() return first_line { 'branch', '--show-current' } end
function M.remotes() return git { 'remote' } or {} end

function M.branches()
  local lines = git {
    'for-each-ref',
    '--sort=-committerdate',
    '--format=%(refname:short)\t%(committerdate:relative)\t%(committerdate:unix)',
    'refs/heads/',
    'refs/remotes/',
  }
  local branches = {}
  for _, line in ipairs(lines or {}) do
    local name, relative, ts = line:match '^([^\t]+)\t([^\t]+)\t(%d+)$'
    if name then branches[#branches + 1] = { name = name, relative = relative, ts = tonumber(ts) } end
  end
  return branches
end

function M.show_commit(revision)
  local args = { '-C', revision.cwd or vim.fn.getcwd(), 'show', '--no-ext-diff', '--no-color', revision.commit }
  if revision.file then vim.list_extend(args, { '--', revision.file }) end
  return git(args)
end

return M
