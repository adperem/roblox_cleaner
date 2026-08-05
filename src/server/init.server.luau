--!strict
-- Punto de entrada del servidor. El orden importa: el mundo y los objetivos
-- tienen que existir antes de que la limpieza o la tienda puedan usarlos.

require(script.Services.WorldService).start()
require(script.Services.PlayerDataService).start()
require(script.Services.TargetService).start()
require(script.Services.CleaningService).start()
require(script.Services.ShopService).start()
