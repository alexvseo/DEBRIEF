#!/bin/bash
set -euo pipefail

# Gera backup lógico do banco usando a DATABASE_URL do backend.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/backend/.env"

if [ -f "${ENV_FILE}" ]; then
    # shellcheck disable=SC1090
    source "${ENV_FILE}"
fi

if [ -z "${DATABASE_URL:-}" ]; then
    echo "DATABASE_URL não definido. Configure backend/.env antes de gerar backup."
    exit 1
fi

OUTPUT_DIR="${PROJECT_ROOT}/backups"
mkdir -p "${OUTPUT_DIR}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_FILE="${OUTPUT_DIR}/dbrief_backup_${TIMESTAMP}.sql"

echo "📦 Gerando backup em ${OUTPUT_FILE}"
pg_dump "${DATABASE_URL}" --no-owner --format=plain > "${OUTPUT_FILE}"
echo "✅ Backup concluído."

