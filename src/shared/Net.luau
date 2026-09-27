--!strict
--[[
	Net — acceso centralizado a los RemoteEvents del juego.

	El servidor crea TODOS los eventos al arrancar (`Net.createAll`, llamado
	desde Boot antes de cualquier servicio); el cliente espera a que existan.
	No basta con crearlos "la primera vez que alguien los pide": los que van
	de servidor a cliente (MegaDirtStarted, PetHatched...) solo se pedían al
	dispararse, y el cliente se quedaba bloqueado en su WaitForChild al
	arrancar la interfaz — sin menú hasta la primera Mega Suciedad (20 min).

	Cualquier nombre nuevo va en `EventName` Y en `EventNames`: la
	comprobación de CI (scripts/check_remotes.py) falla si no coinciden con
	los nombres usados en el código.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

export type EventName =
	"SetSpraying"
	| "RequestBuyNozzle"
	| "TargetCompleted"
	| "RequestTeleport"
	| "RequestClaimMission"
	| "MissionClaimed"
	| "RequestBuyEgg"
	| "PetHatched"
	| "RequestEquipPet"
	| "ServerAnnouncement"
	| "EventResolved"
	| "MegaDirtStarted"
	| "MegaDirtEnded"
	| "RequestRebirth"
	| "RebirthCompleted"
	| "RequestClaimSeasonTier"
	| "RequestRedeemCode"
	| "CodeRedeemed"
	| "RequestTradeInvite"
	| "TradeInviteReceived"
	| "RequestRespondTradeInvite"
	| "RequestSetTradeOffer"
	| "RequestSetTradeReady"
	| "RequestCancelTrade"
	| "TradeStateUpdated"
	| "TradeEnded"
	| "RequestFusePets"
	| "PetFused"

Net.EventNames = {
	"SetSpraying",
	"RequestBuyNozzle",
	"TargetCompleted",
	"RequestTeleport",
	"RequestClaimMission",
	"MissionClaimed",
	"RequestBuyEgg",
	"PetHatched",
	"RequestEquipPet",
	"ServerAnnouncement",
	"EventResolved",
	"MegaDirtStarted",
	"MegaDirtEnded",
	"RequestRebirth",
	"RebirthCompleted",
	"RequestClaimSeasonTier",
	"RequestRedeemCode",
	"CodeRedeemed",
	"RequestTradeInvite",
	"TradeInviteReceived",
	"RequestRespondTradeInvite",
	"RequestSetTradeOffer",
	"RequestSetTradeReady",
	"RequestCancelTrade",
	"TradeStateUpdated",
	"TradeEnded",
	"RequestFusePets",
	"PetFused",
} :: { EventName }

local FOLDER_NAME = "PressureWashRemotes"

local function getFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing then
		return existing :: Folder
	end

	if RunService:IsServer() then
		local folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
		return folder
	end

	return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

function Net.getRemoteEvent(name: EventName): RemoteEvent
	local folder = getFolder()
	local existing = folder:FindFirstChild(name)
	if existing then
		return existing :: RemoteEvent
	end

	if RunService:IsServer() then
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = folder
		return event
	end

	return folder:WaitForChild(name) :: RemoteEvent
end

-- Solo servidor: crea de golpe todos los eventos para que ya estén
-- replicados cuando entre el primer jugador.
function Net.createAll()
	assert(RunService:IsServer(), "Net.createAll solo se llama desde el servidor")
	for _, name in Net.EventNames do
		Net.getRemoteEvent(name)
	end
end

return Net
