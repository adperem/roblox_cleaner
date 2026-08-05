--!strict
--[[ Teletransporte entre zonas. El nivel se valida en el servidor a partir
	del atributo `Level` (que solo escribe PlayerDataService) — un cliente
	modificado no puede pedir viajar a una zona que no ha desbloqueado. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Zones = require(ReplicatedStorage.Shared.Config.Zones)

local ZoneService = {}

local zonesById: { [string]: Zones.ZoneDef } = {}
for _, zone in Zones do
	zonesById[zone.Id] = zone
end

function ZoneService.start()
	Net.getRemoteEvent("RequestTeleport").OnServerEvent:Connect(function(player: Player, zoneId: unknown)
		if typeof(zoneId) ~= "string" then
			return
		end
		local zone = zonesById[zoneId]
		if not zone then
			return
		end

		local level = (player:GetAttribute("Level") :: number?) or 1
		if level < zone.RequiredLevel then
			return
		end

		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			return
		end
		root.CFrame = CFrame.new(zone.Origin + Vector3.new(0, 5, 0))
	end)
end

return ZoneService
