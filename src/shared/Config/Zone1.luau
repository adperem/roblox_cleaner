--!strict
--[[ Zona 1 · Barrio — los objetivos sucios del prototipo. ]]

export type TargetDef = {
	Id: string,
	Name: string,
	Position: Vector3,
	Size: Vector3,
	Payout: number,
}

local Zone1: { TargetDef } = {
	{ Id = "trashcan_1", Name = "Cubo de basura", Position = Vector3.new(0, 2, 10), Size = Vector3.new(3, 4, 3), Payout = 50 },
	{ Id = "bench_1", Name = "Banco", Position = Vector3.new(8, 1.5, 14), Size = Vector3.new(6, 3, 2), Payout = 80 },
	{ Id = "wall_1", Name = "Muro grafiteado", Position = Vector3.new(-10, 4, 18), Size = Vector3.new(2, 8, 10), Payout = 140 },
	{ Id = "car_1", Name = "Coche abandonado", Position = Vector3.new(15, 3, 22), Size = Vector3.new(8, 6, 16), Payout = 400 },
}

return Zone1
