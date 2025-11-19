# 🔧 Solução: Backend Error - Container não inicia

**Data:** 19/11/2025  
**Problema:** Container backend fica com erro e não inicia  
**Status:** ✅ SOLUÇÕES IMPLEMENTADAS

---

## 🔴 Problema Identificado

O container backend está falhando ao iniciar. Possíveis causas:

1. **Volume mount sobrescrevendo código:** `./backend:/app` pode estar sobrescrevendo o código do build
2. **Código desatualizado no servidor:** Código local pode ter erros ou estar desatualizado
3. **Erro de configuração:** Variáveis de ambiente ou dependências
4. **Erro de inicialização:** Problema ao conectar ao banco ou importar módulos

---

## ✅ Soluções Implementadas

### 1. Criar `docker-compose.prod.yml` (Sem Volume Mount)

**Problema:** O volume mount `./backend:/app` pode causar conflitos se o código no servidor estiver desatualizado.

**Solução:** Criar versão de produção que **NÃO** monta o código fonte:

```yaml
volumes:
  # Apenas uploads - código vem do build (produção)
  - ./backend/uploads:/app/uploads
  # NÃO montar código fonte em produção
  # - ./backend:/app  # COMENTADO
```

**Vantagens:**
- ✅ Código vem do build da imagem (mais confiável)
- ✅ Evita conflitos com código local
- ✅ Mais rápido (não precisa sincronizar arquivos)

### 2. Script de Verificação de Logs

Criado `verificar_logs_backend.sh` para diagnosticar rapidamente.

---

## 🚀 Como Resolver no Servidor

### Opção 1: Usar docker-compose.prod.yml (Recomendado)

```bash
ssh root@82.25.92.217
cd ~/debrief

# Pull atualizações
git pull

# Parar containers
docker-compose down

# Usar versão de produção (sem volume mount de código)
docker-compose -f docker-compose.prod.yml build --no-cache backend
docker-compose -f docker-compose.prod.yml up -d

# Aguardar backend iniciar
echo "Aguardando backend iniciar (2 minutos)..."
sleep 120

# Verificar
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml logs backend | tail -30
```

### Opção 2: Comentar Volume Mount no docker-compose.yml

```bash
ssh root@82.25.92.217
cd ~/debrief

# Editar docker-compose.yml
nano docker-compose.yml

# Comentar a linha:
# - ./backend:/app

# Salvar e reiniciar
docker-compose down
docker-compose build --no-cache backend
docker-compose up -d
```

### Opção 3: Verificar Logs e Corrigir

```bash
# Executar script de verificação
./verificar_logs_backend.sh

# Ver logs completos
docker-compose logs --tail=100 backend

# Procurar erros específicos
docker-compose logs backend | grep -i "error\|exception\|traceback" | tail -20
```

---

## 🔍 Diagnóstico Passo a Passo

### 1. Verificar Logs do Backend

```bash
# Últimas 100 linhas
docker-compose logs --tail=100 backend

# Ver apenas erros
docker-compose logs backend | grep -i "error\|exception\|traceback\|failed"
```

### 2. Verificar se Container Está Rodando

```bash
docker-compose ps backend

# Se estiver "Exited" ou "Error", ver logs
docker-compose logs backend
```

### 3. Testar Inicialização Manual

```bash
# Tentar iniciar backend isoladamente
docker-compose up backend

# Ver saída em tempo real
# Pressione Ctrl+C para parar
```

### 4. Verificar Código no Servidor

```bash
# Verificar se há erros de sintaxe
cd backend
python3 -m py_compile app/main.py

# Verificar imports
python3 -c "from app.main import app; print('OK')"
```

---

## 🐛 Troubleshooting por Tipo de Erro

### Erro: "ModuleNotFoundError" ou "ImportError"

**Causa:** Dependências não instaladas ou código com erro

**Solução:**
```bash
# Rebuild completo
docker-compose build --no-cache backend

# Verificar requirements.txt
cat backend/requirements.txt

# Se persistir, verificar se código está correto
git status
git diff
```

### Erro: "error parsing value for field ALLOWED_EXTENSIONS"

**Causa:** Já foi corrigido, mas pode precisar rebuild

**Solução:**
```bash
# Rebuild do backend
docker-compose build --no-cache backend
docker-compose up -d backend
```

### Erro: "could not connect to server" (banco)

**Causa:** Backend não consegue conectar ao banco

**Solução:**
```bash
# Verificar DATABASE_URL
docker-compose exec backend env | grep DATABASE_URL

# Testar conexão do servidor
psql -h 82.25.92.217 -p 5432 -U root -d dbrief

# Verificar firewall
ufw status | grep 5432
```

### Erro: Volume mount causando conflito

**Causa:** Código local sobrescrevendo código do build

**Solução:**
```bash
# Usar docker-compose.prod.yml (sem volume mount)
docker-compose -f docker-compose.prod.yml up -d --build

# OU comentar volume mount no docker-compose.yml
```

---

## 🔧 Soluções Rápidas

### Solução 1: Rebuild Completo (Recomendado)

```bash
# Parar tudo
docker-compose down

# Rebuild sem cache
docker-compose build --no-cache

# Iniciar
docker-compose up -d

# Aguardar
sleep 120

# Verificar
docker-compose ps
```

### Solução 2: Usar Versão de Produção

```bash
# Usar docker-compose.prod.yml (sem volume mount)
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d

# Aguardar
sleep 120

# Verificar
docker-compose -f docker-compose.prod.yml ps
```

### Solução 3: Limpar e Recriar

```bash
# Parar e remover tudo
docker-compose down -v

# Remover imagens antigas
docker rmi debrief-backend:latest 2>/dev/null || true

# Rebuild
docker-compose build --no-cache backend

# Iniciar
docker-compose up -d backend

# Aguardar
sleep 120

# Verificar
docker-compose ps backend
docker-compose logs backend | tail -30
```

---

## 📝 Comparação: docker-compose.yml vs docker-compose.prod.yml

### docker-compose.yml (Desenvolvimento)
```yaml
volumes:
  - ./backend/uploads:/app/uploads
  - ./backend:/app  # ✅ Monta código para hot-reload
```

**Uso:** Desenvolvimento local com hot-reload

### docker-compose.prod.yml (Produção)
```yaml
volumes:
  - ./backend/uploads:/app/uploads
  # - ./backend:/app  # ❌ NÃO monta código
```

**Uso:** Produção - código vem do build da imagem

---

## ✅ Checklist de Verificação

- [ ] Logs do backend verificados
- [ ] Erro específico identificado
- [ ] Código no servidor atualizado (git pull)
- [ ] Rebuild do backend executado
- [ ] Volume mount verificado/comentado
- [ ] Backend está "healthy"
- [ ] Frontend consegue iniciar

---

## 🚀 Próximos Passos

1. ✅ **No servidor, executar:**
   ```bash
   ./verificar_logs_backend.sh
   ```

2. ✅ **Identificar o erro específico nos logs**

3. ✅ **Aplicar solução apropriada:**
   - Se for volume mount: usar `docker-compose.prod.yml`
   - Se for erro de código: fazer rebuild
   - Se for banco: verificar conexão
   - Se for dependências: verificar requirements.txt

4. ✅ **Verificar se funcionou:**
   ```bash
   docker-compose ps
   curl http://localhost:2025/health
   ```

---

**✅ Soluções implementadas!**

**🔧 Execute `./verificar_logs_backend.sh` no servidor para identificar o erro específico!**

