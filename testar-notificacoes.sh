#!/bin/bash

#############################################
# Script de Teste - Sistema de Notificações WhatsApp
# DeBrief - 2024
#
# Testa o sistema completo de notificações:
# - Configuração de usuário
# - Envio de notificações
# - Segmentação por cliente
# - Logs de notificação
#############################################

echo "════════════════════════════════════════════════════════════"
echo "   TESTE - SISTEMA DE NOTIFICAÇÕES WHATSAPP"
echo "════════════════════════════════════════════════════════════"
echo ""

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configurações
BACKEND_URL="http://localhost:8000"
DB_HOST="localhost"
DB_PORT="5433"
DB_NAME="dbrief"
DB_USER="postgres"
DB_PASSWORD="Mslestra@2025db"

# Função para fazer requisição autenticada
make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local token=$4
    
    if [ -n "$data" ]; then
        curl -s -X $method "${BACKEND_URL}${endpoint}" \
            -H "Authorization: Bearer ${token}" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X $method "${BACKEND_URL}${endpoint}" \
            -H "Authorization: Bearer ${token}"
    fi
}

# Função para executar SQL
exec_sql() {
    local query=$1
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "$query"
}

echo -e "${BLUE}📋 ETAPA 1: Verificar Usuários no Banco${NC}"
echo "────────────────────────────────────────────────────────────"

users_query="
SELECT 
    username,
    tipo,
    cliente_id,
    whatsapp,
    receber_notificacoes,
    ativo
FROM users
WHERE ativo = true
ORDER BY tipo, username;
"

echo "Usuários ativos:"
exec_sql "$users_query"
echo ""

echo -e "${BLUE}📋 ETAPA 2: Verificar Configuração WhatsApp Evolution API${NC}"
echo "────────────────────────────────────────────────────────────"

# Verificar status da instância
echo "Verificando conexão WhatsApp..."
status_response=$(curl -s http://localhost:21465/instance/connectionState/debrief \
    -H "apikey: debrief-wpp-58a2b7dda7da9474958e2a853062d5d5")

if echo "$status_response" | grep -q "open"; then
    echo -e "${GREEN}✅ WhatsApp conectado!${NC}"
else
    echo -e "${YELLOW}⚠️  WhatsApp pode não estar conectado${NC}"
    echo "Resposta: $status_response"
fi
echo ""

echo -e "${BLUE}📋 ETAPA 3: Configurar WhatsApp de um Usuário${NC}"
echo "────────────────────────────────────────────────────────────"
echo "Digite o email do usuário para configurar:"
read user_email

echo "Digite o número WhatsApp (ex: 5585991042626):"
read whatsapp_number

echo "Digite a senha do usuário:"
read -s password
echo ""

# Fazer login
echo "Fazendo login..."
login_response=$(curl -s -X POST "${BACKEND_URL}/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\": \"${user_email}\", \"password\": \"${password}\"}")

token=$(echo $login_response | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$token" ]; then
    echo -e "${RED}❌ Erro ao fazer login. Verifique as credenciais.${NC}"
    echo "Resposta: $login_response"
    exit 1
fi

echo -e "${GREEN}✅ Login realizado com sucesso!${NC}"
echo ""

# Atualizar configurações de notificação
echo "Configurando WhatsApp e notificações..."
config_response=$(make_request PUT "/api/usuarios/me/notificacoes" \
    "{\"whatsapp\": \"${whatsapp_number}\", \"receber_notificacoes\": true}" \
    "$token")

if echo "$config_response" | grep -q "whatsapp"; then
    echo -e "${GREEN}✅ Configurações atualizadas!${NC}"
    echo "Resposta:"
    echo "$config_response" | jq '.'
else
    echo -e "${RED}❌ Erro ao atualizar configurações${NC}"
    echo "Resposta: $config_response"
fi
echo ""

echo -e "${BLUE}📋 ETAPA 4: Verificar Perfil Atualizado${NC}"
echo "────────────────────────────────────────────────────────────"

profile_response=$(make_request GET "/api/usuarios/me" "" "$token")
echo "$profile_response" | jq '.'
echo ""

echo -e "${BLUE}📋 ETAPA 5: Criar Demanda de Teste${NC}"
echo "────────────────────────────────────────────────────────────"
echo "Esta demanda irá disparar notificações para todos os usuários elegíveis."
echo ""

# Buscar IDs necessários
clientes_query="SELECT id, nome FROM clientes LIMIT 5;"
echo "Clientes disponíveis:"
exec_sql "$clientes_query"
echo ""

echo "Digite o ID do cliente:"
read cliente_id

secretarias_query="SELECT id, nome FROM secretarias WHERE cliente_id = '$cliente_id' LIMIT 5;"
echo "Secretarias disponíveis:"
exec_sql "$secretarias_query"
echo ""

echo "Digite o ID da secretaria:"
read secretaria_id

tipos_query="SELECT id, nome FROM tipos_demanda LIMIT 5;"
echo "Tipos de demanda disponíveis:"
exec_sql "$tipos_query"
echo ""

echo "Digite o ID do tipo de demanda:"
read tipo_demanda_id

prioridades_query="SELECT id, nome FROM prioridades LIMIT 5;"
echo "Prioridades disponíveis:"
exec_sql "$prioridades_query"
echo ""

echo "Digite o ID da prioridade:"
read prioridade_id

# Obter user_id do token
user_id=$(echo "$profile_response" | jq -r '.id')

echo ""
echo "Criando demanda de teste..."

# Criar demanda
demanda_data='{
    "cliente_id": "'$cliente_id'",
    "secretaria_id": "'$secretaria_id'",
    "nome": "TESTE - Notificação WhatsApp",
    "tipo_demanda_id": "'$tipo_demanda_id'",
    "prioridade_id": "'$prioridade_id'",
    "descricao": "Demanda criada automaticamente para testar sistema de notificações WhatsApp",
    "prazo_final": "2024-12-31",
    "usuario_id": "'$user_id'",
    "links_referencia": "[]"
}'

# Nota: endpoint de criar demanda usa FormData, não JSON
# Vamos criar via banco para simplificar
echo "Criando demanda via SQL (para garantir sucesso)..."

demanda_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
create_demanda_sql="
INSERT INTO demandas (
    id, cliente_id, secretaria_id, nome, tipo_demanda_id, 
    prioridade_id, descricao, prazo_final, usuario_id, status,
    created_at, updated_at
) VALUES (
    '$demanda_id',
    '$cliente_id',
    '$secretaria_id',
    'TESTE - Notificação WhatsApp',
    '$tipo_demanda_id',
    '$prioridade_id',
    'Demanda criada automaticamente para testar sistema de notificações WhatsApp',
    '2024-12-31',
    '$user_id',
    'aberta',
    NOW(),
    NOW()
) RETURNING id;
"

result=$(exec_sql "$create_demanda_sql")
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Demanda criada: $demanda_id${NC}"
else
    echo -e "${RED}❌ Erro ao criar demanda${NC}"
    exit 1
fi
echo ""

echo -e "${BLUE}📋 ETAPA 6: Verificar Notificações Enviadas${NC}"
echo "────────────────────────────────────────────────────────────"
echo "Aguardando 5 segundos para processar notificações..."
sleep 5

logs_query="
SELECT 
    nl.id,
    nl.tipo,
    nl.status,
    nl.created_at,
    nl.dados_enviados
FROM notification_logs nl
WHERE nl.demanda_id = '$demanda_id'
ORDER BY nl.created_at DESC;
"

echo "Logs de notificação para esta demanda:"
exec_sql "$logs_query"
echo ""

# Verificar quem recebeu
usuarios_notificados_query="
SELECT 
    json_extract_path_text(nl.dados_enviados, 'usuario_nome') as usuario,
    json_extract_path_text(nl.dados_enviados, 'whatsapp') as whatsapp,
    nl.status
FROM notification_logs nl
WHERE nl.demanda_id = '$demanda_id';
"

echo "Usuários notificados:"
exec_sql "$usuarios_notificados_query"
echo ""

echo -e "${BLUE}📋 ETAPA 7: Estatísticas Gerais${NC}"
echo "────────────────────────────────────────────────────────────"

stats_query="
SELECT 
    COUNT(*) as total_notificacoes,
    SUM(CASE WHEN status = 'enviado' THEN 1 ELSE 0 END) as enviadas,
    SUM(CASE WHEN status = 'erro' THEN 1 ELSE 0 END) as erros
FROM notification_logs
WHERE tipo = 'whatsapp';
"

echo "Estatísticas de notificações WhatsApp:"
exec_sql "$stats_query"
echo ""

echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   TESTE CONCLUÍDO!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "📱 Verifique seu WhatsApp para confirmar o recebimento da notificação."
echo ""
echo "Para limpar a demanda de teste, execute:"
echo "DELETE FROM demandas WHERE id = '$demanda_id';"
echo ""

