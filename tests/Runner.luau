--!strict
--[[
	Runner — ejecutor mínimo de pruebas, sin dependencias.

	Cada ModuleScript cuyo nombre acaba en `.spec` (Rojo convierte
	`Config.spec.luau` en un ModuleScript "Config.spec") devuelve una lista
	de casos `{ Name, Run }`. Se ejecutan en orden alfabético y, si alguno
	falla, se lanza un error al final — así la tarea de Open Cloud termina en
	FAILED y el pipeline se para antes de publicar.

	Se ejecuta en dos sitios:
	- En un servidor real de Roblox (tasks/run-tests.luau vía la API Luau
	  Execution de Open Cloud): todas las pruebas, incluidas las de la
	  carpeta `Engine`, que arrancan el servidor de verdad.
	- En local/CI sin credenciales (scripts/lune/run-tests.luau, con Lune):
	  solo las de esta carpeta, que no necesitan el motor de Roblox.
]]

export type Case = {
	Name: string,
	Run: () -> (),
}

export type Summary = {
	Passed: number,
	Failed: number,
	Failures: { string },
}

local Runner = {}

local function collectSpecs(folder: Instance): { ModuleScript }
	local specs: { ModuleScript } = {}
	for _, child in folder:GetChildren() do
		if child:IsA("ModuleScript") and string.sub(child.Name, -5) == ".spec" then
			table.insert(specs, child)
		end
	end
	table.sort(specs, function(a, b)
		return a.Name < b.Name
	end)
	return specs
end

function Runner.run(engineAvailable: boolean): Summary
	local specModules = collectSpecs(script.Parent)
	if engineAvailable then
		for _, module in collectSpecs(script.Parent:FindFirstChild("Engine") :: Instance) do
			table.insert(specModules, module)
		end
	else
		print("○ Pruebas de Engine/ omitidas: necesitan un servidor de Roblox de verdad")
	end

	local summary: Summary = { Passed = 0, Failed = 0, Failures = {} }

	for _, module in specModules do
		print(`▶ {module.Name}`)
		local loaded, cases = pcall((require :: any), module)
		if not loaded then
			summary.Failed += 1
			table.insert(summary.Failures, `{module.Name} no carga:\n{cases}`)
			print(`  ✗ no carga: {cases}`)
			continue
		end

		for _, case in cases :: { Case } do
			local ok, err = xpcall(case.Run, debug.traceback)
			if ok then
				summary.Passed += 1
				print(`  ✓ {case.Name}`)
			else
				summary.Failed += 1
				table.insert(summary.Failures, `{module.Name} › {case.Name}\n{err}`)
				print(`  ✗ {case.Name}\n{err}`)
			end
		end
	end

	print(`\n{summary.Passed} OK, {summary.Failed} fallidas`)
	if summary.Failed > 0 then
		error(`{summary.Failed} prueba(s) fallida(s):\n\n{table.concat(summary.Failures, "\n\n")}`, 0)
	end
	return summary
end

return Runner
