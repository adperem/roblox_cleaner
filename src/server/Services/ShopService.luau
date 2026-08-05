--!strict
--[[ Compra de boquillas: solo la siguiente en la secuencia, solo si el
	servidor confirma que el jugador tiene el dinero. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Nozzles = require(ReplicatedStorage.Shared.Config.Nozzles)

local ShopService = {}

local function tryBuy(player: Player, requestedTier: unknown)
	if typeof(requestedTier) ~= "number" then
		return
	end
	local currentTier = player:GetAttribute("NozzleTier") :: number
	if requestedTier ~= currentTier + 1 then
		return
	end

	local nozzle = Nozzles[requestedTier]
	if not nozzle then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local money = leaderstats and leaderstats:FindFirstChild("Money") :: IntValue?
	if not money or money.Value < nozzle.Price then
		return
	end

	money.Value -= nozzle.Price
	player:SetAttribute("NozzleTier", nozzle.Tier)
end

function ShopService.start()
	Net.getRemoteEvent("RequestBuyNozzle").OnServerEvent:Connect(function(player, requestedTier)
		tryBuy(player, requestedTier)
	end)
end

return ShopService
