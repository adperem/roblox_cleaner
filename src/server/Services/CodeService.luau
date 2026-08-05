--!strict
--[[ Canje de códigos. La validación vive en PlayerDataService.redeemCode;
	este servicio solo conecta el remoto y devuelve el mensaje de resultado
	al jugador que lo pidió (éxito o motivo del rechazo). ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)

local CodeService = {}

function CodeService.start()
	Net.getRemoteEvent("RequestRedeemCode").OnServerEvent:Connect(function(player: Player, code: unknown)
		if typeof(code) ~= "string" then
			return
		end
		local success, message = PlayerDataService.redeemCode(player, code)
		Net.getRemoteEvent("CodeRedeemed"):FireClient(player, success, message)
	end)
end

return CodeService
