#!/bin/bash

############################################
# DEPLOY RÁPIDO - Correção Página WhatsApp
# Execute este script para fazer deploy em 1 comando
############################################

echo "════════════════════════════════════════════════════════════"
echo "   DEPLOY - SISTEMA NOTIFICAÇÕES WHATSAPP"
echo "════════════════════════════════════════════════════════════"
echo ""

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Diretório do projeto
PROJETO_DIR="/Users/alexmini/Documents/PROJETOS DEV COM IA/DEBRIEF"

echo -e "${BLUE}📋 PASSO 1: Commit das Alterações${NC}"
echo "────────────────────────────────────────────────────────────"

cd "$PROJETO_DIR" || exit 1

# Verificar se há alterações
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Adicionando arquivos modificados..."
    
    # Adicionar arquivos principais
    git add frontend/src/pages/admin/ConfiguracaoWhatsApp.jsx
    git add backend/app/api/endpoints/whatsapp.py
    git add backend/app/api/endpoints/usuarios.py
    git add backend/app/api/endpoints/demandas.py
    git add backend/app/services/notification.py
    git add backend/app/schemas/user.py
    
    # Adicionar documentação
    git add NOTIFICACOES-WHATSAPP.md
    git add RESUMO-IMPLEMENTACAO-NOTIFICACOES.md
    git add INICIO-RAPIDO-NOTIFICACOES.md
    git add DEPLOY-NOTIFICACOES.md
    git add README-NOTIFICACOES.md
    git add CORRECAO-PAGINA-WHATSAPP.md
    git add DEPLOY-URGENTE.md
    git add testar-notificacoes.sh
    git add configurar-whatsapp-usuarios.sql
    
    echo ""
    echo "Fazendo commit..."
    git commit -m "feat: Sistema completo de notificações WhatsApp + correção página config

✅ Implementado:
- Sistema de notificações individuais via WhatsApp
- Segmentação automática por cliente
- NotificationService completo
- Endpoints de configuração (/api/usuarios/me/notificacoes)
- Endpoints de teste (/api/whatsapp/status e /api/whatsapp/testar)

✅ Corrigido:
- Página /admin/configuracao-whatsapp reformulada
- Número remetente 5585991042626 visível
- Instância debrief visível
- Campo de teste ATIVO
- Status da conexão em tempo real

✅ Documentação:
- 6 guias completos em Markdown
- Scripts de teste
- Queries SQL prontas"
    
    echo ""
    echo "Fazendo push para GitHub..."
    git push origin main
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Commit e push realizados com sucesso!${NC}"
    else
        echo -e "${RED}❌ Erro ao fazer push. Verifique sua conexão.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  Não há alterações para commitar.${NC}"
fi

echo ""
echo -e "${BLUE}📋 PASSO 2: Deploy no Servidor${NC}"
echo "────────────────────────────────────────────────────────────"
echo ""

read -p "Deseja fazer deploy no servidor agora? (s/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo ""
    echo "Conectando ao servidor..."
    echo ""
    
    ssh root@82.25.92.217 << 'ENDSSH'
        echo "📦 Atualizando código..."
        cd /var/www/debrief
        
        # Backup
        echo "Fazendo backup..."
        cp frontend/src/pages/admin/ConfiguracaoWhatsApp.jsx frontend/src/pages/admin/ConfiguracaoWhatsApp.jsx.bak 2>/dev/null || true
        
        # Pull
        echo "Puxando alterações..."
        git pull origin main
        
        if [ $? -ne 0 ]; then
            echo "❌ Erro ao puxar alterações. Tentando resolver conflitos..."
            git stash
            git pull origin main
        fi
        
        # Verificar arquivo atualizado
        echo ""
        echo "Verificando arquivo atualizado..."
        if grep -q "Evolution API" frontend/src/pages/admin/ConfiguracaoWhatsApp.jsx; then
            echo "✅ Arquivo atualizado corretamente!"
        else
            echo "⚠️  Arquivo pode não ter sido atualizado. Verificar manualmente."
        fi
        
        # Reiniciar containers
        echo ""
        echo "🔄 Reiniciando containers..."
        docker restart debrief-backend
        docker restart debrief-frontend
        
        # Aguardar
        echo "Aguardando containers iniciarem..."
        sleep 15
        
        # Verificar status
        echo ""
        echo "📊 Status dos containers:"
        docker ps | grep debrief | awk '{print $1, $2, $NF}'
        
        echo ""
        echo "✅ Deploy concluído!"
        echo ""
        echo "📝 Últimos logs do backend:"
        docker logs debrief-backend --tail 10
ENDSSH
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   DEPLOY CONCLUÍDO!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "🌐 Acesse agora:"
    echo "   https://debrief.interce.com.br/admin/configuracao-whatsapp"
    echo ""
    echo "📝 Faça um hard refresh no navegador:"
    echo "   - Windows/Linux: Ctrl + Shift + R"
    echo "   - Mac: Cmd + Shift + R"
    echo ""
    echo "✅ Verifique se:"
    echo "   - Número remetente aparece: 5585991042626"
    echo "   - Instância aparece: debrief"
    echo "   - Campo de teste está ATIVO"
    echo ""
else
    echo ""
    echo "Deploy cancelado. Para fazer manualmente:"
    echo ""
    echo "ssh root@82.25.92.217"
    echo "cd /var/www/debrief"
    echo "git pull origin main"
    echo "docker restart debrief-backend debrief-frontend"
    echo ""
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "   FIM DO SCRIPT"
echo "════════════════════════════════════════════════════════════"

