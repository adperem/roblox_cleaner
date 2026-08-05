--!strict
--[[ Mapa de zonas: viajar a cualquiera ya desbloqueada por nivel. Pestaña
	🗺️ del menú. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Net = require(ReplicatedStorage.Shared.Net)
local Zones = require(ReplicatedStorage.Shared.Config.Zones)
local Widgets = require(script.Parent.Widgets)

local player = Players.LocalPlayer

local ZonePanel = {}

function ZonePanel.build(content: ScrollingFrame)
	local rows: { [string]: { Button: TextButton, Label: TextLabel } } = {}

	for _, zone in Zones do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 48)
		row.BackgroundTransparency = 1

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.6, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Font = Theme.Text.Body.Font
		label.TextSize = 16
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = Theme.Color.TextOnDark
		label.Text = zone.Name
		label.Parent = row

		local goButton = Widgets.pillButton({
			Parent = row,
			Size = UDim2.new(0.35, 0, 0.7, 0),
			Position = UDim2.new(1, 0, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Text = "Viajar",
			BackgroundColor = Theme.Color.Success,
		})
		goButton.MouseButton1Click:Connect(function()
			Net.getRemoteEvent("RequestTeleport"):FireServer(zone.Id)
		end)

		row.Parent = content
		rows[zone.Id] = { Button = goButton, Label = label }
	end

	local function refresh()
		local level = (player:GetAttribute("Level") :: number?) or 1
		for _, zone in Zones do
			local entry = rows[zone.Id]
			if not entry then
				continue
			end
			local unlocked = level >= zone.RequiredLevel
			entry.Button.Active = unlocked
			entry.Button.Text = if unlocked then "Viajar" else "🔒"
			entry.Button.BackgroundColor3 = if unlocked then Theme.Color.Success else Theme.Color.Dirty
			entry.Label.Text = if unlocked then zone.Name else `{zone.Name} (Nivel {zone.RequiredLevel})`
		end
	end

	player:GetAttributeChangedSignal("Level"):Connect(refresh)
	refresh()
end

return ZonePanel
