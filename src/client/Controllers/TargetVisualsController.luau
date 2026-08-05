--!strict
--[[ Traduce el atributo `Progress` (autoridad del servidor) en la
	transparencia visual de la capa de suciedad, para todos los clientes por
	igual. Es puramente de presentación: no manda nada al servidor. ]]

local CollectionService = game:GetService("CollectionService")

local TAG = "DirtyTarget"

local TargetVisualsController = {}

local function bind(target: Instance)
	if not target:IsA("BasePart") then
		return
	end

	local function refresh()
		local progress = target:GetAttribute("Progress")
		target.Transparency = if typeof(progress) == "number" then progress / 100 else 0
	end

	target:GetAttributeChangedSignal("Progress"):Connect(refresh)
	refresh()
end

function TargetVisualsController.start()
	for _, target in CollectionService:GetTagged(TAG) do
		bind(target)
	end
	CollectionService:GetInstanceAddedSignal(TAG):Connect(bind)
end

return TargetVisualsController
