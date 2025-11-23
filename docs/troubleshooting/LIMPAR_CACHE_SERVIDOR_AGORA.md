# 🧹 Limpar Cache do Frontend no Servidor

## ⚡ Comando Rápido

```bash
./scripts/deploy/limpar-cache-frontend.sh
```

## 📋 Passos Manuais

Se preferir executar manualmente:

```bash
# 1. Parar e remover container
docker-compose stop frontend
docker-compose rm -f frontend

# 2. Remover imagem antiga
docker rmi debrief-frontend:latest 2>/dev/null || true

# 3. Reconstruir sem cache
docker-compose build --no-cache frontend

# 4. Iniciar container
docker-compose up -d frontend

# 5. Verificar status
docker-compose ps frontend
```

## 🌐 Limpar Cache do Navegador

Após executar o script, **limpe o cache do navegador**:

- **Chrome/Edge**: `Ctrl+Shift+R` (Windows/Linux) ou `Cmd+Shift+R` (Mac)
- **Firefox**: `Ctrl+F5` (Windows/Linux) ou `Cmd+Shift+R` (Mac)
- **Safari**: `Cmd+Option+R`

Ou use o modo anônimo/privado para testar.

## ✅ Verificação

Após limpar o cache, verifique se:
- O botão "Relatórios" aparece no Dashboard (apenas para Master)
- Os botões estão menores (h-16 em vez de h-20)
- A ordem está correta: Nova Demanda → Minhas Demandas → Meu Perfil → Relatórios → Configurações

