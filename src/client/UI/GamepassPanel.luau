--!strict
--[[ Tienda de gamepasses. Pestaña 💎 del menú. Si un gamepass todavía no
	existe en el Creator Dashboard (ProductId = 0 en la config), el botón
	sale desactivado con "Pronto" — no se puede invocar MarketplaceService
	con un id que no existe. ]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Gamepasses = require(ReplicatedStorage.Shared.Config.Gamepasses)
local Widgets = require(script.Parent.Widgets)

local player = Players.LocalPlayer

local GamepassPanel = {}

function GamepassPanel.build(content: ScrollingFrame)
	for _, gamepass in Gamepasses do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 64)
		row.BackgroundTransparency = 1

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.65, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Font = Theme.Text.Body.Font
		label.TextSize = 13
		label.TextWrapped = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = Theme.Color.TextOnDark
		label.Text = `{gamepass.Name}\n{gamepass.Description}`
		label.Parent = row

		local buyButton = Widgets.pillButton({
			Parent = row,
			Size = UDim2.new(0.3, 0, 0.6, 0),
			Position = UDim2.new(1, 0, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Text = if gamepass.ProductId > 0 then "Comprar" else "Pronto",
			BackgroundColor = if gamepass.ProductId > 0 then Theme.Color.Success else Theme.Color.Dirty,
		})
		buyButton.Active = gamepass.ProductId > 0

		if gamepass.ProductId > 0 then
			local productId = gamepass.ProductId
			buyButton.MouseButton1Click:Connect(function()
				MarketplaceService:PromptGamePassPurchase(player, productId)
			end)

			local attributeName = "Owns_" .. gamepass.Id
			local function refresh()
				local owns = player:GetAttribute(attributeName) == true
				buyButton.Text = if owns then "✓ Tuyo" else "Comprar"
				buyButton.Active = not owns
				buyButton.BackgroundColor3 = if owns then Theme.Color.Dirty else Theme.Color.Success
			end
			player:GetAttributeChangedSignal(attributeName):Connect(refresh)
			refresh()
		end

		row.Parent = content
	end
end

return GamepassPanel
