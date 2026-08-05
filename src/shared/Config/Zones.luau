--!strict
--[[ Las 9 zonas del documento de diseño. Cada zona vive en su propio rincón
	del mundo (Origin) para no solaparse; TargetService coloca sus objetivos
	ahí y ZoneService teletransporta al jugador cuando desbloquea una nueva.

	Los payouts de las zonas 6-9 son enormes a propósito (documento de
	diseño, sección 4.1: de $60K a $10M de base) — son números de relleno
	sin playtesting, pensados para la curva de progresión de un juego en
	vivo a largo plazo, no para equilibrarse a ciegas aquí. ]]

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
	{
		Id = "puerto",
		Name = "Puerto",
		RequiredLevel = 42,
		Origin = Vector3.new(1350, 0, 0),
		Targets = {
			{ Id = "ship_1", Name = "Barco pesquero con percebes", LocalPosition = Vector3.new(0, 4, 14), Size = Vector3.new(10, 8, 30), Payout = 12000, XP = 900 },
			{ Id = "anchor_1", Name = "Ancla oxidada gigante", LocalPosition = Vector3.new(-16, 3, 10), Size = Vector3.new(4, 6, 4), Payout = 18000, XP = 1300 },
			{ Id = "crane_1", Name = "Grúa del puerto", LocalPosition = Vector3.new(18, 8, 12), Size = Vector3.new(4, 16, 4), Payout = 25000, XP = 1800 },
			{ Id = "container_1", Name = "Contenedor oxidado", LocalPosition = Vector3.new(0, 3, -10), Size = Vector3.new(8, 6, 12), Payout = 35000, XP = 2400 },
		},
	},
	{
		Id = "obra",
		Name = "Obra",
		RequiredLevel = 55,
		Origin = Vector3.new(1650, 0, 0),
		Targets = {
			{ Id = "excavator_1", Name = "Excavadora cubierta de cemento", LocalPosition = Vector3.new(0, 3, 12), Size = Vector3.new(8, 6, 10), Payout = 45000, XP = 3200 },
			{ Id = "mixer_1", Name = "Hormigonera", LocalPosition = Vector3.new(-14, 3, 16), Size = Vector3.new(5, 6, 5), Payout = 65000, XP = 4200 },
			{ Id = "scaffold_1", Name = "Andamio completo", LocalPosition = Vector3.new(14, 6, 18), Size = Vector3.new(6, 12, 20), Payout = 90000, XP = 5500 },
			{ Id = "crane_2", Name = "Grúa torre", LocalPosition = Vector3.new(0, 10, -8), Size = Vector3.new(4, 20, 4), Payout = 130000, XP = 7200 },
		},
	},
	{
		Id = "aeropuerto",
		Name = "Aeropuerto",
		RequiredLevel = 70,
		Origin = Vector3.new(1950, 0, 0),
		Targets = {
			{ Id = "jet_1", Name = "Jet privado", LocalPosition = Vector3.new(0, 3, 16), Size = Vector3.new(8, 6, 30), Payout = 180000, XP = 9000 },
			{ Id = "runway_1", Name = "Tramo de pista", LocalPosition = Vector3.new(0, 0.2, -10), Size = Vector3.new(20, 0.4, 20), Payout = 260000, XP = 12000 },
			{ Id = "luggage_1", Name = "Carro de equipaje", LocalPosition = Vector3.new(-16, 2, 12), Size = Vector3.new(4, 4, 8), Payout = 350000, XP = 16000 },
			{ Id = "tower_1", Name = "Torre de control", LocalPosition = Vector3.new(18, 10, 10), Size = Vector3.new(6, 20, 6), Payout = 480000, XP = 21000 },
		},
	},
	{
		Id = "espacio",
		Name = "Estación espacial",
		RequiredLevel = 90,
		Origin = Vector3.new(2250, 0, 0),
		Targets = {
			{ Id = "module_1", Name = "Módulo espacial", LocalPosition = Vector3.new(0, 5, 14), Size = Vector3.new(8, 8, 16), Payout = 1800000, XP = 42000 },
			{ Id = "solarpanel_1", Name = "Panel solar polvoriento", LocalPosition = Vector3.new(-16, 6, 10), Size = Vector3.new(2, 12, 10), Payout = 2600000, XP = 55000 },
			{ Id = "satellite_1", Name = "Satélite averiado", LocalPosition = Vector3.new(16, 5, 12), Size = Vector3.new(6, 6, 6), Payout = 3500000, XP = 72000 },
			{ Id = "airlock_1", Name = "Esclusa de aire", LocalPosition = Vector3.new(0, 4, -8), Size = Vector3.new(5, 8, 5), Payout = 4800000, XP = 95000 },
		},
	},
}

return Zones
