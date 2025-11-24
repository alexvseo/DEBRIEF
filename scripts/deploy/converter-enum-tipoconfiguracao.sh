#!/bin/bash
# Script para converter enum nativo tipoconfiguracao para VARCHAR usando psql diretamente

echo "🔧 Convertendo enum nativo tipoconfiguracao para VARCHAR usando psql..."
echo ""

DB_NAME="dbrief"
DB_USER="postgres"
DB_PASS="Mslestra@2025"

export PGPASSWORD="$DB_PASS"

echo "1️⃣  Verificando estrutura atual da coluna tipo..."
psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
SELECT 
    column_name, 
    data_type, 
    udt_name
FROM information_schema.columns
WHERE table_name = 'configuracoes' AND column_name = 'tipo';
SQL

echo ""
echo "2️⃣  Verificando se é enum nativo..."
ENUM_CHECK=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT udt_name FROM information_schema.columns WHERE table_name = 'configuracoes' AND column_name = 'tipo';")

if [ "$ENUM_CHECK" = "tipoconfiguracao" ]; then
    echo "   ✅ Enum nativo detectado: $ENUM_CHECK"
    echo ""
    
    echo "3️⃣  Verificando total de registros..."
    COUNT=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT COUNT(*) FROM configuracoes;")
    echo "   Total de registros: $COUNT"
    echo ""
    
    echo "4️⃣  Verificando valores atuais..."
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
SELECT DISTINCT tipo, COUNT(*) as total
FROM configuracoes 
GROUP BY tipo
ORDER BY tipo;
SQL
    echo ""
    
    echo "5️⃣  Iniciando conversão..."
    echo ""
    
    echo "   Passo 1: Adicionando coluna temporária VARCHAR..."
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
ALTER TABLE configuracoes 
ADD COLUMN IF NOT EXISTS tipo_temp VARCHAR(50);
SQL
    echo "   ✅ Coluna temporária criada"
    echo ""
    
    echo "   Passo 2: Copiando valores (convertendo para minúsculo)..."
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
UPDATE configuracoes 
SET tipo_temp = LOWER(tipo::text);
SQL
    echo "   ✅ Valores copiados e convertidos para minúsculo"
    echo ""
    
    echo "   Passo 3: Removendo coluna antiga..."
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
ALTER TABLE configuracoes 
DROP COLUMN tipo;
SQL
    echo "   ✅ Coluna antiga removida"
    echo ""
    
    echo "   Passo 4: Renomeando coluna temporária..."
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
ALTER TABLE configuracoes 
RENAME COLUMN tipo_temp TO tipo;
SQL
    echo "   ✅ Coluna renomeada"
    echo ""
    
    echo "   Passo 5: Adicionando constraint NOT NULL..."
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
ALTER TABLE configuracoes 
ALTER COLUMN tipo SET NOT NULL;
SQL
    echo "   ✅ Constraint adicionada"
    echo ""
    
    echo "   Passo 6: Verificando/criando índice..."
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
CREATE INDEX IF NOT EXISTS idx_configuracao_tipo ON configuracoes(tipo);
SQL
    echo "   ✅ Índice verificado/criado"
    echo ""
    
    echo "6️⃣  Verificando estrutura final..."
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
SELECT 
    column_name, 
    data_type, 
    udt_name
FROM information_schema.columns
WHERE table_name = 'configuracoes' AND column_name = 'tipo';
SQL
    echo ""
    
    echo "7️⃣  Verificando valores preservados..."
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
SELECT DISTINCT tipo, COUNT(*) as total
FROM configuracoes 
GROUP BY tipo
ORDER BY tipo;
SQL
    echo ""
    
    echo "✅ Conversão concluída com sucesso!"
else
    echo "   ℹ️  Coluna não é enum nativo (tipo: $ENUM_CHECK)"
    echo "   Nenhuma conversão necessária"
fi

unset PGPASSWORD

echo ""
echo "✅ Script concluído!"

