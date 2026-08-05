--!strict
--[[
	Net — acceso centralizado a los RemoteEvents del juego.

	El servidor crea la carpeta y los eventos la primera vez que alguien los pide;
	el cliente espera a que existan. Así ningún script tiene que preocuparse de
	quién los crea primero.
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

return Net
