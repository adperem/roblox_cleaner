--!strict
--[[ Certificación / rebirth (documento de diseño, sección 4.3). Cada
	rebirth pide el mismo nivel (el máximo, 90 — haber desbloqueado las 9
	zonas) y cada vez más dinero acumulado; a cambio da +25% de ganancias
	acumulativo y sube de rango. "Aprendiz" es el rango inicial (0 rebirths)
	y no está en la lista. ]]

export type RebirthTier = {
	Rank: string,
	RequiredLevel: number,
	RequiredMoney: number,
}

local List: { RebirthTier } = {
	{ Rank = "Profesional", RequiredLevel = 90, RequiredMoney = 50000 },
	{ Rank = "Experto", RequiredLevel = 90, RequiredMoney = 150000 },
	{ Rank = "Maestro", RequiredLevel = 90, RequiredMoney = 400000 },
	{ Rank = "Leyenda", RequiredLevel = 90, RequiredMoney = 1000000 },
	{ Rank = "Mito", RequiredLevel = 90, RequiredMoney = 2500000 },
}

local Rebirths = { List = List }

function Rebirths.rankForCount(count: number): string
	if count <= 0 then
		return "Aprendiz"
	end
	return List[math.min(count, #List)].Rank
end

return Rebirths
