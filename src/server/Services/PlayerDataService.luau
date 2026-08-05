--!strict
--[[
	PlayerDataService — único dueño y escritor del perfil guardado de cada
	jugador (dinero, XP, boquilla, progreso de misiones diarias). Todo lo
	demás lee/escribe a través de las funciones de este módulo, nunca tocando
	el `IntValue` de leaderstats ni el perfil directamente — así el
	leaderstat, los atributos que lee el HUD y lo que se guarda en el
	DataStore no pueden desincronizarse entre sí.

	Si el perfil no se puede cargar (típicamente: en Studio sin "Enable
	Studio Access to API Services" activado en Game Settings > Security), la
	partida sigue funcionando con datos solo en memoria — se avisa por
	consola y no se guarda nada al salir.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileStoreLib = require(script.Parent.Parent.ThirdParty.ProfileStore)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Nozzles = require(ReplicatedStorage.Shared.Config.Nozzles)
local Levels = require(ReplicatedStorage.Shared.Config.Levels)
local DailyMissions = require(ReplicatedStorage.Shared.Config.DailyMissions)

local PlayerDataService = {}

export type ProfileData = {
	Money: number,
	XP: number,
	NozzleTier: number,
	DayKey: string,
	TargetsCleanedToday: number,
	MoneyEarnedToday: number,
	ClaimedMissions: { [string]: boolean },
}

local TEMPLATE: ProfileData = {
	Money = GameConfig.StartingMoney,
	XP = 0,
	NozzleTier = Nozzles[1].Tier,
	DayKey = "",
	TargetsCleanedToday = 0,
	MoneyEarnedToday = 0,
	ClaimedMissions = {},
}

local missionsById = {}
for _, mission in DailyMissions do
	missionsById[mission.Id] = mission
end

local playerStore = ProfileStoreLib.New("PlayerStore_v1", TEMPLATE)

type LoadedProfile = {
	Data: ProfileData,
	release: () -> (),
}

local loaded: { [Player]: LoadedProfile } = {}

local function currentDayKey(): string
	return os.date("!%Y-%m-%d") :: string
end

local function ensureCurrentDay(data: ProfileData)
	local today = currentDayKey()
	if data.DayKey ~= today then
		data.DayKey = today
		data.TargetsCleanedToday = 0
		data.MoneyEarnedToday = 0
		data.ClaimedMissions = {}
	end
end

local function syncAttributes(player: Player, data: ProfileData)
	local leaderstats = player:FindFirstChild("leaderstats")
	local money = leaderstats and leaderstats:FindFirstChild("Money") :: IntValue?
	if money then
		money.Value = data.Money
	end
	player:SetAttribute("NozzleTier", data.NozzleTier)
	player:SetAttribute("XP", data.XP)
	player:SetAttribute("Level", Levels.levelForXp(data.XP))
	player:SetAttribute("TargetsCleanedToday", data.TargetsCleanedToday)
	player:SetAttribute("MoneyEarnedToday", data.MoneyEarnedToday)
	for _, mission in DailyMissions do
		local claimed: boolean = data.ClaimedMissions[mission.Id] == true
		player:SetAttribute("Claimed_" .. mission.Id, claimed)
	end
end

local function loadProfile(player: Player): LoadedProfile
	local profile = playerStore:StartSessionAsync(tostring(player.UserId), {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile.OnSessionEnd:Connect(function()
			loaded[player] = nil
			if player.Parent then
				player:Kick("Tu partida se abrió en otra sesión. Vuelve a entrar.")
			end
		end)
		return {
			Data = profile.Data :: ProfileData,
			release = function()
				profile:EndSession()
			end,
		}
	end

	warn(`[PlayerDataService] No se pudo cargar el perfil de {player.Name}; esta partida no se guardará.`)
	return {
		Data = table.clone(TEMPLATE),
		release = function() end,
	}
end

local function onPlayerAdded(player: Player)
	local profile = loadProfile(player)
	if not player:IsDescendantOf(Players) then
		profile.release()
		return
	end
	ensureCurrentDay(profile.Data)
	loaded[player] = profile

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Parent = leaderstats

	player:SetAttribute("WaterTank", GameConfig.WaterTankMax)
	syncAttributes(player, profile.Data)
end

local function onPlayerRemoving(player: Player)
	local profile = loaded[player]
	if profile then
		loaded[player] = nil
		profile.release()
	end
end

function PlayerDataService.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

function PlayerDataService.getData(player: Player): ProfileData?
	local profile = loaded[player]
	return profile and profile.Data
end

function PlayerDataService.addMoney(player: Player, amount: number)
	local profile = loaded[player]
	if not profile then
		return
	end
	profile.Data.Money = math.max(0, profile.Data.Money + amount)
	syncAttributes(player, profile.Data)
end

function PlayerDataService.setNozzleTier(player: Player, tier: number)
	local profile = loaded[player]
	if not profile then
		return
	end
	profile.Data.NozzleTier = tier
	syncAttributes(player, profile.Data)
end

-- Recompensa por completar un objetivo de limpieza: dinero + XP + los
-- contadores que alimentan las misiones diarias, todo en un solo golpe.
function PlayerDataService.grantCleaningReward(player: Player, money: number, xp: number)
	local profile = loaded[player]
	if not profile then
		return
	end
	ensureCurrentDay(profile.Data)
	profile.Data.Money += money
	profile.Data.XP += xp
	profile.Data.TargetsCleanedToday += 1
	profile.Data.MoneyEarnedToday += money
	syncAttributes(player, profile.Data)
end

function PlayerDataService.claimMission(player: Player, missionId: string): boolean
	local profile = loaded[player]
	if not profile then
		return false
	end
	ensureCurrentDay(profile.Data)

	local mission = missionsById[missionId]
	if not mission or profile.Data.ClaimedMissions[missionId] == true then
		return false
	end

	local progress = if mission.Type == "TargetsCleaned"
		then profile.Data.TargetsCleanedToday
		else profile.Data.MoneyEarnedToday
	if progress < mission.Goal then
		return false
	end

	profile.Data.ClaimedMissions[missionId] = true
	profile.Data.Money += mission.MoneyReward
	profile.Data.XP += mission.XpReward
	syncAttributes(player, profile.Data)
	return true
end

return PlayerDataService
