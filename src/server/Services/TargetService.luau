--!strict
--[[
	TargetService — construye los objetivos sucios de las 9 zonas y es el
	registro único de "qué Part corresponde a qué TargetId" (CleaningService
	y EventService lo consultan; EventService además registra ahí mismo la
	Mega Suciedad, que no pertenece a ninguna zona).

	Cada objetivo son dos parts superpuestas: una "limpia" debajo (siempre
	sólida, da la colisión) y una "sucia" encima (sin colisión, es la que se
	etiqueta, se apunta y se raycastea). El atributo `Progress` de la part
	sucia controla su transparencia — al llegar a 100 se vuelve invisible y
	se ve la limpia debajo. Es una aproximación deliberadamente simple: el
	disolvido píxel a píxel con EditableImage (documento de diseño, sección
	3.2) es una pasada de arte/tech aparte, posterior a validar el bucle.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Net = require(ReplicatedStorage.Shared.Net)
local Zones = require(ReplicatedStorage.Shared.Config.Zones)
local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)

local TAG = "DirtyTarget"

local TargetService = {}

local targetsFolder: Folder
local targetsById: { [string]: Part } = {}

local function rollMutation(dirt: Part)
	local mutation = Mutations.roll()
	dirt:SetAttribute("MutationId", mutation.Id)
	dirt.Color = if mutation.Id == "mud" then Theme.Color.Dirty else mutation.Color

	if mutation.Announce then
		local name = dirt:GetAttribute("DisplayName") or dirt.Name
		Net.getRemoteEvent("ServerAnnouncement"):FireAllClients(
			`✨ ¡{mutation.Name} (x{mutation.Multiplier}) apareció en "{name}"! ¡corre!`
		)
	end
end

local function buildTarget(zone: Zones.ZoneDef, def: Zones.TargetDef): Part
	local worldPosition = zone.Origin + def.LocalPosition

	local clean = Instance.new("Part")
	clean.Name = def.Id .. "_Clean"
	clean.Anchored = true
	clean.CanCollide = true
	clean.Size = def.Size
	clean.CFrame = CFrame.new(worldPosition)
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
	dirt.Material = Enum.Material.SmoothPlastic
	dirt.Transparency = 0

	dirt:SetAttribute("TargetId", def.Id)
	dirt:SetAttribute("DisplayName", def.Name)
	dirt:SetAttribute("Progress", 0)
	dirt:SetAttribute("Payout", def.Payout)
	dirt:SetAttribute("XP", def.XP)
	dirt:SetAttribute("Cleaned", false)
	dirt:SetAttribute("IsEvent", false)

	CollectionService:AddTag(dirt, TAG)
	dirt.Parent = targetsFolder
	targetsById[def.Id] = dirt
	rollMutation(dirt)
	return dirt
end

local function buildZonePad(zone: Zones.ZoneDef)
	local pad = Instance.new("Part")
	pad.Name = zone.Id .. "_Pad"
	pad.Anchored = true
	pad.CanCollide = false
	pad.Size = Vector3.new(10, 1, 10)
	pad.CFrame = CFrame.new(zone.Origin)
	pad.Color = Theme.Color.Primary
	pad.Material = Enum.Material.Neon
	pad.Transparency = 0.4
	pad.Parent = targetsFolder
end

function TargetService.start()
	targetsFolder = Instance.new("Folder")
	targetsFolder.Name = "DirtyTargets"
	targetsFolder.Parent = Workspace

	for _, zone in Zones do
		buildZonePad(zone)
		for _, def in zone.Targets do
			buildTarget(zone, def)
		end
	end
end

function TargetService.getById(id: string): Part?
	return targetsById[id]
end

-- Usado por EventService para que la Mega Suciedad (que no vive en ninguna
-- zona) sea localizable por TargetId igual que cualquier objetivo normal.
function TargetService.register(id: string, part: Part)
	targetsById[id] = part
end

function TargetService.unregister(id: string)
	targetsById[id] = nil
end

function TargetService.reset(target: Part)
	target:SetAttribute("Progress", 0)
	target:SetAttribute("Cleaned", false)
	target:SetAttribute("IsEvent", false)
	target:SetAttribute("EventEndsAt", nil)
	rollMutation(target)
end

return TargetService
