# Automatización: Claude programa, prueba y publica; tú no tocas nada

## Cómo funciona

Todo el juego es texto en este repositorio (proyecto [Rojo](https://rojo.space/)).
Claude escribe el código y hace push. A partir de ahí, GitHub Actions
(`.github/workflows/roblox.yml`) hace solo:

```
push ──► 1. Compilar y revisar          (siempre, sin credenciales)
         │   · rojo build → build/game.rbxl
         │   · RemoteEvents coherentes     (scripts/check_remotes.py)
         │   · análisis con la API de Roblox (scripts/analyze.py)
         │   · pruebas de configuración     (tests/, con Lune)
         ▼
         2. Probar en Roblox de verdad   (si configuraste el acceso)
         │   · sube el lugar como versión GUARDADA: los jugadores no la ven
         │   · arranca el servidor completo dentro de un servidor real de
         │     Roblox (API Luau Execution de Open Cloud) y pasa todas las
         │     pruebas, incluidas tests/Engine/
         ▼
         3. Publicar                      (push a main, o lanzado a mano)
             · sube esa misma compilación como versión PUBLICADA
```

Si algo falla, el pipeline se para antes de publicar y el error queda en
los logs de GitHub Actions, que Claude puede leer y corregir en la
siguiente sesión sin que tú copies nada.

## Lo que solo tú puedes hacer (una vez, unos 15 minutos)

Roblox no tiene API para estos pasos: están atados a tu cuenta.

### 1. Crear la experiencia (la única vez que se abre Studio)

Crear una experiencia nueva solo se puede desde Roblox Studio:

1. Abre Roblox Studio → plantilla **Baseplate**.
2. **File → Publish to Roblox** → pon un nombre (p. ej. "Pressure Wash
   Tycoon") → **Create**.
3. Cierra Studio. No hace falta volver a abrirlo: cada publicación
   posterior sustituye el lugar entero por lo que hay en este repo.

### 2. Copiar los dos ids

En el [Creator Dashboard](https://create.roblox.com/dashboard/creations):

- **Universe ID**: pasa el ratón por la miniatura de la experiencia → **⋯**
  → **Copy Universe ID**.
- **Place ID**: entra en la experiencia → pestaña **Places** → pulsa el
  lugar. Es el número de la URL:
  `.../experiences/<universe>/places/`**`<place id>`**`/configure`.

### 3. Crear la API key

En [Creator Dashboard → API Keys](https://create.roblox.com/dashboard/credentials?activeTab=ApiKeysTab)
→ **Create API Key**:

- **Name**: `github-actions`.
- **Access Permissions** → **Select API System**, añade dos:
  - `universe-places` → tu experiencia → operación **Write**.
  - `universe.place.luau-execution-session` → tu experiencia → **Write**
    (y **Read** si te lo ofrece).
- **Security**: deja **Restrict IP addresses** desactivado. GitHub Actions
  cambia de IP en cada ejecución.
- Sin fecha de caducidad (o una larga: cuando caduque, el pipeline avisa).
- **Save & Generate key** y copia la clave. Trátala como una contraseña.

### 4. Dárselo a GitHub

En GitHub: **Settings → Secrets and variables → Actions**.

| Pestaña       | Nombre               | Valor                     |
| ------------- | -------------------- | ------------------------- |
| **Secrets**   | `ROBLOX_API_KEY`     | la clave del paso 3       |
| **Variables** | `ROBLOX_UNIVERSE_ID` | el Universe ID del paso 2 |
| **Variables** | `ROBLOX_PLACE_ID`    | el Place ID del paso 2    |

La clave va solo ahí: no la pegues en el chat ni en ningún archivo del
repo. GitHub la oculta incluso en los logs.

Listo. El siguiente push ya prueba en Roblox, y el siguiente push a `main`
publica.

## Publicar

- **Automático**: cada push a `main` que pase todas las pruebas se publica.
- **Desde cualquier rama**: pide a Claude "publícalo". Lanza el workflow
  a mano con la opción `publicar` (o hazlo tú desde la pestaña **Actions** →
  **Roblox** → **Run workflow**).

## Para abrirlo al público (cuando quieras, también una vez)

Una experiencia nueva es **privada**: solo tú puedes entrar. Para que entre
cualquiera, Roblox exige pasos de identidad que nadie puede hacer por ti
([requisitos oficiales](https://create.roblox.com/docs/production/publishing/publish-games-and-places#make-game-public)):

- Una comprobación de edad de tu cuenta (estimación facial o documento de
  identidad).
- El cuestionario de **madurez y cumplimiento** de la experiencia.
- En la experiencia: **Configure → Settings → Audience → Public**.

Para llegar también a menores de 16 hay requisitos extra (2FA, Premium o
una tasa reembolsable de 1.000 Robux, y una evaluación).

## Opcional: un lugar aparte para las pruebas

Por defecto, las pruebas suben versiones *guardadas* (no publicadas) a la
misma experiencia. Los jugadores no las ven, pero si abrieras la
experiencia en Studio verías la última versión guardada, no la publicada. Si
lo prefieres separado, crea una segunda experiencia (paso 1), dale permisos
también en la API key y añade las variables `ROBLOX_TEST_UNIVERSE_ID` y
`ROBLOX_TEST_PLACE_ID`.

## Límites (lo que esto no cubre)

- **Nadie juega de verdad**: las pruebas en Roblox arrancan el servidor
  completo, pero sin jugadores, sin física y sin interfaz. Detectan errores
  de arranque, de datos y de API, no si el juego es divertido o si un botón
  queda descolocado. Para eso hace falta entrar a jugar (con la experiencia
  privada puedes probarla tú antes de abrirla al público).
- **Assets**: sonidos, modelos e imágenes propios hay que subirlos con tu
  cuenta (la API de Assets de Open Cloud permite automatizarlo más adelante
  con otra API key).
- **Gamepasses**: siguen con `ProductId = 0`. Se pueden crear desde el
  Creator Dashboard, o automatizarlo con la API de Game Passes de Open Cloud
  (permiso `game-pass:write`).

## Hacerlo en local

```sh
scripts/check.sh                                  # paso 1 completo
ROBLOX_API_KEY=... ROBLOX_UNIVERSE_ID=... ROBLOX_PLACE_ID=... \
  python3 scripts/roblox_cloud.py test build/game.rbxl   # paso 2
```

`scripts/install-tools.sh` (lo llama `check.sh`) descarga en `.tools/` las
versiones fijadas de Rojo, luau-lsp y Lune.
