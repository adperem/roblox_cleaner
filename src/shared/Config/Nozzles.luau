--!strict
--[[ Boquillas. Power = % de limpieza por segundo. Las de RequiredRebirths > 0
	son las "boquillas de prestigio" del documento de diseño (sección 4.3):
	además del precio en dinero, piden haberse certificado esa cantidad de
	veces — el rebirth no es solo un multiplicador, también abre equipo
	mejor que no se puede comprar de otra forma. ]]

export type NozzleConfig = {
	Tier: number,
	Name: string,
	Power: number,
	Price: number,
	RequiredRebirths: number,
	Color: Color3,
}

local Nozzles: { NozzleConfig } = {
	{ Tier = 1, Name = "Boquilla Básica", Power = 12, Price = 0, RequiredRebirths = 0, Color = Color3.fromHex("#9AA5B1") },
	{ Tier = 2, Name = "Boquilla Turbo", Power = 20, Price = 250, RequiredRebirths = 0, Color = Color3.fromHex("#17C3F2") },
	{ Tier = 3, Name = "Boquilla Plasma", Power = 34, Price = 900, RequiredRebirths = 0, Color = Color3.fromHex("#B36BFF") },
	{ Tier = 4, Name = "Boquilla de Vapor", Power = 55, Price = 3000, RequiredRebirths = 1, Color = Color3.fromHex("#FF8A1F") },
	{ Tier = 5, Name = "Boquilla Cuántica", Power = 85, Price = 12000, RequiredRebirths = 3, Color = Color3.fromHex("#FFCB2F") },
}

return Nozzles
