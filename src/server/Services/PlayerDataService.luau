--!strict
--[[
	PlayerDataService — único dueño y escritor del perfil guardado de cada
	jugador (dinero, XP, boquilla, mascotas, rebirth, pase de temporada,
	códigos canjeados, progreso de misiones diarias). Todo lo demás
	lee/escribe a través de las funciones de este módulo, nunca tocando el
	`IntValue` de leaderstats ni el perfil directamente — así el leaderstat,
	los atributos que lee el HUD y lo que se guarda en el DataStore no
	pueden desincronizarse entre sí. También es el único punto donde se
	aplican el gamepass de Dinero x2 y el bonus de rebirth, para que valgan
	en todos los sitios donde se gana dinero sin repetir la lógica en cada uno.

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
local Pets = require(ReplicatedStorage.Shared.Config.Pets)
local Rebirths = require(ReplicatedStorage.Shared.Config.Rebirths)
local SeasonPass = require(ReplicatedStorage.Shared.Config.SeasonPass)
local Codes = require(ReplicatedStorage.Shared.Config.Codes)
local GamepassService = require(script.Parent.GamepassService)

local PlayerDataService = {}

export type ProfileData = {
	Money: number,
	XP: number,
	NozzleTier: number,
	DayKey: string,
	TargetsCleanedToday: number,
	MoneyEarnedToday: number,
	ClaimedMissions: { [string]: boolean },
	OwnedPets: { [string]: number },
	EquippedPet: string?,
	RebirthCount: number,
	SeasonTokens: number,
	ClaimedSeasonTiers: { [string]: boolean },
	RedeemedCodes: { [string]: boolean },
}

local TEMPLATE: ProfileData = {
	Money = GameConfig.StartingMoney,
	XP = 0,
	NozzleTier = Nozzles[1].Tier,
	DayKey = "",
	TargetsCleanedToday = 0,
	MoneyEarnedToday = 0,
	ClaimedMissions = {},
	OwnedPets = {},
	RebirthCount = 0,
	SeasonTokens = 0,
	ClaimedSeasonTiers = {},
	RedeemedCodes = {},
}

local missionsById = {}
for _, mission in DailyMissions do
	missionsById[mission.Id] = mission
end

local codesById = {}
for _, code in Codes do
	codesById[code.Code] = code
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

local function seasonTierKey(tier: number, track: string): string
	return `{tier}_{track}`
end

-- Único sitio donde se aplican el gamepass de Dinero x2 y el bonus de
-- rebirth. Solo a ganancias (montos positivos) — una compra en la tienda
-- resta dinero con esta misma función y no debería duplicarse el descuento.
local function applyMoneyMultiplier(player: Player, data: ProfileData, amount: number): number
	if amount <= 0 then
		return amount
	end
	local rebirthBonus = 1 + GameConfig.RebirthMoneyBonusPerCount * data.RebirthCount
	local gamepassBonus = if GamepassService.playerOwns(player, "MoneyX2") then 2 else 1
	return amount * rebirthBonus * gamepassBonus
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
	player:SetAttribute("EquippedPet", data.EquippedPet)
	player:SetAttribute("RebirthCount", data.RebirthCount)
	player:SetAttribute("Rank", Rebirths.rankForCount(data.RebirthCount))
	player:SetAttribute("SeasonTokens", data.SeasonTokens)

	for _, mission in DailyMissions do
		local claimed: boolean = data.ClaimedMissions[mission.Id] == true
		player:SetAttribute("Claimed_" .. mission.Id, claimed)
	end
	for _, pet in Pets do
		local count: number = data.OwnedPets[pet.Id] or 0
		player:SetAttribute("PetCount_" .. pet.Id, count)
	end
	for _, tier in SeasonPass.Tiers do
		local freeClaimed: boolean = data.ClaimedSeasonTiers[seasonTierKey(tier.Tier, "Free")] == true
		local premiumClaimed: boolean = data.ClaimedSeasonTiers[seasonTierKey(tier.Tier, "Premium")] == true
		player:SetAttribute(`SeasonClaimed_{tier.Tier}_Free`, freeClaimed)
		player:SetAttribute(`SeasonClaimed_{tier.Tier}_Premium`, premiumClaimed)
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
	profile.Data.Money = math.max(0, profile.Data.Money + applyMoneyMultiplier(player, profile.Data, amount))
	syncAttributes(player, profile.Data)
end

function PlayerDataService.addXp(player: Player, amount: number)
	local profile = loaded[player]
	if not profile then
		return
	end
	profile.Data.XP += amount
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
	local finalMoney = applyMoneyMultiplier(player, profile.Data, money)
	profile.Data.Money += finalMoney
	profile.Data.XP += xp
	profile.Data.TargetsCleanedToday += 1
	profile.Data.MoneyEarnedToday += finalMoney
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
	profile.Data.Money += applyMoneyMultiplier(player, profile.Data, mission.MoneyReward)
	profile.Data.XP += mission.XpReward
	profile.Data.SeasonTokens += mission.SeasonTokens
	syncAttributes(player, profile.Data)
	return true
end

function PlayerDataService.addPet(player: Player, petId: string)
	local profile = loaded[player]
	if not profile then
		return
	end
	profile.Data.OwnedPets[petId] = (profile.Data.OwnedPets[petId] or 0) + 1
	syncAttributes(player, profile.Data)
end

function PlayerDataService.setEquippedPet(player: Player, petId: string?): boolean
	local profile = loaded[player]
	if not profile then
		return false
	end
	if petId ~= nil and (profile.Data.OwnedPets[petId] or 0) <= 0 then
		return false
	end
	profile.Data.EquippedPet = petId
	syncAttributes(player, profile.Data)
	return true
end

-- Transfiere una mascota entre dos jugadores ya cargados (comercio). Resta
-- primero y solo suma si la resta fue válida — nunca crea ni destruye
-- mascotas de la nada.
function PlayerDataService.transferPet(from: Player, to: Player, petId: string): boolean
	local fromProfile = loaded[from]
	local toProfile = loaded[to]
	if not fromProfile or not toProfile then
		return false
	end

	local count = fromProfile.Data.OwnedPets[petId] or 0
	if count <= 0 then
		return false
	end

	fromProfile.Data.OwnedPets[petId] = count - 1
	if fromProfile.Data.EquippedPet == petId and fromProfile.Data.OwnedPets[petId] <= 0 then
		fromProfile.Data.EquippedPet = nil
	end
	toProfile.Data.OwnedPets[petId] = (toProfile.Data.OwnedPets[petId] or 0) + 1

	syncAttributes(from, fromProfile.Data)
	syncAttributes(to, toProfile.Data)
	return true
end

function PlayerDataService.claimSeasonTier(player: Player, tierNumber: number, track: string): boolean
	local profile = loaded[player]
	if not profile then
		return false
	end
	if track ~= "Free" and track ~= "Premium" then
		return false
	end
	if track == "Premium" and not GamepassService.playerOwns(player, "SeasonPass") then
		return false
	end

	local tier = SeasonPass.Tiers[tierNumber]
	if not tier then
		return false
	end
	local key = seasonTierKey(tierNumber, track)
	if profile.Data.ClaimedSeasonTiers[key] == true then
		return false
	end
	if profile.Data.SeasonTokens < tier.TokensRequired then
		return false
	end

	profile.Data.ClaimedSeasonTiers[key] = true
	local reward = if track == "Free" then tier.FreeReward else tier.PremiumReward
	profile.Data.Money += applyMoneyMultiplier(player, profile.Data, reward)
	syncAttributes(player, profile.Data)
	return true
end

function PlayerDataService.redeemCode(player: Player, rawCode: string): (boolean, string)
	local profile = loaded[player]
	if not profile then
		return false, "Tu perfil todavía no ha cargado."
	end

	local code = string.upper(string.gsub(rawCode, "%s+", ""))
	local def = codesById[code]
	if not def then
		return false, "Ese código no existe."
	end
	if profile.Data.RedeemedCodes[code] == true then
		return false, "Ya has usado ese código."
	end

	profile.Data.RedeemedCodes[code] = true
	profile.Data.Money += applyMoneyMultiplier(player, profile.Data, def.MoneyReward)
	profile.Data.XP += def.XpReward
	syncAttributes(player, profile.Data)
	return true, `¡Código canjeado! +${def.MoneyReward} +{def.XpReward} XP`
end

function PlayerDataService.rebirth(player: Player): (boolean, string)
	local profile = loaded[player]
	if not profile then
		return false, "Tu perfil todavía no ha cargado."
	end

	local data = profile.Data
	local nextTier = Rebirths.List[data.RebirthCount + 1]
	if not nextTier then
		return false, "Ya tienes el rango máximo."
	end
	if Levels.levelForXp(data.XP) < nextTier.RequiredLevel then
		return false, `Necesitas ser nivel {nextTier.RequiredLevel}.`
	end
	if data.Money < nextTier.RequiredMoney then
		return false, `Necesitas ${nextTier.RequiredMoney}.`
	end

	data.Money = 0
	data.XP = 0
	data.NozzleTier = Nozzles[1].Tier
	data.RebirthCount += 1
	syncAttributes(player, data)
	return true, nextTier.Rank
end

return PlayerDataService
