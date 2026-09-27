#!/usr/bin/env python3
"""Análisis estático del código Luau con luau-lsp y los tipos de la API de Roblox.

Muestra todos los avisos, pero solo hace fallar el pipeline con los que son
casi seguro un error real (que en Roblox explotaría en tiempo de ejecución):

- errores de sintaxis
- require a un módulo que no existe
- variable global desconocida (nombre mal escrito)
- propiedad o método que no existe en una clase de Roblox o en una tabla
  conocida (`part.Colour`, `task.wiat`, `Theme.Color.Primry`...)
- clase inexistente en Instance.new / tipo desconocido

El resto de TypeError del verificador de tipos se muestran como aviso sin
bloquear: esta versión de luau-lsp da falsos positivos con tablas de tipos
literales (p. ej. iterar un `{ PetTier }` y pasar cada elemento a una
función que espera `PetTier`).

Requiere haber ejecutado antes scripts/install-tools.sh y `rojo sourcemap`
(scripts/check.sh hace las dos cosas).
"""

import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.environ.get("TOOLS_DIR", os.path.join(ROOT, ".tools"))

HEADER = re.compile(r"^(?P<file>[^\s(\[]+)(?: \[[^\]]*\])?\s?\((?P<line>\d+),(?P<col>\d+)\): (?P<kind>\w+): (?P<msg>.*)$")

BLOCKING = [
    ("SyntaxError", None),
    ("TypeError", re.compile(r"^Unknown require")),
    ("TypeError", re.compile(r"^Unknown global")),
    ("TypeError", re.compile(r"^Key '[^']+' not found in")),
    ("TypeError", re.compile(r"^Invalid class name")),
    ("TypeError", re.compile(r"^Unknown type")),
    ("UnknownGlobal", None),
    ("UnknownType", None),
]


def is_blocking(kind, msg):
    return any(kind == k and (pattern is None or pattern.search(msg)) for k, pattern in BLOCKING)


def run_luau_lsp():
    command = [
        os.path.join(TOOLS, "bin", "luau-lsp"),
        "analyze",
        "--platform=roblox",
        f"--sourcemap={os.path.join(ROOT, 'build', 'sourcemap.json')}",
        f"--definitions=@roblox={os.path.join(TOOLS, 'globalTypes.d.luau')}",
        "--ignore=**/ThirdParty/**",
        "src",
        "tests",
    ]
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
    return result.returncode, result.stdout + result.stderr


def parse(output):
    diagnostics = []
    current = None
    for raw in output.splitlines():
        if raw.startswith("[INFO]") or raw.startswith("[WARN]"):
            continue
        match = HEADER.match(raw)
        if match:
            current = match.groupdict()
            current["file"] = os.path.relpath(current["file"], ROOT) if os.path.isabs(current["file"]) else current["file"]
            diagnostics.append(current)
        elif current is not None and raw.strip():
            current["msg"] += " " + raw.strip()

    unique = {}
    for d in diagnostics:
        unique[(d["file"], d["line"], d["col"], d["kind"], d["msg"])] = d
    return sorted(unique.values(), key=lambda d: (d["file"], int(d["line"]), int(d["col"])))


def annotate(level, d):
    if os.environ.get("GITHUB_ACTIONS") == "true":
        message = f"{d['kind']}: {d['msg']}".replace("%", "%25").replace("\r", "").replace("\n", "%0A")
        print(f"::{level} file={d['file']},line={d['line']},col={d['col']}::{message}")


def main():
    returncode, output = run_luau_lsp()
    diagnostics = parse(output)
    if returncode not in (0, 1) or (returncode == 1 and not diagnostics):
        print(output)
        print(f"✗ luau-lsp terminó con código {returncode} sin diagnósticos que leer")
        return 1

    blocking = [d for d in diagnostics if is_blocking(d["kind"], d["msg"])]
    warnings = [d for d in diagnostics if d not in blocking]

    for d in warnings:
        print(f"  aviso  {d['file']}:{d['line']}:{d['col']} {d['kind']}: {d['msg']}")
        annotate("warning", d)
    for d in blocking:
        print(f"✗ ERROR  {d['file']}:{d['line']}:{d['col']} {d['kind']}: {d['msg']}")
        annotate("error", d)

    print(f"\nAnálisis: {len(blocking)} errores que bloquean, {len(warnings)} avisos informativos")
    return 1 if blocking else 0


if __name__ == "__main__":
    sys.exit(main())
