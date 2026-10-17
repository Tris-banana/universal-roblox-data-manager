--!strict
local DataManager = require(game:GetService("ServerScriptService").Tris_bananaDataSystem:WaitForChild("GithubDataManager"))
local invEvent = game:GetService("ReplicatedStorage").Events.InventoryEvent

local InventoryManager = {}

--return inventory data to the client
invEvent.OnServerEvent:Connect(function(player)
	local inv = DataManager.getData(player).inventory
	--return inventory data back to client
	invEvent:FireClient(player, inv)
end)

--input positive amount to give, and negative amount to remove
function InventoryManager.editInventory(player: Player, item: string, amount: number?)
	local inv = DataManager.changeInventory(player, item, amount)
	--fire client with edited inventory
	invEvent:FireClient(player, inv)
end

return InventoryManager
