# 🔧 Converter Enum Nativo para VARCHAR - AGORA

## ✅ Problema Identificado

O erro persiste porque:
- O banco tem **enum nativo do PostgreSQL** (`statusdemanda`) com valores em minúsculo
- O SQLAlchemy detecta o enum nativo e tenta usá-lo diretamente
- O TypeDecorator só funciona quando a coluna é **VARCHAR**, não enum nativo
- Resultado: `LookupError` ao ler e `InvalidTextRepresentation` ao escrever

## ✅ Solução

Converter o enum nativo para VARCHAR no banco de dados.

## 🚀 Aplicar no Servidor

Execute no servidor:

```bash
ssh root@82.25.92.217
cd /root/debrief

# 1. Atualizar código (pegar o script)
git pull

# 2. Executar script de conversão
./scripts/deploy/converter-enum-para-varchar.sh

# 3. Reiniciar backend
docker-compose restart backend

# 4. Aguardar inicialização
sleep 15

# 5. Verificar logs (não deve ter erros)
docker-compose logs backend | grep -E "LookupError|InvalidTextRepresentation|ERROR" | tail -20

# 6. Testar endpoint de secretarias
TOKEN=$(curl -s -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

curl -X GET "http://localhost:8000/api/secretarias/?apenas_ativas=false" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" | jq .

# 7. Verificar logs recentes
docker-compose logs backend | tail -30
```

## ✅ O Que o Script Faz

1. **Verifica** se a coluna é enum nativo
2. **Cria** coluna temporária VARCHAR
3. **Copia** valores existentes (preserva dados)
4. **Remove** coluna antiga (enum nativo)
5. **Renomeia** coluna temporária para `status`
6. **Adiciona** constraints (NOT NULL, índice)
7. **Verifica** estrutura final

## 🔍 Verificar se Funcionou

1. **Logs do backend:**
   ```bash
   docker-compose logs backend | grep -E "LookupError|InvalidTextRepresentation" | tail -20
   ```
   Não deve ter erros.

2. **Estrutura do banco:**
   ```bash
   docker exec debrief-backend python3 << 'PYTHON'
   from app.core.database import SessionLocal
   from sqlalchemy import text
   db = SessionLocal()
   result = db.execute(text("""
       SELECT column_name, data_type, udt_name
       FROM information_schema.columns
       WHERE table_name = 'demandas' AND column_name = 'status'
   """))
   row = result.fetchone()
   print(f"Tipo: {row[1]}, UDT: {row[2]}")
   # Deve mostrar: Tipo: character varying, UDT: varchar
   db.close()
   PYTHON
   ```

3. **Testar no frontend:**
   - Acesse: http://82.25.92.217:2022/configuracoes
   - As secretarias devem aparecer na lista
   - Não deve aparecer erro "Erro no servidor"

## ⚠️ Importante

- O script **preserva todos os dados** existentes
- A conversão é **irreversível** (enum nativo é removido)
- Se houver erro, o script faz rollback automático
- Faça backup antes se necessário (mas o script é seguro)

## 📋 Após Conversão

Após a conversão bem-sucedida:
- O TypeDecorator funcionará corretamente
- Não haverá mais erros de `LookupError`
- Não haverá mais erros de `InvalidTextRepresentation`
- As secretarias aparecerão corretamente no frontend

