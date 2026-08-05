--!strict
--[[ Comprar huevos, ver mascotas conseguidas por nivel de fusión (Normal,
	Dorada, Arcoíris — con siluetas para las que faltan), equipar una y
	fusionar 5 iguales en la siguiente. Pestaña 🐾 del menú. El revelado al
	abrir huevo se muestra como overlay a nivel de pantalla (necesita
	`screenGui`, no solo el contenido de la pestaña, para que se vea aunque
	cambies de pestaña justo después de comprar). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Net = require(ReplicatedStorage.Shared.Net)
local Pets = require(ReplicatedStorage.Shared.Config.Pets)
local Eggs = require(ReplicatedStorage.Shared.Config.Eggs)
local Widgets = require(script.Parent.Widgets)

local player = Players.LocalPlayer

local TIERS: { Pets.PetTier } = { "Normal", "Golden", "Rainbow" }

local PetsPanel = {}

type PetRow = {
	Row: Frame,
	PetId: string,
	Tier: Pets.PetTier,
	StorageKey: string,
	EquipButton: TextButton,
	FuseButton: TextButton?,
	CountLabel: TextLabel,
	NameLabel: TextLabel,
}

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

local function buildPetRow(parent: Instance, petId: string, tier: Pets.PetTier): PetRow
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 44)
	row.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.Radius.Md
	corner.Parent = row

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
	nameLabel.Position = UDim2.fromOffset(8, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Theme.Text.Body.Font
	nameLabel.TextSize = 12
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextColor3 = Theme.Color.TextOnDark
	nameLabel.TextWrapped = true
	nameLabel.Parent = row

	local countLabel = Instance.new("TextLabel")
	countLabel.Size = UDim2.new(0.12, 0, 1, 0)
	countLabel.Position = UDim2.new(0.4, 0, 0, 0)
	countLabel.BackgroundTransparency = 1
	countLabel.Font = Theme.Text.Small.Font
	countLabel.TextSize = 13
	countLabel.TextColor3 = Theme.Color.TextOnDark
	countLabel.Text = "x0"
	countLabel.Parent = row

	-- Botones en escala pura (nunca mezclada con offset): el ancho real de
	-- la fila depende del ScrollingFrame que la contiene, no es fijo.
	local canFuse = Pets.nextTier(tier) ~= nil
	local equipButton = Widgets.pillButton({
		Parent = row,
		Size = UDim2.new(if canFuse then 0.21 else 0.44, 0, 0.75, 0),
		Position = UDim2.new(0.98, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Text = "🔒",
		BackgroundColor = Theme.Color.Dirty,
	})

	local fuseButton = nil
	if canFuse then
		fuseButton = Widgets.pillButton({
			Parent = row,
			Size = UDim2.new(0.21, 0, 0.75, 0),
			Position = UDim2.new(0.54, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Text = "⚗️",
			BackgroundColor = Theme.Color.Dirty,
		})
	end

	row.Parent = parent
	return {
		Row = row,
		PetId = petId,
		Tier = tier,
		StorageKey = Pets.storageKey(petId, tier),
		EquipButton = equipButton,
		FuseButton = fuseButton,
		CountLabel = countLabel,
		NameLabel = nameLabel,
	}
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

function PetsPanel.build(screenGui: ScreenGui, content: ScrollingFrame)
	local egg = Eggs.List[1]
	local buyButton = buildEggRow(content, egg)

	local rows: { [string]: PetRow } = {}
	for _, pet in Pets.List do
		for _, tier in TIERS do
			local entry = buildPetRow(content, pet.Id, tier)
			rows[entry.StorageKey] = entry
		end
	end

	local function refresh()
		local equipped = player:GetAttribute("EquippedPet")
		for _, pet in Pets.List do
			for _, tier in TIERS do
				local entry = rows[Pets.storageKey(pet.Id, tier)]
				if not entry then
					continue
				end
				local count = (player:GetAttribute("PetCount_" .. entry.StorageKey) :: number?) or 0
				local owned = count > 0

				entry.Row.BackgroundColor3 = if owned then Theme.Rarity[pet.Rarity] else Theme.Color.Dirty
				entry.Row.BackgroundTransparency = if owned then 0 else 0.5
				entry.CountLabel.Text = `x{count}`
				entry.NameLabel.Text = if owned then Pets.displayName(pet.Id, tier) else "???"

				if not owned then
					entry.EquipButton.Active = false
					entry.EquipButton.Text = "🔒"
					entry.EquipButton.BackgroundColor3 = Theme.Color.Dirty
				elseif equipped == entry.StorageKey then
					entry.EquipButton.Active = true
					entry.EquipButton.Text = "✓"
					entry.EquipButton.BackgroundColor3 = Theme.Color.Success
				else
					entry.EquipButton.Active = true
					entry.EquipButton.Text = "Poner"
					entry.EquipButton.BackgroundColor3 = Theme.Color.Primary
				end

				if entry.FuseButton then
					local ready = count >= Pets.FusionCost
					entry.FuseButton.Active = ready
					entry.FuseButton.Text = if ready then `⚗️ {Pets.FusionCost}→1` else "⚗️"
					entry.FuseButton.BackgroundColor3 = if ready then Theme.Color.Money else Theme.Color.Dirty
				end
			end
		end
	end

	for _, entry in rows do
		entry.EquipButton.MouseButton1Click:Connect(function()
			local equipped = player:GetAttribute("EquippedPet")
			local newEquipped = if equipped == entry.StorageKey then nil else entry.StorageKey
			Net.getRemoteEvent("RequestEquipPet"):FireServer(newEquipped)
		end)
		if entry.FuseButton then
			entry.FuseButton.MouseButton1Click:Connect(function()
				Net.getRemoteEvent("RequestFusePets"):FireServer(entry.PetId, entry.Tier)
			end)
		end
	end

	local leaderstats = player:WaitForChild("leaderstats")
	local money = leaderstats:WaitForChild("Money") :: IntValue
	local function refreshBuyButton()
		buyButton.BackgroundColor3 = if money.Value >= egg.Price then Theme.Color.Success else Theme.Color.Danger
	end
	money:GetPropertyChangedSignal("Value"):Connect(refreshBuyButton)
	refreshBuyButton()

	player:GetAttributeChangedSignal("EquippedPet"):Connect(refresh)
	for _, entry in rows do
		player:GetAttributeChangedSignal("PetCount_" .. entry.StorageKey):Connect(refresh)
	end
	refresh()

	local reveal, revealLabel, revealStroke = buildRevealPopup(screenGui)
	local function popReveal(text: string, color: Color3)
		revealStroke.Color = color
		revealLabel.Text = text
		reveal.Size = UDim2.fromOffset(0, 0)
		TweenService:Create(reveal, Theme.tween("Celebrate"), { Size = UDim2.fromOffset(300, 140) }):Play()
		task.delay(2, function()
			TweenService:Create(reveal, Theme.tween("PopIn"), { Size = UDim2.fromOffset(0, 0) }):Play()
		end)
	end

	Net.getRemoteEvent("PetHatched").OnClientEvent:Connect(function(petId: unknown)
		if typeof(petId) ~= "string" then
			return
		end
		local pet = Pets.getById(petId)
		if not pet then
			return
		end
		popReveal(`🥚 ¡{pet.Name}!\n({pet.Rarity})`, Theme.Rarity[pet.Rarity])
	end)

	Net.getRemoteEvent("PetFused").OnClientEvent:Connect(function(resultKey: unknown)
		if typeof(resultKey) ~= "string" then
			return
		end
		local petId, tier = Pets.parseStorageKey(resultKey)
		local pet = Pets.getById(petId)
		if not pet then
			return
		end
		popReveal(`⚗️ ¡Fusión lista!\n{Pets.displayName(petId, tier)}`, Theme.Rarity[pet.Rarity])
	end)
end

return PetsPanel
