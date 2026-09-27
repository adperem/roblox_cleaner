--[[
	Ejecuta con Lune (https://lune-org.github.io/docs) las pruebas de
	tests/ que no necesitan el motor de Roblox, sobre el mismo .rbxl que
	construye Rojo. No hace falta ninguna credencial de Roblox, así que
	corre en cada push aunque Open Cloud todavía no esté configurado.

	Uso: lune run scripts/lune/run-tests.luau build/game.rbxl

	Lune carga el lugar como un DataModel pero no sabe ejecutar sus
	ModuleScript: `require` se reimplementa aquí leyendo `Source` y
	cargándolo con `script` apuntando a su instancia, igual que en Roblox.
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

local placePath = process.args[1] or "build/game.rbxl"
local game = roblox.deserializePlace(fs.readFile(placePath))

local ROBLOX_GLOBALS = {
	"Axes",
	"BrickColor",
	"CFrame",
	"Color3",
	"ColorSequence",
	"ColorSequenceKeypoint",
	"Enum",
	"Faces",
	"Font",
	"Instance",
	"NumberRange",
	"NumberSequence",
	"NumberSequenceKeypoint",
	"PhysicalProperties",
	"Ray",
	"Rect",
	"Region3",
	"UDim",
	"UDim2",
	"Vector2",
	"Vector3",
}

local baseEnvironment: { [string]: any } = {
	game = game,
	workspace = game:GetService("Workspace"),
	task = task,
}
for _, name in ROBLOX_GLOBALS do
	baseEnvironment[name] = roblox[name]
end

local cache: { [Instance]: { value: any } } = {}

local function requireModule(module: any): any
	if typeof(module) ~= "Instance" or not module:IsA("ModuleScript") then
		error(`require: se esperaba un ModuleScript, llegó {typeof(module)}`, 2)
	end
	local cached = cache[module]
	if cached then
		return cached.value
	end

	-- Lune copia los campos del entorno (no mira su metatabla): se
	-- rellena entero en cada módulo.
	local environment = table.clone(baseEnvironment)
	environment.script = module
	environment.require = requireModule
	local chunk = luau.load(module.Source, {
		debugName = module:GetFullName(),
		environment = environment,
	})
	local value = chunk()
	cache[module] = { value = value }
	return value
end

local runner = game:GetService("ServerStorage").Tests.Runner
local ok, err = pcall(function()
	requireModule(runner).run(false)
end)
if not ok then
	print(err)
	process.exit(1)
end
