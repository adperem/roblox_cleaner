--!strict
-- Arranque del servidor. Vive en un ModuleScript (y no directamente en
-- init.server.luau) para que las pruebas automáticas en la nube de Roblox
-- (tests/Boot.spec.luau) arranquen exactamente la misma secuencia que un
-- servidor de verdad.
--
-- El orden importa: los RemoteEvents primero (el cliente los espera al
-- arrancar su interfaz), luego el mundo y los objetivos, que tienen que
-- existir antes de que la limpieza, la tienda, las zonas o los eventos los
-- usen. GamepassService antes que nada que gaste o pague dinero.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local Services = script.Parent.Services

local Boot = {}

function Boot.start()
	Net.createAll()

	require(Services.WorldService).start()
	require(Services.GamepassService).start()
	require(Services.PlayerDataService).start()
	require(Services.TargetService).start()
	require(Services.CleaningService).start()
	require(Services.ShopService).start()
	require(Services.ZoneService).start()
	require(Services.MissionService).start()
	require(Services.PetService).start()
	require(Services.EventService).start()
	require(Services.RebirthService).start()
	require(Services.SeasonPassService).start()
	require(Services.CodeService).start()
	require(Services.TradeService).start()
end

return Boot
