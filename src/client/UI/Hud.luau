--!strict
--[[ HUD de partida: dinero, mira, botón de disparo, barra de progreso del
	objetivo apuntado, tienda de boquillas y la celebración al cobrar. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Net = require(ReplicatedStorage.Shared.Net)
local Nozzles = require(ReplicatedStorage.Shared.Config.Nozzles)
local Widgets = require(script.Parent.Widgets)
local SprayController = require(script.Parent.Parent.Controllers.SprayController)

local player = Players.LocalPlayer

local Hud = {}

type ShopRow = { Button: TextButton }
type ShopRows = { [number]: ShopRow }

local function buildMoneyLabel(parent: Instance): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = "Money"
	label.Size = UDim2.fromOffset(220, 64)
	label.Position = UDim2.fromOffset(16, 16)
	label.BackgroundTransparency = 1
	label.Font = Theme.Text.Money.Font
	label.TextSize = Theme.Text.Money.Size
	label.TextColor3 = Theme.Color.Money
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Theme.Color.Outline
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = "$0"
	label.Parent = parent
	return label
end

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

local function buildProgressBar(parent: Instance): (Frame, Frame, TextLabel)
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

	return container, fill, label
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

local function buildShopPanel(parent: Instance, openButton: TextButton): ShopRows
	local panel = Widgets.panel({
		Parent = parent,
		Size = UDim2.fromOffset(300, 260),
		Position = UDim2.new(0, 16, 1, -32),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor = Theme.Color.BackgroundAlt,
	})
	panel.Visible = false

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.Parent = panel

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = panel

	local rows: ShopRows = {}

	for _, nozzle in Nozzles do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 56)
		row.BackgroundTransparency = 1

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.6, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Font = Theme.Text.Body.Font
		label.TextSize = 16
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = Theme.Color.TextOnDark
		label.Text = `{nozzle.Name}\n{nozzle.Power}%/s`
		label.Parent = row

		local buyButton = Widgets.pillButton({
			Parent = row,
			Size = UDim2.new(0.35, 0, 0.7, 0),
			Position = UDim2.new(1, 0, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Text = if nozzle.Price == 0 then "—" else `${nozzle.Price}`,
			BackgroundColor = Theme.Color.Success,
		})

		buyButton.MouseButton1Click:Connect(function()
			Net.getRemoteEvent("RequestBuyNozzle"):FireServer(nozzle.Tier)
		end)

		row.Parent = panel
		rows[nozzle.Tier] = { Button = buyButton }
	end

	openButton.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
	end)

	return rows
end

local function refreshShopRows(rows: ShopRows, money: number, currentTier: number)
	for _, nozzle in Nozzles do
		local row = rows[nozzle.Tier]
		if not row then
			continue
		end
		local button = row.Button
		if nozzle.Tier <= currentTier then
			button.Text = "✓"
			button.BackgroundColor3 = Theme.Color.Dirty
			button.Active = false
		elseif nozzle.Tier == currentTier + 1 then
			button.Active = true
			button.BackgroundColor3 = if money >= nozzle.Price then Theme.Color.Success else Theme.Color.Danger
			button.Text = `${nozzle.Price}`
		else
			button.Active = false
			button.BackgroundColor3 = Theme.Color.Dirty
			button.Text = "🔒"
		end
	end
end

function Hud.start()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PressureWashHud"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local moneyLabel = buildMoneyLabel(screenGui)
	buildReticle(screenGui)
	local progressContainer, progressFill, progressLabel = buildProgressBar(screenGui)
	local celebrationFrame, celebrationLabel = buildCelebration(screenGui)
	buildFireButton(screenGui)

	local shopOpenButton = Widgets.pillButton({
		Parent = screenGui,
		Size = UDim2.fromOffset(140, 48),
		Position = UDim2.new(0, 16, 1, -32),
		AnchorPoint = Vector2.new(0, 1),
		Text = "🛠️ Mejoras",
		BackgroundColor = Theme.Color.Primary,
	})
	local shopRows = buildShopPanel(screenGui, shopOpenButton)

	local leaderstats = player:WaitForChild("leaderstats")
	local money = leaderstats:WaitForChild("Money") :: IntValue

	local function refresh()
		moneyLabel.Text = `${money.Value}`
		refreshShopRows(shopRows, money.Value, player:GetAttribute("NozzleTier") :: number)
	end
	money:GetPropertyChangedSignal("Value"):Connect(refresh)
	player:GetAttributeChangedSignal("NozzleTier"):Connect(refresh)
	refresh()

	RunService.RenderStepped:Connect(function()
		local target = SprayController.getAim()
		if target and SprayController.isFiring() then
			local progress = target:GetAttribute("Progress") :: number
			progressContainer.Visible = true
			progressFill.Size = UDim2.fromScale(progress / 100, 1)
			progressLabel.Text = `{math.floor(progress)}%`
		else
			progressContainer.Visible = false
		end
	end)

	Net.getRemoteEvent("TargetCompleted").OnClientEvent:Connect(function(_targetId: unknown, amount: unknown)
		celebrationLabel.Text = `+${amount}`
		celebrationFrame.Size = UDim2.fromOffset(0, 0)
		TweenService:Create(celebrationFrame, Theme.tween("Celebrate"), { Size = UDim2.fromOffset(260, 90) }):Play()
		task.delay(1, function()
			TweenService:Create(celebrationFrame, Theme.tween("PopIn"), { Size = UDim2.fromOffset(0, 0) }):Play()
		end)
	end)
end

return Hud
