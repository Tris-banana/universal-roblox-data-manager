-- Created by Tris_banana--		https://github.com/Tris-banana
--project link--           		https://github.com/Tris-banana/universal-roblox-data-manager

local scriptService = game:GetService("ServerScriptService")
local typeConversion = require(scriptService.Tris_bananaDataSystem:WaitForChild("TypeConversion"))

local players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local statStore = DataStoreService:GetDataStore("playerStats")

local DataManager = {}

--------------------------------------------------------------------------------------------

--data types
--[[ Here is where you define what variables you want in each
type of data storage.

RunTimeStats are stored when the player is in the game, once the
player leaves, this data is not saved and will get deleted.

PlayerStats are stored forever using data stores and will be
saved between sessions.

You will need to specify the type of data you want to store
and also initialize it further down
]]

--saved values
type PlayerStats = {
	--values for ingame leaderboard (top right)
	leaderstats: {
		Wins: number,
		Level: number,
	},
	--background values you dont want visible to players
	flags: {
		claimedGB: boolean, --claimed group bonus
		completedTutorial: boolean, --completed first join tutorial	
	},
	--inventory values (name as the key and number as the amount of that item)
	inventory: {
		[string]: number,
	}
}
--runtime temporary values
type RunTimeStats = {
	CurrentStage: number,
	ReviveStage: number
}

-- initialization of data holders
local sessionData: {[Player]: PlayerStats} = {}
local runTimeData: {[Player]: RunTimeStats} = {}

--------------------------------------------------------------------------------------------

--default values
--[[ This is where you create the default values of each stat you want stored.

Copy the exact name of the variable you initialized in the type above,
then put an "=" sign followed by the value you want to assign. 
These values have to be consistent with the type.
]]

--set the default values for new players
local function createDefaultStats(): PlayerStats
	return {
		leaderstats = {
			Wins = 0,
			Level = 0,
		},
		flags = {
			claimedGB = false,
			completedTutorial = false,
		},
		inventory = {}
	}
end
--create default runtime values
local function createDefaultRuntimeStats(): RunTimeStats
	return {
		CurrentStage = 1,
		ReviveStage = 1
	}
end

--[[ 
Don't touch any code below this line unless you know what you're doing.
]]
--------------------------------------------------------------------------------------------

--reconcile data to match new structures if they have been updated
local function reconcileData(defaults, data)
	for key, value in pairs(defaults) do
		if data[key] == nil then
			data[key] = value
		elseif typeof(value) == "table" and typeof(data[key]) == "table" then
			reconcileData(value, data[key]) -- recursive for nested tables
		end
	end
end

--------------------------------------------------------------------------------------------

--update data
function DataManager.updateData(player: Player, statKey: string?)
	local data = DataManager.getData(player)
	local defaultRuntime = createDefaultRuntimeStats()
	
	--update value directly, otherwise update every value if none specified
	if statKey then
		if player.leaderstats:FindFirstChild(statKey) then
			data.leaderstats[statKey] = player.leaderstats:FindFirstChild(statKey).Value
		elseif player:GetAttribute(statKey) ~= nil and defaultRuntime[statKey] == nil then
			data.flags[statKey] = player:GetAttribute(statKey)
		end
	else
		--automatically update every value
		for container, list in pairs(data) do
			--update leaderstats
			if container == "leaderstats" then
				for key, value in pairs(list) do
					--update data with leaderstats
					data[container][key] = player.leaderstats:FindFirstChild(key).Value
				end
				--update flags
			elseif container == "flags" then
				for key, value in pairs(list) do
					--update hidden data with attributes
					data[container][key] = player:GetAttribute(key)
				end
			end
		end
	end

	--print("updated "..player.Name.." stats")
end

--save player data
function DataManager.saveData(player: Player)
	DataManager.updateData(player) --update data
	local data = sessionData[player]
	
	--wrap request in pcall to catch errors
	local success, err = pcall(function()
		statStore:SetAsync("Stats_" .. player.UserId, data)
	end)

	--print success or failure
	if not success then
		warn("Data save failed:", err)
		return
	end
	print("saved "..player.Name.." stats")
end

--------------------------------------------------------------------------------------------

--loaders
--retrieve saved data
function DataManager.loadData(player: Player): PlayerStats
	local savedData: PlayerStats? = nil

	--wait for player to exist or leave the game
	repeat task.wait() until player.Parent or not player:IsDescendantOf(game)
	if not player.Parent then return createDefaultStats() end

	local success, err = pcall(function()
		savedData = statStore:GetAsync("Stats_" .. player.UserId)
	end)
	if not success then
		warn(err) -- warn if datastore retreival failed
	end

	--if player has saved data; load it
	if savedData then
		local defaultData = createDefaultStats()
		reconcileData(defaultData, savedData)
		sessionData[player] = savedData
	else
		sessionData[player] = createDefaultStats()
	end

	--create runtime temporary values (not saved)
	runTimeData[player] = createDefaultRuntimeStats()

	task.wait() --wait for stats to fully load
	
	--automatically create leaderstat and other values from saved data
	for container, list in pairs(sessionData[player]) do
		--create leaderstats objects
		if container == "leaderstats" then
			for key, value in pairs(list) do
				--create leaderstats object
				local newVal = Instance.new(typeConversion.GetClassName(value))
				newVal.Name = key
				newVal.Value = value
				newVal.Parent = player.leaderstats
				--print("created leaderstat "..key) --extra print statement for debugging purposes
			end
		--create attributes on player object
		elseif container == "flags" then
			--create saved flags
			for key, value in pairs(list) do
				player:SetAttribute(key, value)
				--print("created flag "..key) --extra print statement for debugging purposes
			end
			
			--create runtime flags
			local tempData = DataManager.getTempData(player)
			for key, value in pairs(tempData) do
				player:SetAttribute(key, value)
			end
		end
	end
	
	task.wait()
	--return loaded data
	return sessionData[player]
end

--------------------------------------------------------------------------------------------
--getters

--get saved data
function DataManager.getData(player: Player): PlayerStats
	--instantly return data if it is fully loaded
	if sessionData[player] then
		return sessionData[player]
	end
	
	-- yield and wait for data to finish loading
	local startTime = os.clock()
	while not sessionData[player] do
		-- if player leaves while waiting, safely return default stats
		if not player.Parent then return createDefaultStats() end

		-- timeout to prevent freezing if the DataStore crashes
		if os.clock() - startTime > 10 then
			warn("Data load timed out for player: " .. player.Name)
			return nil
		end

		task.wait(0.1)
	end
	
	return sessionData[player]
end

--get runtime data
function DataManager.getTempData(player: Player): RunTimeStats
	return runTimeData[player] or createDefaultRuntimeStats()
end

--------------------------------------------------------------------------------------------
--setters

--inventory setter
function DataManager.changeInventory(player: Player, item: string, amount: number?)
	local inv = DataManager.getData(player).inventory
	local qty = amount or 1
	
	if qty < 0 then
		--remove inventory
		if inv[item] > -qty then
			--remove quantity
			inv[item] += qty
		else
			--remove from inventory if 0
			inv[item] = nil
		end
	else
		--add item to inventory
		if inv[item] then
			inv[item] += qty
		else
			inv[item] = qty
		end
	end
	
	return inv
end

--------------------------------------------------------------------------------------------

--remove player from runtime storage
function DataManager.removePlayer(player: Player)
	if sessionData[player] then
		DataManager.saveData(player) --save
	end
	sessionData[player] = nil --remove player data
end

return DataManager
