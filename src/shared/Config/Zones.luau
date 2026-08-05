--!strict
--[[ Las 3 zonas de la Fase 2. Cada zona vive en su propio rincón del mundo
	(Origin) para no solaparse; TargetService coloca sus objetivos ahí y
	ZoneService teletransporta al jugador cuando desbloquea una nueva. ]]

export type TargetDef = {
	Id: string,
	Name: string,
	LocalPosition: Vector3,
	Size: Vector3,
	Payout: number,
	XP: number,
}

export type ZoneDef = {
	Id: string,
	Name: string,
	RequiredLevel: number,
	Origin: Vector3,
	Targets: { TargetDef },
}

local Zones: { ZoneDef } = {
	{
		Id = "barrio",
		Name = "Barrio",
		RequiredLevel = 1,
		Origin = Vector3.new(0, 0, 0),
		Targets = {
			{ Id = "trashcan_1", Name = "Cubo de basura", LocalPosition = Vector3.new(0, 2, 10), Size = Vector3.new(3, 4, 3), Payout = 50, XP = 10 },
			{ Id = "bench_1", Name = "Banco", LocalPosition = Vector3.new(8, 1.5, 14), Size = Vector3.new(6, 3, 2), Payout = 80, XP = 15 },
			{ Id = "wall_1", Name = "Muro grafiteado", LocalPosition = Vector3.new(-10, 4, 18), Size = Vector3.new(2, 8, 10), Payout = 140, XP = 25 },
			{ Id = "car_1", Name = "Coche abandonado", LocalPosition = Vector3.new(15, 3, 22), Size = Vector3.new(8, 6, 16), Payout = 400, XP = 60 },
		},
	},
	{
		Id = "lavadero",
		Name = "Lavadero de coches",
		RequiredLevel = 5,
		Origin = Vector3.new(250, 0, 0),
		Targets = {
			{ Id = "moto_1", Name = "Moto embarrada", LocalPosition = Vector3.new(0, 1.5, 10), Size = Vector3.new(2, 3, 4), Payout = 300, XP = 40 },
			{ Id = "car_2", Name = "Sedán sucio", LocalPosition = Vector3.new(10, 2, 14), Size = Vector3.new(6, 4, 14), Payout = 450, XP = 55 },
			{ Id = "van_1", Name = "Furgoneta embarrada", LocalPosition = Vector3.new(-12, 2.5, 18), Size = Vector3.new(7, 5, 18), Payout = 650, XP = 75 },
			{ Id = "truck_1", Name = "Camioneta de lujo", LocalPosition = Vector3.new(20, 3, 24), Size = Vector3.new(8, 6, 20), Payout = 900, XP = 110 },
		},
	},
	{
		Id = "parque",
		Name = "Parque infantil",
		RequiredLevel = 12,
		Origin = Vector3.new(500, 0, 0),
		Targets = {
			{ Id = "slide_1", Name = "Tobogán mohoso", LocalPosition = Vector3.new(0, 3, 10), Size = Vector3.new(4, 6, 8), Payout = 900, XP = 90 },
			{ Id = "swing_1", Name = "Columpio oxidado", LocalPosition = Vector3.new(10, 3, 14), Size = Vector3.new(6, 6, 3), Payout = 1100, XP = 110 },
			{ Id = "sandbox_1", Name = "Cajón de arena", LocalPosition = Vector3.new(-12, 1, 18), Size = Vector3.new(8, 2, 8), Payout = 1400, XP = 140 },
			{ Id = "climber_1", Name = "Estructura trepadora", LocalPosition = Vector3.new(18, 4, 24), Size = Vector3.new(10, 8, 10), Payout = 1800, XP = 180 },
		},
	},
}

return Zones
