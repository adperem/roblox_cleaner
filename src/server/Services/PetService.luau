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
end

return PetService
