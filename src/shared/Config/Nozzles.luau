--!strict
--[[ Las 3 boquillas del prototipo (Fase 1). Power = % de limpieza por segundo. ]]

export type NozzleConfig = {
	Tier: number,
	Name: string,
	Power: number,
	Price: number,
	Color: Color3,
}

local Nozzles: { NozzleConfig } = {
	{ Tier = 1, Name = "Boquilla Básica", Power = 12, Price = 0, Color = Color3.fromHex("#9AA5B1") },
	{ Tier = 2, Name = "Boquilla Turbo", Power = 20, Price = 250, Color = Color3.fromHex("#17C3F2") },
	{ Tier = 3, Name = "Boquilla Plasma", Power = 34, Price = 900, Color = Color3.fromHex("#B36BFF") },
}

return Nozzles
