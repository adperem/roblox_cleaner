--!strict
--[[ Mutaciones de suciedad (documento de diseño, sección 5.1). Se sortea una
	al construir o reensuciar cada objetivo; multiplica dinero y XP. Los
	pesos sirven directamente como probabilidad en tantos por mil. ]]

export type MutationDef = {
	Id: string,
	Name: string,
	Multiplier: number,
	Weight: number, -- tantos por mil
	Announce: boolean, -- si sale, se avisa a todo el servidor
	Color: Color3,
}

local List: { MutationDef } = {
	{ Id = "mud", Name = "Barro", Multiplier = 1, Weight = 600, Announce = false, Color = Color3.fromHex("#6E5B3A") },
	{ Id = "grease", Name = "Grasa", Multiplier = 2, Weight = 200, Announce = false, Color = Color3.fromHex("#4A4A3C") },
	{ Id = "mold", Name = "Moho", Multiplier = 3, Weight = 100, Announce = false, Color = Color3.fromHex("#7C8F4E") },
	{ Id = "gum", Name = "Chicle", Multiplier = 4, Weight = 60, Announce = false, Color = Color3.fromHex("#FF6FB1") },
	{ Id = "tar", Name = "Alquitrán", Multiplier = 6, Weight = 30, Announce = true, Color = Color3.fromHex("#141414") },
	{ Id = "radioactive", Name = "Slime radiactivo", Multiplier = 10, Weight = 9, Announce = true, Color = Color3.fromHex("#7CFF3B") },
	{ Id = "golden", Name = "Suciedad dorada", Multiplier = 25, Weight = 1, Announce = true, Color = Color3.fromHex("#FFCB2F") },
}

local totalWeight = 0
for _, mutation in List do
	totalWeight += mutation.Weight
end

local Mutations = {
	List = List,
}

function Mutations.roll(): MutationDef
	local roll = math.random() * totalWeight
	local accumulated = 0
	for _, mutation in List do
		accumulated += mutation.Weight
		if roll <= accumulated then
			return mutation
		end
	end
	return List[1]
end

function Mutations.getById(id: string?): MutationDef
	if id then
		for _, mutation in List do
			if mutation.Id == id then
				return mutation
			end
		end
	end
	return List[1]
end

return Mutations
