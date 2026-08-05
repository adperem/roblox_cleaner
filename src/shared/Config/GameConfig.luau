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

	-- Depósito de agua: se gasta disparando, se rellena solo al soltar el gatillo.
	WaterTankMax = 100,
	WaterDrainRate = 14, -- %/s mientras se dispara
	WaterRefillRate = 25, -- %/s mientras no se dispara
	-- El gamepass VIP multiplica ambos por esto.
	VipWaterMultiplier = 1.5,

	-- Contrato VIP (documento de diseño, sección 5.2): reaparece cada
	-- intervalo, coge un objetivo cualquiera ya existente y lo pone a
	-- contrarreloj con recompensa repartida por contribución.
	VipContractInterval = 240, -- segundos entre contratos
	VipContractDuration = 90, -- segundos para completarlo
	VipRewardMultiplier = 4, -- sobre el Payout/XP normales del objetivo
	VipFinisherBonus = 1.2, -- +20% para quien lo remata

	-- Mega Suciedad (sección 5.3): jefe de servidor cooperativo.
	MegaDirtInterval = 1200, -- 20 minutos
	MegaDirtDuration = 300, -- 5 minutos para limpiarla
	MegaDirtBaseReward = 500, -- × jugadores conectados al aparecer
	MegaDirtBaseXp = 100, -- × jugadores conectados al aparecer
	MegaDirtDespawnDelay = 6, -- segundos que se queda visible ya limpia

	-- Certificación (rebirth, sección 4.3): +25% de ganancias por rebirth,
	-- acumulativo (no compuesto).
	RebirthMoneyBonusPerCount = 0.25,

	-- Comercio de mascotas (sección 5.5): cuánto se mantiene la cuenta
	-- atrás antes de que un trueque con ambos "listos" se cierre de verdad.
	-- Cualquier cambio de oferta durante este tiempo la reinicia.
	TradeConfirmDelay = 3,
	TradeInviteTimeout = 30,
}

return GameConfig
