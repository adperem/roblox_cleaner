--!strict
--[[ Tienda de boquillas. Pestaña 🛠️ del menú. Las de RequiredRebirths > 0
	son de prestigio: no basta el dinero, hace falta haberse certificado
	esa cantidad de veces. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Net = require(ReplicatedStorage.Shared.Net)
local Nozzles = require(ReplicatedStorage.Shared.Config.Nozzles)
local Widgets = require(script.Parent.Widgets)

local player = Players.LocalPlayer

local ShopPanel = {}

function ShopPanel.build(content: ScrollingFrame)
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
		local requirement = if nozzle.RequiredRebirths > 0 then ` · {nozzle.RequiredRebirths}+ rebirths` else ""
		label.Text = `{nozzle.Name}\n{nozzle.Power}%/s{requirement}`
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

		row.Parent = content
		rows[nozzle.Tier] = buyButton
	end

	local leaderstats = player:WaitForChild("leaderstats")
	local money = leaderstats:WaitForChild("Money") :: IntValue

	local function refresh()
		local currentTier = (player:GetAttribute("NozzleTier") :: number?) or 1
		local rebirths = (player:GetAttribute("RebirthCount") :: number?) or 0
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
			elseif nozzle.Tier ~= currentTier + 1 then
				button.Active = false
				button.BackgroundColor3 = Theme.Color.Dirty
				button.Text = "🔒"
			elseif rebirths < nozzle.RequiredRebirths then
				button.Active = false
				button.BackgroundColor3 = Theme.Color.Dirty
				button.Text = `🔒 {nozzle.RequiredRebirths}+`
			else
				button.Active = true
				button.BackgroundColor3 = if cash >= nozzle.Price then Theme.Color.Success else Theme.Color.Danger
				button.Text = `${nozzle.Price}`
			end
		end
	end

	player:GetAttributeChangedSignal("NozzleTier"):Connect(refresh)
	player:GetAttributeChangedSignal("RebirthCount"):Connect(refresh)
	money:GetPropertyChangedSignal("Value"):Connect(refresh)
	refresh()
end

return ShopPanel
