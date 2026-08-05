--!strict
--[[ Banner que baja desde arriba con los avisos del servidor: mutaciones
	raras, inicio de contrato VIP, inicio de Mega Suciedad. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Net = require(ReplicatedStorage.Shared.Net)

local AnnouncementBanner = {}

function AnnouncementBanner.build(screenGui: ScreenGui)
	local hiddenPosition = UDim2.new(0.5, 0, 0, -90)
	local visiblePosition = UDim2.new(0.5, 0, 0, 16)

	local banner = Instance.new("Frame")
	banner.Name = "Announcement"
	banner.Size = UDim2.fromOffset(560, 64)
	banner.Position = hiddenPosition
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.BackgroundColor3 = Theme.Color.Money
	banner.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.Radius.Lg
	corner.Parent = banner

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Color.Outline
	stroke.Thickness = Theme.Layout.OutlineThicknessPx
	stroke.Parent = banner

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = banner

	banner.Parent = screenGui

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Theme.Text.Heading.Font
	label.TextSize = 18
	label.TextColor3 = Theme.Color.TextOnLight
	label.TextWrapped = true
	label.Text = ""
	label.Parent = banner

	local hideDelayToken = 0

	Net.getRemoteEvent("ServerAnnouncement").OnClientEvent:Connect(function(message: unknown)
		if typeof(message) ~= "string" then
			return
		end
		label.Text = message
		TweenService:Create(banner, Theme.tween("PopIn"), { Position = visiblePosition }):Play()

		hideDelayToken += 1
		local myToken = hideDelayToken
		task.delay(4.5, function()
			if myToken == hideDelayToken then
				TweenService:Create(banner, Theme.tween("PopIn"), { Position = hiddenPosition }):Play()
			end
		end)
	end)
end

return AnnouncementBanner
