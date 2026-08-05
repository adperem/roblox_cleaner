--!strict
--[[ Las 3 misiones diarias de la Fase 2. Se reinician cada día (ver DayKey en
	PlayerDataService) y se cobran a mano desde el panel de misiones. ]]

export type MissionType = "TargetsCleaned" | "MoneyEarned"

export type MissionDef = {
	Id: string,
	Name: string,
	Type: MissionType,
	Goal: number,
	MoneyReward: number,
	XpReward: number,
}

local DailyMissions: { MissionDef } = {
	{ Id = "clean_5", Name = "Limpia 5 objetivos", Type = "TargetsCleaned", Goal = 5, MoneyReward = 100, XpReward = 20 },
	{ Id = "clean_15", Name = "Limpia 15 objetivos", Type = "TargetsCleaned", Goal = 15, MoneyReward = 400, XpReward = 60 },
	{ Id = "earn_500", Name = "Gana $500 hoy", Type = "MoneyEarned", Goal = 500, MoneyReward = 200, XpReward = 40 },
}

return DailyMissions
