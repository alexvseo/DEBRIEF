# 🧹 Limpar Cache do Servidor

## 🚀 Comando Rápido

Execute no servidor:

```bash
cd /root/debrief
./scripts/deploy/limpar-cache-frontend.sh
```

## 📋 Passos Manuais

Se preferir fazer manualmente:

```bash
# 1. Fazer pull das alterações
git pull

# 2. Parar frontend
docker-compose stop frontend

# 3. Remover container
docker-compose rm -f frontend

# 4. Remover imagem
docker rmi debrief-frontend:latest

# 5. Reconstruir sem cache
docker-compose build --no-cache frontend

# 6. Iniciar frontend
docker-compose up -d frontend

# 7. Verificar status
docker-compose ps frontend
```

## 🌐 Limpar Cache do Navegador

### Chrome/Edge:
- **Windows/Linux:** `Ctrl + Shift + R` ou `Ctrl + F5`
- **Mac:** `Cmd + Shift + R`
- Ou: DevTools (F12) → Network → Marcar "Disable cache" → Recarregar

### Firefox:
- **Windows/Linux:** `Ctrl + Shift + R` ou `Ctrl + F5`
- **Mac:** `Cmd + Shift + R`
- Ou: DevTools (F12) → Network → Marcar "Disable cache" → Recarregar

### Safari:
- **Mac:** `Cmd + Option + R`
- Ou: Menu → Desenvolver → Limpar Caches

### Modo Anônimo/Privado:
- Abra uma janela anônima/privada e acesse `http://82.25.92.217:2022`

## 🔍 Verificar se Funcionou

1. Abra o DevTools (F12)
2. Vá para a aba **Network**
3. Recarregue a página (Ctrl+Shift+R)
4. Verifique se os arquivos JavaScript têm timestamp novo
5. Verifique se a estrutura de secretarias está agrupada por cliente

## 🐛 Se Ainda Não Funcionar

### Verificar se o frontend foi reconstruído:

```bash
# Ver logs do frontend
docker-compose logs frontend --tail 50

# Verificar se o container está rodando
docker-compose ps frontend

# Verificar se o arquivo foi atualizado
docker-compose exec frontend ls -la /usr/share/nginx/html/ | head -20
```

### Forçar rebuild completo:

```bash
# Parar tudo
docker-compose down

# Remover todas as imagens
docker rmi debrief-frontend:latest debrief-backend:latest 2>/dev/null

# Reconstruir tudo
docker-compose build --no-cache

# Iniciar tudo
docker-compose up -d

# Verificar
docker-compose ps
```

