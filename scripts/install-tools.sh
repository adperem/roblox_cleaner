#!/usr/bin/env bash
# Descarga en .tools/ las versiones exactas de las herramientas del pipeline
# (Linux x86_64, que es lo que usan GitHub Actions y los entornos de Claude).
# Si ya están esas mismas versiones, no hace nada.
set -euo pipefail

ROJO_VERSION=7.7.0
LUAU_LSP_VERSION=1.70.0
LUNE_VERSION=0.10.5

DIR="${TOOLS_DIR:-$(cd "$(dirname "$0")/.." && pwd)/.tools}"
STAMP="rojo=$ROJO_VERSION luau-lsp=$LUAU_LSP_VERSION lune=$LUNE_VERSION"

if [[ -f "$DIR/versions" && "$(cat "$DIR/versions")" == "$STAMP" ]]; then
	echo "Herramientas ya instaladas ($STAMP)"
	exit 0
fi

rm -rf "$DIR"
mkdir -p "$DIR/bin"

fetch_zip() {
	curl -fsSL --retry 4 -o "$DIR/download.zip" "$1"
	unzip -o -q "$DIR/download.zip" -d "$DIR/bin"
	rm "$DIR/download.zip"
}

fetch_zip "https://github.com/rojo-rbx/rojo/releases/download/v$ROJO_VERSION/rojo-$ROJO_VERSION-linux-x86_64.zip"
fetch_zip "https://github.com/JohnnyMorganz/luau-lsp/releases/download/$LUAU_LSP_VERSION/luau-lsp-linux-x86_64.zip"
fetch_zip "https://github.com/lune-org/lune/releases/download/v$LUNE_VERSION/lune-$LUNE_VERSION-linux-x86_64.zip"
# Tipos de la API de Roblox, fijados a la misma versión de luau-lsp.
curl -fsSL --retry 4 -o "$DIR/globalTypes.d.luau" \
	"https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/$LUAU_LSP_VERSION/scripts/globalTypes.None.d.luau"

chmod +x "$DIR/bin/"*
echo "$STAMP" > "$DIR/versions"
echo "Herramientas instaladas en $DIR ($STAMP)"
