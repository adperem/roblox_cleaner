--!strict
--[[
	MenuShell — el menú único que reemplaza los botones sueltos de las fases
	anteriores. Con 9 sistemas ya no caben como iconos apilados en la
	pantalla; esto los agrupa en un panel con pestañas, una por sistema.
	Cada pestaña construye su contenido una sola vez al arrancar; cambiar de
	pestaña solo alterna qué `ScrollingFrame` está visible.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage.Shared.Theme)
local Widgets = require(script.Parent.Widgets)

local MenuShell = {}

export type TabDef = {
	Id: string,
	Icon: string,
	Build: (content: ScrollingFrame) -> (),
}

function MenuShell.build(screenGui: ScreenGui, tabs: { TabDef })
	local openButton = Widgets.pillButton({
		Parent = screenGui,
		Size = UDim2.fromOffset(96, 96),
		Position = UDim2.new(0, 32, 1, -32),
		AnchorPoint = Vector2.new(0, 1),
		Text = "☰",
		BackgroundColor = Theme.Color.Primary,
	})

	local panel = Widgets.panel({
		Parent = screenGui,
		Size = UDim2.fromOffset(560, 440),
		Position = UDim2.fromScale(0.5, 0.45),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor = Theme.Color.BackgroundAlt,
	})
	panel.Visible = false

	local closeButton = Widgets.pillButton({
		Parent = panel,
		Size = UDim2.fromOffset(32, 32),
		Position = UDim2.new(1, -8, 0, 8),
		AnchorPoint = Vector2.new(1, 0),
		Text = "✕",
		BackgroundColor = Theme.Color.Danger,
	})

	local tabRow = Instance.new("Frame")
	tabRow.Size = UDim2.new(1, -56, 0, 48)
	tabRow.Position = UDim2.fromOffset(8, 8)
	tabRow.BackgroundTransparency = 1
	tabRow.Parent = panel

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 6)
	tabLayout.Parent = tabRow

	local contentArea = Instance.new("Frame")
	contentArea.Size = UDim2.new(1, -16, 1, -72)
	contentArea.Position = UDim2.fromOffset(8, 64)
	contentArea.BackgroundTransparency = 1
	contentArea.Parent = panel

	local tabButtons: { [string]: TextButton } = {}
	local tabContents: { [string]: ScrollingFrame } = {}

	local function selectTab(id: string)
		for tabId, content in tabContents do
			content.Visible = tabId == id
		end
		for tabId, button in tabButtons do
			button.BackgroundColor3 = if tabId == id then Theme.Color.Primary else Theme.Color.Dirty
		end
	end

	for index, tab in tabs do
		-- Envuelto en un Frame propio: Widgets.pillButton añade una sombra
		-- como hermano en su Parent, y si el botón fuera hijo directo de
		-- tabRow esa sombra colaría como un elemento más del UIListLayout,
		-- descolocando toda la fila.
		local slot = Instance.new("Frame")
		slot.Size = UDim2.fromOffset(40, 40)
		slot.BackgroundTransparency = 1
		slot.LayoutOrder = index
		slot.Parent = tabRow

		local button = Widgets.pillButton({
			Parent = slot,
			Size = UDim2.fromScale(1, 1),
			Text = tab.Icon,
			BackgroundColor = Theme.Color.Dirty,
		})
		button.MouseButton1Click:Connect(function()
			selectTab(tab.Id)
		end)
		tabButtons[tab.Id] = button

		local content = Instance.new("ScrollingFrame")
		content.Size = UDim2.fromScale(1, 1)
		content.BackgroundTransparency = 1
		content.BorderSizePixel = 0
		content.ScrollBarThickness = 6
		content.CanvasSize = UDim2.fromScale(0, 0)
		content.AutomaticCanvasSize = Enum.AutomaticSize.Y
		content.Visible = false
		content.Parent = contentArea

		local listLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0, 8)
		listLayout.Parent = content

		tabContents[tab.Id] = content
		tab.Build(content)
	end

	if tabs[1] then
		selectTab(tabs[1].Id)
	end

	openButton.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
	end)
	closeButton.MouseButton1Click:Connect(function()
		panel.Visible = false
	end)
end

return MenuShell
