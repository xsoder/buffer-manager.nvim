-- buffer_manager_spec.lua
-- Basic tests for buffer-manager.nvim using busted

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Minimal vim mock for busted
if not _G.vim then
	_G.vim = {
		g = {},
		fn = setmetatable({}, {
			__index = function(_, key)
				return function()
					return nil
				end
			end,
		}),
		api = setmetatable({}, {
			__index = function(_, key)
				return function()
					return nil
				end
			end,
		}),
	}
end

local buffer_manager = require("buffer-manager")

describe("buffer-manager", function()
	it("should load the module", function()
		assert.is_table(buffer_manager)
	end)

	it("should have a setup function", function()
		assert.is_function(buffer_manager.setup)
	end)

	-- Add more tests as the plugin evolves
end)
