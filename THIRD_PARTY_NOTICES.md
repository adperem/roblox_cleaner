# Software de terceros

## ProfileStore

- Ruta: `src/server/ThirdParty/ProfileStore.luau`
- Fuente: https://github.com/MadStudioRoblox/ProfileStore
- Autor: Mad Studio (loleris)
- Licencia: Apache License 2.0 (`LICENSE-ProfileStore.txt`, en la raíz del repo —
  fuera de `src/` a propósito, para que Rojo no la sincronice como instancia).
- Sin modificar respecto al original.

Solución de guardado periódico en DataStore con bloqueo de sesión (evita que
dos servidores escriban el mismo perfil a la vez y produzcan una duplicación).
El documento de diseño (`docs/DISENO_JUEGO.md`, sección "Arquitectura técnica")
la nombra explícitamente como la solución de datos del proyecto.
