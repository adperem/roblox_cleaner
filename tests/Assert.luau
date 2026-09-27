--!strict
-- Comprobaciones para las pruebas. Cada una lanza un error con un mensaje
-- legible (en el nivel de quien la llama) si no se cumple.

local Assert = {}

local function describe(value: any): string
	if typeof(value) == "string" then
		return `"{value}"`
	end
	return tostring(value)
end

function Assert.truthy(value: any, message: string)
	if not value then
		error(message, 2)
	end
end

function Assert.equal(actual: any, expected: any, message: string)
	if actual ~= expected then
		error(`{message}: se esperaba {describe(expected)}, llegó {describe(actual)}`, 2)
	end
end

function Assert.near(actual: number, expected: number, tolerance: number, message: string)
	if math.abs(actual - expected) > tolerance then
		error(`{message}: se esperaba {expected} ± {tolerance}, llegó {actual}`, 2)
	end
end

-- Falla si algún valor de `values` se repite. `label` describe qué se
-- está comprobando ("Id de zona", "código"...).
function Assert.unique(values: { any }, label: string)
	local seen = {}
	for _, value in values do
		if seen[value] then
			error(`{label} repetido: {describe(value)}`, 2)
		end
		seen[value] = true
	end
end

return Assert
