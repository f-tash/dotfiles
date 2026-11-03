local M = {}

M.default_branches = { 'origin/main', 'origin/master', 'main', 'master', 'develop' }

local function pin_rank(name)
  if name == 'main' then return 1 end
  if name:match '/main$' then return 2 end
  if name == 'master' then return 3 end
  if name:match '/master$' then return 4 end
  return 5
end

-- Return a sorted copy without the current branch, symbolic HEADs, or duplicates.
function M.compare_branches(refs, current, remotes)
  local remote_names = {}
  for _, remote in ipairs(remotes) do
    remote_names[remote] = true
  end
  local branches, seen = {}, {}
  for _, ref in ipairs(refs) do
    local name = ref.name
    if not seen[name] and name ~= current and not name:match '/HEAD$' and not remote_names[name] then
      seen[name] = true
      branches[#branches + 1] = { name = name, relative = ref.relative, ts = ref.ts, rank = pin_rank(name) }
    end
  end
  table.sort(branches, function(a, b)
    if a.rank ~= b.rank then return a.rank < b.rank end
    if a.ts ~= b.ts then return a.ts > b.ts end
    return a.name < b.name
  end)
  return branches
end

-- Return the first changed working-tree line and total added/deleted line count.
function M.diff_summary(diff, start_line)
  local line_number = start_line or 1
  local first_change, in_hunk
  local changes = 0
  for line in tostring(diff or ''):gmatch '[^\n]+' do
    if line:find '^@@' then
      in_hunk = true
      line_number = tonumber(line:match '%+(%d+)') or line_number
    elseif in_hunk then
      local prefix = line:sub(1, 1)
      if prefix == '+' or prefix == '-' then
        first_change = first_change or line_number
        changes = changes + 1
      end
      if prefix == '+' or prefix == ' ' then line_number = line_number + 1 end
    end
  end
  return math.max(1, first_change or line_number), changes
end

-- Build a directory-first tree from repository-relative paths, without filesystem reads.
function M.file_tree(paths)
  local root = { children = {}, entries = {} }
  for _, path in ipairs(paths) do
    local parts = {}
    for part in path:gmatch '[^/]+' do
      parts[#parts + 1] = part
    end
    local parent, prefix = root, ''
    for i, name in ipairs(parts) do
      local directory = i < #parts
      local key = (directory and 'dir:' or 'file:') .. name
      prefix = prefix == '' and name or prefix .. '/' .. name
      local node = parent.entries[key]
      if not node then
        node = { name = name, path = prefix, directory = directory, children = {}, entries = {} }
        parent.entries[key] = node
        parent.children[#parent.children + 1] = node
      end
      parent = node
    end
  end
  local function sort(node)
    table.sort(node.children, function(a, b)
      if a.directory ~= b.directory then return a.directory end
      return a.name < b.name
    end)
    node.entries = nil
    for _, child in ipairs(node.children) do
      sort(child)
    end
  end
  sort(root)
  return root.children
end

return M
