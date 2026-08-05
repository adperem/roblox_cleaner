--!strict
--[[ Compra de huevos y equipar mascotas. El sorteo lo hace el servidor
	(Eggs.roll usa math.random, nunca algo que el cliente pueda influir). ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Eggs = require(ReplicatedStorage.Shared.Config.Eggs)
local PlayerDataService = require(script.Parent.PlayerDataService)

local PetService = {}

local function tryBuyEgg(player: Player, eggId: string)
	local egg = Eggs.getById(eggId)
	if not egg then
		return
	end

	local data = PlayerDataService.getData(player)
	if not data or data.Money < egg.Price then
		return
	end

	PlayerDataService.addMoney(player, -egg.Price)
	local petId = Eggs.roll(egg)
	PlayerDataService.addPet(player, petId)
	Net.getRemoteEvent("PetHatched"):FireClient(player, petId)
end

local function tryEquipPet(player: Player, petId: string?)
	PlayerDataService.setEquippedPet(player, petId)
end

local function tryFusePets(player: Player, petId: string, tier: string)
	local success, resultKey = PlayerDataService.fusePets(player, petId, tier)
	if success then
		Net.getRemoteEvent("PetFused"):FireClient(player, resultKey)
	end
end

function PetService.start()
	Net.getRemoteEvent("RequestBuyEgg").OnServerEvent:Connect(function(player, eggId)
		if typeof(eggId) == "string" then
			tryBuyEgg(player, eggId)
		end
	end)

	Net.getRemoteEvent("RequestEquipPet").OnServerEvent:Connect(function(player, petId)
		if petId == nil or typeof(petId) == "string" then
			tryEquipPet(player, petId)
		end
	end)

	Net.getRemoteEvent("RequestFusePets").OnServerEvent:Connect(function(player, petId, tier)
		if typeof(petId) == "string" and typeof(tier) == "string" then
			tryFusePets(player, petId, tier)
		end
	end)
end

return PetService
