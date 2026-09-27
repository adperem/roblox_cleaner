--!strict
--[[ Coherencia de las tablas de configuración (src/shared/Config). Son
	los datos que más se van a tocar a mano (balance, contenido nuevo), y
	cada prueba protege algo de lo que el código depende sin comprobarlo en
	tiempo de ejecución — el comentario de cada una dice qué se rompería. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assert = require(script.Parent.Assert)

local Shared = ReplicatedStorage.Shared
local Config = Shared.Config
local Theme = require(Shared.Theme)
local Zones = require(Config.Zones)
local Nozzles = require(Config.Nozzles)
local Eggs = require(Config.Eggs)
local Mutations = require(Config.Mutations)
local Pets = require(Config.Pets)
local Levels = require(Config.Levels)
local DailyMissions = require(Config.DailyMissions)
local SeasonPass = require(Config.SeasonPass)
local Codes = require(Config.Codes)
local Gamepasses = require(Config.Gamepasses)
local Rebirths = require(Config.Rebirths)
local GameConfig = require(Config.GameConfig)

local PET_TIERS: { Pets.PetTier } = { "Normal", "Golden", "Rainbow" }

type Box = { Zone: string, Id: string, Center: Vector3, Size: Vector3 }

local function targetBoxes(): { Box }
	local boxes = {}
	for _, zone in Zones do
		for _, def in zone.Targets do
			table.insert(boxes, { Zone = zone.Id, Id = def.Id, Center = zone.Origin + def.LocalPosition, Size = def.Size })
		end
	end
	return boxes
end

local function overlaps(a: Box, b: Box): boolean
	local delta = a.Center - b.Center
	local reach = (a.Size + b.Size) / 2
	return math.abs(delta.X) < reach.X and math.abs(delta.Y) < reach.Y and math.abs(delta.Z) < reach.Z
end

local cases = {
	{
		Name = "zonas: Ids únicos y nivel requerido creciente, empezando en 1",
		Run = function()
			local ids = {}
			for i, zone in Zones do
				table.insert(ids, zone.Id)
				if i == 1 then
					Assert.equal(zone.RequiredLevel, 1, "la primera zona tiene que estar abierta desde el principio")
				else
					Assert.truthy(
						zone.RequiredLevel > Zones[i - 1].RequiredLevel,
						`"{zone.Id}" pide nivel {zone.RequiredLevel}, no más que la zona anterior`
					)
				end
			end
			Assert.unique(ids, "Id de zona")
		end,
	},
	{
		-- TargetService y EventService indexan los objetivos por Id: uno
		-- repetido pisaría al otro sin avisar.
		Name = "zonas: cada Id de objetivo es único en todo el juego",
		Run = function()
			local ids = {}
			for _, box in targetBoxes() do
				table.insert(ids, box.Id)
			end
			Assert.unique(ids, "Id de objetivo")
		end,
	},
	{
		Name = "zonas: objetivos con tamaño, pago y XP positivos",
		Run = function()
			for _, zone in Zones do
				for _, def in zone.Targets do
					Assert.truthy(def.Size.X > 0 and def.Size.Y > 0 and def.Size.Z > 0, `{def.Id}: tamaño no positivo`)
					Assert.truthy(def.Payout > 0, `{def.Id}: Payout tiene que ser > 0`)
					Assert.truthy(def.XP > 0, `{def.Id}: XP tiene que ser > 0`)
					Assert.truthy(#def.Name > 0, `{def.Id}: sin nombre visible`)
				end
			end
		end,
	},
	{
		-- El suelo de WorldService tiene la cara de arriba en Y = 0.
		Name = "zonas: ningún objetivo queda enterrado bajo el suelo",
		Run = function()
			for _, box in targetBoxes() do
				local bottom = box.Center.Y - box.Size.Y / 2
				Assert.truthy(bottom >= -0.05, `{box.Id}: su base está en Y = {bottom}, por debajo del suelo`)
			end
		end,
	},
	{
		-- Dos objetivos metidos uno dentro de otro se roban el raycast del
		-- chorro: apuntas a uno y limpias el otro.
		Name = "zonas: ningún objetivo se solapa con otro",
		Run = function()
			local boxes = targetBoxes()
			for i = 1, #boxes do
				for j = i + 1, #boxes do
					Assert.truthy(not overlaps(boxes[i], boxes[j]), `{boxes[i].Id} y {boxes[j].Id} se solapan`)
				end
			end
		end,
	},
	{
		-- ShopService compra `Nozzles[requestedTier]` y exige que sea
		-- NozzleTier + 1: el Tier tiene que ser exactamente la posición.
		Name = "boquillas: el Tier de cada una coincide con su posición en la lista",
		Run = function()
			for i, nozzle in Nozzles do
				Assert.equal(nozzle.Tier, i, `boquilla "{nozzle.Name}"`)
			end
		end,
	},
	{
		Name = "boquillas: la primera es gratis; potencia y precio suben con cada una",
		Run = function()
			Assert.equal(Nozzles[1].Price, 0, "precio de la boquilla inicial")
			Assert.equal(Nozzles[1].RequiredRebirths, 0, "rebirths de la boquilla inicial")
			for i = 2, #Nozzles do
				Assert.truthy(Nozzles[i].Power > Nozzles[i - 1].Power, `{Nozzles[i].Name} no es más potente que la anterior`)
				Assert.truthy(Nozzles[i].Price > Nozzles[i - 1].Price, `{Nozzles[i].Name} no es más cara que la anterior`)
				Assert.truthy(
					Nozzles[i].RequiredRebirths >= Nozzles[i - 1].RequiredRebirths,
					`{Nozzles[i].Name} pide menos rebirths que la anterior`
				)
			end
		end,
	},
	{
		Name = "boquillas: ninguna pide más rebirths de los que existen",
		Run = function()
			for _, nozzle in Nozzles do
				Assert.truthy(
					nozzle.RequiredRebirths <= #Rebirths.List,
					`{nozzle.Name} pide {nozzle.RequiredRebirths} rebirths y solo hay {#Rebirths.List}: imposible de comprar`
				)
			end
		end,
	},
	{
		Name = "huevos: solo sortean mascotas que existen, con pesos que suman 1000",
		Run = function()
			local ids = {}
			for _, egg in Eggs.List do
				table.insert(ids, egg.Id)
				Assert.truthy(egg.Price > 0, `{egg.Id}: precio no positivo`)
				local total = 0
				for _, entry in egg.Pool do
					Assert.truthy(Pets.getById(entry.PetId) ~= nil, `{egg.Id} sortea "{entry.PetId}", que no existe en Pets`)
					Assert.truthy(entry.Weight > 0, `{egg.Id}: peso no positivo para {entry.PetId}`)
					total += entry.Weight
				end
				Assert.near(total, 1000, 1e-6, `{egg.Id}: suma de pesos (son tantos por mil)`)
				Assert.truthy(Eggs.getById(egg.Id) == egg, `Eggs.getById("{egg.Id}") no lo encuentra`)
			end
			Assert.unique(ids, "Id de huevo")
		end,
	},
	{
		Name = "huevos: roll solo devuelve mascotas de la bolsa de ese huevo",
		Run = function()
			for _, egg in Eggs.List do
				local inPool = {}
				for _, entry in egg.Pool do
					inPool[entry.PetId] = true
				end
				for _ = 1, 2000 do
					local petId = Eggs.roll(egg)
					Assert.truthy(inPool[petId], `{egg.Id}: roll devolvió "{petId}", que no está en su bolsa`)
				end
			end
		end,
	},
	{
		-- Mutations.getById cae en List[1] ante un Id desconocido: ese
		-- respaldo no puede dar bonus.
		Name = "mutaciones: Ids únicos, pesos que suman 1000 y la primera sin bonus",
		Run = function()
			local ids = {}
			local total = 0
			for _, mutation in Mutations.List do
				table.insert(ids, mutation.Id)
				Assert.truthy(mutation.Multiplier >= 1, `{mutation.Id}: multiplicador por debajo de 1`)
				Assert.truthy(mutation.Weight > 0, `{mutation.Id}: peso no positivo`)
				total += mutation.Weight
				Assert.equal(Mutations.getById(mutation.Id), mutation, `Mutations.getById("{mutation.Id}")`)
			end
			Assert.unique(ids, "Id de mutación")
			Assert.near(total, 1000, 1e-6, "suma de pesos de mutaciones (son tantos por mil)")
			Assert.equal(Mutations.List[1].Multiplier, 1, "multiplicador de la mutación de respaldo")
			Assert.equal(Mutations.getById(nil), Mutations.List[1], "Mutations.getById(nil)")
			Assert.equal(Mutations.getById("no_existe"), Mutations.List[1], "Mutations.getById con Id desconocido")
		end,
	},
	{
		Name = "mutaciones: roll siempre devuelve una de la lista",
		Run = function()
			local valid = {}
			for _, mutation in Mutations.List do
				valid[mutation] = true
			end
			for _ = 1, 2000 do
				Assert.truthy(valid[Mutations.roll()], "Mutations.roll devolvió algo fuera de la lista")
			end
		end,
	},
	{
		-- parseStorageKey separa el nivel por el sufijo: un Id que ya acabe
		-- en _Golden o _Rainbow se leería como otra mascota.
		Name = "mascotas: Ids únicos, rareza con color en el tema y sin sufijos reservados",
		Run = function()
			local ids = {}
			for _, pet in Pets.List do
				table.insert(ids, pet.Id)
				Assert.truthy(Theme.Rarity[pet.Rarity] ~= nil, `{pet.Id}: la rareza "{pet.Rarity}" no tiene color en Theme.Rarity`)
				Assert.truthy(pet.Multiplier > 0, `{pet.Id}: multiplicador no positivo`)
				Assert.truthy(
					string.match(pet.Id, "_Golden$") == nil and string.match(pet.Id, "_Rainbow$") == nil,
					`{pet.Id}: acaba en un sufijo reservado para la fusión`
				)
			end
			Assert.unique(ids, "Id de mascota")
		end,
	},
	{
		Name = "mascotas: la clave de guardado va y vuelve igual para cada nivel",
		Run = function()
			for _, pet in Pets.List do
				for _, tier in PET_TIERS do
					local key = Pets.storageKey(pet.Id, tier)
					local parsedId, parsedTier = Pets.parseStorageKey(key)
					Assert.equal(parsedId, pet.Id, `Id leído de la clave "{key}"`)
					Assert.equal(parsedTier, tier, `nivel leído de la clave "{key}"`)
				end
			end
			-- Compatibilidad con partidas de antes de la fusión.
			Assert.equal(Pets.storageKey("duck", "Normal"), "duck", "clave de una mascota Normal")
		end,
	},
	{
		Name = "mascotas: la fusión sube Normal → Dorada → Arcoíris y cada nivel vale más",
		Run = function()
			Assert.equal(Pets.nextTier("Normal"), "Golden", "siguiente de Normal")
			Assert.equal(Pets.nextTier("Golden"), "Rainbow", "siguiente de Golden")
			Assert.equal(Pets.nextTier("Rainbow"), nil, "siguiente de Rainbow")
			Assert.truthy(Pets.FusionCost >= 2, "fusionar tiene que costar al menos 2 mascotas")
			for _, pet in Pets.List do
				local normal = Pets.multiplierFor(pet.Id, "Normal")
				local golden = Pets.multiplierFor(pet.Id, "Golden")
				local rainbow = Pets.multiplierFor(pet.Id, "Rainbow")
				Assert.truthy(normal < golden and golden < rainbow, `{pet.Id}: el bonus no sube con el nivel de fusión`)
			end
		end,
	},
	{
		Name = "niveles: la curva de XP es creciente y levelForXp es su inversa",
		Run = function()
			Assert.equal(Levels.xpToReach(1), 0, "XP para el nivel 1")
			Assert.equal(Levels.levelForXp(0), 1, "nivel con 0 XP")
			for level = 2, 120 do
				local xp = Levels.xpToReach(level)
				Assert.truthy(xp > Levels.xpToReach(level - 1), `xpToReach({level}) no crece`)
				Assert.equal(Levels.levelForXp(xp), level, `levelForXp(xpToReach({level}))`)
				Assert.equal(Levels.levelForXp(xp - 1), level - 1, `levelForXp(xpToReach({level}) - 1)`)
			end
			-- El comentario de Levels.luau (y el balance de Zones.luau) cuenta con esto.
			Assert.equal(Levels.xpToReach(12), 3300, "XP acumulada para el nivel 12")
		end,
	},
	{
		Name = "misiones diarias: Ids únicos, tipo válido, meta y recompensas positivas",
		Run = function()
			local ids = {}
			for _, mission in DailyMissions do
				table.insert(ids, mission.Id)
				Assert.truthy(
					mission.Type == "TargetsCleaned" or mission.Type == "MoneyEarned",
					`{mission.Id}: tipo "{mission.Type}" desconocido`
				)
				Assert.truthy(mission.Goal > 0, `{mission.Id}: meta no positiva`)
				Assert.truthy(mission.MoneyReward >= 0 and mission.XpReward >= 0, `{mission.Id}: recompensa negativa`)
				Assert.truthy(mission.SeasonTokens >= 0, `{mission.Id}: fichas negativas`)
			end
			Assert.unique(ids, "Id de misión")
		end,
	},
	{
		-- PlayerDataService.claimSeasonTier busca `SeasonPass.Tiers[tierNumber]`.
		Name = "pase de temporada: cada nivel está en su posición y pide más fichas que el anterior",
		Run = function()
			Assert.truthy(#SeasonPass.Tiers > 0, "el pase no tiene niveles")
			for i, tier in SeasonPass.Tiers do
				Assert.equal(tier.Tier, i, "número de nivel del pase")
				Assert.truthy(tier.FreeReward > 0 and tier.PremiumReward > 0, `nivel {i}: recompensa no positiva`)
				if i > 1 then
					Assert.truthy(tier.TokensRequired > SeasonPass.Tiers[i - 1].TokensRequired, `nivel {i}: no pide más fichas`)
				end
			end
		end,
	},
	{
		-- redeemCode pasa lo que escribe el jugador a mayúsculas y le quita
		-- los espacios antes de buscarlo: un código definido de otra forma
		-- no se podría canjear nunca.
		Name = "códigos: en mayúsculas, sin espacios y sin repetir",
		Run = function()
			local codes = {}
			for _, def in Codes do
				table.insert(codes, def.Code)
				local normalized = string.upper((string.gsub(def.Code, "%s+", "")))
				Assert.equal(def.Code, normalized, "el código tiene que estar ya normalizado")
				Assert.truthy(def.MoneyReward >= 0 and def.XpReward >= 0, `{def.Code}: recompensa negativa`)
			end
			Assert.unique(codes, "código")
		end,
	},
	{
		-- GamepassService.playerOwns se consulta con estos Ids fijos en el código.
		Name = "gamepasses: existen los que usa el código y los ids de producto son válidos",
		Run = function()
			local byId = {}
			local ids = {}
			for _, gamepass in Gamepasses do
				byId[gamepass.Id] = gamepass
				table.insert(ids, gamepass.Id)
				Assert.truthy(
					gamepass.ProductId >= 0 and gamepass.ProductId == math.floor(gamepass.ProductId),
					`{gamepass.Id}: ProductId tiene que ser un entero >= 0 (0 = todavía no creado)`
				)
			end
			Assert.unique(ids, "Id de gamepass")
			for _, required in { "MoneyX2", "VIP", "SeasonPass" } do
				Assert.truthy(byId[required] ~= nil, `falta el gamepass "{required}", que el código consulta`)
			end
		end,
	},
	{
		Name = "rebirths: cada rango pide más dinero y rankForCount cubre los extremos",
		Run = function()
			for i, tier in Rebirths.List do
				Assert.truthy(tier.RequiredLevel >= 1, `{tier.Rank}: nivel requerido no válido`)
				if i > 1 then
					Assert.truthy(tier.RequiredMoney > Rebirths.List[i - 1].RequiredMoney, `{tier.Rank}: no pide más dinero`)
				end
			end
			Assert.equal(Rebirths.rankForCount(0), "Aprendiz", "rango sin rebirths")
			Assert.equal(Rebirths.rankForCount(1), Rebirths.List[1].Rank, "rango con 1 rebirth")
			Assert.equal(Rebirths.rankForCount(#Rebirths.List + 3), Rebirths.List[#Rebirths.List].Rank, "rango pasado el máximo")
		end,
	},
	{
		Name = "config general: tiempos y ritmos positivos",
		Run = function()
			for _, key in {
				"SprayRange",
				"ServerTickHz",
				"RespawnDelay",
				"WaterTankMax",
				"WaterDrainRate",
				"WaterRefillRate",
				"VipContractInterval",
				"VipContractDuration",
				"MegaDirtInterval",
				"MegaDirtDuration",
				"TradeConfirmDelay",
				"TradeInviteTimeout",
			} do
				local value = (GameConfig :: any)[key]
				Assert.truthy(typeof(value) == "number" and value > 0, `GameConfig.{key} tiene que ser un número > 0`)
			end
			Assert.truthy(
				GameConfig.VipContractDuration < GameConfig.VipContractInterval,
				"un contrato VIP dura más que el intervalo entre contratos"
			)
			Assert.truthy(
				GameConfig.MegaDirtDuration < GameConfig.MegaDirtInterval,
				"la Mega Suciedad dura más que el intervalo entre apariciones"
			)
		end,
	},
}

return cases
