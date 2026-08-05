--!strict
--[[
	EventService — contratos VIP y Mega Suciedad (documento de diseño,
	secciones 5.2 y 5.3). Ambos son el mismo patrón: un objetivo compartido,
	contra el reloj, con recompensa repartida por cuánto aportó cada uno.

	CleaningService es quien mueve el `Progress` del objetivo tick a tick (es
	la única autoridad sobre la limpieza en sí); este servicio solo decide
	QUÉ objetivo está en evento ahora mismo, registra cuánto aportó cada
	jugador mientras dura, y reparte el dinero al terminar — por limpieza
	real o por que se acabó el tiempo, lo que llegue antes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Net = require(ReplicatedStorage.Shared.Net)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Zones = require(ReplicatedStorage.Shared.Config.Zones)
local TargetService = require(script.Parent.TargetService)
local PlayerDataService = require(script.Parent.PlayerDataService)

local EventService = {}

type EventState = {
	Kind: "Vip" | "Mega",
	Target: Part,
	EndsAt: number,
	RewardPool: number,
	XpPool: number,
	Contributions: { [Player]: number },
	TotalContribution: number,
}

local activeEvents: { [Part]: EventState } = {}
local activeEventTargetIds: { [string]: boolean } = {}
local lastVipAt = 0
local lastMegaAt = 0

function EventService.isEventTarget(target: Part): boolean
	return activeEvents[target] ~= nil
end

function EventService.addContribution(target: Part, player: Player, amount: number)
	local event = activeEvents[target]
	if not event then
		return
	end
	event.Contributions[player] = (event.Contributions[player] or 0) + amount
	event.TotalContribution += amount
end

local function payOut(event: EventState, finisher: Player?)
	for player, contribution in event.Contributions do
		if contribution <= 0 or not player.Parent then
			continue
		end
		local share = contribution / math.max(1, event.TotalContribution)
		local bonus = if finisher == player then GameConfig.VipFinisherBonus else 1
		local money = math.floor(event.RewardPool * share * bonus)
		local xp = math.floor(event.XpPool * share * bonus)
		if money > 0 then
			PlayerDataService.addMoney(player, money)
		end
		if xp > 0 then
			PlayerDataService.addXp(player, xp)
		end
		if money > 0 or xp > 0 then
			Net.getRemoteEvent("EventResolved"):FireClient(player, event.Kind, money, xp)
		end
	end
end

-- Llamado por CleaningService cuando un objetivo en evento llega al 100%.
function EventService.resolve(target: Part, finisher: Player)
	local event = activeEvents[target]
	if not event then
		return
	end
	activeEvents[target] = nil
	activeEventTargetIds[target:GetAttribute("TargetId")] = nil
	payOut(event, finisher)

	if event.Kind == "Vip" then
		task.delay(GameConfig.RespawnDelay, function()
			TargetService.reset(target)
		end)
	else
		local targetId = target:GetAttribute("TargetId") :: string
		task.delay(GameConfig.MegaDirtDespawnDelay, function()
			TargetService.unregister(targetId)
			target:Destroy()
		end)
		Net.getRemoteEvent("MegaDirtEnded"):FireAllClients(target)
	end
end

local function expireEvent(event: EventState)
	local target = event.Target
	activeEvents[target] = nil
	activeEventTargetIds[target:GetAttribute("TargetId")] = nil
	payOut(event, nil)

	if event.Kind == "Vip" then
		TargetService.reset(target)
	else
		local targetId = target:GetAttribute("TargetId") :: string
		TargetService.unregister(targetId)
		target:Destroy()
		Net.getRemoteEvent("MegaDirtEnded"):FireAllClients(target)
	end
end

local function pickVipTarget(): Part?
	local candidates = {}
	for _, zone in Zones do
		for _, def in zone.Targets do
			if activeEventTargetIds[def.Id] then
				continue
			end
			local part = TargetService.getById(def.Id)
			if part and part:GetAttribute("Cleaned") ~= true then
				table.insert(candidates, part)
			end
		end
	end
	if #candidates == 0 then
		return nil
	end
	return candidates[math.random(1, #candidates)]
end

local function startVipContract()
	local target = pickVipTarget()
	if not target then
		return
	end

	local basePayout = target:GetAttribute("Payout") :: number
	local baseXp = target:GetAttribute("XP") :: number
	local endsAt = os.time() + GameConfig.VipContractDuration

	target:SetAttribute("IsEvent", true)
	target:SetAttribute("EventEndsAt", endsAt)

	local targetId = target:GetAttribute("TargetId") :: string
	activeEventTargetIds[targetId] = true
	activeEvents[target] = {
		Kind = "Vip",
		Target = target,
		EndsAt = endsAt,
		RewardPool = basePayout * GameConfig.VipRewardMultiplier,
		XpPool = baseXp * GameConfig.VipRewardMultiplier,
		Contributions = {},
		TotalContribution = 0,
	}

	local name = target:GetAttribute("DisplayName") or target.Name
	Net.getRemoteEvent("ServerAnnouncement"):FireAllClients(
		`🚨 ¡CONTRATO VIP! Limpia "{name}" en menos de {GameConfig.VipContractDuration}s — ¡recompensa repartida entre todos los que ayuden!`
	)
end

local function findZone(id: string): Zones.ZoneDef
	for _, zone in Zones do
		if zone.Id == id then
			return zone
		end
	end
	return Zones[1]
end

local function startMegaDirt()
	local barrio = findZone("barrio")

	local part = Instance.new("Part")
	part.Name = "mega_dirt"
	part.Anchored = true
	part.CanCollide = true
	part.CanTouch = false
	part.Size = Vector3.new(20, 20, 20)
	part.CFrame = CFrame.new(barrio.Origin + Vector3.new(0, 10, -24))
	part.Color = Theme.Color.Dirty
	part.Material = Enum.Material.SmoothPlastic

	local targetId = "mega_dirt_" .. tostring(os.time())
	part:SetAttribute("TargetId", targetId)
	part:SetAttribute("DisplayName", "Mega Suciedad")
	part:SetAttribute("Progress", 0)
	part:SetAttribute("Payout", 0)
	part:SetAttribute("XP", 0)
	part:SetAttribute("Cleaned", false)
	part:SetAttribute("IsEvent", true)

	local endsAt = os.time() + GameConfig.MegaDirtDuration
	part:SetAttribute("EventEndsAt", endsAt)

	game:GetService("CollectionService"):AddTag(part, "DirtyTarget")
	part.Parent = Workspace
	TargetService.register(targetId, part)

	local playerCount = math.max(1, #Players:GetPlayers())
	activeEventTargetIds[targetId] = true
	activeEvents[part] = {
		Kind = "Mega",
		Target = part,
		EndsAt = endsAt,
		RewardPool = GameConfig.MegaDirtBaseReward * playerCount,
		XpPool = GameConfig.MegaDirtBaseXp * playerCount,
		Contributions = {},
		TotalContribution = 0,
	}

	Net.getRemoteEvent("ServerAnnouncement"):FireAllClients(
		`🏗️ ¡MEGA SUCIEDAD en el Barrio! Todo el servidor tiene {GameConfig.MegaDirtDuration / 60} minutos para limpiarla juntos.`
	)
	Net.getRemoteEvent("MegaDirtStarted"):FireAllClients(part, endsAt)
end

function EventService.start()
	lastVipAt = os.time()
	lastMegaAt = os.time()

	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.time()

			if now - lastVipAt >= GameConfig.VipContractInterval then
				lastVipAt = now
				startVipContract()
			end

			if now - lastMegaAt >= GameConfig.MegaDirtInterval then
				lastMegaAt = now
				startMegaDirt()
			end

			for _, event in activeEvents do
				if now >= event.EndsAt then
					expireEvent(event)
				end
			end
		end
	end)
end

return EventService
