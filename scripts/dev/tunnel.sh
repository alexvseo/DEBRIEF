#!/bin/bash

# Configurações
# Agora usamos o alias 'debrief' definido em ~/.ssh/config
SSH_HOST="debrief"
DB_HOST="127.0.0.1"        # Host do banco RELATIVO ao servidor
DB_PORT="5432"             # Porta do Postgres no servidor
LOCAL_PORT="5433"          # Porta local para mapear

echo "🔌 Iniciando Túnel SSH Persistente..."
echo "   SSH: $SSH_HOST (via ~/.ssh/config)"
echo "   Forward: localhost:$LOCAL_PORT -> $DB_HOST:$DB_PORT"
echo ""

# Verificar se a porta já está em uso
if lsof -Pi :$LOCAL_PORT -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  A porta $LOCAL_PORT já está em uso. Tentando matar o processo..."
    lsof -Pi :$LOCAL_PORT -sTCP:LISTEN -t | xargs kill -9
    echo "✅ Processo anterior encerrado."
fi

# Iniciar túnel
# -f: Background
# -N: Não executar comando remoto
# -M: Coloca o ssh em modo "Master" para monitoramento (opcional com ControlMaster auto)
ssh -f -N -L $LOCAL_PORT:$DB_HOST:$DB_PORT $SSH_HOST

if [ $? -eq 0 ]; then
    echo "✅ Túnel estabelecido com sucesso!"
    echo "   Agora você pode conectar no banco usando: localhost:$LOCAL_PORT"
    echo "   Para parar o túnel, use: lsof -ti:$LOCAL_PORT | xargs kill -9"
else
    echo "❌ Falha ao estabelecer túnel."
fi
