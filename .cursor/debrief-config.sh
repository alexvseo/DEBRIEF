#!/bin/bash
# Configuração Automática DeBrief - Acesso VPS Hostinger
# Este script facilita o acesso e gerenciamento do servidor

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
VPS_HOST="debrief"
VPS_IP="82.25.92.217"
VPS_USER="root"
PROJECT_DIR_SERVER="/var/www/debrief"
PROJECT_DIR_LOCAL="/Users/alexsantos/Documents/PROJETOS DEV COM IA/DEBRIEF"
DB_TUNNEL_PORT="5433"
DB_REMOTE_PORT="5432"

# Banner
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     DeBrief - Gestão VPS Hostinger        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Funções
show_menu() {
    echo -e "${YELLOW}Escolha uma opção:${NC}"
    echo "1)  🔌 Iniciar Túnel SSH (Banco de Dados)"
    echo "2)  🛑 Parar Túnel SSH"
    echo "3)  📊 Status do Túnel"
    echo "4)  🖥️  Conectar ao Servidor (SSH)"
    echo "5)  📂 Listar Arquivos do Servidor"
    echo "6)  🐳 Ver Containers Docker no Servidor"
    echo "7)  📝 Ver Logs do Backend (Servidor)"
    echo "8)  📝 Ver Logs do Frontend (Servidor)"
    echo "9)  🔄 Atualizar Código no Servidor (git pull)"
    echo "10) 🚀 Deploy Completo (pull + build + restart)"
    echo "11) 💾 Backup do Banco de Dados"
    echo "12) 🔧 Executar Comando Customizado no Servidor"
    echo "13) 📋 Aplicar Migrations no Servidor"
    echo "14) 🏠 Iniciar Ambiente Local (Docker)"
    echo "15) 🛑 Parar Ambiente Local"
    echo "16) 📊 Status Ambiente Local"
    echo "0)  ❌ Sair"
    echo ""
    echo -n "Opção: "
}

# 1. Iniciar Túnel SSH
start_tunnel() {
    echo -e "${YELLOW}🔌 Iniciando túnel SSH para banco de dados...${NC}"
    
    # Verificar se já existe
    if lsof -Pi :$DB_TUNNEL_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${RED}⚠️  Túnel já está ativo na porta $DB_TUNNEL_PORT${NC}"
        return
    fi
    
    # Iniciar túnel
    ssh -f -N -L $DB_TUNNEL_PORT:127.0.0.1:$DB_REMOTE_PORT $VPS_HOST
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Túnel estabelecido com sucesso!${NC}"
        echo -e "${BLUE}   localhost:$DB_TUNNEL_PORT -> servidor:$DB_REMOTE_PORT${NC}"
    else
        echo -e "${RED}❌ Erro ao estabelecer túnel${NC}"
    fi
}

# 2. Parar Túnel SSH
stop_tunnel() {
    echo -e "${YELLOW}🛑 Parando túnel SSH...${NC}"
    
    PID=$(lsof -ti:$DB_TUNNEL_PORT)
    if [ -z "$PID" ]; then
        echo -e "${RED}⚠️  Nenhum túnel ativo encontrado${NC}"
        return
    fi
    
    kill -9 $PID
    echo -e "${GREEN}✅ Túnel parado com sucesso!${NC}"
}

# 3. Status do Túnel
status_tunnel() {
    echo -e "${YELLOW}📊 Verificando status do túnel...${NC}"
    
    if lsof -Pi :$DB_TUNNEL_PORT -sTCP:LISTEN >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Túnel ATIVO na porta $DB_TUNNEL_PORT${NC}"
        lsof -Pi :$DB_TUNNEL_PORT -sTCP:LISTEN
    else
        echo -e "${RED}❌ Túnel NÃO está ativo${NC}"
    fi
}

# 4. Conectar SSH
connect_ssh() {
    echo -e "${BLUE}🖥️  Conectando ao servidor...${NC}"
    ssh $VPS_HOST
}

# 5. Listar Arquivos
list_files() {
    echo -e "${YELLOW}📂 Arquivos no servidor ($PROJECT_DIR_SERVER):${NC}"
    ssh $VPS_HOST "ls -lah $PROJECT_DIR_SERVER"
}

# 6. Ver Containers Docker
docker_ps() {
    echo -e "${YELLOW}🐳 Containers Docker no servidor:${NC}"
    ssh $VPS_HOST "cd $PROJECT_DIR_SERVER && docker-compose ps"
}

# 7. Logs Backend
logs_backend() {
    echo -e "${YELLOW}📝 Logs do Backend (últimas 50 linhas):${NC}"
    ssh $VPS_HOST "cd $PROJECT_DIR_SERVER && docker-compose logs --tail=50 backend"
}

# 8. Logs Frontend
logs_frontend() {
    echo -e "${YELLOW}📝 Logs do Frontend (últimas 50 linhas):${NC}"
    ssh $VPS_HOST "cd $PROJECT_DIR_SERVER && docker-compose logs --tail=50 frontend"
}

# 9. Git Pull
git_pull() {
    echo -e "${YELLOW}🔄 Atualizando código no servidor...${NC}"
    ssh $VPS_HOST "cd $PROJECT_DIR_SERVER && git pull origin main"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Código atualizado com sucesso!${NC}"
    else
        echo -e "${RED}❌ Erro ao atualizar código${NC}"
    fi
}

# 10. Deploy Completo
deploy_full() {
    echo -e "${BLUE}🚀 Iniciando deploy completo...${NC}"
    
    ssh $VPS_HOST "cd $PROJECT_DIR_SERVER && \
        echo '📥 1/4: Git pull...' && \
        git pull origin main && \
        echo '🏗️  2/4: Rebuild containers...' && \
        docker-compose down && \
        docker-compose up -d --build && \
        echo '⏳ 3/4: Aguardando containers iniciarem...' && \
        sleep 10 && \
        echo '🔧 4/4: Aplicando migrations...' && \
        docker-compose exec -T backend alembic upgrade head && \
        echo '✅ Deploy completo!' && \
        docker-compose ps"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Deploy realizado com sucesso!${NC}"
    else
        echo -e "${RED}❌ Erro durante o deploy${NC}"
    fi
}

# 11. Backup Banco
backup_db() {
    echo -e "${YELLOW}💾 Criando backup do banco de dados...${NC}"
    
    BACKUP_FILE="debrief_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    ssh $VPS_HOST "PGPASSWORD='Mslestrategia.2025@' pg_dump -h localhost -U postgres -d dbrief > /tmp/$BACKUP_FILE"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Backup criado: /tmp/$BACKUP_FILE${NC}"
        echo -n "Deseja baixar o backup para o computador local? (s/n): "
        read -r DOWNLOAD
        
        if [[ $DOWNLOAD == "s" || $DOWNLOAD == "S" ]]; then
            scp $VPS_HOST:/tmp/$BACKUP_FILE "$PROJECT_DIR_LOCAL/backups/$BACKUP_FILE"
            echo -e "${GREEN}✅ Backup baixado para: $PROJECT_DIR_LOCAL/backups/$BACKUP_FILE${NC}"
        fi
    else
        echo -e "${RED}❌ Erro ao criar backup${NC}"
    fi
}

# 12. Comando Customizado
custom_command() {
    echo -e "${YELLOW}🔧 Executar comando customizado no servidor${NC}"
    echo -n "Digite o comando: "
    read -r CMD
    
    echo -e "${BLUE}Executando: $CMD${NC}"
    ssh $VPS_HOST "$CMD"
}

# 13. Aplicar Migrations
apply_migrations() {
    echo -e "${YELLOW}📋 Aplicando migrations no servidor...${NC}"
    
    ssh $VPS_HOST "cd $PROJECT_DIR_SERVER && docker-compose exec -T backend alembic upgrade head"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Migrations aplicadas com sucesso!${NC}"
        
        # Mostrar versão atual
        echo -e "${BLUE}Versão atual:${NC}"
        ssh $VPS_HOST "cd $PROJECT_DIR_SERVER && docker-compose exec -T backend alembic current"
    else
        echo -e "${RED}❌ Erro ao aplicar migrations${NC}"
    fi
}

# 14. Iniciar Ambiente Local
start_local() {
    echo -e "${YELLOW}🏠 Iniciando ambiente local...${NC}"
    
    cd "$PROJECT_DIR_LOCAL" || exit
    
    # Verificar se túnel está ativo
    if ! lsof -Pi :$DB_TUNNEL_PORT -sTCP:LISTEN >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Túnel não está ativo. Iniciando...${NC}"
        start_tunnel
        sleep 2
    fi
    
    # Iniciar containers
    docker-compose -f docker-compose.dev.yml up -d
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Ambiente local iniciado!${NC}"
        echo -e "${BLUE}   Frontend: http://localhost:3000${NC}"
        echo -e "${BLUE}   Backend: http://localhost:8000${NC}"
        echo -e "${BLUE}   Docs: http://localhost:8000/docs${NC}"
    else
        echo -e "${RED}❌ Erro ao iniciar ambiente local${NC}"
    fi
}

# 15. Parar Ambiente Local
stop_local() {
    echo -e "${YELLOW}🛑 Parando ambiente local...${NC}"
    
    cd "$PROJECT_DIR_LOCAL" || exit
    docker-compose -f docker-compose.dev.yml down
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Ambiente local parado!${NC}"
    else
        echo -e "${RED}❌ Erro ao parar ambiente local${NC}"
    fi
}

# 16. Status Ambiente Local
status_local() {
    echo -e "${YELLOW}📊 Status do ambiente local:${NC}"
    
    cd "$PROJECT_DIR_LOCAL" || exit
    
    echo -e "${BLUE}Containers:${NC}"
    docker-compose -f docker-compose.dev.yml ps
    
    echo ""
    echo -e "${BLUE}Túnel SSH:${NC}"
    status_tunnel
}

# Loop do Menu
while true; do
    echo ""
    show_menu
    read -r OPTION
    
    case $OPTION in
        1) start_tunnel ;;
        2) stop_tunnel ;;
        3) status_tunnel ;;
        4) connect_ssh ;;
        5) list_files ;;
        6) docker_ps ;;
        7) logs_backend ;;
        8) logs_frontend ;;
        9) git_pull ;;
        10) deploy_full ;;
        11) backup_db ;;
        12) custom_command ;;
        13) apply_migrations ;;
        14) start_local ;;
        15) stop_local ;;
        16) status_local ;;
        0) 
            echo -e "${GREEN}👋 Até logo!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Opção inválida!${NC}"
            ;;
    esac
    
    echo ""
    echo -e "${YELLOW}Pressione ENTER para continuar...${NC}"
    read -r
done


