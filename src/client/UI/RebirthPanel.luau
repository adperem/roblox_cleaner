--!strict
--[[ Certificación (rebirth). Pestaña 🏆 del menú. Es la acción más
	destructiva de todo el juego para el propio progreso (borra dinero,
	boquilla y nivel), así que pide confirmar dos veces: el botón se arma al
	primer clic y solo se ejecuta si se vuelve a pulsar dentro de unos
	segundos — igual que el bloqueo del comercio, pero para protegerte de ti
	mismo en vez de de la otra persona. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Net = require(ReplicatedStorage.Shared.Net)
local Rebirths = require(ReplicatedStorage.Shared.Config.Rebirths)
local Levels = require(ReplicatedStorage.Shared.Config.Levels)
local Widgets = require(script.Parent.Widgets)

local player = Players.LocalPlayer

local CONFIRM_WINDOW = 5

local RebirthPanel = {}

function RebirthPanel.build(content: ScrollingFrame)
	local rankLabel = Instance.new("TextLabel")
	rankLabel.Size = UDim2.new(1, 0, 0, 32)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Font = Theme.Text.Heading.Font
	rankLabel.TextSize = 22
	rankLabel.TextXAlignment = Enum.TextXAlignment.Left
	rankLabel.TextColor3 = Theme.Color.Money
	rankLabel.Text = "Aprendiz"
	rankLabel.Parent = content

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, 0, 0, 80)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Font = Theme.Text.Body.Font
	infoLabel.TextSize = 14
	infoLabel.TextWrapped = true
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.TextYAlignment = Enum.TextYAlignment.Top
	infoLabel.TextColor3 = Theme.Color.TextOnDark
	infoLabel.Text = ""
	infoLabel.Parent = content

	-- Envuelto en un Frame propio: si el botón fuera hijo directo de
	-- `content` (un ScrollingFrame con UIListLayout), su sombra colaría
	-- como una fila más y descolocaría todo lo que va debajo.
	local actionSlot = Instance.new("Frame")
	actionSlot.Size = UDim2.new(1, 0, 0, 56)
	actionSlot.BackgroundTransparency = 1
	actionSlot.Parent = content

	local actionButton = Widgets.pillButton({
		Parent = actionSlot,
		Size = UDim2.fromScale(1, 1),
		Text = "Certificarse",
		BackgroundColor = Theme.Color.Danger,
	})

	local resultLabel = Instance.new("TextLabel")
	resultLabel.Size = UDim2.new(1, 0, 0, 24)
	resultLabel.BackgroundTransparency = 1
	resultLabel.Font = Theme.Text.Small.Font
	resultLabel.TextSize = Theme.Text.Small.Size
	resultLabel.TextColor3 = Theme.Color.TextOnDark
	resultLabel.Text = ""
	resultLabel.Parent = content

	local leaderstats = player:WaitForChild("leaderstats")
	local money = leaderstats:WaitForChild("Money") :: IntValue

	local armed = false
	local armedUntil = 0

	local function disarm()
		armed = false
		actionButton.Text = "Certificarse"
	end

	local function refresh()
		local xp = (player:GetAttribute("XP") :: number?) or 0
		local level = Levels.levelForXp(xp)
		local rebirthCount = (player:GetAttribute("RebirthCount") :: number?) or 0

		rankLabel.Text = (player:GetAttribute("Rank") :: string?) or "Aprendiz"

		local nextTier = Rebirths.List[rebirthCount + 1]
		if not nextTier then
			infoLabel.Text = "Ya tienes el rango máximo: Mito."
			actionSlot.Visible = false
			return
		end

		actionSlot.Visible = true
		infoLabel.Text = `Siguiente rango: {nextTier.Rank}\nRequisitos: nivel {nextTier.RequiredLevel} y ${nextTier.RequiredMoney}\n\nAl certificarte pierdes el dinero y la boquilla — conservas mascotas. Ganas +25% de dinero acumulativo y acceso a boquillas de prestigio.`

		local ready = level >= nextTier.RequiredLevel and money.Value >= nextTier.RequiredMoney
		actionButton.Active = ready
		if not ready then
			disarm()
		end
		if not armed then
			actionButton.BackgroundColor3 = if ready then Theme.Color.Danger else Theme.Color.Dirty
		end
	end

	actionButton.MouseButton1Click:Connect(function()
		if not armed or os.clock() > armedUntil then
			armed = true
			armedUntil = os.clock() + CONFIRM_WINDOW
			actionButton.Text = "¿Seguro? Pulsa otra vez"
			actionButton.BackgroundColor3 = Theme.Color.Warning
			task.delay(CONFIRM_WINDOW, function()
				if armed and os.clock() > armedUntil then
					disarm()
					refresh()
				end
			end)
			return
		end

		disarm()
		Net.getRemoteEvent("RequestRebirth"):FireServer()
	end)

	Net.getRemoteEvent("RebirthCompleted").OnClientEvent:Connect(function(success: unknown, message: unknown)
		if typeof(message) ~= "string" then
			return
		end
		resultLabel.Text = if success == true then `🏆 ¡Ahora eres {message}!` else `❌ {message}`
		resultLabel.TextColor3 = if success == true then Theme.Color.Success else Theme.Color.Danger
	end)

	player:GetAttributeChangedSignal("XP"):Connect(refresh)
	player:GetAttributeChangedSignal("RebirthCount"):Connect(refresh)
	player:GetAttributeChangedSignal("Rank"):Connect(refresh)
	money:GetPropertyChangedSignal("Value"):Connect(refresh)

	refresh()
end

return RebirthPanel
