#!/usr/bin/env python3
"""Comprueba que los RemoteEvents del juego son coherentes (sin credenciales).

- El tipo `EventName` y la lista `Net.EventNames` de src/shared/Net.luau
  tienen exactamente los mismos nombres y la lista no repite ninguno. Así
  `Net.createAll()` crea al arrancar todos los que el código puede pedir.
- Cada nombre que se usa en `getRemoteEvent("...")` está declarado.
- Cada evento declarado se usa en el servidor Y en el cliente (si solo lo
  usa un lado, nadie lo dispara o nadie lo escucha).
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
NET = ROOT / "src" / "shared" / "Net.luau"
USE = re.compile(r'getRemoteEvent\(\s*"(\w+)"\s*\)')


def names_in(block):
    return re.findall(r'"(\w+)"', block)


def main():
    source = NET.read_text(encoding="utf-8")
    type_block = re.search(r"export type EventName =(.*?)\n\n", source, re.S)
    list_block = re.search(r"Net\.EventNames = \{(.*?)\}", source, re.S)
    if not type_block or not list_block:
        print("✗ No encuentro `export type EventName` o `Net.EventNames` en Net.luau")
        return 1

    typed = names_in(type_block.group(1))
    listed = names_in(list_block.group(1))
    errors = []

    duplicates = sorted({n for n in listed if listed.count(n) > 1})
    if duplicates:
        errors.append(f"Net.EventNames repite: {', '.join(duplicates)}")
    if set(typed) != set(listed):
        only_type = sorted(set(typed) - set(listed))
        only_list = sorted(set(listed) - set(typed))
        if only_type:
            errors.append(f"En EventName pero no en Net.EventNames (no se crearían al arrancar): {', '.join(only_type)}")
        if only_list:
            errors.append(f"En Net.EventNames pero no en EventName: {', '.join(only_list)}")

    used = {"server": set(), "client": set()}
    for side in used:
        for path in (ROOT / "src" / side).rglob("*.luau"):
            for name in USE.findall(path.read_text(encoding="utf-8")):
                used[side].add(name)
                if name not in listed:
                    errors.append(f'{path.relative_to(ROOT)} usa "{name}", que no está declarado en Net.luau')

    for name in listed:
        missing = [side for side in ("server", "client") if name not in used[side]]
        if missing:
            errors.append(f'"{name}" no se usa en: {", ".join(missing)} (nadie lo dispara o nadie lo escucha)')

    if errors:
        for error in errors:
            print(f"✗ {error}")
        return 1
    print(f"✓ {len(listed)} RemoteEvents: declarados, creados al arrancar y usados en servidor y cliente")
    return 0


if __name__ == "__main__":
    sys.exit(main())
