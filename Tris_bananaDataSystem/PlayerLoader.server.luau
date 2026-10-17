local scriptService = game:GetService("ServerScriptService")

local DataManager = require(scriptService.Tris_bananaDataSystem.GithubDataManager)
local InventoryManager = require(scriptService.Tris_bananaDataSystem.InventoryManager)
local StatManager = require(scriptService.Tris_bananaDataSystem.StatManager)

local players = game:GetService("Players")
local closingTime = 3

--------------------------------------------------------------------------------------------
--player loading

--set data and default run speed
players.PlayerAdded:Connect(function(player)
	--load saved data
	local data = DataManager.loadData(player)
	local leaderstats = player:WaitForChild("leaderstats")
	
	--stat/attribute listeners trigger stat manager
	for _, stat in pairs(leaderstats:GetChildren()) do
		stat.Changed:Connect(function()
			StatManager.statChanged(player, stat.Name)
		end)
	end
	for attribute in player:GetAttributes() do
		player:GetAttributeChangedSignal(attribute):Connect(function()
			StatManager.statChanged(player, attribute)
		end)
	end
	
	--example on how to update physical values and have it automatically update data stores
	leaderstats:WaitForChild("Wins").Value += 1
	player:SetAttribute("claimedGB", false)
	player:SetAttribute("CurrentStage", 2)
	InventoryManager.editInventory(player, "sword", 2)
	--you can change these values in any server script if you have the player object
end)

-- player leaving
players.PlayerRemoving:Connect(function(player)
	DataManager.removePlayer(player) --remove player data
end)

--save player data when server closes
game:BindToClose(function()
	if game:GetService("RunService"):IsStudio() then
		task.wait(closingTime)
		return --cancel if running in studio
	end

	for _, player in ipairs(players:GetPlayers()) do
		DataManager.removePlayer(player)
		task.wait()
	end

	task.wait(closingTime)
end)
