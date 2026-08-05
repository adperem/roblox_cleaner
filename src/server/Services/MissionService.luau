--!strict
--[[ Cobro de misiones diarias. La validación (existe, no cobrada, progreso
	suficiente) vive en PlayerDataService.claimMission — este servicio solo
	conecta el remoto y avisa al cliente si se concedió la recompensa. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)

local MissionService = {}

function MissionService.start()
	Net.getRemoteEvent("RequestClaimMission").OnServerEvent:Connect(function(player: Player, missionId: unknown)
		if typeof(missionId) ~= "string" then
			return
		end
		if PlayerDataService.claimMission(player, missionId) then
			Net.getRemoteEvent("MissionClaimed"):FireClient(player, missionId)
		end
	end)
end

return MissionService
