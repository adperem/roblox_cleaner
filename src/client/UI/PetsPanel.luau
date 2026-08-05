--!strict
--[[ Comprar huevos, ver mascotas conseguidas (con siluetas para las que
	faltan) y equipar una. El revelado al abrir huevo se muestra aquí mismo. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Net = require(ReplicatedStorage.Shared.Net)
local Pets = require(ReplicatedStorage.Shared.Config.Pets)
local Eggs = require(ReplicatedStorage.Shared.Config.Eggs)
local Widgets = require(script.Parent.Widgets)

local player = Players.LocalPlayer

local petsById = {}
for _, pet in Pets do
	petsById[pet.Id] = pet
end

local PetsPanel = {}

type PetRow = { Row: Frame, EquipButton: TextButton, CountLabel: TextLabel, NameLabel: TextLabel }

local function buildEggRow(parent: Instance, egg: Eggs.EggDef): TextButton
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
	label.Text = egg.Name
	label.Parent = row

	local buyButton = Widgets.pillButton({
		Parent = row,
		Size = UDim2.new(0.35, 0, 0.7, 0),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Text = `${egg.Price}`,
		BackgroundColor = Theme.Color.Success,
	})
	buyButton.MouseButton1Click:Connect(function()
		Net.getRemoteEvent("RequestBuyEgg"):FireServer(egg.Id)
	end)

	row.Parent = parent
	return buyButton
end

local function buildPetRow(parent: Instance): (Frame, PetRow)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 44)
	row.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.Radius.Md
	corner.Parent = row

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.52, 0, 1, 0)
	nameLabel.Position = UDim2.fromOffset(8, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Theme.Text.Body.Font
	nameLabel.TextSize = 13
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextColor3 = Theme.Color.TextOnDark
	nameLabel.Parent = row

	local countLabel = Instance.new("TextLabel")
	countLabel.Size = UDim2.new(0.18, 0, 1, 0)
	countLabel.Position = UDim2.new(0.52, 0, 0, 0)
	countLabel.BackgroundTransparency = 1
	countLabel.Font = Theme.Text.Small.Font
	countLabel.TextSize = 13
	countLabel.TextColor3 = Theme.Color.TextOnDark
	countLabel.Text = "x0"
	countLabel.Parent = row

	local equipButton = Widgets.pillButton({
		Parent = row,
		Size = UDim2.new(0.28, 0, 0.75, 0),
		Position = UDim2.new(1, -6, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Text = "🔒",
		BackgroundColor = Theme.Color.Dirty,
	})

	row.Parent = parent
	return row, { Row = row, EquipButton = equipButton, CountLabel = countLabel, NameLabel = nameLabel }
end

local function buildRevealPopup(parent: Instance): (Frame, TextLabel, UIStroke)
	local reveal = Instance.new("Frame")
	reveal.AnchorPoint = Vector2.new(0.5, 0.5)
	reveal.Position = UDim2.fromScale(0.5, 0.4)
	reveal.Size = UDim2.fromOffset(0, 0)
	reveal.BackgroundColor3 = Theme.Color.BackgroundAlt
	reveal.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.Radius.Xl
	corner.Parent = reveal

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 5
	stroke.Parent = reveal

	reveal.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Theme.Text.Heading.Font
	label.TextSize = 22
	label.TextColor3 = Theme.Color.TextOnDark
	label.TextWrapped = true
	label.Text = ""
	label.Parent = reveal

	return reveal, label, stroke
end

function PetsPanel.build(screenGui: ScreenGui)
	local openButton = Widgets.pillButton({
		Parent = screenGui,
		Size = UDim2.fromOffset(64, 64),
		Position = UDim2.new(0, 16, 0.5, 76),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = "🐾",
		BackgroundColor = Theme.Color.Primary,
	})

	local panel = Widgets.togglePanel({
		Parent = screenGui,
		OpenButton = openButton,
		Size = UDim2.fromOffset(320, 320),
		Position = UDim2.new(0, 92, 0.5, 76),
		AnchorPoint = Vector2.new(0, 0.5),
	})

	local egg = Eggs.List[1]
	local buyButton = buildEggRow(panel, egg)

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, 0, 1, -56)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.CanvasSize = UDim2.fromScale(0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 6)
	listLayout.Parent = scrollFrame
	scrollFrame.Parent = panel

	local rows: { [string]: PetRow } = {}
	for _, pet in Pets do
		local _row, entry = buildPetRow(scrollFrame)
		rows[pet.Id] = entry
	end

	local function refresh()
		local equipped = player:GetAttribute("EquippedPet")
		for _, pet in Pets do
			local entry = rows[pet.Id]
			if not entry then
				continue
			end
			local count = (player:GetAttribute("PetCount_" .. pet.Id) :: number?) or 0
			local owned = count > 0

			entry.Row.BackgroundColor3 = if owned then Theme.Rarity[pet.Rarity] else Theme.Color.Dirty
			entry.Row.BackgroundTransparency = if owned then 0 else 0.5
			entry.CountLabel.Text = `x{count}`
			entry.NameLabel.Text = if owned then pet.Name else "???"

			if not owned then
				entry.EquipButton.Active = false
				entry.EquipButton.Text = "🔒"
				entry.EquipButton.BackgroundColor3 = Theme.Color.Dirty
			elseif equipped == pet.Id then
				entry.EquipButton.Active = true
				entry.EquipButton.Text = "✓"
				entry.EquipButton.BackgroundColor3 = Theme.Color.Success
			else
				entry.EquipButton.Active = true
				entry.EquipButton.Text = "Equipar"
				entry.EquipButton.BackgroundColor3 = Theme.Color.Primary
			end
		end
	end

	for _, pet in Pets do
		rows[pet.Id].EquipButton.MouseButton1Click:Connect(function()
			local equipped = player:GetAttribute("EquippedPet")
			local newEquipped = if equipped == pet.Id then nil else pet.Id
			Net.getRemoteEvent("RequestEquipPet"):FireServer(newEquipped)
		end)
	end

	local leaderstats = player:WaitForChild("leaderstats")
	local money = leaderstats:WaitForChild("Money") :: IntValue
	local function refreshBuyButton()
		buyButton.BackgroundColor3 = if money.Value >= egg.Price then Theme.Color.Success else Theme.Color.Danger
	end
	money:GetPropertyChangedSignal("Value"):Connect(refreshBuyButton)
	refreshBuyButton()

	player:GetAttributeChangedSignal("EquippedPet"):Connect(refresh)
	for _, pet in Pets do
		player:GetAttributeChangedSignal("PetCount_" .. pet.Id):Connect(refresh)
	end
	refresh()

	local reveal, revealLabel, revealStroke = buildRevealPopup(screenGui)
	Net.getRemoteEvent("PetHatched").OnClientEvent:Connect(function(petId: unknown)
		if typeof(petId) ~= "string" then
			return
		end
		local pet = petsById[petId]
		if not pet then
			return
		end
		revealStroke.Color = Theme.Rarity[pet.Rarity]
		revealLabel.Text = `🥚 ¡{pet.Name}!\n({pet.Rarity})`
		reveal.Size = UDim2.fromOffset(0, 0)
		TweenService:Create(reveal, Theme.tween("Celebrate"), { Size = UDim2.fromOffset(300, 140) }):Play()
		task.delay(2, function()
			TweenService:Create(reveal, Theme.tween("PopIn"), { Size = UDim2.fromOffset(0, 0) }):Play()
		end)
	end)
end

return PetsPanel
