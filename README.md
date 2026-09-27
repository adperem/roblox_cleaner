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

## Automatización: Claude programa, prueba y publica

📄 [`docs/AUTOMATIZACION.md`](docs/AUTOMATIZACION.md) — cómo funciona y los 4 pasos que
solo tú puedes hacer (una vez, unos 15 minutos).

Cada push pasa por GitHub Actions (`.github/workflows/roblox.yml`):

1. **Sin credenciales, siempre**: compila el lugar con Rojo, comprueba que los
   RemoteEvents son coherentes, analiza el código con los tipos de la API de Roblox
   (luau-lsp) y ejecuta las pruebas de configuración (`tests/`, con Lune).
2. **En un servidor real de Roblox** (con la API Luau Execution de Open Cloud): sube el
   lugar como versión guardada que los jugadores no ven, arranca el servidor completo y
   pasa todas las pruebas, incluidas las de `tests/Engine/`.
3. **Publica** esa misma compilación si todo pasa y es un push a `main` (o si se lanza a
   mano con la opción `publicar`).

Sin hacer nada, el paso 1 ya corre en cada push. Los pasos 2 y 3 se activan en cuanto
añades la API key y los dos ids en GitHub.

## Cómo probarlo a mano en Studio (opcional)

📄 [`docs/GUIA_INSTALACION.html`](docs/GUIA_INSTALACION.html) — guía paso a paso con el
mismo contenido que sigue, para abrir en el navegador o descargar.

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

No he podido abrir Roblox Studio desde este entorno (no tiene GUI), así que nada de
esto está verificado jugando de verdad. Lo que sí hice antes de darlo por cerrado,
sobre los 49 archivos del proyecto:

- Sintaxis de cada archivo comprobada con `luau-compile`.
- Cada `RemoteEvent` declarado en `Net.luau` tiene un sitio que lo dispara y un
  sitio que lo escucha (comprobado programáticamente, los 28).
- Cada atributo que el servidor escribe con `SetAttribute` tiene su lectura
  correspondiente en el cliente, y viceversa (mismo método).
- Un barrido de los 15 archivos de interfaz buscando el patrón exacto de un bug
  real que encontré (ver más abajo), para confirmar que no se repite en ningún
  otro sitio.
- Una relectura completa de los servicios más críticos (`PlayerDataService`,
  `EventService`, `TradeService`, `CleaningService`) buscando comentarios
  desactualizados o cabos sueltos entre fases — encontré y corregí dos comentarios
  que ya no describían el código (`TargetService` seguía diciendo "5 zonas",
  `TradeService` decía "sin fusión" después de haberla implementado).

Pruébalo en tu Studio y dime qué falla.

### Dos bugs que encontraron las comprobaciones nuevas

- **El menú no funcionaba en un servidor recién arrancado.** Los RemoteEvents se creaban
  en el servidor "la primera vez que alguien los pide", pero los que van de servidor a
  cliente solo se pedían al dispararse. El cliente los espera con `WaitForChild` al
  montar el HUD, así que se quedaba bloqueado en `MegaDirtStarted` (la primera Mega
  Suciedad llega a los 20 minutos): sin menú ☰, sin tienda y sin nada de lo que va
  detrás. Ahora `Net.createAll()` los crea todos al arrancar
  (`src/server/Boot.luau`). `scripts/check_remotes.py` y `tests/Engine/Boot.spec.luau`
  impiden que vuelva a pasar.
- **La cuenta atrás de la Mega Suciedad marcaba ~1.800 millones de segundos**: restaba
  `os.clock()` (tiempo desde que arrancó el cliente) a una hora Unix del servidor. Ahora
  usa `Workspace:GetServerTimeNow()`.

### Qué se completó en la pasada anterior

- **Fusión de mascotas** (documento de diseño, sección 5.4): 5 iguales dan una
  versión Dorada, 5 Doradas dan una Arcoíris (tope). Cada mascota se guarda con
  una clave que codifica el nivel de fusión (`duck`, `duck_Golden`,
  `duck_Rainbow`) — las que ya existían de antes de esta pasada no cambiaron de
  forma, así que no hace falta migrar nada. El comercio ya soporta mascotas
  fusionadas sin tocar `TradeService`: para él, la clave es solo una cadena más.
- Reparado un bug de posicionamiento que introduje yo mismo al principio de esta
  pasada: dos botones nuevos (fusionar, en `PetsPanel`) usaban una posición que
  mezclaba escala con un desplazamiento en píxeles calculado a mano asumiendo un
  ancho de fila fijo — que no está garantizado, porque el ancho real lo decide el
  contenedor (`ScrollingFrame`) donde vive la fila. Corregido a escala pura.

### Por qué no toqué el disolvido píxel a píxel (`EditableImage`)

Es la pieza que más veces he señalado como aproximación deliberada, así que antes
de cerrar esta pasada investigué en serio si podía completarla: `EditableImage`
tiene un error activo y documentado ahora mismo al aplicarse sobre un `Decal` vía
`Content.fromObject()` ("ContentId expected, got Content"), y el soporte en
`SurfaceAppearance` —la alternativa— se añadió a Studio hace apenas unos días.
Implementar esto a ciegas, sin poder abrir Studio para comprobarlo, sobre la
mecánica central del juego, justo antes de tu primera prueba real, es más riesgo
que "completitud": si la API falla o me equivoco en la firma de un método, cambio
un sistema que ya funciona (aunque simplificado) por uno roto. Me pareció la
decisión responsable, no la cómoda — te lo explico en vez de dejarlo caer en
silencio. El sistema actual (dos piezas superpuestas, transparencia dirigida por
`Progress`) se queda como está.

También busqué un asset de sonido de agua a presión integrado en Roblox y seguro
de usar: no encontré ninguno que pudiera verificar como gratuito o de tu
propiedad — solo assets de terceros en el Creator Store, que no voy a asumir que
puedes usar sin que tú los adquieras. Sigue siendo el único hueco que de verdad
depende de que añadas algo tú mismo.

### Un bug real que encontré revisando el menú (antes de esta pasada)

Al construir el menú con pestañas (necesario porque ya no cabían 9 botones sueltos
en pantalla), varios botones quedaron como hijos directos de contenedores con
`UIListLayout` (la fila de pestañas, el contenido de una pestaña, el selector de
mascota del comercio). El problema: todo botón de `Widgets.pillButton` añade su
sombra como un hermano en el mismo padre — si ese padre tiene `UIListLayout`, la
sombra cuela como un elemento más de la lista y descoloca todo lo que va detrás.
Lo comprobé programáticamente barriendo los archivos de UI en busca de este patrón
exacto y corregí los 3 sitios reales envolviendo cada botón en su propio `Frame`.

### Lo que queda fuera a propósito

- **El desprendido de la suciedad** sigue siendo dos piezas superpuestas — ver más
  arriba por qué no se tocó esta pasada.
- **Sin sonido**: el único hueco que depende de un asset que solo tú puedes aportar.
- Los contratos VIP siguen sin tener en cuenta el nivel de la población del
  servidor al elegir objetivo — ajuste de balance pendiente de datos reales de juego.
- El pase de temporada premia con dinero, no con cosméticos/mascotas exclusivas de
  temporada — eso es contenido nuevo que diseñar, no algo que se puede improvisar
  sin inventar assets.
- Sin cosméticos (no existen todavía, no los pide ninguna fase) ni arte real —
  todo sigue siendo cajas de colores.
- La cadencia de LiveOps semanal/mensual del documento de diseño no es un
  entregable de código, es un ritmo de contenido continuo — no aplica aquí.

## Estado

Las 4 fases del documento de diseño están implementadas (prototipo, vertical
slice, lanzamiento suave, escalado) más la fusión de mascotas. Es la primera vez
que el proyecto llega a un punto natural de parada: todo lo que quedaba pendiente
y era responsable completar sin poder probarlo en Studio está cerrado; lo que
sigue fuera (sonido, arte real, `EditableImage`) depende de assets que tú tienes
que aportar o de verificarlo primero en Studio.

Con el pipeline, el siguiente paso ya no es "ábrelo en Studio": son los 4 pasos
de [`docs/AUTOMATIZACION.md`](docs/AUTOMATIZACION.md). Hechos esos, cada cambio se
prueba dentro de un servidor real de Roblox y se publica sin que toques nada.
Las pruebas en la nube todavía no han corrido nunca, porque necesitan esa API key:
la primera ejecución es la que confirmará de verdad el arranque en Roblox.
