--!strict
--[[ Las 5 zonas de la Fase 3. Cada zona vive en su propio rincón del mundo
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
	{
		Id = "gasolinera",
		Name = "Gasolinera",
		RequiredLevel = 20,
		Origin = Vector3.new(750, 0, 0),
		Targets = {
			{ Id = "pump_1", Name = "Surtidor sucio", LocalPosition = Vector3.new(0, 3, 10), Size = Vector3.new(3, 6, 3), Payout = 1200, XP = 140 },
			{ Id = "truck_2", Name = "Camión cisterna", LocalPosition = Vector3.new(12, 3, 16), Size = Vector3.new(10, 6, 24), Payout = 2200, XP = 220 },
			{ Id = "canopy_1", Name = "Techo de la gasolinera", LocalPosition = Vector3.new(-14, 6, 14), Size = Vector3.new(20, 2, 16), Payout = 3000, XP = 280 },
			{ Id = "oilstain_1", Name = "Mancha de aceite gigante", LocalPosition = Vector3.new(0, 0.2, 26), Size = Vector3.new(14, 0.4, 14), Payout = 1800, XP = 180 },
		},
	},
	{
		Id = "mansion",
		Name = "Mansión",
		RequiredLevel = 30,
		Origin = Vector3.new(1050, 0, 0),
		Targets = {
			{ Id = "statue_1", Name = "Estatua de mármol", LocalPosition = Vector3.new(0, 4, 10), Size = Vector3.new(3, 8, 3), Payout = 4500, XP = 380 },
			{ Id = "facade_1", Name = "Fachada de la mansión", LocalPosition = Vector3.new(0, 8, -4), Size = Vector3.new(40, 16, 2), Payout = 9000, XP = 650 },
			{ Id = "pool_1", Name = "Piscina cubierta de algas", LocalPosition = Vector3.new(16, 0.3, 20), Size = Vector3.new(16, 0.6, 10), Payout = 6500, XP = 520 },
			{ Id = "gate_1", Name = "Verja dorada oxidada", LocalPosition = Vector3.new(-18, 3, 16), Size = Vector3.new(2, 6, 14), Payout = 5000, XP = 420 },
		},
	},
}

return Zones
