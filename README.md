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

## Cómo probar el prototipo (Fase 1)

El código está organizado como proyecto [Rojo](https://rojo.space/) — no se edita nada
dentro de Roblox Studio, solo se sincroniza lo que hay en `src/`.

1. Instala Rojo: la extensión de VS Code ("Rojo" de evaera) más el plugin de Studio
   desde su [página del plugin](https://create.roblox.com/store/asset/13916111004), o
   la CLI (`cargo install rojo` / `aftman install`).
2. Abre Roblox Studio con un lugar nuevo (cualquiera vale — si no tiene ya un suelo y
   un `SpawnLocation`, el propio juego crea uno mínimo al arrancar).
3. Desde este repo: `rojo serve` (o "Rojo: Start Server" en VS Code).
4. En Studio, abre el plugin de Rojo y pulsa "Connect".
5. Dale a Play. Apareces con la mira fija en el centro de la pantalla: gira la cámara
   para apuntar y mantén pulsado el botón 💦 (o el clic izquierdo en PC) para
   disparar agua sobre los 4 objetivos sucios de la Zona 1. Cada uno se paga al
   llegar al 100% y se vuelve a ensuciar a los pocos segundos. El dinero se puede
   gastar en el panel "🛠️ Mejoras" para subir de boquilla.

No he podido abrir Roblox Studio desde este entorno (no tiene GUI), así que esto no
está verificado jugando de verdad — solo la sintaxis y el tipado están comprobados
con `luau-analyze`/`luau-compile`. Pruébalo en tu Studio y dime qué falla.

### Qué hace ya y qué no (alcance real de la Fase 1)

- **La limpieza es 100% autoridad del servidor**: el cliente solo manda "estoy
  apuntando a este objetivo, sí/no"; el servidor calcula el progreso con la boquilla
  que él mismo tiene registrada para ese jugador y con su propio reloj. El dinero
  nunca lo toca el cliente.
- **El desprendido de la suciedad es una aproximación**, no el disolvido píxel a
  píxel con `EditableImage` que describe el documento de diseño (sección 3.2): cada
  objetivo son dos piezas superpuestas y la de encima (sucia) se vuelve transparente
  según el `Progress` del servidor. Se ve y se siente bien para validar si la
  mecánica engancha, pero la textura real de suciedad desprendiéndose es una pasada
  de arte/tech aparte, más cara, para cuando ya sepamos que el bucle es divertido.
- **Sin sonido de disparo todavía**: el `Sound` está montado y con el pitch listo
  para variar por boquilla, pero sin `SoundId` — no voy a inventar un id de un
  asset que no sé si existe o si es tuyo. Es la única pieza que falta para que
  suene: pega un `rbxassetid://` en `EffectsController.luau`.
- **Sin persistencia**: el dinero vive en memoria y se pierde al salir. Llega en la
  Fase 2 con guardado real (`ProfileStore`).
- Es una sola zona con 4 objetivos y 3 boquillas, tal como pide la Fase 1 del
  documento de diseño — sin mascotas, contratos VIP, mutaciones ni rebirth todavía;
  esas son fases posteriores.

## Estado

Fase 1 en curso: prototipo jugable de la mecánica de limpieza (1 zona, 4 objetivos,
3 boquillas, dinero, tienda). Pendiente de probarse en Roblox Studio.
