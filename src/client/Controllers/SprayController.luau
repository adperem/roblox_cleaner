--!strict
--[[
	SprayController — apuntado y disparo. Todo lo que manda al servidor es
	"estoy apuntando a este objetivo: sí/no" en cada cambio de objetivo; el
	servidor recalcula el progreso por su cuenta (ver CleaningService).

	La mira está fija en el centro de la pantalla y se apunta girando la
	cámara — funciona igual en PC, móvil y mando sin lógica distinta por
	plataforma.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local TAG = "DirtyTarget"

local SprayController = {}

local isFiring = false
local currentTargetId: string? = nil
local setSprayingRemote = Net.getRemoteEvent("SetSpraying")

local taggedTargets: { Instance } = CollectionService:GetTagged(TAG)
CollectionService:GetInstanceAddedSignal(TAG):Connect(function(instance)
	table.insert(taggedTargets, instance)
end)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(instance)
	local index = table.find(taggedTargets, instance)
	if index then
		table.remove(taggedTargets, index)
	end
end)

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include

local function raycastTarget(): (Part?, Vector3?)
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil, nil
	end
	raycastParams.FilterDescendantsInstances = taggedTargets

	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector * GameConfig.SprayRange
	local result = Workspace:Raycast(origin, direction, raycastParams)
	if result and result.Instance:IsA("BasePart") then
		return result.Instance :: Part, result.Position
	end
	return nil, nil
end

local function setFiring(value: boolean)
	if isFiring == value then
		return
	end
	isFiring = value
	if not value and currentTargetId then
		setSprayingRemote:FireServer(currentTargetId, false)
		currentTargetId = nil
	end
end

function SprayController.isFiring(): boolean
	return isFiring
end

function SprayController.setFiring(value: boolean)
	setFiring(value)
end

function SprayController.getAim(): (Part?, Vector3?)
	return raycastTarget()
end

function SprayController.start()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			setFiring(true)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			setFiring(false)
		end
	end)

	RunService.Heartbeat:Connect(function()
		if not isFiring then
			return
		end
		local target = raycastTarget()
		local targetId = target and (target:GetAttribute("TargetId") :: string?) or nil
		if targetId ~= currentTargetId then
			if currentTargetId then
				setSprayingRemote:FireServer(currentTargetId, false)
			end
			currentTargetId = targetId
			if currentTargetId then
				setSprayingRemote:FireServer(currentTargetId, true)
			end
		end
	end)
end

return SprayController
