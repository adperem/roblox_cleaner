--!strict
--[[ Dinero y boquilla equipada por jugador. Prototipo: en memoria, sin
	persistencia todavía (llega en la Fase 2 con ProfileStore). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Nozzles = require(ReplicatedStorage.Shared.Config.Nozzles)

local PlayerDataService = {}

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = GameConfig.StartingMoney
	money.Parent = leaderstats

	-- Atributo propiedad del servidor: un LocalScript puede llamarlo con
	-- SetAttribute sin que ese cambio llegue nunca al servidor ni a otros
	-- clientes, así que leer esto en el servidor sigue siendo seguro.
	player:SetAttribute("NozzleTier", Nozzles[1].Tier)
end

function PlayerDataService.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return PlayerDataService
