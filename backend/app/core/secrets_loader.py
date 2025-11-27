"""
Carregamento opcional de segredos a partir de um cofre externo.

Suporta:
- Arquivo JSON/ENV (`DEBRIEF_SECRETS_FILE`)
- Doppler CLI (quando `DEBRIEF_SECRETS_PROVIDER=doppler`)
"""
from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path
from typing import Any, Mapping

from functools import lru_cache


def _merge_env(values: Mapping[str, Any]) -> None:
    """
    Mesclar valores vindos do cofre para as variáveis de ambiente sem sobrescrever
    chaves já definidas explicitamente.
    """
    for key, value in values.items():
        if value is None:
            continue
        if key not in os.environ or os.environ[key] == "":
            os.environ[key] = str(value)


def _load_from_file(path: Path) -> None:
    if not path.exists():
        return
    if path.suffix in {".json", ".JSON"}:
        data = json.loads(path.read_text(encoding="utf-8"))
        _merge_env(data)
        return
    
    # Arquivos estilo .env
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            if value.startswith(("'", '"')) and value.endswith(("'", '"')):
                value = value[1:-1]
            if key and (key not in os.environ or os.environ[key] == ""):
                os.environ[key] = value


def _load_from_doppler() -> None:
    """
    Usa a CLI do Doppler para obter secrets em formato JSON.
    Requer DOPPLER_TOKEN configurado.
    """
    token = os.getenv("DOPPLER_TOKEN") or os.getenv("DOPPLER_SERVICE_TOKEN")
    if not token:
        return
    
    try:
        completed = subprocess.run(
            [
                "doppler",
                "secrets",
                "download",
                "--no-file",
                "--format",
                "json",
            ],
            check=True,
            capture_output=True,
            text=True,
            env={**os.environ, "DOPPLER_TOKEN": token},
        )
    except FileNotFoundError:
        return
    except subprocess.CalledProcessError:
        return
    
    try:
        data = json.loads(completed.stdout)
    except json.JSONDecodeError:
        return
    
    # O Doppler retorna {"KEY": {"value": "..."}}
    secrets_dict = {
        key: value["value"] if isinstance(value, dict) and "value" in value else value
        for key, value in data.items()
    }
    _merge_env(secrets_dict)


@lru_cache(maxsize=1)
def load_external_secrets() -> None:
    """
    Entrypoint idempotente para carregar segredos antes da inicialização do Settings.
    """
    provider = (os.getenv("DEBRIEF_SECRETS_PROVIDER") or os.getenv("SECRETS_PROVIDER") or "").lower()
    
    if provider in ("", "env", "none"):
        return
    
    secrets_file = (
        os.getenv("DEBRIEF_SECRETS_FILE")
        or os.getenv("SECRETS_FILE")
        or ".secrets.json"
    )
    path = Path(secrets_file).expanduser()
    
    if provider == "file":
        _load_from_file(path)
    elif provider == "doppler":
        _load_from_doppler()
    else:
        # fallback para arquivo customizado
        _load_from_file(path)


