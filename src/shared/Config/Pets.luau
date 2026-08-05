--!strict
--[[ Mascotas (documento de diseño, sección 5.4), con fusión: 5 iguales dan
	una Dorada, 5 Doradas dan una Arcoíris (Rainbow es el tope, no se
	fusiona más). Cada mascota se guarda con una "clave de almacenamiento"
	que codifica el nivel — `storageKey("duck", "Normal") == "duck"`, así
	que las mascotas normales que ya existían antes de la fusión no cambian
	de forma; solo se añaden claves nuevas para las Doradas y Arcoíris. ]]

export type PetRarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Secret"
export type PetTier = "Normal" | "Golden" | "Rainbow"

export type PetDef = {
	Id: string,
	Name: string,
	Rarity: PetRarity,
	Multiplier: number, -- bonus de dinero, ej. 0.05 = +5%, para el nivel Normal
}

local List: { PetDef } = {
	{ Id = "duck", Name = "Patito de goma", Rarity = "Common", Multiplier = 0.05 },
	{ Id = "sponge", Name = "Esponjita saltarina", Rarity = "Common", Multiplier = 0.05 },
	{ Id = "otter", Name = "Nutria jabonosa", Rarity = "Uncommon", Multiplier = 0.10 },
	{ Id = "crab", Name = "Cangrejo limpiador", Rarity = "Rare", Multiplier = 0.20 },
	{ Id = "robot", Name = "Robot pulidor", Rarity = "Epic", Multiplier = 0.35 },
	{ Id = "phoenix", Name = "Fénix reluciente", Rarity = "Legendary", Multiplier = 0.60 },
	{ Id = "golden_duck", Name = "Patito dorado", Rarity = "Secret", Multiplier = 1.0 },
}

local petsById: { [string]: PetDef } = {}
for _, pet in List do
	petsById[pet.Id] = pet
end

local TIER_SCALE: { [PetTier]: number } = { Normal = 1, Golden = 2.2, Rainbow = 5 }
local TIER_SUFFIX: { [PetTier]: string } = { Normal = "", Golden = "_Golden", Rainbow = "_Rainbow" }
local TIER_LABEL: { [PetTier]: string } = { Normal = "", Golden = " ✨ Dorada", Rainbow = " 🌈 Arcoíris" }

local Pets = {
	List = List,
	FusionCost = 5,
}

function Pets.getById(petId: string): PetDef?
	return petsById[petId]
end

-- La clave con la que se guarda en ProfileData.OwnedPets. Para "Normal" es
-- literalmente el Id de la mascota (compatibilidad con partidas de antes
-- de que existiera la fusión).
function Pets.storageKey(petId: string, tier: PetTier): string
	return petId .. TIER_SUFFIX[tier]
end

-- El inverso: de una clave guardada, saca el Id base y el nivel.
function Pets.parseStorageKey(key: string): (string, PetTier)
	local rainbowBase = string.match(key, "^(.+)_Rainbow$")
	if rainbowBase then
		return rainbowBase, "Rainbow"
	end
	local goldenBase = string.match(key, "^(.+)_Golden$")
	if goldenBase then
		return goldenBase, "Golden"
	end
	return key, "Normal"
end

function Pets.displayName(petId: string, tier: PetTier): string
	local pet = petsById[petId]
	local baseName = if pet then pet.Name else petId
	return baseName .. TIER_LABEL[tier]
end

function Pets.multiplierFor(petId: string, tier: PetTier): number
	local pet = petsById[petId]
	local base = if pet then pet.Multiplier else 0
	return base * TIER_SCALE[tier]
end

-- nil si `tier` ya es el tope (Rainbow no se fusiona más).
function Pets.nextTier(tier: PetTier): PetTier?
	if tier == "Normal" then
		return "Golden"
	elseif tier == "Golden" then
		return "Rainbow"
	end
	return nil
end

return Pets
