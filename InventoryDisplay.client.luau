local invEvent = game:GetService("ReplicatedStorage").Events.InventoryEvent
local player = game:GetService("Players").LocalPlayer

--request inventory from data manager
invEvent:FireServer()

--retrieve inventory data
invEvent.OnClientEvent:Connect(function(inventory)
	--display inventory (change your UI here)
	print(player.Name.."'s inventory: ")
	print(inventory)
end)
