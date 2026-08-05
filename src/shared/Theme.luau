--!strict
--[[
	Theme — tokens de diseño de Pressure Wash Tycoon.

	Traducción directa del bloque de tokens del sistema de diseño
	(`design/sistema-diseno.html`, pestaña "1 · Sistema de Diseño").
	Si cambia el sistema de diseño, este módulo es lo primero que se actualiza:
	ningún color, radio ni duración debe escribirse a mano en otro sitio.
]]

local Theme = {}

--------------------------------------------------------------------------------
-- Color
--------------------------------------------------------------------------------

Theme.Color = {
	Background = Color3.fromHex("#063A5E"),
	BackgroundAlt = Color3.fromHex("#052A45"),
	Surface = Color3.fromHex("#EAF6FF"),
	SurfaceElevated = Color3.fromHex("#FFFFFF"),

	Primary = Color3.fromHex("#17C3F2"),
	PrimaryDark = Color3.fromHex("#0E93BD"),

	Success = Color3.fromHex("#3ECF4B"),
	Money = Color3.fromHex("#FFCB2F"),
	Danger = Color3.fromHex("#FF4B4B"),
	Warning = Color3.fromHex("#FFA22C"),

	-- Estados "sucio", "antes" y "bloqueado".
	Dirty = Color3.fromHex("#6E5B3A"),
	DirtyAlt = Color3.fromHex("#7C8F4E"),

	Outline = Color3.fromHex("#0B2540"),
	TextOnDark = Color3.fromHex("#FFFFFF"),
	TextOnLight = Color3.fromHex("#0B2540"),
}

-- Rampa de rareza. El color nunca va solo: cada escalón lleva además su propio
-- estilo de marco (ver Theme.RarityFrame) para que se distinga sin depender del tono.
Theme.Rarity = {
	Common = Color3.fromHex("#9AA5B1"),
	Uncommon = Color3.fromHex("#4CD787"),
	Rare = Color3.fromHex("#29ABE8"),
	Epic = Color3.fromHex("#B36BFF"),
	Legendary = Color3.fromHex("#FF8A1F"),
	Secret = Color3.fromHex("#1B1B22"),
}

export type RarityName = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Secret"

-- `pips` = número de marcas en la esquina del marco (redundancia para daltónicos).
-- `dashed` = borde discontinuo. `effect` = animación extra del marco.
Theme.RarityFrame: { [RarityName]: { pips: number, dashed: boolean, effect: string? } } = {
	Common = { pips = 1, dashed = false },
	Uncommon = { pips = 2, dashed = false },
	Rare = { pips = 3, dashed = true },
	Epic = { pips = 4, dashed = true },
	Legendary = { pips = 5, dashed = false, effect = "Glow" },
	Secret = { pips = 6, dashed = false, effect = "Shimmer" },
}

--------------------------------------------------------------------------------
-- Espaciado y radios (en píxeles de referencia, escala de 4)
--------------------------------------------------------------------------------

Theme.Spacing = { 4, 8, 12, 16, 20, 24, 32, 40, 48, 64 }

Theme.Radius = {
	Sm = UDim.new(0, 8),
	Md = UDim.new(0, 12),
	Lg = UDim.new(0, 16),
	Xl = UDim.new(0, 24),
	Xxl = UDim.new(0, 32),
	Pill = UDim.new(1, 0),
}

--------------------------------------------------------------------------------
-- Tipografía
--------------------------------------------------------------------------------

export type TextStyle = {
	Font: Enum.Font,
	Size: number,
	Outline: number,
	Shadow: number,
}

Theme.Text: { [string]: TextStyle } = {
	Title = { Font = Enum.Font.LuckiestGuy, Size = 56, Outline = 3, Shadow = 6 },
	Heading = { Font = Enum.Font.FredokaOne, Size = 30, Outline = 1, Shadow = 0 },
	Body = { Font = Enum.Font.GothamMedium, Size = 20, Outline = 0, Shadow = 0 },
	Money = { Font = Enum.Font.Bangers, Size = 48, Outline = 2, Shadow = 5 },
	Small = { Font = Enum.Font.GothamBold, Size = 14, Outline = 0, Shadow = 0 },
}

--------------------------------------------------------------------------------
-- Movimiento
--------------------------------------------------------------------------------

Theme.Duration = {
	Tap = 0.09,
	PopIn = 0.22,
	Celebrate = 0.90,
	Tooltip = 0.12,
	ScreenTransition = 0.26,
}

Theme.Easing = {
	Tap = Enum.EasingStyle.Back,
	PopIn = Enum.EasingStyle.Back,
	Celebrate = Enum.EasingStyle.Elastic,
	Tooltip = Enum.EasingStyle.Quad,
}

--[[
	Devuelve el TweenInfo del movimiento con nombre `name`.
	Uso: TweenService:Create(gui, Theme.tween("PopIn"), { ... })
]]
function Theme.tween(name: string, direction: Enum.EasingDirection?): TweenInfo
	local duration = Theme.Duration[name]
	local easing = Theme.Easing[name]
	assert(duration and easing, `Theme.tween: movimiento desconocido "{name}"`)
	return TweenInfo.new(duration, easing, direction or Enum.EasingDirection.Out)
end

--------------------------------------------------------------------------------
-- Reglas de layout que el diseño da por supuestas
--------------------------------------------------------------------------------

Theme.Layout = {
	-- Zona táctil mínima en móvil. Ningún botón interactivo baja de aquí.
	MinTapTargetPx = 44,
	-- Grosor del contorno oscuro característico del estilo.
	OutlineThicknessPx = 3,
	-- Desplazamiento de la sombra sólida (nunca desenfoque).
	ShadowOffsetPx = 4,
}

return Theme
