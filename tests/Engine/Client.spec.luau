--!strict
--[[ Carga (require) cada módulo del cliente dentro de un servidor real de
	Roblox. No monta la interfaz — para eso hace falta un jugador — pero
	detecta cualquier error al cargar: un require roto, un campo del tema
	mal escrito en el nivel superior, un fallo de sintaxis... Ninguno de
	estos módulos hace nada al cargarse salvo definir funciones y conectar
	señales de CollectionService, así que es seguro hacerlo en el servidor.
	Va después de Boot.spec (orden alfabético), con los RemoteEvents ya
	creados. ]]

local StarterPlayer = game:GetService("StarterPlayer")

local Assert = require(script.Parent.Parent.Assert)

local cases = {
	{
		Name = "todos los módulos del cliente cargan sin errores",
		Run = function()
			local client = StarterPlayer.StarterPlayerScripts.Client
			local failures = {}
			local count = 0
			for _, descendant in client:GetDescendants() do
				if descendant:IsA("ModuleScript") then
					count += 1
					local ok, err = pcall((require :: any), descendant)
					if not ok then
						table.insert(failures, `{descendant:GetFullName()}: {err}`)
					end
				end
			end
			Assert.truthy(count > 0, "no se encontró ningún módulo del cliente")
			Assert.truthy(#failures == 0, `módulos que no cargan:\n{table.concat(failures, "\n")}`)
		end,
	},
}

return cases
