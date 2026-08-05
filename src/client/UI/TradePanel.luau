--!strict
--[[
	TradePanel — comercio de mascotas. Pestaña 🤝 del menú (lista de
	jugadores a quien invitar) más dos overlays a nivel de pantalla que
	tienen que verse aunque el menú esté cerrado: el aviso de invitación
	entrante y la ventana del comercio activo en sí, con el selector de
	mascota propia, la oferta de la otra persona, y el botón de "listo" con
	la cuenta atrás de `GameConfig.TradeConfirmDelay` segundos una vez los
	dos han dicho que sí — cambiar de mascota mientras cuenta la reinicia
	(lo hace el servidor; aquí solo se refleja lo que él decide).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Net = require(ReplicatedStorage.Shared.Net)
local Pets = require(ReplicatedStorage.Shared.Config.Pets)
local Widgets = require(script.Parent.Widgets)

local player = Players.LocalPlayer

local petsById = {}
for _, pet in Pets do
	petsById[pet.Id] = pet
end

local TradePanel = {}

local function petLabel(petId: string?): string
	if not petId then
		return "(nada)"
	end
	local pet = petsById[petId]
	return if pet then pet.Name else petId
end

local function buildInviteList(content: ScrollingFrame)
	local rows: { [Player]: Frame } = {}

	local function addRow(target: Player)
		if target == player or rows[target] then
			return
		end
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
		label.Text = target.Name
		label.Parent = row

		local inviteButton = Widgets.pillButton({
			Parent = row,
			Size = UDim2.new(0.35, 0, 0.7, 0),
			Position = UDim2.new(1, 0, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Text = "Invitar",
			BackgroundColor = Theme.Color.Primary,
		})
		inviteButton.MouseButton1Click:Connect(function()
			Net.getRemoteEvent("RequestTradeInvite"):FireServer(target)
		end)

		row.Parent = content
		rows[target] = row
	end

	local function removeRow(target: Player)
		local row = rows[target]
		if row then
			row:Destroy()
			rows[target] = nil
		end
	end

	for _, other in Players:GetPlayers() do
		addRow(other)
	end
	Players.PlayerAdded:Connect(addRow)
	Players.PlayerRemoving:Connect(removeRow)
end

local function buildInvitePrompt(screenGui: ScreenGui)
	local prompt = Widgets.panel({
		Parent = screenGui,
		Size = UDim2.fromOffset(320, 140),
		Position = UDim2.fromScale(0.5, 0.3),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor = Theme.Color.BackgroundAlt,
	})
	prompt.Visible = false

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -16, 0, 60)
	label.Position = UDim2.fromOffset(8, 8)
	label.BackgroundTransparency = 1
	label.Font = Theme.Text.Body.Font
	label.TextSize = 16
	label.TextWrapped = true
	label.TextColor3 = Theme.Color.TextOnDark
	label.Text = ""
	label.Parent = prompt

	local acceptButton = Widgets.pillButton({
		Parent = prompt,
		Size = UDim2.new(0.45, 0, 0, 44),
		Position = UDim2.new(0, 8, 1, -8),
		AnchorPoint = Vector2.new(0, 1),
		Text = "Aceptar",
		BackgroundColor = Theme.Color.Success,
	})
	local declineButton = Widgets.pillButton({
		Parent = prompt,
		Size = UDim2.new(0.45, 0, 0, 44),
		Position = UDim2.new(1, -8, 1, -8),
		AnchorPoint = Vector2.new(1, 1),
		Text = "Rechazar",
		BackgroundColor = Theme.Color.Danger,
	})

	acceptButton.MouseButton1Click:Connect(function()
		prompt.Visible = false
		Net.getRemoteEvent("RequestRespondTradeInvite"):FireServer(true)
	end)
	declineButton.MouseButton1Click:Connect(function()
		prompt.Visible = false
		Net.getRemoteEvent("RequestRespondTradeInvite"):FireServer(false)
	end)

	Net.getRemoteEvent("TradeInviteReceived").OnClientEvent:Connect(function(inviter: unknown)
		if typeof(inviter) ~= "Instance" or not inviter:IsA("Player") then
			return
		end
		label.Text = `{(inviter :: Player).Name} quiere comerciar contigo.`
		prompt.Visible = true
	end)
end

local function buildTradeWindow(screenGui: ScreenGui)
	local window = Widgets.panel({
		Parent = screenGui,
		Size = UDim2.fromOffset(480, 360),
		Position = UDim2.fromScale(0.5, 0.42),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor = Theme.Color.BackgroundAlt,
	})
	window.Visible = false

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -16, 0, 28)
	title.Position = UDim2.fromOffset(8, 8)
	title.BackgroundTransparency = 1
	title.Font = Theme.Text.Heading.Font
	title.TextSize = 20
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Theme.Color.TextOnDark
	title.Text = "🤝 Comercio"
	title.Parent = window

	local myOfferLabel = Instance.new("TextLabel")
	myOfferLabel.Size = UDim2.new(0.48, 0, 0, 24)
	myOfferLabel.Position = UDim2.fromOffset(8, 44)
	myOfferLabel.BackgroundTransparency = 1
	myOfferLabel.Font = Theme.Text.Body.Font
	myOfferLabel.TextSize = 14
	myOfferLabel.TextXAlignment = Enum.TextXAlignment.Left
	myOfferLabel.TextColor3 = Theme.Color.TextOnDark
	myOfferLabel.Text = "Tu oferta: (nada)"
	myOfferLabel.Parent = window

	local theirOfferLabel = Instance.new("TextLabel")
	theirOfferLabel.Size = UDim2.new(0.48, 0, 0, 24)
	theirOfferLabel.Position = UDim2.new(0.52, 0, 0, 44)
	theirOfferLabel.BackgroundTransparency = 1
	theirOfferLabel.Font = Theme.Text.Body.Font
	theirOfferLabel.TextSize = 14
	theirOfferLabel.TextXAlignment = Enum.TextXAlignment.Left
	theirOfferLabel.TextColor3 = Theme.Color.TextOnDark
	theirOfferLabel.Text = "Su oferta: (nada)"
	theirOfferLabel.Parent = window

	local readyLabel = Instance.new("TextLabel")
	readyLabel.Size = UDim2.new(1, -16, 0, 20)
	readyLabel.Position = UDim2.fromOffset(8, 72)
	readyLabel.BackgroundTransparency = 1
	readyLabel.Font = Theme.Text.Small.Font
	readyLabel.TextSize = Theme.Text.Small.Size
	readyLabel.TextColor3 = Theme.Color.TextOnDark
	readyLabel.Text = ""
	readyLabel.Parent = window

	local pickerLabel = Instance.new("TextLabel")
	pickerLabel.Size = UDim2.new(1, -16, 0, 20)
	pickerLabel.Position = UDim2.fromOffset(8, 100)
	pickerLabel.BackgroundTransparency = 1
	pickerLabel.Font = Theme.Text.Small.Font
	pickerLabel.TextSize = Theme.Text.Small.Size
	pickerLabel.TextColor3 = Theme.Color.TextOnDark
	pickerLabel.Text = "Elige qué ofrecer:"
	pickerLabel.Parent = window

	local picker = Instance.new("ScrollingFrame")
	picker.Size = UDim2.new(1, -16, 0, 110)
	picker.Position = UDim2.fromOffset(8, 124)
	picker.BackgroundTransparency = 1
	picker.BorderSizePixel = 0
	picker.ScrollBarThickness = 6
	picker.CanvasSize = UDim2.fromScale(0, 0)
	picker.AutomaticCanvasSize = Enum.AutomaticSize.Y
	picker.Parent = window

	local pickerLayout = Instance.new("UIListLayout")
	pickerLayout.Padding = UDim.new(0, 6)
	pickerLayout.Parent = picker

	local readyButton = Widgets.pillButton({
		Parent = window,
		Size = UDim2.new(0.48, 0, 0, 48),
		Position = UDim2.new(0, 8, 1, -8),
		AnchorPoint = Vector2.new(0, 1),
		Text = "Listo",
		BackgroundColor = Theme.Color.Success,
	})
	local cancelButton = Widgets.pillButton({
		Parent = window,
		Size = UDim2.new(0.48, 0, 0, 48),
		Position = UDim2.new(1, -8, 1, -8),
		AnchorPoint = Vector2.new(1, 1),
		Text = "Cancelar",
		BackgroundColor = Theme.Color.Danger,
	})

	local myOffer: string? = nil
	local iAmReady = false
	local countdownEndsAt: number? = nil
	-- Guarda el Frame contenedor, no el botón: Widgets.pillButton añade una
	-- sombra como hermano en su Parent, y si el botón fuera hijo directo de
	-- `picker` (que tiene UIListLayout) esa sombra colaría como un elemento
	-- más de la lista.
	local pickerSlots: { [string]: Frame } = {}

	local function refreshPicker()
		for _, pet in Pets do
			local count = (player:GetAttribute("PetCount_" .. pet.Id) :: number?) or 0
			local slot = pickerSlots[pet.Id]
			if count > 0 and not slot then
				local newSlot = Instance.new("Frame")
				newSlot.Size = UDim2.new(1, 0, 0, 36)
				newSlot.BackgroundTransparency = 1
				newSlot.Parent = picker

				local newButton = Widgets.pillButton({
					Parent = newSlot,
					Size = UDim2.fromScale(1, 1),
					Text = pet.Name,
					BackgroundColor = Theme.Rarity[pet.Rarity],
				})
				newButton.MouseButton1Click:Connect(function()
					myOffer = if myOffer == pet.Id then nil else pet.Id
					Net.getRemoteEvent("RequestSetTradeOffer"):FireServer(myOffer)
				end)
				pickerSlots[pet.Id] = newSlot
			elseif count <= 0 and slot then
				slot:Destroy()
				pickerSlots[pet.Id] = nil
			end
		end
	end

	for _, pet in Pets do
		player:GetAttributeChangedSignal("PetCount_" .. pet.Id):Connect(refreshPicker)
	end

	readyButton.MouseButton1Click:Connect(function()
		iAmReady = not iAmReady
		Net.getRemoteEvent("RequestSetTradeReady"):FireServer(iAmReady)
	end)
	cancelButton.MouseButton1Click:Connect(function()
		Net.getRemoteEvent("RequestCancelTrade"):FireServer()
	end)

	local function closeWindow()
		window.Visible = false
		myOffer = nil
		iAmReady = false
		countdownEndsAt = nil
		readyButton.Text = "Listo"
		readyButton.BackgroundColor3 = Theme.Color.Success
	end

	Net.getRemoteEvent("TradeStateUpdated").OnClientEvent:Connect(
		function(myOfferId: unknown, theirOfferId: unknown, amIReady: unknown, isTheirsReady: unknown, remaining: unknown)
			window.Visible = true
			refreshPicker()

			myOffer = if typeof(myOfferId) == "string" then myOfferId else nil
			myOfferLabel.Text = `Tu oferta: {petLabel(myOffer)}`
			theirOfferLabel.Text = `Su oferta: {petLabel(if typeof(theirOfferId) == "string" then theirOfferId else nil)}`

			iAmReady = amIReady == true
			readyButton.Text = if iAmReady then "✓ Listo" else "Listo"
			readyButton.BackgroundColor3 = if iAmReady then Theme.Color.Dirty else Theme.Color.Success

			if typeof(remaining) == "number" then
				countdownEndsAt = os.clock() + remaining
				readyLabel.Text = `Cerrando en {math.ceil(remaining)}s — cualquier cambio lo reinicia`
			else
				countdownEndsAt = nil
				readyLabel.Text = if isTheirsReady == true then "La otra persona ya está lista." else ""
			end
		end
	)

	Net.getRemoteEvent("TradeEnded").OnClientEvent:Connect(function(reason: unknown)
		closeWindow()
		readyLabel.Text = if reason == "Completed"
			then "✅ ¡Comercio completado!"
			elseif reason == "Declined" then "❌ Rechazó el comercio."
			elseif reason == "PlayerLeft" then "❌ Se desconectó."
			else "❌ Comercio cancelado."
	end)

	RunService.RenderStepped:Connect(function()
		if countdownEndsAt and window.Visible then
			local remaining = math.max(0, countdownEndsAt - os.clock())
			readyLabel.Text = `Cerrando en {math.ceil(remaining)}s — cualquier cambio lo reinicia`
		end
	end)
end

function TradePanel.build(screenGui: ScreenGui, content: ScrollingFrame)
	buildInviteList(content)
	buildInvitePrompt(screenGui)
	buildTradeWindow(screenGui)
end

return TradePanel
