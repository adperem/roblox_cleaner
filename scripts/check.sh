#!/usr/bin/env bash
# Todas las comprobaciones que no necesitan credenciales de Roblox: compila
# el lugar, revisa los RemoteEvents, analiza el código y ejecuta las pruebas
# que no necesitan el motor. Deja el lugar listo en build/game.rbxl.
set -euo pipefail
cd "$(dirname "$0")/.."

scripts/install-tools.sh
BIN=.tools/bin
mkdir -p build

echo "── Compilando con Rojo"
$BIN/rojo build default.project.json -o build/game.rbxl
$BIN/rojo sourcemap default.project.json -o build/sourcemap.json

echo "── RemoteEvents"
python3 scripts/check_remotes.py

echo "── Análisis estático (luau-lsp + API de Roblox)"
python3 scripts/analyze.py

echo "── Pruebas sin motor (Lune)"
$BIN/lune run scripts/lune/run-tests.luau build/game.rbxl
