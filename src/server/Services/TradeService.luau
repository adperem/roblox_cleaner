--!strict
--[[
	TradeService — comercio de mascotas 1x1 entre dos jugadores del mismo
	servidor (documento de diseño, sección 5.5): nunca dinero, doble
	confirmación, y un bloqueo de `GameConfig.TradeConfirmDelay` segundos
	antes de que se cierre de verdad — si cualquiera de los dos cambia lo
	que ofrece durante esos segundos, la cuenta atrás se reinicia. Solo una
	mascota por lado; sin fusión ni cosméticos todavía, así que no hay más
	que comerciar por ahora.

	Cada sesión vive en dos sitios a la vez: `activeTrades` (jugador ->
	sesión, para comprobar "¿está ocupado?" en O(1)) y `sessions` (la lista
	que recorre el bucle de expiración). Toda sesión se cierra siempre por
	`removeSession`, que limpia los dos sitios de una vez — así el bucle de
	expiración nunca depende de que borrar una clave de `activeTrades`
	mientras se itera se comporte de una forma concreta.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)

local TradeService = {}

type TradeSession = {
	PlayerA: Player,
	PlayerB: Player,
	OfferA: string?,
	OfferB: string?,
	ReadyA: boolean,
	ReadyB: boolean,
	ReadySince: number?,
}

type PendingInvite = {
	Inviter: Player,
	Invitee: Player,
	SentAt: number,
}

local sessions: { TradeSession } = {}
local activeTrades: { [Player]: TradeSession } = {}
local pendingInvitesByInvitee: { [Player]: PendingInvite } = {}
local invitingPlayers: { [Player]: boolean } = {}

local function isBusy(player: Player): boolean
	return activeTrades[player] ~= nil or pendingInvitesByInvitee[player] ~= nil or invitingPlayers[player] == true
end

local function otherPlayer(session: TradeSession, player: Player): Player
	return if session.PlayerA == player then session.PlayerB else session.PlayerA
end

local function clearInvite(invite: PendingInvite)
	pendingInvitesByInvitee[invite.Invitee] = nil
	invitingPlayers[invite.Inviter] = nil
end

local function removeSession(session: TradeSession)
	activeTrades[session.PlayerA] = nil
	activeTrades[session.PlayerB] = nil
	local index = table.find(sessions, session)
	if index then
		table.remove(sessions, index)
	end
end

local function sendState(session: TradeSession)
	local remaining = if session.ReadySince
		then math.max(0, GameConfig.TradeConfirmDelay - (os.time() - session.ReadySince))
		else nil
	Net.getRemoteEvent("TradeStateUpdated"):FireClient(
		session.PlayerA,
		session.OfferA,
		session.OfferB,
		session.ReadyA,
		session.ReadyB,
		remaining
	)
	Net.getRemoteEvent("TradeStateUpdated"):FireClient(
		session.PlayerB,
		session.OfferB,
		session.OfferA,
		session.ReadyB,
		session.ReadyA,
		remaining
	)
end

local function endTrade(session: TradeSession, reason: string)
	removeSession(session)
	Net.getRemoteEvent("TradeEnded"):FireClient(session.PlayerA, reason)
	Net.getRemoteEvent("TradeEnded"):FireClient(session.PlayerB, reason)
end

local function finalizeTrade(session: TradeSession)
	removeSession(session)

	local dataA = PlayerDataService.getData(session.PlayerA)
	local dataB = PlayerDataService.getData(session.PlayerB)
	if not dataA or not dataB then
		Net.getRemoteEvent("TradeEnded"):FireClient(session.PlayerA, "Cancelled")
		Net.getRemoteEvent("TradeEnded"):FireClient(session.PlayerB, "Cancelled")
		return
	end

	-- Revalidar que todavía tienen lo que ofrecieron, por si acaso.
	if session.OfferA and (dataA.OwnedPets[session.OfferA] or 0) <= 0 then
		session.OfferA = nil
	end
	if session.OfferB and (dataB.OwnedPets[session.OfferB] or 0) <= 0 then
		session.OfferB = nil
	end

	if session.OfferA then
		PlayerDataService.transferPet(session.PlayerA, session.PlayerB, session.OfferA)
	end
	if session.OfferB then
		PlayerDataService.transferPet(session.PlayerB, session.PlayerA, session.OfferB)
	end

	Net.getRemoteEvent("TradeEnded"):FireClient(session.PlayerA, "Completed")
	Net.getRemoteEvent("TradeEnded"):FireClient(session.PlayerB, "Completed")
end

local function handleInvite(sender: Player, target: unknown)
	if typeof(target) ~= "Instance" or not target:IsA("Player") then
		return
	end
	local invitee = target :: Player
	if invitee == sender or isBusy(sender) or isBusy(invitee) then
		return
	end

	local invite: PendingInvite = { Inviter = sender, Invitee = invitee, SentAt = os.time() }
	pendingInvitesByInvitee[invitee] = invite
	invitingPlayers[sender] = true
	Net.getRemoteEvent("TradeInviteReceived"):FireClient(invitee, sender)
end

local function handleRespond(invitee: Player, accept: unknown)
	local invite = pendingInvitesByInvitee[invitee]
	if not invite then
		return
	end
	clearInvite(invite)

	if accept ~= true then
		Net.getRemoteEvent("TradeEnded"):FireClient(invite.Inviter, "Declined")
		return
	end
	if isBusy(invite.Inviter) or isBusy(invitee) then
		Net.getRemoteEvent("TradeEnded"):FireClient(invite.Inviter, "Cancelled")
		return
	end

	local session: TradeSession = {
		PlayerA = invite.Inviter,
		PlayerB = invitee,
		OfferA = nil,
		OfferB = nil,
		ReadyA = false,
		ReadyB = false,
		ReadySince = nil,
	}
	table.insert(sessions, session)
	activeTrades[invite.Inviter] = session
	activeTrades[invitee] = session
	sendState(session)
end

local function handleSetOffer(player: Player, petId: unknown)
	local session = activeTrades[player]
	if not session then
		return
	end
	if petId ~= nil and typeof(petId) ~= "string" then
		return
	end

	if petId ~= nil then
		local data = PlayerDataService.getData(player)
		if not data or (data.OwnedPets[petId :: string] or 0) <= 0 then
			return
		end
	end

	if session.PlayerA == player then
		session.OfferA = petId :: string?
	else
		session.OfferB = petId :: string?
	end
	-- Cambiar la oferta siempre cancela el "listo" de los dos — nadie debe
	-- cerrar un trato distinto al que aceptó.
	session.ReadyA = false
	session.ReadyB = false
	session.ReadySince = nil
	sendState(session)
end

local function handleSetReady(player: Player, ready: unknown)
	local session = activeTrades[player]
	if not session or typeof(ready) ~= "boolean" then
		return
	end

	if session.PlayerA == player then
		session.ReadyA = ready
	else
		session.ReadyB = ready
	end

	session.ReadySince = if session.ReadyA and session.ReadyB then os.time() else nil
	sendState(session)
end

local function handleCancel(player: Player)
	local session = activeTrades[player]
	if session then
		endTrade(session, "Cancelled")
	end
end

local function handlePlayerRemoving(player: Player)
	local invite = pendingInvitesByInvitee[player]
	if invite then
		clearInvite(invite)
	end
	if invitingPlayers[player] then
		for _, pending in pendingInvitesByInvitee do
			if pending.Inviter == player then
				clearInvite(pending)
				break
			end
		end
	end

	local session = activeTrades[player]
	if session then
		local other = otherPlayer(session, player)
		removeSession(session)
		Net.getRemoteEvent("TradeEnded"):FireClient(other, "PlayerLeft")
	end
end

function TradeService.start()
	Net.getRemoteEvent("RequestTradeInvite").OnServerEvent:Connect(handleInvite)
	Net.getRemoteEvent("RequestRespondTradeInvite").OnServerEvent:Connect(handleRespond)
	Net.getRemoteEvent("RequestSetTradeOffer").OnServerEvent:Connect(handleSetOffer)
	Net.getRemoteEvent("RequestSetTradeReady").OnServerEvent:Connect(handleSetReady)
	Net.getRemoteEvent("RequestCancelTrade").OnServerEvent:Connect(handleCancel)
	Players.PlayerRemoving:Connect(handlePlayerRemoving)

	task.spawn(function()
		while true do
			task.wait(0.5)
			local now = os.time()

			for invitee, invite in pendingInvitesByInvitee do
				if now - invite.SentAt >= GameConfig.TradeInviteTimeout then
					clearInvite(invite)
					Net.getRemoteEvent("TradeEnded"):FireClient(invite.Inviter, "Cancelled")
				end
			end

			-- Recorrido hacia atrás porque finalizeTrade quita entradas de `sessions`.
			for i = #sessions, 1, -1 do
				local session = sessions[i]
				if session.ReadySince and now - session.ReadySince >= GameConfig.TradeConfirmDelay then
					finalizeTrade(session)
				end
			end
		end
	end)
end

return TradeService
