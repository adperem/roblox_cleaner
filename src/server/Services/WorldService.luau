--!strict
--[[ Crea un suelo y un punto de aparición mínimos si el lugar no tiene ya uno,
	para que el prototipo se pueda probar en un DataModel completamente vacío. ]]

local Workspace = game:GetService("Workspace")

local WorldService = {}

function WorldService.start()
	if Workspace:FindFirstChildOfClass("SpawnLocation") then
		return
	end

	-- Ancho de sobra para cubrir las 9 zonas (Origin en X de 0 a 2250).
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Anchored = true
	floor.Size = Vector3.new(2400, 4, 250)
	floor.Position = Vector3.new(1150, -2, 0)
	floor.Color = Color3.fromHex("#4A7C3C")
	floor.Material = Enum.Material.Grass
	floor.Parent = Workspace

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 0.5, 0)
	spawn.Transparency = 1
	spawn.Duration = 0
	spawn.Parent = Workspace
end

return WorldService
