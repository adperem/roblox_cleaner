--!strict
--[[ Feedback visual y sonoro del chorro de agua. Puramente cosmético — no
	envía ni recibe nada del servidor, solo lee el estado de SprayController. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SprayController = require(script.Parent.SprayController)

local player = Players.LocalPlayer

local EffectsController = {}

local function newInvisiblePart(name: string): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.Parent = Workspace
	return part
end

function EffectsController.start()
	local origin = newInvisiblePart("SprayOrigin")
	local hit = newInvisiblePart("SprayHit")

	local originAttachment = Instance.new("Attachment")
	originAttachment.Parent = origin
	local hitAttachment = Instance.new("Attachment")
	hitAttachment.Parent = hit

	local beam = Instance.new("Beam")
	beam.Attachment0 = originAttachment
	beam.Attachment1 = hitAttachment
	beam.Width0 = 0.15
	beam.Width1 = 0.35
	beam.FaceCamera = true
	beam.Color = ColorSequence.new(Color3.fromHex("#BFE7FA"), Color3.fromHex("#17C3F2"))
	beam.Transparency = NumberSequence.new(0.1, 0.6)
	beam.Enabled = false
	beam.Parent = origin

	local splash = Instance.new("ParticleEmitter")
	splash.Color = ColorSequence.new(Color3.fromHex("#EAF6FF"))
	splash.Size = NumberSequence.new(0.25)
	splash.Lifetime = NumberRange.new(0.15, 0.3)
	splash.Speed = NumberRange.new(4, 7)
	splash.SpreadAngle = Vector2.new(35, 35)
	splash.Rate = 0
	splash.Enabled = false
	splash.Parent = hitAttachment

	local spraySound = Instance.new("Sound")
	spraySound.Name = "SpraySound"
	spraySound.Looped = true
	spraySound.Volume = 0.4
	-- Sin asset propio todavía: poner aquí el rbxassetid:// real del bucle
	-- de agua a presión cuando exista. Hasta entonces se queda mudo.
	spraySound.SoundId = ""
	spraySound.Parent = hit

	RunService.RenderStepped:Connect(function()
		local camera = Workspace.CurrentCamera
		local firing = SprayController.isFiring()
		local _, position = SprayController.getAim()
		local tank = (player:GetAttribute("WaterTank") :: number?) or 100
		local hasHit = firing and position ~= nil and tank > 0

		beam.Enabled = hasHit
		splash.Enabled = hasHit
		splash.Rate = hasHit and 40 or 0

		if camera then
			origin.CFrame = camera.CFrame * CFrame.new(0.5, -0.8, -1.4)
		end
		if hasHit and position then
			hit.CFrame = CFrame.new(position)
		end

		if hasHit and spraySound.SoundId ~= "" and not spraySound.Playing then
			spraySound.Playing = true
		elseif not hasHit and spraySound.Playing then
			spraySound.Playing = false
		end
	end)
end

return EffectsController
