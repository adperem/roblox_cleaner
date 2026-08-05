--!strict
--[[ Pase de temporada (documento de diseño, sección 6): 30 niveles, carril
	gratis y carril premium. Las fichas se ganan cobrando misiones diarias
	(ver el campo SeasonTokens en DailyMissions.luau). Las recompensas son
	dinero por ahora — cosméticos/mascotas exclusivas de temporada son
	contenido nuevo que hay que diseñar, no algo que se pueda improvisar
	aquí sin inventar assets. ]]

export type SeasonTier = {
	Tier: number,
	TokensRequired: number, -- acumulado
	FreeReward: number,
	PremiumReward: number,
}

local tiers: { SeasonTier } = {}
for i = 1, 30 do
	tiers[i] = {
		Tier = i,
		TokensRequired = i * 50,
		FreeReward = 50 * i,
		PremiumReward = 150 * i,
	}
end

return { Tiers = tiers }
