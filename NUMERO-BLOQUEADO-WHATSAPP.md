# ⚠️ Número WhatsApp Bloqueado - Registro do Incidente

## 📅 Data do Incidente
**24 de Novembro de 2025**

## 🔴 Problema
**Número bloqueado pelo WhatsApp:** 55 85 91042626

### Sintomas Observados
- Status da instância: `"connecting"` (ficou preso neste estado)
- Impossível enviar mensagens
- Erro nos logs: `ENOENT: no such file or directory, opendir '/evolution/store/messages/debrief'`
- API retornava timeouts nas tentativas de envio

### Causa Provável
**Uso de conta WhatsApp pessoal para fins comerciais/automação**

O WhatsApp tem políticas rigorosas sobre o uso de contas pessoais para:
- ✗ Envio automatizado de mensagens
- ✗ Notificações em massa
- ✗ Uso comercial sem autorização
- ✗ APIs não oficiais (Baileys, etc.)

## 🛠️ Tecnologia Utilizada (Bloqueada)

### Evolution API v1.8.5 (wppconnect-server)
```yaml
Container: wppconnect-server
Porta: 21465
API: Baileys Multi-Device
Instância: debrief
Número: 55 85 91042626
Status: ❌ BLOQUEADO
```

### Configuração Anterior
```env
WHATSAPP_API_URL=http://localhost:21465
WHATSAPP_API_KEY=debrief-wpp-58a2b7dda7da9474958e2a853062d5d5
WHATSAPP_INSTANCE=debrief
WHATSAPP_NUMERO=5585991042626
```

## ✅ Ação Tomada

### 1. Desinstalação Completa
```bash
# Container removido
docker stop wppconnect-server
docker rm wppconnect-server

# Imagens limpas
docker rmi evolution-api:latest (se existir)
```

### 2. Decisão: Migrar para Z-API
**Razão:** API oficial homologada pelo WhatsApp Business

## 🔄 Migração para Z-API

### Por Que Z-API?
1. **✅ Oficial:** Homologado pelo WhatsApp Business
2. **✅ Confiável:** Menor risco de bloqueio
3. **✅ Gerenciado:** Infraestrutura em nuvem
4. **✅ Suporte:** Assistência profissional
5. **✅ Compliance:** Conforme políticas do WhatsApp

### Vantagens Técnicas
- API REST simples
- Webhooks para recebimento
- Status de entrega confiável
- Documentação completa
- SDKs disponíveis

## 📝 Lições Aprendidas

### ❌ O Que NÃO Fazer
1. Usar número pessoal para automação
2. APIs não oficiais (Baileys, etc.) em produção
3. Enviar mensagens sem consentimento do usuário
4. Alto volume de mensagens sem controle

### ✅ O Que Fazer
1. Usar WhatsApp Business API oficial
2. Obter consentimento explícito dos usuários
3. Implementar rate limiting
4. Seguir políticas do WhatsApp
5. Usar provedores homologados (Z-API, Twilio, etc.)

## 🚀 Próximos Passos

### Fase 1: Contratação Z-API ⏳
- [ ] Criar conta no Z-API
- [ ] Escolher plano adequado
- [ ] Obter novo número WhatsApp
- [ ] Configurar instância

### Fase 2: Integração 🔧
- [ ] Receber credenciais (URL, Token, Instance ID)
- [ ] Atualizar `backend/app/core/config.py`
- [ ] Adaptar `backend/app/services/whatsapp.py`
- [ ] Atualizar endpoints de teste

### Fase 3: Testes ✅
- [ ] Testar conexão com Z-API
- [ ] Enviar mensagem de teste
- [ ] Validar webhooks (se necessário)
- [ ] Testar notificações automáticas

### Fase 4: Deploy 🚀
- [ ] Atualizar variáveis de ambiente
- [ ] Rebuild do backend
- [ ] Deploy em produção
- [ ] Monitorar logs

### Fase 5: Comunicação 📢
- [ ] Atualizar documentação
- [ ] Informar usuários sobre novo número
- [ ] Atualizar frontend com novo número
- [ ] Treinar equipe

## 📊 Impacto

### Funcionalidades Afetadas
- ❌ Notificações automáticas (temporariamente desabilitadas)
- ❌ Teste de envio de mensagem
- ❌ Status da conexão WhatsApp
- ✅ Resto do sistema funcionando normalmente

### Tempo Estimado de Recuperação
- **Contratação Z-API:** Depende do processo de aprovação
- **Integração técnica:** ~1 hora
- **Testes:** ~30 minutos
- **Deploy:** ~15 minutos
- **Total:** Depende da contratação + ~2 horas técnicas

## 📞 Contato Z-API

**Site:** https://www.z-api.io/  
**Documentação:** https://developer.z-api.io/  
**Suporte:** Via painel do cliente

### Planos Recomendados
- **Starter:** Para testes e baixo volume
- **Business:** Para uso em produção
- **Enterprise:** Para alto volume

## ✅ Status Atual

**Sistema DeBrief:**
- ✅ Backend funcionando
- ✅ Frontend funcionando
- ✅ Banco de dados OK
- ✅ Demandas OK
- ✅ Usuários OK
- ❌ Notificações WhatsApp (aguardando Z-API)

**Próxima Ação:**
Aguardando credenciais do Z-API para continuar migração.

---

**Importante:** Este documento serve como registro do incidente e guia para evitar problemas similares no futuro.

**Data de Atualização:** 24/11/2025  
**Status:** 🟡 Em Processo de Migração

