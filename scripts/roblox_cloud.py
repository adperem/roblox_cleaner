#!/usr/bin/env python3
"""Cliente mínimo de Roblox Open Cloud para el pipeline (solo librería estándar).

Comandos:
  test    <place.rbxl>  Sube el lugar como versión *guardada* (los jugadores no
                        la ven), ejecuta scripts/cloud/run-tests.luau dentro de
                        un servidor real de Roblox con esa versión y falla si
                        alguna prueba falla.
  publish <place.rbxl>  Sube el lugar como versión *publicada*: los servidores
                        nuevos arrancan con ella.

Variables de entorno:
  ROBLOX_API_KEY           API key de Open Cloud (secreto de GitHub).
  ROBLOX_UNIVERSE_ID       Id de la experiencia.
  ROBLOX_PLACE_ID          Id del lugar de inicio.
  ROBLOX_TEST_UNIVERSE_ID  Opcional: experiencia aparte para las pruebas.
  ROBLOX_TEST_PLACE_ID     Opcional: lugar aparte para las pruebas.

Documentación de las APIs:
  https://create.roblox.com/docs/cloud/guides/usage-place-publishing
  https://create.roblox.com/docs/cloud/reference/features/luau-execution
"""

import json
import os
import sys
import time
import urllib.error
import urllib.request

API = "https://apis.roblox.com"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEST_SCRIPT = os.path.join(ROOT, "scripts", "cloud", "run-tests.luau")
TASK_TIMEOUT = "180s"
RETRYABLE = {429, 500, 502, 503, 504}

HINTS = {
    401: "La API key no es válida o ha caducado. Crea otra en "
    "https://create.roblox.com/dashboard/credentials y actualiza el secreto ROBLOX_API_KEY.",
    403: "La API key no tiene permiso para esta experiencia. Necesita 'universe-places' (Write) y "
    "'universe.place.luau-execution-session' (Write) sobre esta experiencia, y sin 'Restrict IP "
    "addresses' activado (GitHub Actions cambia de IP en cada ejecución).",
    404: "No existe esa experiencia o ese lugar. Revisa ROBLOX_UNIVERSE_ID y ROBLOX_PLACE_ID.",
}


class CloudError(Exception):
    pass


def env(name):
    value = os.environ.get(name, "").strip()
    if not value:
        raise CloudError(f"Falta la variable de entorno {name}.")
    return value


def request(method, url, body=None, content_type=None):
    headers = {"x-api-key": env("ROBLOX_API_KEY"), "Accept": "application/json"}
    if content_type:
        headers["Content-Type"] = content_type

    for attempt in range(6):
        req = urllib.request.Request(url, data=body, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=120) as response:
                raw = response.read()
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as e:
            detail = e.read().decode("utf-8", "replace")
            if e.code in RETRYABLE and attempt < 5:
                retry_after = e.headers.get("Retry-After", "")
                wait = int(retry_after) if retry_after.isdigit() else 2 ** (attempt + 1)
                print(f"  HTTP {e.code}, reintento en {wait}s…", flush=True)
                time.sleep(wait)
                continue
            hint = HINTS.get(e.code, "")
            raise CloudError(f"{method} {url} → HTTP {e.code}\n{detail}\n{hint}".rstrip())
        except urllib.error.URLError as e:
            if attempt < 5:
                wait = 2 ** (attempt + 1)
                print(f"  Error de red ({e.reason}), reintento en {wait}s…", flush=True)
                time.sleep(wait)
                continue
            raise CloudError(f"{method} {url} → error de red: {e.reason}")
    raise CloudError(f"{method} {url}: sin respuesta tras varios intentos")


def upload(place_file, universe_id, place_id, version_type):
    with open(place_file, "rb") as f:
        data = f.read()
    url = f"{API}/universes/v1/{universe_id}/places/{place_id}/versions?versionType={version_type}"
    result = request("POST", url, body=data, content_type="application/octet-stream")
    version = result.get("versionNumber")
    if not version:
        raise CloudError(f"La subida no devolvió número de versión: {result}")
    return version


def task_logs(task_path):
    messages = []
    token = ""
    while True:
        url = f"{API}/cloud/v2/{task_path}/logs?view=STRUCTURED&maxPageSize=10000"
        if token:
            url += f"&pageToken={token}"
        page = request("GET", url)
        for chunk in page.get("luauExecutionSessionTaskLogs", []):
            structured = chunk.get("structuredMessages")
            if structured:
                for entry in structured:
                    messages.append((entry.get("messageType", "OUTPUT"), entry.get("message", "")))
            else:
                messages.extend(("OUTPUT", message) for message in chunk.get("messages", []))
        token = page.get("nextPageToken", "")
        if not token:
            return messages


def run_task(universe_id, place_id, version, script):
    url = f"{API}/cloud/v2/universes/{universe_id}/places/{place_id}/versions/{version}/luau-execution-session-tasks"
    body = json.dumps({"script": script, "timeout": TASK_TIMEOUT}).encode("utf-8")
    task = request("POST", url, body=body, content_type="application/json")
    path = task["path"]
    print(f"  Tarea creada: {path}", flush=True)

    started = time.monotonic()
    while task.get("state") in (None, "STATE_UNSPECIFIED", "QUEUED", "PROCESSING"):
        time.sleep(3)
        task = request("GET", f"{API}/cloud/v2/{path}")
        if time.monotonic() - started > 900:
            raise CloudError("La tarea lleva más de 15 minutos sin terminar.")
    return task, task_logs(path)


def print_logs(messages):
    prefixes = {"WARNING": "⚠ ", "ERROR": "✗ ", "INFO": "ℹ "}
    for kind, message in messages:
        print(prefixes.get(kind, "") + message)


def step_summary(markdown):
    path = os.environ.get("GITHUB_STEP_SUMMARY")
    if path:
        with open(path, "a", encoding="utf-8") as f:
            f.write(markdown + "\n")


def command_test(place_file):
    universe_id = os.environ.get("ROBLOX_TEST_UNIVERSE_ID", "").strip() or env("ROBLOX_UNIVERSE_ID")
    place_id = os.environ.get("ROBLOX_TEST_PLACE_ID", "").strip() or env("ROBLOX_PLACE_ID")
    with open(TEST_SCRIPT, encoding="utf-8") as f:
        script = f.read()

    print(f"Subiendo {place_file} como versión guardada (no publicada)…", flush=True)
    version = upload(place_file, universe_id, place_id, "Saved")
    print(f"  Versión {version}. Ejecutando las pruebas en un servidor de Roblox…", flush=True)

    task, messages = run_task(universe_id, place_id, version, script)
    print("\n──── Salida del servidor de Roblox ────")
    print_logs(messages)
    print("───────────────────────────────────────\n")

    state = task.get("state")
    if state == "COMPLETE":
        print(f"✅ Pruebas superadas en Roblox (versión {version}).")
        step_summary(f"### ✅ Pruebas en Roblox superadas\nVersión guardada {version} del lugar {place_id}.")
        return 0

    error = task.get("error") or {}
    code = error.get("code", state)
    print(f"❌ La tarea terminó en {state} ({code}):\n{error.get('message', '')}")
    if code == "DEADLINE_EXCEEDED":
        print(
            f"La tarea superó el límite de {TASK_TIMEOUT}. Si las pruebas en sí acabaron (ver salida), "
            "puede que algún servicio deje un hilo vivo que la API espera: revisar Boot/servicios."
        )
    step_summary(f"### ❌ Pruebas en Roblox fallidas ({code})\n```\n{error.get('message', '')}\n```")
    return 1


def command_publish(place_file):
    universe_id = env("ROBLOX_UNIVERSE_ID")
    place_id = env("ROBLOX_PLACE_ID")
    print(f"Publicando {place_file}…", flush=True)
    version = upload(place_file, universe_id, place_id, "Published")
    link = f"https://www.roblox.com/games/{place_id}"
    print(f"✅ Publicada la versión {version}. Los servidores nuevos ya la usan: {link}")
    step_summary(f"### 🚀 Publicado\nVersión {version} — [abrir el juego]({link})")
    return 0


def main(argv):
    commands = {"test": command_test, "publish": command_publish}
    if len(argv) != 3 or argv[1] not in commands:
        print(__doc__)
        return 2
    try:
        return commands[argv[1]](argv[2])
    except CloudError as e:
        print(f"❌ {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
