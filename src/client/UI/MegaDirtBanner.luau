--!strict
--[[ Barra persistente de la Mega Suciedad: progreso compartido + cuenta
	atrás, visible para todo el servidor mientras dura el evento. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Net = require(ReplicatedStorage.Shared.Net)
local Widgets = require(script.Parent.Widgets)

local MegaDirtBanner = {}

function MegaDirtBanner.build(screenGui: ScreenGui)
	local container = Widgets.panel({
		Parent = screenGui,
		Size = UDim2.fromOffset(420, 64),
		Position = UDim2.new(0.5, 0, 0, 96),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor = Theme.Color.BackgroundAlt,
	})
	container.Visible = false

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -16, 0, 20)
	title.Position = UDim2.fromOffset(8, 4)
	title.BackgroundTransparency = 1
	title.Font = Theme.Text.Small.Font
	title.TextSize = Theme.Text.Small.Size
	title.TextColor3 = Theme.Color.TextOnDark
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "🏗️ MEGA SUCIEDAD"
	title.Parent = container

	local barBack = Instance.new("Frame")
	barBack.Size = UDim2.new(1, -16, 0, 16)
	barBack.Position = UDim2.fromOffset(8, 28)
	barBack.BackgroundColor3 = Theme.Color.Outline
	barBack.BorderSizePixel = 0
	local barBackCorner = Instance.new("UICorner")
	barBackCorner.CornerRadius = Theme.Radius.Pill
	barBackCorner.Parent = barBack
	barBack.Parent = container

	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.fromScale(0, 1)
	barFill.BackgroundColor3 = Theme.Color.Success
	barFill.BorderSizePixel = 0
	local barFillCorner = Instance.new("UICorner")
	barFillCorner.CornerRadius = Theme.Radius.Pill
	barFillCorner.Parent = barFill
	barFill.Parent = barBack

	local timeLabel = Instance.new("TextLabel")
	timeLabel.Size = UDim2.fromScale(1, 1)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Font = Theme.Text.Small.Font
	timeLabel.TextSize = Theme.Text.Small.Size
	timeLabel.TextColor3 = Theme.Color.TextOnDark
	timeLabel.ZIndex = 2
	timeLabel.Text = ""
	timeLabel.Parent = barBack

	local activeTarget: Part? = nil
	local endsAt = 0
	local renderConnection: RBXScriptConnection? = nil

	local function stopTracking()
		if renderConnection then
			renderConnection:Disconnect()
			renderConnection = nil
		end
		container.Visible = false
		activeTarget = nil
	end

	local function startTracking(target: Part, eventEndsAt: number)
		activeTarget = target
		endsAt = eventEndsAt
		container.Visible = true

		renderConnection = RunService.RenderStepped:Connect(function()
			if not activeTarget or not activeTarget.Parent then
				stopTracking()
				return
			end
			local progress = (activeTarget:GetAttribute("Progress") :: number?) or 0
			barFill.Size = UDim2.fromScale(math.clamp(progress / 100, 0, 1), 1)
			local remaining = math.max(0, math.floor(endsAt - os.clock()))
			timeLabel.Text = `{math.floor(progress)}% — {remaining}s`
		end)
	end

	Net.getRemoteEvent("MegaDirtStarted").OnClientEvent:Connect(function(target: unknown, eventEndsAt: unknown)
		if typeof(target) == "Instance" and target:IsA("Part") and typeof(eventEndsAt) == "number" then
			startTracking(target, eventEndsAt)
		end
	end)

	Net.getRemoteEvent("MegaDirtEnded").OnClientEvent:Connect(function(target: unknown)
		if activeTarget and target == activeTarget then
			stopTracking()
		end
	end)
end

return MegaDirtBanner
