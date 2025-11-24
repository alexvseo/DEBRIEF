# 🔍 Diagnóstico: Secretarias não aparecem na listagem

## Problema
- Secretarias não aparecem na listagem
- Erro ao inserir: "já existe para este cliente"
- Secretarias podem estar no banco mas não visíveis

## Soluções Aplicadas

### 1. ✅ Aumentar Limite de Registros
- **Backend:** Limite padrão aumentado de 100 para 1000
- **Backend:** Limite máximo aumentado de 100 para 10000
- **Frontend:** Agora envia `limit: 10000` explicitamente

### 2. ✅ Validação Corrigida
- Validação verifica apenas secretarias **ATIVAS**
- Permite criar secretaria com mesmo nome se a anterior estiver **INATIVA**
- Mensagem de erro agora mostra ID e status da secretaria duplicada

### 3. ✅ Endpoint de Deletar Permanente
- Endpoint `DELETE /api/secretarias/{id}/permanente` adicionado
- Deleta permanentemente do banco (hard delete)
- Verifica se há demandas antes de deletar

## Como Diagnosticar no Servidor

### Passo 1: Verificar Secretarias no Banco

```bash
ssh root@82.25.92.217
cd /root/debrief

# Executar script de verificação
./scripts/deploy/verificar-secretarias-banco.sh
```

Ou manualmente:

```bash
psql -h localhost -U postgres -d dbrief -c "
SELECT 
    id,
    nome,
    cliente_id,
    ativo,
    created_at
FROM secretarias
ORDER BY nome, cliente_id;
"
```

### Passo 2: Verificar Quantidade Total

```bash
psql -h localhost -U postgres -d dbrief -c "
SELECT 
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE ativo = true) as ativas,
    COUNT(*) FILTER (WHERE ativo = false) as inativas
FROM secretarias;
"
```

### Passo 3: Verificar Secretarias por Cliente

```bash
# Substituir CLIENTE_ID pelo ID do cliente
psql -h localhost -U postgres -d dbrief -c "
SELECT 
    s.id,
    s.nome,
    s.ativo,
    c.nome as cliente_nome
FROM secretarias s
JOIN clientes c ON s.cliente_id = c.id
WHERE c.id = 'CLIENTE_ID'
ORDER BY s.nome;
"
```

### Passo 4: Atualizar Código no Servidor

```bash
ssh root@82.25.92.217
cd /root/debrief

# 1. Atualizar código
git pull

# 2. Reiniciar backend
docker-compose restart backend

# 3. Aguardar inicialização
sleep 15

# 4. Verificar logs
docker-compose logs backend | tail -30
```

### Passo 5: Testar API Diretamente

```bash
# Listar todas as secretarias (ativas e inativas)
curl -X GET "http://localhost:8000/api/secretarias/?apenas_ativas=false&limit=10000" \
  -H "Authorization: Bearer SEU_TOKEN"

# Verificar resposta
# Deve retornar todas as secretarias, incluindo inativas
```

## Possíveis Causas

### 1. Limite de Registros (RESOLVIDO)
- **Problema:** Limite padrão de 100 registros
- **Solução:** Aumentado para 1000 padrão, 10000 máximo

### 2. Secretarias Inativas no Banco
- **Problema:** Secretarias inativas não aparecem na listagem
- **Solução:** Frontend agora carrega com `apenas_ativas: false`

### 3. Validação Verificando Inativas
- **Problema:** Validação verificava todas as secretarias (ativas e inativas)
- **Solução:** Validação agora verifica apenas secretarias ATIVAS

### 4. Cache do Frontend
- **Problema:** Frontend pode estar usando cache antigo
- **Solução:** Limpar cache do navegador (Ctrl+Shift+R ou Cmd+Shift+R)

## Próximos Passos

1. ✅ Executar script de verificação no servidor
2. ✅ Atualizar código no servidor (`git pull`)
3. ✅ Reiniciar backend (`docker-compose restart backend`)
4. ✅ Limpar cache do navegador
5. ✅ Testar inserção de nova secretaria

## Se o Problema Persistir

1. Verificar logs do backend:
   ```bash
   docker-compose logs backend | grep -i secretaria
   ```

2. Verificar se há secretarias duplicadas no banco:
   ```bash
   psql -h localhost -U postgres -d dbrief -c "
   SELECT 
       cliente_id,
       nome,
       COUNT(*) as quantidade,
       array_agg(id) as ids,
       array_agg(ativo::text) as status
   FROM secretarias
   GROUP BY cliente_id, nome
   HAVING COUNT(*) > 1;
   "
   ```

3. Se houver duplicatas, deletar as inativas:
   ```bash
   # CUIDADO: Isso deleta permanentemente secretarias inativas duplicadas
   psql -h localhost -U postgres -d dbrief -c "
   DELETE FROM secretarias
   WHERE id IN (
       SELECT id
       FROM (
           SELECT id,
                  ROW_NUMBER() OVER (PARTITION BY cliente_id, nome ORDER BY created_at DESC) as rn
           FROM secretarias
           WHERE ativo = false
       ) t
       WHERE rn > 1
   );
   "
   ```

