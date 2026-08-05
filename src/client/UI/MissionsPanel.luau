--!strict
--[[ Misiones diarias: progreso en vivo (atributos server-owned) y cobro
	manual. Botón en la barra lateral izquierda, abajo. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Net = require(ReplicatedStorage.Shared.Net)
local DailyMissions = require(ReplicatedStorage.Shared.Config.DailyMissions)
local Widgets = require(script.Parent.Widgets)

local player = Players.LocalPlayer

local MissionsPanel = {}

function MissionsPanel.build(screenGui: ScreenGui)
	local openButton = Widgets.pillButton({
		Parent = screenGui,
		Size = UDim2.fromOffset(64, 64),
		Position = UDim2.new(0, 16, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = "🎯",
		BackgroundColor = Theme.Color.Primary,
	})

	local panel = Widgets.togglePanel({
		Parent = screenGui,
		OpenButton = openButton,
		Size = UDim2.fromOffset(320, 260),
		Position = UDim2.new(0, 92, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
	})

	local rows: { [string]: { Fill: Frame, Button: TextButton } } = {}

	for _, mission in DailyMissions do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 64)
		row.BackgroundTransparency = 1

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 24)
		label.BackgroundTransparency = 1
		label.Font = Theme.Text.Body.Font
		label.TextSize = 14
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = Theme.Color.TextOnDark
		label.Text = mission.Name
		label.Parent = row

		local barBack = Instance.new("Frame")
		barBack.Size = UDim2.new(0.62, 0, 0, 14)
		barBack.Position = UDim2.fromOffset(0, 28)
		barBack.BackgroundColor3 = Theme.Color.Outline
		barBack.BorderSizePixel = 0
		local barBackCorner = Instance.new("UICorner")
		barBackCorner.CornerRadius = Theme.Radius.Pill
		barBackCorner.Parent = barBack
		barBack.Parent = row

		local barFill = Instance.new("Frame")
		barFill.Size = UDim2.fromScale(0, 1)
		barFill.BackgroundColor3 = Theme.Color.Success
		barFill.BorderSizePixel = 0
		local barFillCorner = Instance.new("UICorner")
		barFillCorner.CornerRadius = Theme.Radius.Pill
		barFillCorner.Parent = barFill
		barFill.Parent = barBack

		local claimButton = Widgets.pillButton({
			Parent = row,
			Size = UDim2.fromOffset(90, 30),
			Position = UDim2.new(1, 0, 0, 28),
			AnchorPoint = Vector2.new(1, 0),
			Text = "…",
			BackgroundColor = Theme.Color.Dirty,
		})
		claimButton.MouseButton1Click:Connect(function()
			Net.getRemoteEvent("RequestClaimMission"):FireServer(mission.Id)
		end)

		row.Parent = panel
		rows[mission.Id] = { Fill = barFill, Button = claimButton }
	end

	local function refresh()
		local targetsToday = (player:GetAttribute("TargetsCleanedToday") :: number?) or 0
		local moneyToday = (player:GetAttribute("MoneyEarnedToday") :: number?) or 0

		for _, mission in DailyMissions do
			local entry = rows[mission.Id]
			if not entry then
				continue
			end
			local progress = if mission.Type == "TargetsCleaned" then targetsToday else moneyToday
			local claimed = player:GetAttribute("Claimed_" .. mission.Id) == true
			local ready = progress >= mission.Goal

			entry.Fill.Size = UDim2.fromScale(math.clamp(progress / mission.Goal, 0, 1), 1)

			if claimed then
				entry.Button.Text = "✓"
				entry.Button.BackgroundColor3 = Theme.Color.Dirty
				entry.Button.Active = false
			elseif ready then
				entry.Button.Text = "Cobrar"
				entry.Button.BackgroundColor3 = Theme.Color.Success
				entry.Button.Active = true
			else
				entry.Button.Text = `{math.min(progress, mission.Goal)}/{mission.Goal}`
				entry.Button.BackgroundColor3 = Theme.Color.Dirty
				entry.Button.Active = false
			end
		end
	end

	player:GetAttributeChangedSignal("TargetsCleanedToday"):Connect(refresh)
	player:GetAttributeChangedSignal("MoneyEarnedToday"):Connect(refresh)
	for _, mission in DailyMissions do
		player:GetAttributeChangedSignal("Claimed_" .. mission.Id):Connect(refresh)
	end
	refresh()
end

return MissionsPanel
