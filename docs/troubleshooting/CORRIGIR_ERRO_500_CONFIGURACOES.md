# 🔧 Corrigir Erro 500 no Endpoint de Configurações

## 📋 Problema Identificado

O endpoint `/api/configuracoes/agrupadas` estava retornando erro 500, provavelmente devido a:
1. Erro ao descriptografar valores sensíveis (falta de `ENCRYPTION_KEY` ou chave incorreta)
2. Falta de tratamento de erros ao processar configurações individuais

## ✅ Correções Aplicadas

### 1. **Backend** (`backend/app/models/configuracao.py`)
- Melhorado o método `get_valor()` para tratar erros de descriptografia de forma mais robusta
- Adicionado fallback para retornar valor vazio se descriptografia falhar
- Adicionado logging de warnings quando descriptografia falha

### 2. **Backend** (`backend/app/api/endpoints/configuracoes.py`)
- Adicionado tratamento de erros individual para cada configuração
- Se uma configuração falhar ao ser processada, ela é pulada ou adicionada sem valor
- Adicionado logging de erros para facilitar diagnóstico
- Garantido que o endpoint sempre retorna uma resposta válida, mesmo se algumas configurações falharem

### 3. **Script de Diagnóstico** (`scripts/deploy/verificar-erro-500-configuracoes.sh`)
- Criado script para diagnosticar erros 500 no endpoint de configurações
- Verifica logs do backend
- Testa o endpoint diretamente
- Verifica configurações no banco de dados
- Verifica se `ENCRYPTION_KEY` está configurada

## 🚀 Como Aplicar no Servidor

```bash
# 1. Fazer pull das alterações
git pull

# 2. Reconstruir e reiniciar containers
docker-compose down
docker-compose build --no-cache backend
docker-compose up -d

# 3. Aguardar containers ficarem healthy
docker-compose ps

# 4. Executar diagnóstico
./scripts/deploy/verificar-erro-500-configuracoes.sh
```

## 🔍 Verificar no Navegador

1. Abra o DevTools (F12)
2. Vá para a aba **Network**
3. Recarregue a página de Configurações
4. Procure por requisições para `/api/configuracoes/agrupadas`
5. Verifique:
   - ✅ Status code é `200` (não `500`)
   - ✅ Response contém um array de grupos de configurações

## 🐛 Se Ainda Houver Erro 500

### Verificar Logs do Backend

```bash
docker-compose logs backend --tail 200 | grep -iE "(error|exception|traceback|configuracao)"
```

### Verificar ENCRYPTION_KEY

```bash
# Verificar se está configurada no docker-compose.yml
grep ENCRYPTION_KEY docker-compose.yml

# Verificar se está disponível no container
docker-compose exec backend python -c "import os; print('ENCRYPTION_KEY:', 'SIM' if os.getenv('ENCRYPTION_KEY') else 'NÃO')"
```

### Se ENCRYPTION_KEY não estiver configurada

O sistema gerará uma chave temporária, mas isso pode causar problemas se houver valores já criptografados com outra chave. Nesse caso:

1. **Opção 1:** Configurar `ENCRYPTION_KEY` no `docker-compose.yml`
2. **Opção 2:** Recriar as configurações sensíveis (elas serão descriptografadas com a nova chave)

## 📝 Notas

- O endpoint agora é mais resiliente a erros individuais
- Configurações que falharem ao ser processadas serão puladas ou adicionadas sem valor
- Logs de erro são registrados para facilitar diagnóstico
- O frontend continuará funcionando mesmo se algumas configurações não puderem ser descriptografadas

