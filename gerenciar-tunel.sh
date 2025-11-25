#!/bin/bash

# ========================================
# GERENCIADOR DE TÚNEL SSH - DEBRIEF
# ========================================

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

function show_status() {
    echo ""
    echo "=========================================="
    echo "📊 STATUS DO TÚNEL SSH"
    echo "=========================================="
    echo ""
    
    # Verificar se o processo SSH está rodando
    if ps aux | grep -q "[s]sh.*5432.*82.25.92.217"; then
        echo -e "${GREEN}✅ TÚNEL SSH: ATIVO${NC}"
        echo ""
        echo "Processo:"
        ps aux | grep "[s]sh.*5432.*82.25.92.217" | awk '{print "  PID: "$2" | Tempo: "$10}'
        echo ""
        
        # Testar conexão
        if nc -zv localhost 5432 2>&1 | grep -q "succeeded"; then
            echo -e "${GREEN}✅ PORTA LOCAL: ACESSÍVEL${NC}"
            echo ""
            
            # Testar banco de dados
            if PGPASSWORD='Mslestra@2025db' psql -h localhost -p 5432 -U postgres -d dbrief -c "SELECT 1" &>/dev/null; then
                echo -e "${GREEN}✅ BANCO DE DADOS: CONECTADO${NC}"
                echo ""
                
                # Mostrar estatísticas
                echo -e "${CYAN}📊 Registros no banco:${NC}"
                PGPASSWORD='Mslestra@2025db' psql -h localhost -p 5432 -U postgres -d dbrief -t -c "
                    SELECT '  ' || tabela || ': ' || registros 
                    FROM (
                        SELECT 'Usuários' as tabela, COUNT(*) as registros FROM users
                        UNION ALL
                        SELECT 'Demandas', COUNT(*) FROM demandas
                        UNION ALL
                        SELECT 'Secretarias', COUNT(*) FROM secretarias
                        UNION ALL
                        SELECT 'Clientes', COUNT(*) FROM clientes
                        ORDER BY tabela
                    ) t;
                "
            else
                echo -e "${YELLOW}⚠️  BANCO DE DADOS: PORTA ABERTA MAS SEM CONEXÃO${NC}"
            fi
        else
            echo -e "${RED}❌ PORTA LOCAL: NÃO ACESSÍVEL${NC}"
        fi
    else
        echo -e "${RED}❌ TÚNEL SSH: INATIVO${NC}"
        echo ""
        echo "Use: $0 start"
    fi
    
    echo ""
    echo "=========================================="
    echo ""
}

function start_tunnel() {
    echo ""
    echo "=========================================="
    echo "🚀 INICIANDO TÚNEL SSH"
    echo "=========================================="
    echo ""
    
    # Verificar se já está rodando
    if ps aux | grep -q "[s]sh.*5432.*82.25.92.217"; then
        echo -e "${YELLOW}⚠️  Túnel já está rodando!${NC}"
        show_status
        return
    fi
    
    echo "Conectando ao servidor 82.25.92.217..."
    echo ""
    
    # Iniciar túnel em background
    nohup ssh -N -L 5432:localhost:5432 \
        -o ServerAliveInterval=60 \
        -o ServerAliveCountMax=3 \
        -o TCPKeepAlive=yes \
        -o ExitOnForwardFailure=yes \
        -o ConnectTimeout=10 \
        root@82.25.92.217 > /tmp/debrief-tunnel.log 2>&1 &
    
    echo $! > /tmp/debrief-tunnel.pid
    
    echo "Aguardando conexão..."
    sleep 3
    
    if ps aux | grep -q "[s]sh.*5432.*82.25.92.217"; then
        echo -e "${GREEN}✅ Túnel iniciado com sucesso!${NC}"
        echo ""
        echo -e "${CYAN}Configure o DBeaver:${NC}"
        echo "  Host: localhost"
        echo "  Port: 5432"
        echo "  Database: dbrief"
        echo "  Username: postgres"
        echo "  Password: Mslestra@2025db"
        echo ""
    else
        echo -e "${RED}❌ Falha ao iniciar túnel${NC}"
        echo "Verifique os logs em: /tmp/debrief-tunnel.log"
    fi
}

function stop_tunnel() {
    echo ""
    echo "=========================================="
    echo "🛑 ENCERRANDO TÚNEL SSH"
    echo "=========================================="
    echo ""
    
    if ps aux | grep -q "[s]sh.*5432.*82.25.92.217"; then
        pkill -f "ssh.*5432.*82.25.92.217"
        sleep 1
        
        if ! ps aux | grep -q "[s]sh.*5432.*82.25.92.217"; then
            echo -e "${GREEN}✅ Túnel encerrado com sucesso${NC}"
            rm -f /tmp/debrief-tunnel.pid
        else
            echo -e "${RED}❌ Falha ao encerrar túnel${NC}"
            echo "Tente manualmente: pkill -9 -f 'ssh.*5432.*82.25.92.217'"
        fi
    else
        echo -e "${YELLOW}⚠️  Nenhum túnel ativo encontrado${NC}"
    fi
    
    echo ""
}

function restart_tunnel() {
    echo ""
    echo "🔄 Reiniciando túnel..."
    stop_tunnel
    sleep 2
    start_tunnel
}

function test_connection() {
    echo ""
    echo "=========================================="
    echo "🧪 TESTANDO CONEXÃO COM BANCO DE DADOS"
    echo "=========================================="
    echo ""
    
    if ! ps aux | grep -q "[s]sh.*5432.*82.25.92.217"; then
        echo -e "${RED}❌ Túnel não está rodando!${NC}"
        echo "Inicie com: $0 start"
        return
    fi
    
    echo "1. Testando porta local..."
    if nc -zv localhost 5432 2>&1 | grep -q "succeeded"; then
        echo -e "   ${GREEN}✅ Porta 5432 acessível${NC}"
    else
        echo -e "   ${RED}❌ Porta 5432 não acessível${NC}"
        return
    fi
    
    echo ""
    echo "2. Testando conexão PostgreSQL..."
    if PGPASSWORD='Mslestra@2025db' psql -h localhost -p 5432 -U postgres -d dbrief -c "SELECT version();" &>/dev/null; then
        echo -e "   ${GREEN}✅ PostgreSQL conectado${NC}"
    else
        echo -e "   ${RED}❌ Falha na autenticação PostgreSQL${NC}"
        return
    fi
    
    echo ""
    echo "3. Listando tabelas..."
    PGPASSWORD='Mslestra@2025db' psql -h localhost -p 5432 -U postgres -d dbrief -c "\dt" | head -20
    
    echo ""
    echo -e "${GREEN}✅ Conexão funcionando perfeitamente!${NC}"
    echo ""
}

function show_help() {
    echo ""
    echo "=========================================="
    echo "📚 GERENCIADOR DE TÚNEL SSH - DEBRIEF"
    echo "=========================================="
    echo ""
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos:"
    echo "  start     Iniciar túnel SSH"
    echo "  stop      Encerrar túnel SSH"
    echo "  restart   Reiniciar túnel SSH"
    echo "  status    Ver status do túnel"
    echo "  test      Testar conexão com banco"
    echo "  help      Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 start     # Iniciar túnel"
    echo "  $0 status    # Ver se está rodando"
    echo "  $0 test      # Testar conexão"
    echo ""
}

# Menu principal
case "$1" in
    start)
        start_tunnel
        ;;
    stop)
        stop_tunnel
        ;;
    restart)
        restart_tunnel
        ;;
    status)
        show_status
        ;;
    test)
        test_connection
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        if [ -z "$1" ]; then
            show_status
        else
            echo -e "${RED}Comando desconhecido: $1${NC}"
            show_help
        fi
        ;;
esac



