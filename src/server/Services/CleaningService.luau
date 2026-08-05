--!strict
--[[
	CleaningService — el núcleo del juego. Autoridad total del servidor:

	El cliente solo puede decir "estoy apuntando a este objetivo, sí/no".
	El servidor decide cuánto avanza el progreso (según la boquilla que ÉL
	mismo tiene registrada para ese jugador, no la que el cliente diga tener),
	valida la distancia en cada tick, gasta y rellena el depósito de agua de
	cada jugador (más grande y más rápido con el gamepass VIP), aplica la
	mutación del objetivo y el bonus de la mascota equipada al pagar, y es el
	único que toca el dinero y la XP (a través de PlayerDataService). Ningún
	número que importe para la economía viaja nunca desde el cliente.

	Si el objetivo está marcado como evento (contrato VIP o Mega Suciedad),
	el pago no sale de aquí: se registra cuánto aportó cada jugador y es
	EventService quien reparte la recompensa al terminar.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = require(ReplicatedStorage.Shared.Net)
local Nozzles = require(ReplicatedStorage.Shared.Config.Nozzles)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local Pets = require(ReplicatedStorage.Shared.Config.Pets)
local TargetService = require(script.Parent.TargetService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local GamepassService = require(script.Parent.GamepassService)
local EventService = require(script.Parent.EventService)

local CleaningService = {}

local petsById = {}
for _, pet in Pets do
	petsById[pet.Id] = pet
end

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

local function getPetMultiplier(player: Player): number
	local equippedId = player:GetAttribute("EquippedPet")
	if typeof(equippedId) ~= "string" then
		return 1
	end
	local pet = petsById[equippedId]
	return if pet then 1 + pet.Multiplier else 1
end

local function getWaterLimits(player: Player): (number, number, number)
	local isVip = GamepassService.playerOwns(player, "VIP")
	local scale = if isVip then GameConfig.VipWaterMultiplier else 1
	return GameConfig.WaterTankMax * scale, GameConfig.WaterDrainRate * scale, GameConfig.WaterRefillRate * scale
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

local function payoutNormalTarget(player: Player, target: Part)
	local mutation = Mutations.getById(target:GetAttribute("MutationId") :: string?)
	local basePayout = (target:GetAttribute("Payout") :: number) * mutation.Multiplier
	local baseXp = (target:GetAttribute("XP") :: number) * mutation.Multiplier
	local petMultiplier = getPetMultiplier(player)

	local finalPayout = math.floor(basePayout * petMultiplier)
	local finalXp = math.floor(baseXp)

	PlayerDataService.grantCleaningReward(player, finalPayout, finalXp)
	Net.getRemoteEvent("TargetCompleted"):FireClient(player, target:GetAttribute("TargetId"), finalPayout)
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

		local tankMax, drainRate, refillRate = getWaterLimits(player)
		local tank = (player:GetAttribute("WaterTank") :: number?) or tankMax
		if tank <= 0 then
			continue -- sin agua: no limpia hasta que se rellene
		end

		local power = getNozzlePower(player)
		local increment = power * dt
		local progress = math.min(100, (target:GetAttribute("Progress") :: number) + increment)
		target:SetAttribute("Progress", progress)
		player:SetAttribute("WaterTank", math.max(0, tank - drainRate * dt))
		drainedThisTick[player] = true

		local isEvent = target:GetAttribute("IsEvent") == true
		if isEvent then
			EventService.addContribution(target, player, increment)
		end

		if progress >= 100 then
			target:SetAttribute("Cleaned", true)
			activeSessions[player] = nil

			if isEvent then
				EventService.resolve(target, player)
			else
				payoutNormalTarget(player, target)
				task.delay(GameConfig.RespawnDelay, function()
					TargetService.reset(target)
				end)
			end
		end
	end

	-- Rellena el depósito de todo el mundo salvo quien lo esté gastando ahora mismo.
	for _, player in Players:GetPlayers() do
		if drainedThisTick[player] then
			continue
		end
		local tankMax, _, refillRate = getWaterLimits(player)
		local tank = (player:GetAttribute("WaterTank") :: number?) or tankMax
		if tank < tankMax then
			player:SetAttribute("WaterTank", math.min(tankMax, tank + refillRate * dt))
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
