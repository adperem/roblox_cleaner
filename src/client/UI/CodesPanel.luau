--!strict
--[[ Canje de códigos. Pestaña 🎁 del menú: un cuadro de texto, un botón, y
	el mensaje que devuelva el servidor (válido, ya usado, no existe...). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Net = require(ReplicatedStorage.Shared.Net)
local Widgets = require(script.Parent.Widgets)

local player = Players.LocalPlayer

local CodesPanel = {}

function CodesPanel.build(content: ScrollingFrame)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 28)
	title.BackgroundTransparency = 1
	title.Font = Theme.Text.Heading.Font
	title.TextSize = 20
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Theme.Color.TextOnDark
	title.Text = "🎁 Canjear código"
	title.Parent = content

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 48)
	row.BackgroundTransparency = 1
	row.Parent = content

	local textBox = Instance.new("TextBox")
	textBox.Size = UDim2.new(0.62, 0, 1, 0)
	textBox.BackgroundColor3 = Theme.Color.Surface
	textBox.BorderSizePixel = 0
	textBox.Font = Theme.Text.Body.Font
	textBox.TextSize = 16
	textBox.TextColor3 = Theme.Color.TextOnLight
	textBox.PlaceholderText = "TUCÓDIGOAQUÍ"
	textBox.ClearTextOnFocus = false
	textBox.Text = ""

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.Radius.Md
	corner.Parent = textBox

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Color.Outline
	stroke.Thickness = Theme.Layout.OutlineThicknessPx
	stroke.Parent = textBox

	textBox.Parent = row

	local submitButton = Widgets.pillButton({
		Parent = row,
		Size = UDim2.new(0.34, 0, 1, 0),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Text = "Canjear",
		BackgroundColor = Theme.Color.Primary,
	})

	local resultLabel = Instance.new("TextLabel")
	resultLabel.Size = UDim2.new(1, 0, 0, 40)
	resultLabel.BackgroundTransparency = 1
	resultLabel.Font = Theme.Text.Small.Font
	resultLabel.TextSize = Theme.Text.Small.Size
	resultLabel.TextWrapped = true
	resultLabel.TextXAlignment = Enum.TextXAlignment.Left
	resultLabel.TextColor3 = Theme.Color.TextOnDark
	resultLabel.Text = ""
	resultLabel.Parent = content

	local function submit()
		local code = textBox.Text
		if code == "" then
			return
		end
		Net.getRemoteEvent("RequestRedeemCode"):FireServer(code)
	end

	submitButton.MouseButton1Click:Connect(submit)
	textBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			submit()
		end
	end)

	Net.getRemoteEvent("CodeRedeemed").OnClientEvent:Connect(function(success: unknown, message: unknown)
		if typeof(message) ~= "string" then
			return
		end
		resultLabel.Text = if success == true then message else `❌ {message}`
		resultLabel.TextColor3 = if success == true then Theme.Color.Success else Theme.Color.Danger
		if success == true then
			textBox.Text = ""
		end
	end)
end

return CodesPanel
