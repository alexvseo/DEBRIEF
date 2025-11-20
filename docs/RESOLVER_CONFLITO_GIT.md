# 🔧 Resolver Conflito Git - docker-compose.yml

**Data:** 19/11/2025  
**Problema:** Erro ao fazer `git pull` - mudanças locais conflitam  
**Status:** ✅ SOLUÇÃO IMPLEMENTADA

---

## 🔴 Problema Identificado

Ao tentar fazer `git pull` no servidor, o Git detecta mudanças locais no `docker-compose.yml` que conflitam com as mudanças remotas.

**Erro:**
```
error: Your local changes to the following files would be overwritten by merge:
        docker-compose.yml
Please commit your changes or stash them before you merge.
```

**Causa:**
- Arquivo `docker-compose.yml` foi modificado localmente no servidor
- Versão remota tem mudanças diferentes
- Git não pode fazer merge automaticamente

---

## ✅ Soluções Implementadas

### 1. Script `resolver-conflito-git.sh`

Script interativo que oferece 3 opções:
1. **Descartar mudanças locais** (recomendado)
2. **Fazer stash** (salvar para depois)
3. **Fazer commit** (manter mudanças locais)

### 2. Atualizar `rebuild-completo.sh`

Script agora resolve conflitos automaticamente antes de fazer pull.

---

## 🚀 Como Resolver no Servidor

### Opção 1: Usar Script Automático (Recomendado)

```bash
ssh root@82.25.92.217
cd ~/debrief

# Executar script de resolução
./resolver-conflito-git.sh
```

O script irá:
1. Mostrar mudanças locais
2. Oferecer opções
3. Resolver conflito
4. Fazer pull
5. Mostrar status final

### Opção 2: Resolver Manualmente (Rápido)

```bash
ssh root@82.25.92.217
cd ~/debrief

# Descartar mudanças locais e usar versão remota
git checkout -- docker-compose.yml
git reset --hard HEAD

# Fazer pull
git pull
```

### Opção 3: Fazer Stash (Se quiser manter mudanças)

```bash
# Salvar mudanças locais
git stash push -m "Mudanças locais antes do pull"

# Fazer pull
git pull

# Se quiser recuperar mudanças depois
git stash pop
```

---

## 🔍 Verificar Mudanças Locais

### Ver o que foi modificado:

```bash
# Ver status
git status

# Ver diferenças
git diff docker-compose.yml

# Ver todas as mudanças
git diff
```

### Decidir o que fazer:

**Se as mudanças locais não são importantes:**
```bash
# Descartar
git checkout -- docker-compose.yml
git pull
```

**Se as mudanças locais são importantes:**
```bash
# Fazer commit primeiro
git add docker-compose.yml
git commit -m "chore: Mudanças locais"
git pull
# Resolver conflitos se houver
```

---

## 📝 Solução Rápida (Recomendada)

Para produção, geralmente queremos usar a versão do repositório:

```bash
# No servidor
cd ~/debrief

# Descartar mudanças locais
git checkout -- docker-compose.yml
git reset --hard HEAD

# Fazer pull
git pull

# Rebuild
./rebuild-completo.sh
```

---

## ✅ Checklist de Resolução

- [ ] Conflito identificado
- [ ] Mudanças locais verificadas
- [ ] Decisão tomada (descartar/stash/commit)
- [ ] Conflito resolvido
- [ ] Pull realizado com sucesso
- [ ] Rebuild executado
- [ ] Sistema funcionando

---

## 🚀 Próximos Passos

1. ✅ **No servidor, executar:**
   ```bash
   ./resolver-conflito-git.sh
   ```

2. ✅ **Ou resolver manualmente:**
   ```bash
   git checkout -- docker-compose.yml
   git pull
   ```

3. ✅ **Depois fazer rebuild:**
   ```bash
   ./rebuild-completo.sh
   ```

---

**✅ Script de resolução criado!**

**🔧 Execute `./resolver-conflito-git.sh` no servidor para resolver o conflito!**

