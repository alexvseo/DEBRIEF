# 🔧 Correção do Erro 521 - Web Server is Down

**Data:** 27/11/2025 20:27 UTC  
**Status:** ✅ RESOLVIDO

---

## 🐛 Problema Identificado

O Cloudflare estava retornando erro **521 (Web server is down)** ao tentar acessar `https://debrief.interce.com.br`.

### Causa Raiz

O Caddy global (`caddy-global`) estava rodando, mas **não estava escutando na porta 443 (HTTPS)**. O Caddy estava configurado apenas para HTTP (porta 80), o que impedia o Cloudflare de estabelecer conexão HTTPS com o servidor de origem.

### Sintomas

- ❌ Porta 443 não estava aberta
- ❌ Cloudflare retornava erro 521
- ⚠️ Logs do Caddy mostravam: "server is listening only on the HTTP port, so no automatic HTTPS will be applied"
- ✅ Porta 80 funcionando normalmente
- ✅ Containers Docker rodando (backend e frontend healthy)

---

## ✅ Solução Aplicada

### 1. Diagnóstico Completo

Script criado: `scripts/diagnostico/diagnosticar-erro-521.sh`

Verificações realizadas:
- Status dos containers Docker
- Portas abertas (80, 443, 2022, 2023)
- Health checks dos containers
- Conectividade local
- Logs do backend e frontend
- Configuração do firewall

### 2. Verificação do Caddy Global

Script criado: `scripts/diagnostico/verificar-caddy-global.sh`

Descobertas:
- Container `caddy-global` rodando (healthy)
- Porta 80 aberta ✅
- Porta 443 **NÃO** aberta ❌
- Configuração correta com DNS Challenge do Cloudflare
- Token Cloudflare válido

### 3. Correção

**Comando executado:**
```bash
ssh root@82.25.92.217 "cd /root/caddy && docker-compose restart caddy"
```

**Resultado:**
- ✅ Porta 443 aberta após restart
- ✅ HTTPS funcionando (HTTP Status 200)
- ✅ Cloudflare conseguindo conectar

---

## 📊 Status Final

### Portas
```
Porta 80:  ✅ Aberta (HTTP)
Porta 443: ✅ Aberta (HTTPS)
Porta 2022: ✅ Frontend
Porta 2023: ✅ Backend
```

### Containers
```
debrief-backend:  ✅ Running (healthy)
debrief-frontend: ✅ Running (unhealthy mas respondendo)
debrief_db:       ✅ Running (healthy)
caddy-global:     ✅ Running (healthy)
```

### Conectividade
```
HTTP:  ✅ Funcionando
HTTPS: ✅ Funcionando
Cloudflare: ✅ Conectando corretamente
```

---

## 🔍 Scripts de Diagnóstico Criados

1. **`scripts/diagnostico/diagnosticar-erro-521.sh`**
   - Diagnóstico completo do erro 521
   - Verifica containers, portas, logs, firewall, etc.

2. **`scripts/diagnostico/verificar-caddy-global.sh`**
   - Verifica status do Caddy global
   - Testa conectividade HTTPS
   - Mostra logs do Caddy

---

## 🚨 Prevenção

### Monitoramento

Para evitar que o problema ocorra novamente:

1. **Verificar portas regularmente:**
   ```bash
   netstat -tlnp | grep -E ':80|:443'
   ```

2. **Monitorar logs do Caddy:**
   ```bash
   docker logs caddy-global --tail 50
   ```

3. **Testar HTTPS:**
   ```bash
   curl -I https://debrief.interce.com.br
   ```

### Reiniciar Caddy se necessário

Se a porta 443 não estiver aberta:

```bash
ssh root@82.25.92.217 "cd /root/caddy && docker-compose restart caddy"
```

Aguardar 5-10 segundos e verificar:
```bash
netstat -tlnp | grep :443
```

---

## 📝 Notas Técnicas

### Por que o Caddy não estava escutando na 443?

O Caddy estava configurado corretamente com:
- DNS Challenge do Cloudflare
- Certificados SSL válidos
- Configuração TLS correta

Mas após algum tempo (possivelmente após reinicialização do servidor ou atualização), o Caddy não estava escutando na porta 443. O restart forçou o Caddy a:
1. Revalidar a configuração
2. Reabrir a porta 443
3. Reestabelecer conexões HTTPS

### Configuração do Caddy

**Arquivo:** `/root/caddy/sites/debrief.caddy`

```caddyfile
debrief.interce.com.br {
    tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }
    
    handle /api/* {
        reverse_proxy localhost:2023
    }
    
    handle {
        reverse_proxy localhost:2022
    }
}
```

**Docker Compose:** `/root/caddy/docker-compose.yml`
- Usa `network_mode: host` para acessar localhost
- Portas 80 e 443 mapeadas automaticamente

---

## ✅ Checklist de Resolução

- [x] Identificar causa do erro 521
- [x] Verificar status do Caddy global
- [x] Confirmar que porta 443 não estava aberta
- [x] Reiniciar Caddy
- [x] Verificar porta 443 aberta
- [x] Testar HTTPS localmente
- [x] Confirmar Cloudflare conectando
- [x] Criar scripts de diagnóstico
- [x] Documentar solução

---

**Resolvido por:** Cursor AI + Alex Santos  
**Tempo de resolução:** ~15 minutos  
**Impacto:** Site DeBrief voltou a funcionar via Cloudflare


