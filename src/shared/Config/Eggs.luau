--!strict
--[[ Huevos: cada uno tiene su propia bolsa de mascotas con pesos en tantos
	por mil. Solo hay uno en la Fase 3 (el del Barrio) — un huevo por zona
	nueva es la forma natural de ampliar esto más adelante. ]]

export type EggPoolEntry = {
	PetId: string,
	Weight: number, -- tantos por mil
}

export type EggDef = {
	Id: string,
	Name: string,
	Price: number,
	Pool: { EggPoolEntry },
}

local Eggs: { EggDef } = {
	{
		Id = "barrio_egg",
		Name = "Huevo del Barrio",
		Price = 300,
		Pool = {
			{ PetId = "duck", Weight = 400 },
			{ PetId = "sponge", Weight = 400 },
			{ PetId = "otter", Weight = 150 },
			{ PetId = "crab", Weight = 40 },
			{ PetId = "robot", Weight = 8 },
			{ PetId = "phoenix", Weight = 1.9 },
			{ PetId = "golden_duck", Weight = 0.1 },
		},
	},
}

local Module = { List = Eggs }

function Module.roll(egg: EggDef): string
	local totalWeight = 0
	for _, entry in egg.Pool do
		totalWeight += entry.Weight
	end

	local roll = math.random() * totalWeight
	local accumulated = 0
	for _, entry in egg.Pool do
		accumulated += entry.Weight
		if roll <= accumulated then
			return entry.PetId
		end
	end
	return egg.Pool[1].PetId
end

function Module.getById(id: string): EggDef?
	for _, egg in Eggs do
		if egg.Id == id then
			return egg
		end
	end
	return nil
end

return Module
