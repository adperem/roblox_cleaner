--!strict
--[[ Dinero, nivel + barra de XP, y el depósito de agua junto al botón de
	disparo. Todo atado directamente a atributos del jugador (server-owned),
	sin pasar por Hud.luau. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Levels = require(ReplicatedStorage.Shared.Config.Levels)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local player = Players.LocalPlayer

local StatusBar = {}

function StatusBar.build(screenGui: ScreenGui)
	local moneyLabel = Instance.new("TextLabel")
	moneyLabel.Name = "Money"
	moneyLabel.Size = UDim2.fromOffset(220, 48)
	moneyLabel.Position = UDim2.fromOffset(16, 16)
	moneyLabel.BackgroundTransparency = 1
	moneyLabel.Font = Theme.Text.Money.Font
	moneyLabel.TextSize = 36
	moneyLabel.TextColor3 = Theme.Color.Money
	moneyLabel.TextStrokeTransparency = 0
	moneyLabel.TextStrokeColor3 = Theme.Color.Outline
	moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
	moneyLabel.Text = "$0"
	moneyLabel.Parent = screenGui

	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "Level"
	levelLabel.Size = UDim2.fromOffset(220, 20)
	levelLabel.Position = UDim2.fromOffset(16, 62)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Font = Theme.Text.Small.Font
	levelLabel.TextSize = Theme.Text.Small.Size
	levelLabel.TextColor3 = Theme.Color.TextOnDark
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.Text = "Nivel 1"
	levelLabel.Parent = screenGui

	local xpBarBack = Instance.new("Frame")
	xpBarBack.Size = UDim2.fromOffset(220, 10)
	xpBarBack.Position = UDim2.fromOffset(16, 84)
	xpBarBack.BackgroundColor3 = Theme.Color.Outline
	xpBarBack.BorderSizePixel = 0
	local xpBarBackCorner = Instance.new("UICorner")
	xpBarBackCorner.CornerRadius = Theme.Radius.Pill
	xpBarBackCorner.Parent = xpBarBack
	xpBarBack.Parent = screenGui

	local xpBarFill = Instance.new("Frame")
	xpBarFill.Size = UDim2.fromScale(0, 1)
	xpBarFill.BackgroundColor3 = Theme.Color.Primary
	xpBarFill.BorderSizePixel = 0
	local xpBarFillCorner = Instance.new("UICorner")
	xpBarFillCorner.CornerRadius = Theme.Radius.Pill
	xpBarFillCorner.Parent = xpBarFill
	xpBarFill.Parent = xpBarBack

	-- Depósito de agua vertical, a la izquierda del botón de disparo.
	local waterBack = Instance.new("Frame")
	waterBack.Name = "WaterTank"
	waterBack.Size = UDim2.fromOffset(16, 112)
	waterBack.Position = UDim2.new(1, -160, 1, -32)
	waterBack.AnchorPoint = Vector2.new(1, 1)
	waterBack.BackgroundColor3 = Theme.Color.Outline
	waterBack.BorderSizePixel = 0
	local waterBackCorner = Instance.new("UICorner")
	waterBackCorner.CornerRadius = Theme.Radius.Md
	waterBackCorner.Parent = waterBack
	waterBack.Parent = screenGui

	local waterFill = Instance.new("Frame")
	waterFill.Size = UDim2.fromScale(1, 1)
	waterFill.AnchorPoint = Vector2.new(0, 1)
	waterFill.Position = UDim2.fromScale(0, 1)
	waterFill.BackgroundColor3 = Theme.Color.Primary
	waterFill.BorderSizePixel = 0
	local waterFillCorner = Instance.new("UICorner")
	waterFillCorner.CornerRadius = Theme.Radius.Md
	waterFillCorner.Parent = waterFill
	waterFill.Parent = waterBack

	local leaderstats = player:WaitForChild("leaderstats")
	local money = leaderstats:WaitForChild("Money") :: IntValue

	local function refreshMoney()
		moneyLabel.Text = `${money.Value}`
	end

	local function refreshLevel()
		local xp = (player:GetAttribute("XP") :: number?) or 0
		local level = (player:GetAttribute("Level") :: number?) or 1
		local xpBase = Levels.xpToReach(level)
		local xpNext = Levels.xpToReach(level + 1)
		local span = math.max(1, xpNext - xpBase)
		levelLabel.Text = `Nivel {level}`
		xpBarFill.Size = UDim2.fromScale(math.clamp((xp - xpBase) / span, 0, 1), 1)
	end

	local function refreshWater()
		local tank = (player:GetAttribute("WaterTank") :: number?) or GameConfig.WaterTankMax
		waterFill.Size = UDim2.fromScale(1, tank / GameConfig.WaterTankMax)
		waterFill.BackgroundColor3 = if tank < 20 then Theme.Color.Danger else Theme.Color.Primary
	end

	money:GetPropertyChangedSignal("Value"):Connect(refreshMoney)
	player:GetAttributeChangedSignal("XP"):Connect(refreshLevel)
	player:GetAttributeChangedSignal("Level"):Connect(refreshLevel)
	player:GetAttributeChangedSignal("WaterTank"):Connect(refreshWater)

	refreshMoney()
	refreshLevel()
	refreshWater()
end

return StatusBar
