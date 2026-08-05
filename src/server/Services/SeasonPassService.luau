--!strict
--[[ Cobro del pase de temporada. La validación (fichas suficientes, no
	cobrado ya, gamepass si es el carril premium) vive en
	PlayerDataService.claimSeasonTier. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)

local SeasonPassService = {}

function SeasonPassService.start()
	Net.getRemoteEvent("RequestClaimSeasonTier").OnServerEvent:Connect(function(player: Player, tier: unknown, track: unknown)
		if typeof(tier) ~= "number" or typeof(track) ~= "string" then
			return
		end
		PlayerDataService.claimSeasonTier(player, tier, track)
	end)
end

return SeasonPassService
