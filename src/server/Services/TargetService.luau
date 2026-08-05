--!strict
--[[
	TargetService — construye los objetivos sucios de la zona actual.

	Cada objetivo son dos parts superpuestas:
	  - una part "limpia" debajo (color claro, siempre sólida, da la colisión),
	  - una part "sucia" encima (marrón, sin colisión, es la que se etiqueta,
	    se apunta y se raycastea).
	El atributo `Progress` de la part sucia controla su transparencia — al
	llegar a 100 se vuelve invisible y se ve la limpia debajo. Es una
	aproximación deliberadamente simple para este prototipo: el disolvido
	píxel a píxel con EditableImage descrito en el documento de diseño
	(sección 3.2) es una pasada de arte/tech aparte, posterior a validar que
	la mecánica en sí es divertida.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Zone1 = require(ReplicatedStorage.Shared.Config.Zone1)

local TAG = "DirtyTarget"

local TargetService = {}

local targetsFolder: Folder
local targetsById: { [string]: Part } = {}

local function buildTarget(def: Zone1.TargetDef): Part
	local clean = Instance.new("Part")
	clean.Name = def.Id .. "_Clean"
	clean.Anchored = true
	clean.CanCollide = true
	clean.Size = def.Size
	clean.CFrame = CFrame.new(def.Position)
	clean.Color = Theme.Color.SurfaceElevated
	clean.Material = Enum.Material.SmoothPlastic
	clean.Parent = targetsFolder

	local dirt = Instance.new("Part")
	dirt.Name = def.Id
	dirt.Anchored = true
	dirt.CanCollide = false
	dirt.CanTouch = false
	-- Un pelín más grande que la limpia para que la cubra del todo mientras está sucia.
	dirt.Size = def.Size * 1.01
	dirt.CFrame = clean.CFrame
	dirt.Color = Theme.Color.Dirty
	dirt.Material = Enum.Material.SmoothPlastic
	dirt.Transparency = 0

	dirt:SetAttribute("TargetId", def.Id)
	dirt:SetAttribute("DisplayName", def.Name)
	dirt:SetAttribute("Progress", 0)
	dirt:SetAttribute("Payout", def.Payout)
	dirt:SetAttribute("Cleaned", false)

	CollectionService:AddTag(dirt, TAG)
	dirt.Parent = targetsFolder
	targetsById[def.Id] = dirt
	return dirt
end

function TargetService.start()
	targetsFolder = Instance.new("Folder")
	targetsFolder.Name = "DirtyTargets"
	targetsFolder.Parent = Workspace

	for _, def in Zone1 do
		buildTarget(def)
	end
end

function TargetService.getById(id: string): Part?
	return targetsById[id]
end

function TargetService.reset(target: Part)
	target:SetAttribute("Progress", 0)
	target:SetAttribute("Cleaned", false)
end

return TargetService
