--!strict
--[[ HUD de partida: orquesta las piezas (StatusBar, paneles de la barra
	lateral) y se queda con lo que es puramente de la partida en curso —
	mira, botón de disparo, barra de progreso del objetivo apuntado y la
	celebración al cobrar (contrato o misión). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Net = require(ReplicatedStorage.Shared.Net)
local DailyMissions = require(ReplicatedStorage.Shared.Config.DailyMissions)
local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local Widgets = require(script.Parent.Widgets)
local StatusBar = require(script.Parent.StatusBar)
local ShopPanel = require(script.Parent.ShopPanel)
local ZonePanel = require(script.Parent.ZonePanel)
local MissionsPanel = require(script.Parent.MissionsPanel)
local PetsPanel = require(script.Parent.PetsPanel)
local GamepassPanel = require(script.Parent.GamepassPanel)
local AnnouncementBanner = require(script.Parent.AnnouncementBanner)
local MegaDirtBanner = require(script.Parent.MegaDirtBanner)
local SprayController = require(script.Parent.Parent.Controllers.SprayController)

local player = Players.LocalPlayer

local missionsById = {}
for _, mission in DailyMissions do
	missionsById[mission.Id] = mission
end

local Hud = {}

local function buildReticle(parent: Instance)
	local reticle = Instance.new("Frame")
	reticle.Name = "Reticle"
	reticle.Size = UDim2.fromOffset(14, 14)
	reticle.AnchorPoint = Vector2.new(0.5, 0.5)
	reticle.Position = UDim2.fromScale(0.5, 0.5)
	reticle.BackgroundColor3 = Theme.Color.SurfaceElevated
	reticle.BackgroundTransparency = 0.2

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.Radius.Pill
	corner.Parent = reticle

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Color.Outline
	stroke.Thickness = 2
	stroke.Parent = reticle

	reticle.Parent = parent
end

local function buildProgressBar(parent: Instance): (Frame, Frame, TextLabel, TextLabel)
	local container = Widgets.panel({
		Parent = parent,
		Size = UDim2.fromOffset(220, 40),
		Position = UDim2.new(0.5, 0, 0.5, 30),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor = Theme.Color.BackgroundAlt,
	})
	container.Visible = false

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Theme.Color.Success
	fill.BorderSizePixel = 0
	fill.ZIndex = 2
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = Theme.Radius.Lg
	fillCorner.Parent = fill
	fill.Parent = container

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Theme.Text.Small.Font
	label.TextSize = Theme.Text.Small.Size
	label.TextColor3 = Theme.Color.TextOnDark
	label.Text = "0%"
	label.ZIndex = 3
	label.Parent = container

	-- Insignia de mutación (×2, ×10, DORADA...), solo visible si no es la
	-- mutación base ("Barro", multiplicador 1).
	local badge = Instance.new("TextLabel")
	badge.AnchorPoint = Vector2.new(0.5, 1)
	badge.Position = UDim2.new(0.5, 0, 0, -4)
	badge.Size = UDim2.fromOffset(140, 22)
	badge.BackgroundTransparency = 1
	badge.Font = Theme.Text.Small.Font
	badge.TextSize = Theme.Text.Small.Size
	badge.TextStrokeTransparency = 0
	badge.TextStrokeColor3 = Theme.Color.Outline
	badge.Text = ""
	badge.Visible = false
	badge.Parent = container

	return container, fill, label, badge
end

local function buildCelebration(parent: Instance): (Frame, TextLabel)
	local frame = Instance.new("Frame")
	frame.Name = "Celebration"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.4)
	frame.Size = UDim2.fromOffset(0, 0)
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Theme.Text.Money.Font
	label.TextSize = Theme.Text.Money.Size
	label.TextColor3 = Theme.Color.Success
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Theme.Color.Outline
	label.Text = ""
	label.Parent = frame

	return frame, label
end

local function buildFireButton(parent: Instance)
	local button = Widgets.pillButton({
		Parent = parent,
		Size = UDim2.fromOffset(112, 112),
		Position = UDim2.new(1, -32, 1, -32),
		AnchorPoint = Vector2.new(1, 1),
		Text = "💦",
		BackgroundColor = Theme.Color.Primary,
	})

	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			SprayController.setFiring(true)
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			SprayController.setFiring(false)
		end
	end)
end

function Hud.start()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PressureWashHud"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = player:WaitForChild("PlayerGui")

	StatusBar.build(screenGui)
	buildReticle(screenGui)
	local progressContainer, progressFill, progressLabel, mutationBadge = buildProgressBar(screenGui)
	local celebrationFrame, celebrationLabel = buildCelebration(screenGui)
	buildFireButton(screenGui)
	ShopPanel.build(screenGui)
	ZonePanel.build(screenGui)
	MissionsPanel.build(screenGui)
	PetsPanel.build(screenGui)
	GamepassPanel.build(screenGui)
	AnnouncementBanner.build(screenGui)
	MegaDirtBanner.build(screenGui)

	RunService.RenderStepped:Connect(function()
		local target = SprayController.getAim()
		if target and SprayController.isFiring() then
			local progress = target:GetAttribute("Progress") :: number
			progressContainer.Visible = true
			progressFill.Size = UDim2.fromScale(progress / 100, 1)
			progressLabel.Text = `{math.floor(progress)}%`

			local mutation = Mutations.getById(target:GetAttribute("MutationId") :: string?)
			if mutation.Multiplier > 1 then
				mutationBadge.Visible = true
				mutationBadge.Text = `{mutation.Name} ×{mutation.Multiplier}`
				mutationBadge.TextColor3 = mutation.Color
			else
				mutationBadge.Visible = false
			end
		else
			progressContainer.Visible = false
		end
	end)

	local function popCelebration(text: string)
		celebrationLabel.Text = text
		celebrationFrame.Size = UDim2.fromOffset(0, 0)
		TweenService:Create(celebrationFrame, Theme.tween("Celebrate"), { Size = UDim2.fromOffset(280, 120) }):Play()
		task.delay(1, function()
			TweenService:Create(celebrationFrame, Theme.tween("PopIn"), { Size = UDim2.fromOffset(0, 0) }):Play()
		end)
	end

	Net.getRemoteEvent("TargetCompleted").OnClientEvent:Connect(function(_targetId: unknown, amount: unknown)
		popCelebration(`+${amount}`)
	end)

	Net.getRemoteEvent("MissionClaimed").OnClientEvent:Connect(function(missionId: unknown)
		local mission = typeof(missionId) == "string" and missionsById[missionId]
		if mission then
			popCelebration(`+${mission.MoneyReward}\n+{mission.XpReward} XP`)
		end
	end)

	Net.getRemoteEvent("EventResolved").OnClientEvent:Connect(function(kind: unknown, money: unknown, xp: unknown)
		if typeof(money) ~= "number" or typeof(xp) ~= "number" then
			return
		end
		local label = if kind == "Mega" then "🏗️ ¡Mega Suciedad!" else "🚨 ¡Contrato VIP!"
		popCelebration(`{label}\n+${money}  +{xp} XP`)
	end)
end

return Hud
