# 🔧 Corrigir Carregamento de Secretarias

## ✅ Problema Identificado

A lista de secretarias não estava carregando todas as secretarias do banco de dados.

## 🔧 Correções Aplicadas

1. **Frontend**: Enviar `apenas_ativas` como string `'false'` em vez de boolean `false`
   - Axios pode converter boolean de forma incorreta na URL
   - Enviar como string garante compatibilidade com o backend

2. **Backend**: Melhorar tratamento do parâmetro `apenas_ativas`
   - Garantir que strings sejam convertidas corretamente
   - Tratar caso `None` como padrão `True`

3. **Validação**: Adicionar validação para garantir que resposta é array antes de atualizar estado

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

### Passo 3: Reiniciar serviços
```bash
docker-compose restart backend frontend
```

### Passo 4: Aguardar serviços iniciarem
```bash
sleep 10
docker-compose ps
```

### Passo 5: Executar diagnóstico (opcional)
```bash
./scripts/deploy/diagnosticar-secretarias.sh
```

### Passo 6: Testar
1. Acesse `http://82.25.92.217:2022/configuracoes`
2. Vá para a seção "Gerenciar Secretarias"
3. Verifique se todas as secretarias (ativas e inativas) aparecem na lista

## 🔍 Verificação

### Verificar no console do navegador (F12):
1. Abra o console (F12 → Console)
2. Procure por logs:
   - `🔍 Carregando secretarias com apenas_ativas=false`
   - `✅ Secretarias carregadas: X registros`
   - `📋 Todas as secretarias: [...]`

### Se ainda não carregar:
1. Verifique se há erros no console
2. Verifique a aba Network (F12 → Network)
3. Procure pela requisição `/api/secretarias/`
4. Verifique:
   - Status code (deve ser 200)
   - Query params (deve ter `apenas_ativas=false`)
   - Response (deve conter array de secretarias)

## 📝 O que foi corrigido

- ✅ Parâmetro `apenas_ativas` agora é enviado como string `'false'`
- ✅ Backend trata corretamente o parâmetro `apenas_ativas=false`
- ✅ Validação adicionada para garantir que resposta é array
- ✅ Logs melhorados para debug
- ✅ Script de diagnóstico criado

