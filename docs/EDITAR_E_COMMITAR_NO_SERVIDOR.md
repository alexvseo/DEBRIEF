# 📝 Editar e Fazer Commit Direto no Servidor

Este guia explica como editar arquivos e fazer commits Git diretamente no servidor.

---

## 🎯 Quando Usar

- Correções rápidas no servidor
- Ajustes de configuração
- Testes diretos
- **⚠️ Cuidado:** Sempre faça `git pull` antes de editar para evitar conflitos

---

## 📋 Passo a Passo

### 1. Conectar ao Servidor

```bash
ssh root@82.25.92.217
cd /root/debrief
```

### 2. Atualizar Código (IMPORTANTE!)

```bash
# Sempre atualize antes de editar
git pull origin main
```

### 3. Editar Arquivo

```bash
# Usar nano (mais simples)
nano docker-compose.yml

# OU usar vim
vim docker-compose.yml

# OU usar cat e redirecionamento
cat > arquivo.txt << 'EOF'
conteúdo aqui
EOF
```

### 4. Verificar Mudanças

```bash
# Ver o que mudou
git status

# Ver diferenças
git diff
```

### 5. Adicionar Arquivos

```bash
# Adicionar arquivo específico
git add docker-compose.yml

# OU adicionar todos os arquivos modificados
git add .
```

### 6. Fazer Commit

```bash
git commit -m "🔧 fix: Descrição da correção"
```

### 7. Fazer Push

```bash
git push origin main
```

---

## 🔧 Exemplo Prático: Corrigir DATABASE_URL

```bash
# 1. Conectar
ssh root@82.25.92.217
cd /root/debrief

# 2. Atualizar
git pull

# 3. Editar
nano docker-compose.yml

# 4. Procurar linha com DATABASE_URL e alterar:
# DE: localhost:5432
# PARA: host.docker.internal:5432

# 5. Salvar (Ctrl+O, Enter, Ctrl+X no nano)

# 6. Verificar
grep DATABASE_URL docker-compose.yml

# 7. Adicionar
git add docker-compose.yml

# 8. Commit
git commit -m "🔧 fix: Corrigir DATABASE_URL para host.docker.internal"

# 9. Push
git push origin main

# 10. Aplicar mudança
docker-compose restart backend
```

---

## 🚀 Comandos Rápidos

### Editar e Commit Rápido

```bash
# Editar arquivo
nano arquivo.txt

# Adicionar, commit e push em um comando
git add arquivo.txt && \
git commit -m "🔧 fix: Correção rápida" && \
git push origin main
```

### Ver Status e Diferenças

```bash
# Status
git status

# Diferenças
git diff

# Log recente
git log --oneline -5
```

### Desfazer Mudanças (se necessário)

```bash
# Descartar mudanças não commitadas
git checkout -- arquivo.txt

# OU descartar tudo
git checkout -- .
```

---

## ⚠️ Boas Práticas

1. **Sempre faça `git pull` antes de editar**
2. **Teste as mudanças antes de commitar**
3. **Use mensagens de commit descritivas**
4. **Evite editar muitos arquivos de uma vez**
5. **Faça commits pequenos e frequentes**

---

## 🔍 Verificar Configuração Git

```bash
# Ver configuração
git config --list

# Configurar usuário (se necessário)
git config user.name "Seu Nome"
git config user.email "seu@email.com"
```

---

## 📚 Exemplos de Mensagens de Commit

```bash
# Correção
git commit -m "🔧 fix: Corrigir conexão com banco de dados"

# Nova funcionalidade
git commit -m "✨ feat: Adicionar endpoint de relatórios"

# Documentação
git commit -m "📝 docs: Atualizar guia de instalação"

# Configuração
git commit -m "⚙️ config: Atualizar variáveis de ambiente"
```

---

## 🆘 Resolver Conflitos

Se houver conflito ao fazer `git pull`:

```bash
# Ver conflitos
git status

# Abortar merge
git merge --abort

# OU resolver manualmente
# Editar arquivos com conflitos (procure por <<<<<<<)
# Depois:
git add .
git commit -m "🔧 fix: Resolver conflitos"
```

---

## ✅ Checklist

Antes de fazer commit:

- [ ] Fiz `git pull` para atualizar
- [ ] Testei as mudanças
- [ ] Verifiquei com `git status`
- [ ] Mensagem de commit é clara
- [ ] Apenas arquivos necessários foram modificados

---

## 🎉 Pronto!

Agora você pode editar e commitar diretamente no servidor. Lembre-se de sempre fazer `git pull` antes de editar para evitar conflitos!

