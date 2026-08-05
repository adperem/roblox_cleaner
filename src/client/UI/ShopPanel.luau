--!strict
--[[ Tienda de boquillas. Botón en la barra lateral izquierda, arriba. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Net = require(ReplicatedStorage.Shared.Net)
local Nozzles = require(ReplicatedStorage.Shared.Config.Nozzles)
local Widgets = require(script.Parent.Widgets)

local player = Players.LocalPlayer

local ShopPanel = {}

function ShopPanel.build(screenGui: ScreenGui)
	local openButton = Widgets.pillButton({
		Parent = screenGui,
		Size = UDim2.fromOffset(64, 64),
		Position = UDim2.new(0, 16, 0.5, -152),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = "🛠️",
		BackgroundColor = Theme.Color.Primary,
	})

	local panel = Widgets.togglePanel({
		Parent = screenGui,
		OpenButton = openButton,
		Size = UDim2.fromOffset(300, 260),
		Position = UDim2.new(0, 92, 0.5, -152),
		AnchorPoint = Vector2.new(0, 0.5),
	})

	local rows: { [number]: TextButton } = {}

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
		rows[nozzle.Tier] = buyButton
	end

	local leaderstats = player:WaitForChild("leaderstats")
	local money = leaderstats:WaitForChild("Money") :: IntValue

	local function refresh()
		local currentTier = (player:GetAttribute("NozzleTier") :: number?) or 1
		local cash = money.Value

		for _, nozzle in Nozzles do
			local button = rows[nozzle.Tier]
			if not button then
				continue
			end
			if nozzle.Tier <= currentTier then
				button.Text = "✓"
				button.BackgroundColor3 = Theme.Color.Dirty
				button.Active = false
			elseif nozzle.Tier == currentTier + 1 then
				button.Active = true
				button.BackgroundColor3 = if cash >= nozzle.Price then Theme.Color.Success else Theme.Color.Danger
				button.Text = `${nozzle.Price}`
			else
				button.Active = false
				button.BackgroundColor3 = Theme.Color.Dirty
				button.Text = "🔒"
			end
		end
	end

	player:GetAttributeChangedSignal("NozzleTier"):Connect(refresh)
	money:GetPropertyChangedSignal("Value"):Connect(refresh)
	refresh()
end

return ShopPanel
