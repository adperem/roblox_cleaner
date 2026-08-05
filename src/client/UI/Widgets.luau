--!strict
--[[ Piezas de UI reutilizables con el estilo del sistema de diseño: contorno
	oscuro grueso + sombra sólida desplazada (nunca desenfoque). ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage.Shared.Theme)

local Widgets = {}

local function addHardShadow(host: GuiObject, cornerRadius: UDim)
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.Size = host.Size
	shadow.Position = host.Position + UDim2.fromOffset(0, Theme.Layout.ShadowOffsetPx)
	shadow.AnchorPoint = host.AnchorPoint
	shadow.BackgroundColor3 = Theme.Color.Outline
	shadow.BorderSizePixel = 0
	shadow.ZIndex = host.ZIndex - 1
	shadow.Active = false

	local corner = Instance.new("UICorner")
	corner.CornerRadius = cornerRadius
	corner.Parent = shadow

	shadow.Parent = host.Parent
end

export type PanelProps = {
	Parent: Instance,
	Size: UDim2,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	BackgroundColor: Color3?,
}

function Widgets.panel(props: PanelProps): Frame
	local frame = Instance.new("Frame")
	frame.Size = props.Size
	frame.Position = props.Position or UDim2.fromScale(0, 0)
	frame.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
	frame.BackgroundColor3 = props.BackgroundColor or Theme.Color.BackgroundAlt
	frame.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.Radius.Lg
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Color.Outline
	stroke.Thickness = Theme.Layout.OutlineThicknessPx
	stroke.Parent = frame

	frame.Parent = props.Parent
	addHardShadow(frame, Theme.Radius.Lg)
	return frame
end

export type ButtonProps = {
	Parent: Instance,
	Size: UDim2,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Text: string,
	BackgroundColor: Color3?,
	TextColor: Color3?,
}

function Widgets.pillButton(props: ButtonProps): TextButton
	local button = Instance.new("TextButton")
	button.Size = props.Size
	button.Position = props.Position or UDim2.fromScale(0, 0)
	button.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
	button.BackgroundColor3 = props.BackgroundColor or Theme.Color.Primary
	button.AutoButtonColor = false
	button.Text = props.Text
	button.TextColor3 = props.TextColor or Theme.Color.TextOnLight
	button.Font = Theme.Text.Body.Font
	button.TextScaled = true
	button.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.Radius.Pill
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Color.Outline
	stroke.Thickness = Theme.Layout.OutlineThicknessPx
	stroke.Parent = button

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = button

	button.Parent = props.Parent
	addHardShadow(button, Theme.Radius.Pill)
	return button
end

return Widgets
