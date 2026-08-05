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

## Cómo probar el lanzamiento suave (Fase 3)

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
   disparar. La columna de botones de la izquierda tiene, de arriba abajo: 🛠️
   boquillas, 🗺️ mapa de zonas, 🎯 misiones diarias, 🐾 huevos y mascotas, 💎
   gamepasses. Cada pocos minutos aparece un banner arriba avisando de un contrato
   VIP o de una mutación rara; cada 20 minutos, una Mega Suciedad en el Barrio que
   puede limpiar todo el servidor a la vez.

No he podido abrir Roblox Studio desde este entorno (no tiene GUI), así que esto no
está verificado jugando de verdad — solo la sintaxis está comprobada con
`luau-compile`. Además usé `luau-analyze` para revisar tipos y sí encontró dos bugs
reales que corregí (ver más abajo); el resto del ruido que da son falsos positivos
de ejecutarlo sin las definiciones de Roblox ni el sourcemap de Rojo (que aquí no
tengo) — lo explico si te encuentras alguno raro en tu editor. Pruébalo en tu Studio
y dime qué falla.

### Qué hay nuevo en la Fase 3

- **5 zonas**: se añaden Gasolinera (nivel 20) y Mansión (nivel 30) a las tres de la
  Fase 2.
- **Mutaciones de suciedad**: cada objetivo sortea una al aparecer (Barro, Grasa,
  Moho, Chicle, Alquitrán, Slime radiactivo, Suciedad dorada — documento de diseño,
  sección 5.1), multiplican dinero y XP, y las tres más raras avisan a todo el
  servidor. Insignia visible en la barra de progreso mientras apuntas.
- **Contratos VIP**: cada 4 minutos, un objetivo cualquiera ya existente se pone a
  contrarreloj (90s) con una recompensa 4 veces mayor repartida por cuánto aportó
  cada jugador, +20% para quien lo remata. Es cooperativo: no hace falta ser tú
  quien lo empezó para llevarte tu parte.
- **Mega Suciedad**: cada 20 minutos aparece una estructura enorme en el Barrio
  (accesible para cualquier nivel) que todo el servidor tiene 5 minutos para limpiar
  entre todos, con barra de progreso compartida visible para todos. Misma mecánica
  de reparto por contribución que los contratos VIP.
- **Mascotas**: un huevo (300$, en el Barrio) sortea una de 7 mascotas por rareza;
  la equipada da un bonus permanente de dinero. Sin fusión todavía — se deja para
  cuando haga falta alargar la economía de coleccionables.
- **Gamepasses**: Dinero x2 (dobla todo lo que ganas, en cualquier sitio) y VIP
  (depósito de agua un 50% más grande y más rápido). El código de compra y
  comprobación de propiedad con `MarketplaceService` está completo, pero los
  `ProductId` están a 0 — un gamepass real **solo se puede crear desde el Creator
  Dashboard una vez publiques el lugar**, no hay id que pueda inventarme. En cuanto
  los crees, pégalos en `src/shared/Config/Gamepasses.luau` y el botón de comprar
  se activa solo.

### Dos bugs reales que encontré revisando antes de darlo por terminado

- Los contratos VIP calculaban su cuenta atrás con `os.clock()` en el servidor y
  se la mandaban tal cual al cliente — ese reloj no está sincronizado entre
  máquinas (cada una arranca su propio contador desde que se inicia el proceso),
  así que el tiempo restante habría salido sin sentido en el HUD. Cambiado a
  `os.time()` en todo `EventService.luau`, que sí es comparable entre servidor y
  cliente.
- Si un contrato VIP se completaba limpiándolo de verdad (no por agotarse el
  tiempo), nunca se volvía a llamar a `TargetService.reset()` — el objetivo se
  quedaba "limpio" para siempre y desaparecía del juego hasta reiniciar el
  servidor. Corregido en `EventService.resolve()`.

### Lo que sigue siendo una aproximación deliberada

- **El desprendido de la suciedad** sigue siendo dos piezas superpuestas, no el
  disolvido píxel a píxel con `EditableImage` del documento de diseño (sección 3.2).
- **Sin sonido todavía** (ni de disparo ni de eventos): sigue sin `SoundId` por el
  mismo motivo de siempre, no voy a inventar un asset que no sé si existe.
- Los contratos VIP eligen el objetivo al azar entre las 5 zonas sin tener en cuenta
  qué nivel tiene la población del servidor — un contrato podría salir en la Mansión
  con todo el mundo todavía en el Barrio. Es un ajuste de balance para cuando haya
  datos reales de juego, no algo que se pueda afinar a ciegas.
- Sin fusión de mascotas, sin rebirth/certificación, sin trading — quedan para la
  Fase 4 (documento de diseño).

## Estado

Fase 3 en curso: lanzamiento suave (5 zonas, mutaciones, contratos VIP, Mega
Suciedad, mascotas, gamepasses). Pendiente de probarse en Roblox Studio.
