--!strict
--[[
	GamepassService — comprueba y cachea (en un atributo) qué gamepasses
	tiene cada jugador. Los gamepasses con `ProductId = 0` en la config
	(Gamepasses.luau) todavía no existen en el Creator Dashboard, así que se
	tratan siempre como "no comprado" sin ni siquiera llamar a la API —
	llamar a MarketplaceService con el id 0 lanzaría un error.

	El efecto real de cada gamepass vive donde tiene sentido (Dinero x2 en
	PlayerDataService, el depósito VIP en CleaningService) — este servicio
	solo responde "¿lo tiene o no?".
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gamepasses = require(ReplicatedStorage.Shared.Config.Gamepasses)

local GamepassService = {}

local gamepassesById = {}
for _, gamepass in Gamepasses do
	gamepassesById[gamepass.Id] = gamepass
end

local function attributeName(id: string): string
	return "Owns_" .. id
end

local function checkOwnership(player: Player, id: string)
	local gamepass = gamepassesById[id]
	if not gamepass or gamepass.ProductId <= 0 then
		return
	end

	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepass.ProductId)
	end)
	if ok then
		player:SetAttribute(attributeName(id), owns)
	end
end

local function onPlayerAdded(player: Player)
	for _, gamepass in Gamepasses do
		task.spawn(checkOwnership, player, gamepass.Id)
	end
end

function GamepassService.playerOwns(player: Player, id: string): boolean
	return player:GetAttribute(attributeName(id)) == true
end

function GamepassService.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
		if not wasPurchased then
			return
		end
		for _, gamepass in Gamepasses do
			if gamepass.ProductId == gamepassId then
				player:SetAttribute(attributeName(gamepass.Id), true)
				return
			end
		end
	end)
end

return GamepassService
