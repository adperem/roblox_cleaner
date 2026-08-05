--!strict
--[[ Curva de experiencia. Los requisitos de nivel de las zonas (Zones.luau)
	dependen de esto — si se ajusta la curva, hay que revisar si siguen
	teniendo sentido. Nivel 12 (Parque infantil) pide 3300 XP acumulada. ]]

local Levels = {}

local function xpForStep(level: number): number
	return 100 + (level - 1) * 40
end

function Levels.xpToReach(level: number): number
	local total = 0
	for l = 1, level - 1 do
		total += xpForStep(l)
	end
	return total
end

function Levels.levelForXp(xp: number): number
	local level = 1
	while Levels.xpToReach(level + 1) <= xp do
		level += 1
	end
	return level
end

return Levels
