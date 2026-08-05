# roblox_cleaner — Pressure Wash Tycoon

Juego de limpieza con agua a presión para Roblox.

## Documentación

- [`docs/DISENO_JUEGO.md`](docs/DISENO_JUEGO.md) — diseño completo: bucles de juego,
  mecánica de limpieza, progresión, economía, monetización, retención y plan por fases.
- [`docs/PROMPT_CLAUDE_DESIGN.md`](docs/PROMPT_CLAUDE_DESIGN.md) — prompt listo para
  pegar en Claude Design y obtener el sistema visual y los mockups de todas las
  pantallas.

## Diseño visual

- [`design/sistema-diseno.html`](design/sistema-diseno.html) — sistema de diseño
  entregado por Claude Design: paleta, rampa de rareza, tipografía, componentes,
  24 iconos SVG, las 17 pantallas y el arte de captación. Se abre en el navegador
  sin conexión (todo va incrustado).
- [`src/shared/Theme.luau`](src/shared/Theme.luau) — los tokens de ese sistema
  traducidos a Luau. Única fuente de verdad para colores, radios y animaciones.

## Cómo probar el escalado (Fase 4)

El código está organizado como proyecto [Rojo](https://rojo.space/) — no se edita nada
dentro de Roblox Studio, solo se sincroniza lo que hay en `src/`.

1. Instala Rojo: la extensión de VS Code ("Rojo" de evaera) más el plugin de Studio
   desde su [página del plugin](https://create.roblox.com/store/asset/13916111004), o
   la CLI (`cargo install rojo` / `aftman install`).
2. Abre Roblox Studio con un lugar nuevo (cualquiera vale — si no tiene ya un suelo y
   un `SpawnLocation`, el propio juego crea uno mínimo al arrancar).
3. **Para que el guardado real funcione en Studio**: Game Settings → Security →
   activa "Enable Studio Access to API Services". Sin esto el juego funciona igual,
   pero avisa por consola y no persiste nada entre partidas.
4. Desde este repo: `rojo serve` (o "Rojo: Start Server" en VS Code).
5. En Studio, abre el plugin de Rojo y pulsa "Connect".
6. Dale a Play. Apareces en el Barrio con la mira fija en el centro de la pantalla:
   gira la cámara para apuntar y mantén pulsado 💦 (o clic izquierdo en PC) para
   disparar. El botón ☰ (abajo a la izquierda) abre el menú con pestañas: 🛠️
   boquillas, 🗺️ mapa, 🎯 misiones, 🐾 mascotas, 💎 gamepasses, 🏆 certificación,
   🎫 pase de temporada, 🎁 códigos y 🤝 comercio.

No he podido abrir Roblox Studio desde este entorno (no tiene GUI), así que esto no
está verificado jugando de verdad — solo la sintaxis está comprobada con
`luau-compile`. Pruébalo en tu Studio y dime qué falla.

### Qué hay nuevo en la Fase 4

- **9 zonas**: se añaden Puerto (nivel 42), Obra (55), Aeropuerto (70) y Estación
  espacial (90) a las cinco anteriores — las 9 del documento de diseño al completo.
  Los payouts de estas cuatro son enormes a propósito (hasta $4.8M por objetivo);
  son números de relleno para la curva de un juego en vivo a largo plazo, no algo
  con playtesting detrás.
- **Certificación (rebirth)**: al llegar a nivel 90 con suficiente dinero, puedes
  certificarte — pierdes el dinero y la boquilla (conservas mascotas), y ganas
  +25% de dinero acumulativo para siempre más acceso a 2 boquillas de prestigio
  que no se pueden comprar de otra forma. 6 rangos: Aprendiz → Profesional →
  Experto → Maestro → Leyenda → Mito. Pide confirmar dos veces — es la acción más
  destructiva del juego para tu propio progreso.
- **Pase de temporada**: 30 niveles, carril gratis y carril premium (gamepass). Las
  fichas se ganan cobrando misiones diarias.
- **Comercio de mascotas**: invita a otro jugador del servidor, cada uno ofrece una
  mascota (nunca dinero), y cuando ambos dicen "Listo" hay 3 segundos antes de que
  se cierre de verdad — cambiar la oferta de cualquiera de los dos lo reinicia. El
  servidor es quien decide todo; si alguno se desconecta a mitad, se cancela solo.
- **Códigos canjeables**: un cuadro de texto en el menú, con un código de ejemplo
  (`LIMPIEZA2026`) ya cargado para probar el flujo.

### Un bug real que encontré revisando antes de darlo por terminado

Al construir el menú con pestañas nuevo (necesario porque ya no cabían 9 botones
sueltos en pantalla), varios botones quedaron como hijos directos de contenedores
con `UIListLayout` (la fila de pestañas, el contenido de una pestaña, el selector
de mascota del comercio). El problema: todo botón de `Widgets.pillButton` añade su
sombra como un hermano en el mismo padre — si ese padre tiene `UIListLayout`, la
sombra cuela como un elemento más de la lista y descoloca todo lo que va detrás.
Lo comprobé programáticamente barriendo los 12 archivos de UI en busca de este
patrón exacto y corregí los 3 sitios reales envolviendo cada botón en su propio
`Frame` (ver `MenuShell.luau`, `RebirthPanel.luau`, `TradePanel.luau`).

### Lo que sigue siendo una aproximación deliberada

- **El desprendido de la suciedad** sigue siendo dos piezas superpuestas, no el
  disolvido píxel a píxel con `EditableImage` del documento de diseño (sección 3.2).
- **Sin sonido todavía**: sigue sin `SoundId` por el mismo motivo de siempre, no voy
  a inventar un asset que no sé si existe.
- Los contratos VIP (Fase 3) siguen sin tener en cuenta el nivel de la población del
  servidor al elegir objetivo — ajuste de balance pendiente de datos reales.
- El pase de temporada premia con dinero, no con cosméticos/mascotas exclusivas de
  temporada — eso es contenido nuevo que diseñar, no algo que se puede improvisar
  sin inventar assets.
- Sin fusión de mascotas ni trading de cosméticos (no hay cosméticos todavía) — el
  documento de diseño ya los deja para más adelante.

## Estado

Fase 4 en curso: escalado (9 zonas, certificación/rebirth, pase de temporada,
comercio de mascotas, códigos) — los 5 puntos que pide esa fase del documento de
diseño. Quedan fuera a propósito, para cuando haga falta: arte real (todo sigue
siendo cajas de colores), sonido, el disolvido píxel a píxel, fusión de mascotas,
UGC/cosméticos, y la cadencia de LiveOps semanal/mensual en sí (eso no es un
entregable de código, es un ritmo de contenido continuo). Pendiente de probarse en
Roblox Studio.
