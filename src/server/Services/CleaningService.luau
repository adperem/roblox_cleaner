--!strict
--[[
	CleaningService — el núcleo del juego. Autoridad total del servidor:

	El cliente solo puede decir "estoy apuntando a este objetivo, sí/no".
	El servidor decide cuánto avanza el progreso (según la boquilla que ÉL
	mismo tiene registrada para ese jugador, no la que el cliente diga tener),
	valida la distancia en cada tick, gasta y rellena el depósito de agua de
	cada jugador, y es el único que toca el dinero y la XP (a través de
	PlayerDataService). Ningún número que importe para la economía viaja
	nunca desde el cliente.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = require(ReplicatedStorage.Shared.Net)
local Nozzles = require(ReplicatedStorage.Shared.Config.Nozzles)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local TargetService = require(script.Parent.TargetService)
local PlayerDataService = require(script.Parent.PlayerDataService)

local CleaningService = {}

-- jugador -> objetivo que está limpiando ahora mismo (o nil)
local activeSessions: { [Player]: Part } = {}

local function getNozzlePower(player: Player): number
	local tier = player:GetAttribute("NozzleTier")
	for _, nozzle in Nozzles do
		if nozzle.Tier == tier then
			return nozzle.Power
		end
	end
	return Nozzles[1].Power
end

local function isInRange(player: Player, target: Part): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end
	return (root.Position - target.Position).Magnitude <= GameConfig.SprayRange
end

local function isCleaned(target: Part): boolean
	return target:GetAttribute("Cleaned") == true
end

local function tick(dt: number)
	local drainedThisTick: { [Player]: boolean } = {}

	for player, target in activeSessions do
		if not target.Parent then
			activeSessions[player] = nil
			continue
		end
		-- Otro jugador pudo haber completado este mismo objetivo en esta
		-- misma pasada (varios pueden apuntar a la vez, es cooperativo):
		-- si ya está marcado como limpio, no se vuelve a pagar.
		if isCleaned(target) then
			activeSessions[player] = nil
			continue
		end
		if not isInRange(player, target) then
			continue
		end

		local tank = (player:GetAttribute("WaterTank") :: number?) or GameConfig.WaterTankMax
		if tank <= 0 then
			continue -- sin agua: no limpia hasta que se rellene
		end

		local power = getNozzlePower(player)
		local progress = math.min(100, (target:GetAttribute("Progress") :: number) + power * dt)
		target:SetAttribute("Progress", progress)
		player:SetAttribute("WaterTank", math.max(0, tank - GameConfig.WaterDrainRate * dt))
		drainedThisTick[player] = true

		if progress >= 100 then
			target:SetAttribute("Cleaned", true)
			activeSessions[player] = nil

			local payout = target:GetAttribute("Payout") :: number
			local xp = target:GetAttribute("XP") :: number
			PlayerDataService.grantCleaningReward(player, payout, xp)
			Net.getRemoteEvent("TargetCompleted"):FireClient(player, target:GetAttribute("TargetId"), payout)

			task.delay(GameConfig.RespawnDelay, function()
				TargetService.reset(target)
			end)
		end
	end

	-- Rellena el depósito de todo el mundo salvo quien lo esté gastando ahora mismo.
	for _, player in Players:GetPlayers() do
		if drainedThisTick[player] then
			continue
		end
		local tank = (player:GetAttribute("WaterTank") :: number?) or GameConfig.WaterTankMax
		if tank < GameConfig.WaterTankMax then
			player:SetAttribute("WaterTank", math.min(GameConfig.WaterTankMax, tank + GameConfig.WaterRefillRate * dt))
		end
	end
end

function CleaningService.start()
	local setSpraying = Net.getRemoteEvent("SetSpraying")
	setSpraying.OnServerEvent:Connect(function(player: Player, targetId: unknown, isSpraying: unknown)
		if isSpraying ~= true then
			activeSessions[player] = nil
			return
		end
		if typeof(targetId) ~= "string" then
			return
		end
		local target = TargetService.getById(targetId)
		if target and not isCleaned(target) and isInRange(player, target) then
			activeSessions[player] = target
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		activeSessions[player] = nil
	end)

	local accumulated = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulated += dt
		local step = 1 / GameConfig.ServerTickHz
		if accumulated >= step then
			tick(accumulated)
			accumulated = 0
		end
	end)
end

return CleaningService
