local M = {}
local actions

function M.setup()
  -- Re-registering mappings must not reset the session's selected compare base.
  if not actions then
    require('features.git.plugins').setup()
    actions = require('features.git.actions').new {
      repository = require 'features.git.adapters.repository',
      view = require 'features.git.adapters.view',
    }
  end
  require('features.git.keymaps').setup(actions)
end

return M
