--!strict
--[[ Arranca el servidor con la misma secuencia que un servidor real
	(src/server/Boot.luau) y comprueba el mundo que deja montado. Solo corre
	en un servidor de Roblox de verdad (Open Cloud Luau Execution): ahí los
	scripts del lugar no se ejecutan solos, así que este es el único
	arranque — y no hay jugadores, así que nada de esto toca los DataStores.

	El orden de los casos importa: el primero arranca el servidor. ]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Assert = require(script.Parent.Parent.Assert)

local Server = ServerScriptService.Server
local Net = require(ReplicatedStorage.Shared.Net)
local Zones = require(ReplicatedStorage.Shared.Config.Zones)
local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local TargetService = require(Server.Services.TargetService)

local TAG = "DirtyTarget"

local function allTargetDefs(): { Zones.TargetDef }
	local defs = {}
	for _, zone in Zones do
		for _, def in zone.Targets do
			table.insert(defs, def)
		end
	end
	return defs
end

local function assertValidMutation(target: Part)
	local mutationId = target:GetAttribute("MutationId")
	Assert.truthy(typeof(mutationId) == "string", `{target.Name}: sin atributo MutationId`)
	Assert.equal(Mutations.getById(mutationId :: string).Id, mutationId, `{target.Name}: mutación desconocida`)
end

local cases = {
	{
		Name = "el servidor arranca sin errores",
		Run = function()
			require(Server.Boot).start()
		end,
	},
	{
		-- El cliente espera cada evento con WaitForChild al montar su
		-- interfaz: si alguno falta al arrancar, el HUD se queda colgado.
		Name = "todos los RemoteEvents existen nada más arrancar",
		Run = function()
			local folder = ReplicatedStorage:FindFirstChild("PressureWashRemotes")
			Assert.truthy(folder ~= nil, "no existe la carpeta de RemoteEvents")
			for _, name in Net.EventNames do
				local event = (folder :: Instance):FindFirstChild(name)
				Assert.truthy(event ~= nil and event:IsA("RemoteEvent"), `falta el RemoteEvent "{name}"`)
			end
		end,
	},
	{
		Name = "hay suelo y un punto de aparición en la zona inicial",
		Run = function()
			local floor = Workspace:FindFirstChild("Floor")
			Assert.truthy(floor ~= nil and floor:IsA("BasePart"), "no hay suelo")
			local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
			Assert.truthy(spawn ~= nil, "no hay SpawnLocation")
			local distance = ((spawn :: SpawnLocation).Position - Zones[1].Origin).Magnitude
			Assert.truthy(distance < 30, `el punto de aparición está a {math.floor(distance)} studs de "{Zones[1].Id}"`)
		end,
	},
	{
		Name = "cada objetivo de cada zona existe, etiquetado y con sus atributos",
		Run = function()
			local defs = allTargetDefs()
			for _, def in defs do
				local target = TargetService.getById(def.Id)
				Assert.truthy(target ~= nil, `falta el objetivo "{def.Id}"`)
				local part = target :: Part
				Assert.truthy(part:IsDescendantOf(Workspace), `{def.Id}: no está en Workspace`)
				Assert.truthy(CollectionService:HasTag(part, TAG), `{def.Id}: sin la etiqueta {TAG}`)
				Assert.equal(part:GetAttribute("TargetId"), def.Id, `{def.Id}: atributo TargetId`)
				Assert.equal(part:GetAttribute("Progress"), 0, `{def.Id}: atributo Progress`)
				Assert.equal(part:GetAttribute("Cleaned"), false, `{def.Id}: atributo Cleaned`)
				Assert.equal(part:GetAttribute("Payout"), def.Payout, `{def.Id}: atributo Payout`)
				Assert.equal(part:GetAttribute("XP"), def.XP, `{def.Id}: atributo XP`)
				assertValidMutation(part)
			end
			Assert.equal(#CollectionService:GetTagged(TAG), #defs, "objetivos etiquetados en total")
		end,
	},
	{
		Name = "todos los objetivos y plataformas de zona quedan encima del suelo",
		Run = function()
			local floor = Workspace:FindFirstChild("Floor") :: BasePart
			local halfX, halfZ = floor.Size.X / 2, floor.Size.Z / 2
			local function assertOnFloor(name: string, position: Vector3, size: Vector3)
				local dx = math.abs(position.X - floor.Position.X) + size.X / 2
				local dz = math.abs(position.Z - floor.Position.Z) + size.Z / 2
				Assert.truthy(dx <= halfX and dz <= halfZ, `{name} se sale del suelo`)
			end
			for _, def in allTargetDefs() do
				local part = TargetService.getById(def.Id) :: Part
				assertOnFloor(def.Id, part.Position, part.Size)
			end
			for _, zone in Zones do
				assertOnFloor(`plataforma de "{zone.Id}"`, zone.Origin, Vector3.new(10, 1, 10))
			end
		end,
	},
	{
		Name = "TargetService.reset deja un objetivo limpio sucio otra vez",
		Run = function()
			local target = TargetService.getById(Zones[1].Targets[1].Id) :: Part
			target:SetAttribute("Progress", 100)
			target:SetAttribute("Cleaned", true)
			target:SetAttribute("IsEvent", true)
			TargetService.reset(target)
			Assert.equal(target:GetAttribute("Progress"), 0, "Progress tras reset")
			Assert.equal(target:GetAttribute("Cleaned"), false, "Cleaned tras reset")
			Assert.equal(target:GetAttribute("IsEvent"), false, "IsEvent tras reset")
			assertValidMutation(target)
		end,
	},
}

return cases
