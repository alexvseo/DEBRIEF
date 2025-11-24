# 🔍 Guia: Como Acessar o Banco de Dados do DeBrief

## 📋 Problema Identificado

Você está tentando acessar o banco de dados via DBeaver com as seguintes credenciais:

```
Host: 82.25.92.217
Port: 5432
Database: dbrief
Username: postgres
Password: Mslestra@2025db
```

**MAS** a conexão está sendo bloqueada! 🔒

---

## 🎯 Possíveis Cenários

Existem **DUAS** configurações possíveis de banco de dados no projeto:

### Cenário 1: Banco em Container Docker (docker-compose.prod.yml)
- Container local chamado `debrief_db`
- Não acessível diretamente de fora
- **Solução:** Túnel SSH

### Cenário 2: Banco PostgreSQL Local do Servidor
- PostgreSQL instalado diretamente no servidor
- Firewall bloqueando acesso remoto
- **Solução:** Configurar acesso remoto

---

## 🚀 Passo a Passo para Descobrir e Resolver

### Passo 1: Descobrir Onde Estão os Dados

**Conecte-se ao servidor:**

```bash
ssh root@82.25.92.217
```

**Execute o script de diagnóstico:**

```bash
cd /var/www/debrief
bash diagnostico-servidor.sh
```

Este script vai mostrar:
- ✅ Qual container Docker está rodando
- ✅ Qual é a DATABASE_URL configurada
- ✅ Onde os dados estão sendo salvos
- ✅ Quantos registros existem em cada tabela

---

### Passo 2: Configurar Acesso (Baseado no Resultado)

#### **Se os dados estão em CONTAINER Docker (debrief_db)**

Use **Túnel SSH** (mais seguro):

**No seu Mac, execute:**

```bash
ssh -L 5432:localhost:5432 root@82.25.92.217
```

**Configure o DBeaver:**
```
Host: localhost
Port: 5432
Database: dbrief
Username: postgres
Password: Mslestra@2025  (senha do container, não db no final)
```

**Mantenha o terminal do SSH aberto** enquanto usa o DBeaver!

---

#### **Se os dados estão em PostgreSQL Local do Servidor**

**No servidor, execute:**

```bash
cd /var/www/debrief
sudo bash configurar-acesso-remoto-banco.sh
```

Este script vai:
1. ✅ Fazer backup das configurações atuais
2. ✅ Configurar PostgreSQL para aceitar conexões remotas
3. ✅ Liberar porta 5432 no firewall
4. ✅ Reiniciar o serviço

**Configure o DBeaver:**
```
Host: 82.25.92.217
Port: 5432
Database: dbrief
Username: postgres
Password: Mslestra@2025db
```

---

## 📦 Arquivos Criados para Você

Os seguintes scripts foram criados para facilitar o processo:

### 1. `diagnostico-servidor.sh`
Execute **NO SERVIDOR** para descobrir onde os dados estão:
```bash
ssh root@82.25.92.217
cd /var/www/debrief
bash diagnostico-servidor.sh
```

### 2. `configurar-acesso-remoto-banco.sh`
Execute **NO SERVIDOR** para configurar acesso remoto:
```bash
ssh root@82.25.92.217
cd /var/www/debrief
sudo bash configurar-acesso-remoto-banco.sh
```

### 3. `testar-conexao-banco.py`
Execute **LOCALMENTE** para testar se a conexão está funcionando:
```bash
python3 testar-conexao-banco.py
```

---

## 🔐 Questões de Segurança

### ⚠️ Avisos Importantes:

1. **Túnel SSH é mais seguro** que abrir a porta 5432 para o mundo
2. Se abrir acesso remoto, considere restringir apenas ao seu IP
3. Nunca compartilhe as credenciais do banco

### Restringir Acesso por IP (Opcional)

Se você configurou acesso remoto, pode restringir ao seu IP:

**No servidor:**
```bash
# Descubra seu IP
curl ifconfig.me

# Edite pg_hba.conf
sudo nano /etc/postgresql/15/main/pg_hba.conf

# Substitua esta linha:
host    all             all             0.0.0.0/0               md5

# Por (usando SEU IP):
host    all             all             SEU.IP.AQUI.XXX/32      md5

# Reinicie PostgreSQL
sudo systemctl restart postgresql
```

---

## 🐛 Troubleshooting

### Erro: "Connection refused"
- ✅ Verifique se o PostgreSQL está rodando: `systemctl status postgresql`
- ✅ Verifique se a porta está aberta: `ss -tuln | grep 5432`
- ✅ Verifique o firewall: `sudo ufw status`

### Erro: "Password authentication failed"
- ✅ Verifique a senha no arquivo `.env` do backend
- ✅ Tente com a senha do container: `Mslestra@2025` (sem 'db')
- ✅ Tente com a senha da URL: `Mslestra@2025db`

### Erro: "Connection timed out"
- ✅ PostgreSQL não está configurado para aceitar conexões remotas
- ✅ Firewall está bloqueando a porta 5432
- ✅ Execute o script `configurar-acesso-remoto-banco.sh`

### Não vejo os dados inseridos
- ✅ Os dados podem estar em outro banco/schema
- ✅ Execute o script de diagnóstico para verificar
- ✅ Verifique se está conectando no banco correto (dbrief)

---

## 📊 Verificação Final

Após configurar o acesso, verifique:

```sql
-- Listar todos os bancos
\l

-- Conectar ao banco dbrief
\c dbrief

-- Listar todas as tabelas
\dt

-- Ver quantos registros existem
SELECT 'usuarios' as tabela, COUNT(*) FROM usuarios
UNION ALL
SELECT 'demandas', COUNT(*) FROM demandas
UNION ALL
SELECT 'secretarias', COUNT(*) FROM secretarias
UNION ALL
SELECT 'configuracoes', COUNT(*) FROM configuracoes;

-- Ver últimas demandas criadas
SELECT id, titulo, status, created_at 
FROM demandas 
ORDER BY created_at DESC 
LIMIT 10;
```

---

## 📞 Resumo Rápido

### Opção 1: Túnel SSH (RECOMENDADO) 🔒
```bash
# No seu Mac
ssh -L 5432:localhost:5432 root@82.25.92.217

# DBeaver: localhost:5432
```

### Opção 2: Acesso Direto ⚠️
```bash
# No servidor
ssh root@82.25.92.217
cd /var/www/debrief
sudo bash configurar-acesso-remoto-banco.sh

# DBeaver: 82.25.92.217:5432
```

---

## ✅ Checklist

- [ ] Executei o diagnóstico no servidor
- [ ] Descobri onde os dados estão (container ou PostgreSQL local)
- [ ] Configurei o acesso (túnel SSH ou acesso remoto)
- [ ] Testei a conexão no DBeaver
- [ ] Consigo ver as tabelas
- [ ] Consigo ver os registros

---

**Próximo passo:** Execute o `diagnostico-servidor.sh` no servidor para descobrir onde seus dados estão! 🚀

