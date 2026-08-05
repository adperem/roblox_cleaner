--!strict
--[[
	Gamepasses (documento de diseño, sección 7). `ProductId = 0` significa
	"todavía no existe" — un gamepass real solo se puede crear desde el
	Creator Dashboard de Roblox (Studio → Monetización) una vez publicado el
	lugar; no hay forma de inventar un id que funcione. En cuanto lo crees,
	pega aquí el id real y el botón de comprar se activa solo.
]]

export type GamepassDef = {
	Id: string,
	Name: string,
	ProductId: number,
	Description: string,
}

local Gamepasses: { GamepassDef } = {
	{
		Id = "MoneyX2",
		Name = "Dinero x2",
		ProductId = 0,
		Description = "Duplica todo el dinero que ganas limpiando, en misiones y en eventos.",
	},
	{
		Id = "VIP",
		Name = "VIP",
		ProductId = 0,
		Description = "Depósito de agua un 50% más grande y que se rellena un 50% más rápido.",
	},
}

return Gamepasses
