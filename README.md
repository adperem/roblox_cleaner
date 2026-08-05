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

## Cómo probar el vertical slice (Fase 2)

El código está organizado como proyecto [Rojo](https://rojo.space/) — no se edita nada
dentro de Roblox Studio, solo se sincroniza lo que hay en `src/`.

1. Instala Rojo: la extensión de VS Code ("Rojo" de evaera) más el plugin de Studio
   desde su [página del plugin](https://create.roblox.com/store/asset/13916111004), o
   la CLI (`cargo install rojo` / `aftman install`).
2. Abre Roblox Studio con un lugar nuevo (cualquiera vale — si no tiene ya un suelo y
   un `SpawnLocation`, el propio juego crea uno mínimo al arrancar).
3. **Para que el guardado real funcione en Studio**: Game Settings → Security →
   activa "Enable Studio Access to API Services". Sin esto el juego funciona igual,
   pero avisa por consola y no persiste nada entre partidas (ver más abajo).
4. Desde este repo: `rojo serve` (o "Rojo: Start Server" en VS Code).
5. En Studio, abre el plugin de Rojo y pulsa "Connect".
6. Dale a Play. Apareces en el Barrio (Zona 1) con la mira fija en el centro de la
   pantalla: gira la cámara para apuntar y mantén pulsado el botón 💦 (o el clic
   izquierdo en PC) para disparar. El depósito de agua se agota si disparas sin
   parar — se rellena solo al soltar. Al subir de nivel se desbloquean el Lavadero
   (nivel 5) y el Parque infantil (nivel 12): viaja con el botón 🗺️. El botón 🛠️
   sube de boquilla y el 🎯 cobra las misiones diarias.

No he podido abrir Roblox Studio desde este entorno (no tiene GUI), así que esto no
está verificado jugando de verdad — solo la sintaxis está comprobada con
`luau-compile` y una parte del tipado con `luau-analyze` (sin las definiciones reales
de Roblox, así que da algo de ruido y un par de falsos positivos que ya investigué;
lo explico si te encuentras alguno raro en tu editor). Pruébalo en tu Studio y dime
qué falla.

### Qué hay nuevo en la Fase 2

- **3 zonas** (Barrio, Lavadero de coches, Parque infantil) desbloqueadas por nivel,
  cada una en su propio rincón del mapa, con teletransporte server-validado — un
  cliente modificado no puede pedir viajar a una zona que no ha desbloqueado.
- **Nivel y XP**: cada objetivo limpiado da experiencia además de dinero. La curva
  vive en `src/shared/Config/Levels.luau`.
- **Depósito de agua**: recurso nuevo que se gasta disparando y se rellena solo,
  gestionado igual que el resto — autoridad del servidor, el HUD solo lo muestra.
- **Misiones diarias** (3, se reinician cada día): progreso en vivo, cobro manual,
  dan dinero y XP.
- **Guardado real** con [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore)
  (vendorizado en `src/server/ThirdParty/`, ver `THIRD_PARTY_NOTICES.md`): dinero,
  XP, boquilla y progreso de misiones sobreviven a salir y volver a entrar, con
  bloqueo de sesión para que dos servidores no puedan pisarse el mismo perfil.
  Si el perfil no carga (típicamente Studio sin el ajuste del paso 3), la partida
  sigue funcionando solo con datos en memoria — se avisa por consola.

### Lo que sigue siendo una aproximación deliberada

- **El desprendido de la suciedad** sigue siendo dos piezas superpuestas (la sucia
  se vuelve transparente según `Progress`), no el disolvido píxel a píxel con
  `EditableImage` del documento de diseño (sección 3.2) — pasada de arte/tech aparte,
  pendiente de que el bucle esté validado.
- **Sin sonido de disparo todavía**: el `Sound` está montado pero sin `SoundId` — no
  voy a inventar un id de un asset que no sé si existe o si es tuyo. Corregí además
  una imprecisión de este README: en la Fase 1 decía que el pitch ya variaba por
  boquilla y no era cierto, no se había implementado.
- Sin mascotas, contratos VIP, mutaciones de suciedad ni rebirth todavía — fases
  posteriores del documento de diseño.
- El mapa desbloquea zonas por nivel, pero el "mapa/teletransporte" de las 9 zonas
  completas y su arte son cosa de fases posteriores; aquí solo hay 3, sin decorar
  más allá de una plataforma que marca cada punto de origen.

## Estado

Fase 2 en curso: vertical slice jugable (3 zonas, nivel/XP, depósito de agua,
misiones diarias, guardado real). Pendiente de probarse en Roblox Studio.
