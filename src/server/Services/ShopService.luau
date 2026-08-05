--!strict
--[[ Compra de boquillas: solo la siguiente en la secuencia, solo si el
	servidor confirma que el jugador tiene el dinero. Toda la mutación pasa
	por PlayerDataService para que quede reflejada en el perfil guardado. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Nozzles = require(ReplicatedStorage.Shared.Config.Nozzles)
local PlayerDataService = require(script.Parent.PlayerDataService)

local ShopService = {}

local function tryBuy(player: Player, requestedTier: unknown)
	if typeof(requestedTier) ~= "number" then
		return
	end

	local data = PlayerDataService.getData(player)
	if not data then
		return
	end
	if requestedTier ~= data.NozzleTier + 1 then
		return
	end

	local nozzle = Nozzles[requestedTier]
	if not nozzle or data.Money < nozzle.Price then
		return
	end

	PlayerDataService.addMoney(player, -nozzle.Price)
	PlayerDataService.setNozzleTier(player, nozzle.Tier)
end

function ShopService.start()
	Net.getRemoteEvent("RequestBuyNozzle").OnServerEvent:Connect(function(player, requestedTier)
		tryBuy(player, requestedTier)
	end)
end

return ShopService
