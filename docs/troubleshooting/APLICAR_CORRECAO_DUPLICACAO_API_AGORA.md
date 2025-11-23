# 🔧 Aplicar Correção de Duplicação de /api

## ✅ Problema Corrigido

O frontend estava fazendo requisições para `/api/api/...` em vez de `/api/...` porque algumas chamadas estavam usando `/api/` manualmente, quando o `baseURL` do axios já inclui `/api`.

## 🚀 Como Aplicar no Servidor

### Passo 1: Atualizar código
```bash
cd ~/debrief
git pull
```

### Passo 2: Rebuild do frontend
```bash
docker-compose build --no-cache frontend
```

### Passo 3: Reiniciar frontend
```bash
docker-compose restart frontend
```

### Passo 4: Aguardar frontend iniciar
```bash
sleep 10
docker-compose logs frontend | tail -20
```

### Passo 5: Testar
Acesse `http://82.25.92.217:2022/configuracoes` e verifique se a página carrega corretamente sem erros 404.

## 🔍 Verificação

Execute no servidor:
```bash
# Verificar se ainda há requisições para /api/api/...
docker-compose logs caddy | grep "/api/api" | tail -10
```

Se não aparecer nenhuma linha, a correção funcionou! ✅

## 📝 O que foi corrigido

- `Configuracoes.jsx`: Removido `/api/` de 5 chamadas
- `GerenciarUsuarios.jsx`: Removido `/api/` de 3 chamadas
- Todas as chamadas agora usam caminhos relativos (sem `/api/`)
- O `baseURL` do axios (`/api`) adiciona o prefixo automaticamente

