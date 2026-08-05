# Prompt para Claude Design

> Copia todo lo que hay debajo de la línea y pégalo en Claude Design.
> El resultado (sistema de diseño + pantallas) es lo que se implementará después en
> Roblox Studio con Luau, siguiendo `docs/DISENO_JUEGO.md`.

---

Eres el director de arte de UI de un juego de Roblox. Necesito el **sistema de diseño
visual completo y los mockups de todas las pantallas** de un juego llamado
**Pressure Wash Tycoon**, un simulador de limpieza con agua a presión.

## El juego en 4 líneas

El jugador dispara una hidrolimpiadora contra superficies asquerosas (cubos, coches,
mansiones, barcos, jets) y la suciedad se desprende píxel a píxel. Cobra dinero, mejora
boquillas, colecciona mascotas ayudantes, monta su empresa de limpieza y compite con el
resto del servidor por contratos VIP. Es un juego de satisfacción inmediata y progresión
constante: cada 15 segundos tiene que pasar algo bueno.

## Público y contexto de uso — condiciona todo

- **Jugadores de 8 a 16 años.** Nada sutil, nada minimalista, nada elegante-adulto.
- **75% juegan en móvil**, con el pulgar tapando parte de la pantalla y a menudo con una
  sola mano. El resto en PC y consola.
- Sesiones cortas y ruidosas: el jugador decide en **medio segundo** si un botón le
  interesa. La jerarquía visual tiene que gritar.
- Compiten con Pressure Wash Simulator, Adopt Me y Steal a Brainrot: el listón es
  color saturado, formas gordas, sombras duras y mucho brillo.

## Dirección artística que busco

- **Caricaturesco, limpio y jugoso.** Bordes redondeados generosos, contornos oscuros
  gruesos, sombras sólidas (no difusas), degradados de dos paradas.
- **Metáfora del agua:** azules y cianes brillantes para lo bueno y lo interactivo;
  marrones/verdes turbios para “sucio”, “bloqueado” o el estado “antes”.
- Sensación de **antes → después** presente en toda la interfaz: la limpieza es la
  recompensa emocional del juego y la UI debe reforzarlo.
- Todo elemento premiado (raro, legendario, limitado) necesita **aura, brillo y
  movimiento**, no solo un color distinto.

## Entrega 1 — Sistema de diseño

1. **Paleta completa en hex** con nombres semánticos: fondo, superficie, superficie
   elevada, primario (acción), éxito/dinero, peligro, aviso, y **una rampa de rareza de
   6 escalones** (Común, Poco común, Raro, Épico, Legendario, Secreto) que se distinga
   incluso para daltónicos (varía también forma y textura del marco, no solo el tono).
2. **Escala tipográfica** usando fuentes disponibles en Roblox
   (`Fredoka One`, `Luckiest Guy`, `Gotham Bold`, `Bangers`): título, encabezado,
   cuerpo, número grande de dinero, texto pequeño. Indica tamaño, peso, grosor de
   contorno y sombra de cada nivel.
3. **Componentes base**, cada uno en sus estados normal / pulsado / desactivado /
   destacado: botón primario, secundario, botón de Robux, botón de cerrar, tarjeta,
   panel modal, barra de progreso, contador de moneda, insignia de cantidad,
   pestañas, tooltip, toggle, slot de inventario.
4. **Reglas de espaciado y radios** en una escala de 4 px, y qué componentes usan
   9-slice (indícame el borde de corte en píxeles para cada uno).
5. **Sistema de iconos:** 24 iconos en un estilo coherente (dinero, gema, boquilla,
   manguera, mascota, huevo, contrato, mapa, misión, tienda, ajustes, códigos, amigos,
   rebirth, temporada, regalo, VIP, ×2, suerte, candado, marca de verificación, trofeo,
   fuego, gota de agua). Dámelos como SVG en línea.

## Entrega 2 — Pantallas (mockups completos)

Para cada una: composición, jerarquía, todos los estados y **una variante móvil
vertical y una de pantalla ancha**.

1. **HUD de partida** — el más importante. Debe contener: dinero, nivel + barra de XP,
   depósito de agua, botón de disparo móvil, mini-objetivo actual, columna de botones
   de menú, indicador de mascota activa, marcador del contrato VIP en curso.
   **Regla dura: la zona central de la pantalla queda libre**, el juego es el
   protagonista. Diséñalo pensando en pulgares: los controles cerca de los bordes
   inferiores, zonas táctiles de 44 px mínimo.
2. **Barra de progreso de limpieza** que aparece sobre la superficie que estás
   limpiando: porcentaje, insignia de mutación (×2, ×10, DORADA) y pago estimado.
3. **Recompensa de contrato completado** — celebración a pantalla completa: confeti,
   dinero ganado, desglose de bonus, botón de continuar.
4. **Tienda de mejoras** — boquillas, manguera, bomba, depósito. Lista con tier actual
   destacado, siguiente compra resaltada, comparativa de estadísticas antes/después,
   ítems bloqueados con requisito visible.
5. **Mascotas / Ayudantes** — inventario en cuadrícula con marcos de rareza, panel de
   detalle, equipar/desequipar, fusión, e **índice de colección** con siluetas de los
   que faltan.
6. **Apertura de huevo** — la secuencia completa: elección de huevo, probabilidades
   visibles, animación de suspense, revelado (una versión para común y otra para
   legendario, muy distintas en intensidad).
7. **Mapa / teletransporte de zonas** — las 9 zonas: barrio, lavadero, parque
   infantil, gasolinera, mansión, puerto, obra, aeropuerto, estación espacial.
   Desbloqueadas frente a bloqueadas con requisito de nivel.
8. **Certificación (rebirth)** — pantalla de prestigio: qué pierdes, qué ganas,
   multiplicador acumulado, rangos Aprendiz → Mito, confirmación de peso.
9. **Misiones diarias y semanales** con estados por completar / listas para cobrar /
   cobradas, y temporizador de reinicio.
10. **Pase de temporada** — recorrido de 30 niveles, carril gratis y carril premium,
    posición actual, llamada a la compra sin sentirse agresiva.
11. **Tienda de Robux** — gamepasses y packs de dinero, con la jerarquía de valor
    clara y una etiqueta de “mejor oferta”.
12. **Recompensa de login diario** — escalera de 7 días, día actual pulsando.
13. **Anuncios de servidor** — el banner de “¡SUCIEDAD DORADA APARECIÓ!”, el aviso de
    contrato VIP y la barra compartida del jefe de servidor (Mega Suciedad).
14. **Ganancias offline** — el popup de bienvenida con lo que ganaron tus empleados.
15. **Códigos, ajustes y recompensas sociales** (grupo, like, favorito, invitar amigo).
16. **Superposición del tutorial** — flechas, resaltados y bocadillos de una sola línea.
17. **Estados vacíos y de error** con la misma personalidad que el resto.

## Entrega 3 — Arte de captación

Esto decide cuánta gente entra al juego, trátalo como pieza principal:

- **Icono del juego** (512×512), 3 variantes para A/B: partido antes/después, cara
  asombrada, y una centrada en la boquilla con chorro. Legible a 150 px.
- **4 miniaturas** (1920×1080): el antes/después más espectacular, las mascotas, la
  Mega Suciedad con mucha gente, y una de códigos/actualización.
- Reglas de composición y tipografía para que el equipo pueda producir más miniaturas
  después sin romper la coherencia.

## Restricciones técnicas — respétalas o no se puede implementar

- Se implementará con `ScreenGui` de Roblox: nada de blur real, ni sombras con
  desenfoque gaussiano, ni transparencias en cascada complejas. Sombras = capas
  sólidas desplazadas o imágenes 9-slice.
- Todo el posicionamiento será en **escala** (`UDim2.fromScale`), así que dame las
  proporciones relativas, no solo píxeles fijos.
- Respeta la **zona segura** de móviles con notch y no coloques nada crítico en las
  esquinas superiores (ahí están los botones nativos de Roblox).
- Los textos se estirarán con `TextScaled`: evita diseños que se rompan si una palabra
  ocupa el doble por la traducción.
- Las animaciones se harán con `TweenService`: descríbelas como propiedad, duración y
  curva de easing concretas.

## Formato de salida

- Una **página HTML autocontenida** que sirva como guía de estilo navegable: paleta,
  tipografía, componentes en todos sus estados, iconos SVG en línea y los mockups de
  cada pantalla renderizados con HTML/CSS (no descripciones en texto: quiero verlo).
- Un bloque **JSON de tokens de diseño** (colores, espaciado, radios, tipografía,
  duraciones) que pueda convertir directamente en un `ModuleScript` de Luau.
- Para cada pantalla, una nota corta de **jerarquía**: qué mira el jugador primero,
  segundo y tercero.

Prioriza que se entienda en medio segundo y que resulte satisfactorio de mirar por
encima de cualquier otra consideración. Si tienes que elegir entre elegante y llamativo,
elige llamativo.
