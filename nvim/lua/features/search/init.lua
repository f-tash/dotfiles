local M = {}

function M.setup()
  -- Each search operation is a single picker action, so no workflow layer is needed.
  require('features.search.keymaps').setup(require 'features.search.adapters.snacks')
end

return M
