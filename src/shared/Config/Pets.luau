--!strict
--[[ Mascotas (documento de diseño, sección 5.4). Cada una da un bonus de
	dinero al equiparla. Sin fusión todavía — es la parte de la economía de
	mascotas que se deja para una fase posterior. ]]

export type PetRarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Secret"

export type PetDef = {
	Id: string,
	Name: string,
	Rarity: PetRarity,
	Multiplier: number, -- bonus de dinero, ej. 0.05 = +5%
}

local Pets: { PetDef } = {
	{ Id = "duck", Name = "Patito de goma", Rarity = "Common", Multiplier = 0.05 },
	{ Id = "sponge", Name = "Esponjita saltarina", Rarity = "Common", Multiplier = 0.05 },
	{ Id = "otter", Name = "Nutria jabonosa", Rarity = "Uncommon", Multiplier = 0.10 },
	{ Id = "crab", Name = "Cangrejo limpiador", Rarity = "Rare", Multiplier = 0.20 },
	{ Id = "robot", Name = "Robot pulidor", Rarity = "Epic", Multiplier = 0.35 },
	{ Id = "phoenix", Name = "Fénix reluciente", Rarity = "Legendary", Multiplier = 0.60 },
	{ Id = "golden_duck", Name = "Patito dorado", Rarity = "Secret", Multiplier = 1.0 },
}

return Pets
