--!strict
--[[ Pase de temporada. Pestaña 🎫 del menú: 30 niveles, carril gratis y
	carril premium (necesita el gamepass "SeasonPass"). Las fichas se ganan
	cobrando misiones diarias. Solo se muestran los próximos niveles sin
	cobrar de cada carril para no obligar a bajar una lista de 30 filas
	completa — clickar "Ver todos" la despliega entera. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Net = require(ReplicatedStorage.Shared.Net)
local SeasonPass = require(ReplicatedStorage.Shared.Config.SeasonPass)
local Widgets = require(script.Parent.Widgets)

local player = Players.LocalPlayer

local SeasonPassPanel = {}

type TierRow = { FreeButton: TextButton, PremiumButton: TextButton }

local function buildTierRow(parent: Instance, tier: SeasonPass.SeasonTier): TierRow
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 56)
	row.BackgroundTransparency = 1

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.34, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Theme.Text.Body.Font
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Theme.Color.TextOnDark
	label.Text = `Nivel {tier.Tier}\n{tier.TokensRequired} fichas`
	label.Parent = row

	local freeButton = Widgets.pillButton({
		Parent = row,
		Size = UDim2.new(0.3, 0, 0.7, 0),
		Position = UDim2.new(0.36, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = `${tier.FreeReward}`,
		BackgroundColor = Theme.Color.Success,
	})
	freeButton.MouseButton1Click:Connect(function()
		Net.getRemoteEvent("RequestClaimSeasonTier"):FireServer(tier.Tier, "Free")
	end)

	local premiumButton = Widgets.pillButton({
		Parent = row,
		Size = UDim2.new(0.3, 0, 0.7, 0),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Text = `${tier.PremiumReward}`,
		BackgroundColor = Theme.Color.Money,
	})
	premiumButton.MouseButton1Click:Connect(function()
		Net.getRemoteEvent("RequestClaimSeasonTier"):FireServer(tier.Tier, "Premium")
	end)

	row.Parent = parent
	return { FreeButton = freeButton, PremiumButton = premiumButton }
end

function SeasonPassPanel.build(content: ScrollingFrame)
	local tokensLabel = Instance.new("TextLabel")
	tokensLabel.Size = UDim2.new(1, 0, 0, 32)
	tokensLabel.BackgroundTransparency = 1
	tokensLabel.Font = Theme.Text.Heading.Font
	tokensLabel.TextSize = 20
	tokensLabel.TextXAlignment = Enum.TextXAlignment.Left
	tokensLabel.TextColor3 = Theme.Color.Money
	tokensLabel.Text = "🎫 0 fichas"
	tokensLabel.Parent = content

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 20)
	header.BackgroundTransparency = 1
	header.Font = Theme.Text.Small.Font
	header.TextSize = Theme.Text.Small.Size
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextColor3 = Theme.Color.TextOnDark
	header.Text = "                              Gratis          Premium"
	header.Parent = content

	local rows: { [number]: TierRow } = {}
	for _, tier in SeasonPass.Tiers do
		rows[tier.Tier] = buildTierRow(content, tier)
	end

	local function setButtonState(button: TextButton, claimed: boolean, ready: boolean, reward: number)
		if claimed then
			button.Text = "✓"
			button.Active = false
			button.BackgroundColor3 = Theme.Color.Dirty
		elseif ready then
			button.Text = `+${reward}`
			button.Active = true
		else
			button.Text = "🔒"
			button.Active = false
			button.BackgroundColor3 = Theme.Color.Dirty
		end
	end

	local function refresh()
		local tokens = (player:GetAttribute("SeasonTokens") :: number?) or 0
		local hasPremium = player:GetAttribute("Owns_SeasonPass") == true
		tokensLabel.Text = `🎫 {tokens} fichas`

		for _, tier in SeasonPass.Tiers do
			local row = rows[tier.Tier]
			local freeClaimed = player:GetAttribute(`SeasonClaimed_{tier.Tier}_Free`) == true
			local premiumClaimed = player:GetAttribute(`SeasonClaimed_{tier.Tier}_Premium`) == true
			local ready = tokens >= tier.TokensRequired

			setButtonState(row.FreeButton, freeClaimed, ready, tier.FreeReward)
			if not hasPremium then
				row.PremiumButton.Text = "💎"
				row.PremiumButton.Active = false
				row.PremiumButton.BackgroundColor3 = Theme.Color.Dirty
			else
				setButtonState(row.PremiumButton, premiumClaimed, ready, tier.PremiumReward)
				if not premiumClaimed and ready then
					row.PremiumButton.BackgroundColor3 = Theme.Color.Money
				end
			end
			if not freeClaimed and ready then
				row.FreeButton.BackgroundColor3 = Theme.Color.Success
			end
		end
	end

	player:GetAttributeChangedSignal("SeasonTokens"):Connect(refresh)
	player:GetAttributeChangedSignal("Owns_SeasonPass"):Connect(refresh)
	for _, tier in SeasonPass.Tiers do
		player:GetAttributeChangedSignal(`SeasonClaimed_{tier.Tier}_Free`):Connect(refresh)
		player:GetAttributeChangedSignal(`SeasonClaimed_{tier.Tier}_Premium`):Connect(refresh)
	end
	refresh()
end

return SeasonPassPanel
