--!strict
local DataManager = require(game:GetService("ServerScriptService").Tris_bananaDataSystem.GithubDataManager)
local InventoryManager = require(game:GetService("ServerScriptService").Tris_bananaDataSystem.InventoryManager)

local StatManager = {}

--stat functions handlers
local statHandlers = {
	Wins = function(player: Player)
		print(player.Name .. " earned a win!")
		-- do custom logic here for gaining wins
	end,

	Level = function(player: Player)
		print(player.Name .. " leveled up!")
		-- do custom logic here for gaining levels
	end,
}

--stat changed, called from data manager
function StatManager.statChanged(player: Player, statName: string)
	DataManager.updateData(player, statName) --update data store
	
	--call handler
	local handler = statHandlers[statName]
	if handler then
		handler(player)
	end
end

return StatManager
