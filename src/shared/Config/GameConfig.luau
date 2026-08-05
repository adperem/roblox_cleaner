--!strict
--[[ Constantes generales del prototipo. Compartidas por cliente y servidor
	para que el rango que el cliente dibuja coincida con el que el servidor valida. ]]

local GameConfig = {
	-- Distancia máxima (studs) entre jugador y objetivo para que la limpieza cuente.
	SprayRange = 16,
	-- Frecuencia del bucle de limpieza en el servidor.
	ServerTickHz = 10,
	-- Segundos tras completar un objetivo hasta que vuelve a ensuciarse.
	RespawnDelay = 4,
	StartingMoney = 0,
}

return GameConfig
