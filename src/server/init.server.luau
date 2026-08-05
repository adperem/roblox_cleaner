--!strict
-- Punto de entrada del servidor. El orden importa: el mundo y los objetivos
-- tienen que existir antes de que la limpieza, la tienda, las zonas o los
-- eventos los usen. GamepassService antes que nada que gaste o pague dinero.

require(script.Services.WorldService).start()
require(script.Services.GamepassService).start()
require(script.Services.PlayerDataService).start()
require(script.Services.TargetService).start()
require(script.Services.CleaningService).start()
require(script.Services.ShopService).start()
require(script.Services.ZoneService).start()
require(script.Services.MissionService).start()
require(script.Services.PetService).start()
require(script.Services.EventService).start()
