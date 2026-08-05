# PRESSURE WASH TYCOON — Documento de Diseño

> Juego de limpieza con agua a presión para Roblox, diseñado para maximizar jugadores
> concurrentes (CCU) y retención D1/D7 bajo el algoritmo de descubrimiento de 2026.

---

## 0. Resumen ejecutivo

**Nombre de trabajo:** `Pressure Wash Tycoon`
**Título en Roblox (SEO, keyword-first):**
`💦 Pressure Wash Simulator — Clean & Steal Jobs! [UPDATE]`

**Pitch (una frase):**
Limpias superficies asquerosas con una hidrolimpiadora, la suciedad se desprende de
verdad ante tus ojos, cobras, mejoras tu equipo y montas tu propia empresa de limpieza
mientras compites con el servidor por los contratos más jugosos.

**Por qué este juego y no un clon más:**

| Competidor | Qué hace bien | Qué le falta |
|---|---|---|
| Pressure Wash Simulator (140M+ visitas) | Feedback de limpieza satisfactorio | Casi cero capa social, progresión plana |
| Pressure Wash Simulator 2 | Tycoon + coches | Bucle largo, arranque lento |
| Concrete Cleaning Simulator | Empresa propia | Poca variedad visual, sin economía viva |

Nuestro diferencial son **tres capas apiladas** que ninguno tiene junto:
1. **ASMR / satisfacción** (el core, clipeable para TikTok → tráfico externo).
2. **Competencia social sana** (contratos VIP disputados, co-op con bonus, jefe de servidor).
3. **Economía viva** (mutaciones de suciedad, mascotas, temporadas, trading limitado)
   → el jugador vuelve cada día porque *su progreso rinde estando fuera* y porque
   *hay algo nuevo esta semana*.

**Público objetivo:** 8–16 años, ~75% móvil, sesiones de 12–25 min.
**Plataformas:** Móvil primero, PC y consola compatibles desde el día 1.

---

## 1. Los primeros 3 minutos (lo más importante del documento)

El algoritmo de Roblox mide retención a 28 días, pero un jugador que se aburre en el
minuto 1 nunca genera ninguno de esos días. Guion cronometrado del FTUE:

| Tiempo | Qué pasa |
|---|---|
| 0:00 | Spawn **con la hidrolimpiadora ya en la mano**. Sin menú, sin cinemática, sin diálogo. |
| 0:03 | A 4 metros hay un cubo de basura repugnante con un icono `!` flotando y una flecha guía. |
| 0:05 | Primer disparo de agua. Partículas, sonido, la suciedad desaparece por píxeles. |
| 0:15 | Cubo limpio al 100% → confeti, `+$50`, sonido de caja registradora, barra de nivel sube. |
| 0:25 | Se abre solo el panel de **Mejoras**, con la boquilla Tier 2 ya asequible. Comprar es un botón grande y verde. |
| 0:35 | Nueva boquilla equipada: el chorro es visiblemente más ancho y más rápido. **El jugador siente el poder.** |
| 0:45 | Se destaca el primer coche sucio (paga `$400`). Objetivo claro y más grande. |
| 1:30 | Coche limpio → sube de nivel → **desbloqueo de Zona 2** con teleport. |
| 2:00 | Aparece el primer **Contrato VIP** en el servidor con aviso global: “🚨 Limusina embarrada en la Zona 1 — ¡el primero que la limpie se la queda!”. Primera interacción social. |
| 2:30 | Primer **huevo de mascota** gratis. Sale un Patito de Goma que limpia solo un poquito. Enganche de colección. |
| 3:00 | Panel de **misiones diarias** + recompensa de login día 1. Motivo para volver mañana. |

Reglas duras del FTUE:
- **Nunca** hay una pantalla que bloquee al jugador antes de su primer disparo de agua.
- Cada recompensa se ve, se oye y hace vibrar (`HapticService` en móvil).
- Todo texto del tutorial cabe en una línea. Nada de párrafos.

---

## 2. Bucle de juego

### 2.1 Bucle central (15–60 segundos)

```
Elegir superficie sucia → apuntar y limpiar → barra de progreso llena
        → cobrar $ + XP → mejorar equipo → superficie más grande y más rentable
```

### 2.2 Bucle medio (10–25 minutos, una sesión)

```
Subir de nivel → desbloquear zona → mejorar camioneta y base
        → contratar empleado NPC → abrir huevos → completar misiones diarias
```

### 2.3 Bucle largo (días / semanas)

```
Terminar zona → Certificación (rebirth) → multiplicador permanente
        → boquillas de prestigio → índice de coleccionables → temporada / pase de batalla
```

### 2.4 Bucle offline (retención D1)

Los **empleados NPC** de tu base siguen limpiando mientras no estás y acumulan dinero
en la caja fuerte, con tope de 8 h (12 h con VIP). Al volver:
`“Tus 4 empleados ganaron $12.400 mientras dormías”` con animación de monedas.
Esto es lo que convierte a un jugador de una sesión en un jugador de siete días.

---

## 3. Mecánica de limpieza (el corazón del juego)

### 3.1 Sensación

- El agua sale como cono de partículas con **impacto visible**: salpicaduras en el
  punto de contacto, niebla, gotas que caen, decal de humedad temporal.
- La suciedad **no cambia de textura por etapas**: se borra píxel a píxel siguiendo
  el chorro. Esto es lo que hace el juego clipeable y lo que la competencia hace peor.
- Retroceso suave de cámara, sonido en bucle con pitch según la presión, vibración.
- Al llegar al 100%: destello, sonido de “sparkle”, la superficie queda con reflejo.

### 3.2 Implementación técnica

**Opción principal — máscara de suciedad con `EditableImage`:**
cada superficie limpiable tiene una textura de suciedad y una máscara alfa editable.
El cliente pinta en la máscara donde impacta el rayo; el servidor solo recibe
“porcentaje limpiado” cada 0,25 s y valida el ritmo máximo posible según el equipo.

**Fallback — rejilla de tiles:** superficies subdivididas en cuadrículas de
`SurfaceGui` con celdas que se desvanecen. Más barato, se usa en móviles de gama baja
y como sistema de respaldo si `EditableImage` se degrada.

**Presupuesto de rendimiento (móvil de gama baja):**
- máximo 6 superficies activas por jugador, 60 partículas por chorro,
- máscaras de 256×256, streaming de instancias activado,
- objetivo: 30 FPS estables en un dispositivo de 2019.

### 3.3 Anti-exploit

El servidor es la autoridad: calcula `limpieza_máxima_por_segundo` a partir del
equipo real del jugador. Si el cliente reporta más, se recorta y se registra. Tres
avisos → kick silencioso. El dinero **nunca** lo calcula el cliente.

---

## 4. Progresión

### 4.1 Zonas (contenido principal)

| # | Zona | Desbloqueo | Pago base | Gancho visual |
|---|---|---|---|---|
| 1 | Barrio | Inicio | $50 | Cubos, bancos, aceras |
| 2 | Lavadero de coches | Nivel 5 | $400 | Coches, motos |
| 3 | Parque infantil | Nivel 12 | $1.2K | Toboganes, chicle pegado |
| 4 | Gasolinera | Nivel 20 | $4K | Manchas de aceite, camiones |
| 5 | Mansión | Nivel 30 | $15K | Piscina, estatuas, fachada enorme |
| 6 | Puerto | Nivel 42 | $60K | Barcos con percebes y algas |
| 7 | Obra | Nivel 55 | $250K | Excavadoras cubiertas de cemento |
| 8 | Aeropuerto | Nivel 70 | $1M | Jet privado, pista |
| 9 | Estación espacial | Nivel 90 | $10M | Polvo lunar, cero gravedad |

Cada zona añade **una mecánica nueva**, no solo números más grandes:
plataformas elevadas (Z5), limpieza bajo el agua (Z6), grúa para llegar alto (Z7),
tiempo limitado por “vuelo que despega” (Z8), chorro con retroceso sin gravedad (Z9).

### 4.2 Equipo

- **Boquillas** (12 tiers): potencia ×1,6 y precio ×3 por tier. Cambian de modelo y color.
- **Manguera** (alcance), **bomba** (presión), **depósito** (autonomía), **guantes** (velocidad de movimiento).
- **Camioneta**: cosmética + capacidad de contratos simultáneos.

### 4.3 Certificación (rebirth)

Requisito: completar la zona actual + `$X`. Reinicia dinero y equipo, conserva
mascotas y cosméticos. Da **+25% de ganancias acumulativo**, un rango visible en la
tabla y acceso a boquillas de prestigio con VFX exclusivos. Rangos: Aprendiz →
Profesional → Experto → Maestro → Leyenda → Mito.

---

## 5. Economía viva (lo que hace que vuelvan)

### 5.1 Mutaciones de suciedad

Cada superficie puede generarse con una mutación que multiplica el pago:

| Mutación | Multiplicador | Probabilidad |
|---|---|---|
| Barro | ×1 | 60% |
| Grasa | ×2 | 20% |
| Moho | ×3 | 10% |
| Chicle | ×4 | 6% |
| Alquitrán | ×6 | 3% |
| Slime radiactivo | ×10 | 0,9% |
| **Suciedad dorada** | **×25** | **0,1%** |

Al aparecer una mutación rara se anuncia **a todo el servidor** con sonido y banner.
Esto alarga sesiones (“una más y lo dejo”), crea conversación y genera clips.

### 5.2 Contratos VIP (competencia sana)

Cada 4 minutos aparece un contrato VIP con aviso global. Todos los jugadores del
servidor pueden ir. El pago se reparte **según el porcentaje que limpió cada uno**, con
un bonus del 20% para quien llegue al 100%. Competencia sin robar progreso ajeno:
nadie pierde nada, pero todos corren. (Sin PvP tóxico, que destruye la retención.)

### 5.3 Jefe de servidor: la Mega Suciedad

Cada 20 minutos aparece un edificio gigantesco cubierto de porquería que **necesita a
todo el servidor** para limpiarse en 5 minutos. Barra de progreso compartida y
recompensa escalada por contribución. Es el mecanismo de co-play que el algoritmo
premia por encima de casi todo.

### 5.4 Mascotas / Ayudantes

Huevos por zona (100, 5K, 250K…), rarezas Común → Secreto. Cada ayudante limpia
automáticamente a tu lado y da multiplicador. Fusión de 5 iguales → versión Dorada,
de 5 doradas → Arcoíris. Índice coleccionable con recompensa por completarlo.

### 5.5 Trading limitado

Solo mascotas y cosméticos, nunca dinero. Interfaz con confirmación doble y bloqueo
de 3 s antes de aceptar. Es el motor de la economía de largo plazo (modelo Adopt Me).

---

## 6. Retención y LiveOps

- **Login diario:** 7 días de escalera, día 7 = mascota exclusiva del mes.
- **Misiones diarias (3) y semanales (5):** dan fichas del pase de batalla.
- **Pase de temporada:** 30 niveles gratis + 30 premium (799 Robux), 6 semanas.
- **Códigos:** se publican en el grupo de Roblox y en el Discord con cada actualización.
- **Recompensas sociales:** unirse al grupo, dar like, favorito → mascota o dinero.
- **Calendario LiveOps:** actualización pequeña **cada semana** (mutación nueva,
  mascota, cosmético) y evento grande cada mes (mapa temático: Halloween, Navidad,
  verano en la playa, colaboración meme del momento).

Nada de esto es opcional: en 2026 un juego estático pierde su puesto en las listas.

---

## 7. Monetización

| Producto | Precio orientativo | Tipo |
|---|---|---|
| Dinero ×2 | 399 R$ | Gamepass |
| Auto-limpieza (dron) | 599 R$ | Gamepass |
| VIP (chat, aura, +2 mascotas, +50%) | 999 R$ | Gamepass |
| Suerte ×2 (mutaciones y huevos) | 699 R$ | Gamepass |
| Boquilla infinita (sin recarga) | 349 R$ | Gamepass |
| Packs de dinero | 49–999 R$ | Producto |
| Pase de temporada premium | 799 R$ | Producto |
| Ayudante limitado del mes | 499 R$ | Producto (FOMO) |

Reglas: **nada bloquea el progreso**. Todo lo comprable se puede conseguir jugando,
solo que más lento. Un juego que se siente pay-to-win destruye la retención y con ella
la posición en el algoritmo. Se suma Premium Payouts y UGC limitados como reclamo.

---

## 8. Estrategia de descubrimiento (cómo se llenan los servidores)

1. **Icono:** una cara asombrada + un antes/después partido por la mitad, saturado,
   legible a 150 px. Se testean 3 variantes por A/B.
2. **Miniaturas:** la 1ª es el antes/después más espectacular; las siguientes muestran
   mascotas, la Mega Suciedad y los códigos activos.
3. **Título:** palabras clave por las que la gente busca de verdad
   (*pressure wash, cleaning, simulator*) + gancho + `[UPDATE]` en cada parche.
4. **Velocidad de CCU:** los lanzamientos de actualización se concentran en viernes por
   la tarde para que el pico sea vertical (el sort de Trending mide velocidad, no volumen).
5. **Tráfico externo:** cada actualización sale con 3 clips verticales de 15 s de
   limpieza satisfactoria para TikTok/Shorts. El core del juego está diseñado para eso.
6. **Co-play:** botón de “invitar amigos” con recompensa para ambos; el algoritmo
   pondera fuertemente que la gente traiga a sus amigos.

**KPIs objetivo:** D1 ≥ 30%, D7 ≥ 12%, sesión media ≥ 14 min, ≥ 1,4 sesiones/día.

---

## 9. Arquitectura técnica (para la fase de implementación)

```
src/
  server/     Servicios: Economy, Cleaning, Contracts, Pets, Data, AntiExploit, LiveOps
  client/     Controladores: Input, Spray, UI, Camera, Effects, Sound
  shared/     Config del juego (zonas, boquillas, mutaciones, precios), tipos, red
```

- **Rojo + Luau con tipado estricto**, VS Code, no editar dentro de Studio.
- **Datos:** ProfileStore (sesión bloqueada, a prueba de duplicación), autoguardado
  cada 60 s y al salir.
- **Red:** RemoteEvents con limitación de frecuencia por jugador; el cliente nunca
  manda dinero, solo intención.
- **Rendimiento:** StreamingEnabled, LOD de partículas, máscaras compartidas por tipo
  de superficie, pool de instancias.
- **UI:** todo en escala (`UDim2.fromScale`), zonas táctiles ≥ 44 px, respeto de la
  zona segura, probado en 16:9, 20:9 y tablet.

---

## 10. Plan por fases

| Fase | Contenido | Objetivo |
|---|---|---|
| **1. Prototipo** | Mecánica de limpieza + 1 zona + dinero + 3 boquillas | Que limpiar sea divertido sin nada más |
| **2. Vertical slice** | 3 zonas, HUD completo, mejoras, guardado, misiones diarias | Test cerrado, medir D1 |
| **3. Lanzamiento suave** | 5 zonas, mascotas, contratos VIP, Mega Suciedad, gamepasses | Abrir al público, iterar con datos |
| **4. Escalado** | Zonas 6–9, rebirth, pase de temporada, trading, eventos | Empujar CCU y posición en listas |

---

## 11. Riesgos

| Riesgo | Mitigación |
|---|---|
| `EditableImage` pesado en móvil | Sistema de tiles como fallback automático por FPS |
| Género saturado | Diferencial social + economía viva, no otro clon en solitario |
| Fatiga tras el rebirth | Cada certificación desbloquea contenido *nuevo*, no solo números |
| Explotadores de dinero | Autoridad total del servidor + validación de ritmo |
| Contratos VIP percibidos como injustos | Pago proporcional a lo limpiado: nadie se va con las manos vacías |
