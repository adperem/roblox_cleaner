--!strict
--[[ Códigos canjeables (documento de diseño, sección 6 y el widget "Canjear
	código" del sistema de diseño). Uno de ejemplo — el flujo real de
	publicarlos en el grupo/Discord con cada actualización es LiveOps, no
	código; esto solo deja el sistema listo para añadir más aquí. ]]

export type CodeDef = {
	Code: string,
	MoneyReward: number,
	XpReward: number,
}

local Codes: { CodeDef } = {
	{ Code = "LIMPIEZA2026", MoneyReward = 500, XpReward = 100 },
}

return Codes
