--!strict
--[[ Certificación (rebirth). Toda la validación vive en
	PlayerDataService.rebirth — este servicio solo conecta el remoto y avisa
	al cliente del resultado (éxito con el rango nuevo, o el motivo del
	rechazo para que el botón pueda explicar qué falta). ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)

local RebirthService = {}

function RebirthService.start()
	Net.getRemoteEvent("RequestRebirth").OnServerEvent:Connect(function(player: Player)
		local success, message = PlayerDataService.rebirth(player)
		Net.getRemoteEvent("RebirthCompleted"):FireClient(player, success, message)
	end)
end

return RebirthService
