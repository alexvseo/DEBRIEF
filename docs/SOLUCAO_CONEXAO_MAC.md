# 🔧 Solução de Problemas de Conexão - Mac Mini

Este guia ajuda a resolver problemas de conexão do Mac Mini ao banco de dados remoto.

## 🔍 Diagnóstico Rápido

Execute o script de diagnóstico:

```bash
./scripts/dev/diagnosticar-conexao-mac.sh
```

Este script verifica:
- Conectividade básica (ping)
- Acesso à porta 5432
- Configurações de firewall do Mac
- Proxy configurado
- Conexão direta com psql
- Rota de rede
- Resolução DNS

## 🛠️ Correções Comuns

### 1. Firewall do Mac

O firewall do Mac geralmente **NÃO bloqueia conexões de saída**, mas pode estar bloqueando conexões de entrada.

**Verificar status:**
```bash
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
```

**Se estiver ativo e causando problemas:**
- Vá em: Sistema > Segurança > Firewall
- Verifique se há regras bloqueando conexões
- Considere temporariamente desativar para teste

### 2. Proxy ou VPN

**Verificar proxy:**
```bash
echo $http_proxy
echo $HTTP_PROXY
```

**Verificar VPN:**
```bash
scutil --nc list
```

Se estiver usando VPN, pode precisar:
- Desconectar VPN temporariamente para testar
- Configurar rota específica para o servidor
- Usar túnel SSH (veja abaixo)

### 3. Rede Corporativa

Se estiver em rede corporativa:
- Firewall da empresa pode bloquear porta 5432
- Entre em contato com TI para liberar acesso
- Considere usar túnel SSH

### 4. PostgreSQL no Servidor

O problema pode estar no servidor, não no Mac:

**Verificar no servidor:**
```bash
# No servidor (82.25.92.217)
./scripts/diagnostico/verificar-postgresql-servidor.sh
```

**Configurações necessárias no servidor:**
- `postgresql.conf`: `listen_addresses = '*'`
- `pg_hba.conf`: Permitir conexões do seu IP
- Firewall do servidor: Liberar porta 5432

## 🔄 Solução Alternativa: Túnel SSH

Se não conseguir conectar diretamente, use túnel SSH:

### 1. Criar túnel SSH (Automático)

```bash
./scripts/dev/iniciar-tunel-ssh.sh
```

Este script:
- Cria túnel SSH automaticamente
- Usa `autossh` se disponível (reconexão automática)
- Testa a conexão
- Salva PID para gerenciamento

### 2. Atualizar DATABASE_URL

O script detecta automaticamente e atualiza, ou você pode atualizar manualmente no `backend/.env.dev`:

```bash
# De:
DATABASE_URL=postgresql://postgres:<redacted-legacy-password-encoded>@82.25.92.217:5432/dbrief

# Para:
DATABASE_URL=postgresql://postgres:<redacted-legacy-password-encoded>@localhost:5432/dbrief
```

### 3. Parar túnel SSH

```bash
./scripts/dev/parar-tunel-ssh.sh
```

### 4. Manual (se preferir)

**Criar túnel manualmente:**
```bash
ssh -L 5432:localhost:5432 -N root@82.25.92.217
```

**Ou com autossh (reconexão automática):**
```bash
# Instalar autossh
brew install autossh

# Criar túnel persistente
autossh -M 20000 -L 5432:localhost:5432 -N root@82.25.92.217
```

## 📋 Checklist de Troubleshooting

- [ ] Executar `./scripts/dev/diagnosticar-conexao-mac.sh`
- [ ] Verificar firewall do Mac
- [ ] Verificar proxy/VPN
- [ ] Testar de outra rede (mobile hotspot)
- [ ] Verificar configuração do PostgreSQL no servidor
- [ ] Verificar firewall do servidor
- [ ] Tentar túnel SSH como alternativa
- [ ] Verificar logs do servidor PostgreSQL

## 🆘 Ainda com Problemas?

1. **Execute diagnóstico completo:**
   ```bash
   ./scripts/dev/diagnosticar-conexao-mac.sh
   ./scripts/dev/corrigir-conexao-mac.sh
   ```

2. **Verifique no servidor:**
   - Acesse o servidor via SSH
   - Execute: `./scripts/diagnostico/verificar-postgresql-servidor.sh`

3. **Teste de outro local:**
   - Tente de outra rede (casa, escritório, mobile)
   - Isso identifica se é problema de rede local

4. **Use túnel SSH:**
   - Solução mais confiável se firewall bloqueia
   - Funciona mesmo com restrições de rede

## 📝 Notas Importantes

- **Firewall do Mac**: Geralmente não bloqueia conexões de saída
- **Porta 5432**: Pode ser bloqueada por firewall de rede/ISP
- **VPN**: Pode interferir em conexões diretas
- **Túnel SSH**: Solução mais confiável para ambientes restritivos

---

**Última atualização**: 2025-01-XX

