#!/bin/bash
# Script para converter enum nativo para VARCHAR usando psql diretamente
# Mais confiável que Python dentro do container

echo "🔧 Convertendo enum nativo statusdemanda para VARCHAR usando psql..."
echo ""

DB_NAME="dbrief"
DB_USER="postgres"
DB_PASS="Mslestrategia.2025@"

export PGPASSWORD="$DB_PASS"

echo "1️⃣  Verificando estrutura atual da coluna status..."
psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
SELECT 
    column_name, 
    data_type, 
    udt_name
FROM information_schema.columns
WHERE table_name = 'demandas' AND column_name = 'status';
SQL

echo ""
echo "2️⃣  Verificando se é enum nativo..."
ENUM_CHECK=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT udt_name FROM information_schema.columns WHERE table_name = 'demandas' AND column_name = 'status';")

if [ "$ENUM_CHECK" = "statusdemanda" ]; then
    echo "   ✅ Enum nativo detectado: $ENUM_CHECK"
    echo ""
    
    echo "3️⃣  Verificando total de registros..."
    COUNT=$(psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT COUNT(*) FROM demandas;")
    echo "   Total de registros: $COUNT"
    echo ""
    
    echo "4️⃣  Iniciando conversão..."
    echo ""
    
    echo "   Passo 1: Adicionando coluna temporária VARCHAR..."
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
ALTER TABLE demandas 
ADD COLUMN IF NOT EXISTS status_temp VARCHAR(50);
SQL
    echo "   ✅ Coluna temporária criada"
    echo ""
    
    echo "   Passo 2: Copiando valores..."
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
UPDATE demandas 
SET status_temp = status::text;
SQL
    echo "   ✅ Valores copiados"
    echo ""
    
    echo "   Passo 3: Removendo coluna antiga..."
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
ALTER TABLE demandas 
DROP COLUMN status;
SQL
    echo "   ✅ Coluna antiga removida"
    echo ""
    
    echo "   Passo 4: Renomeando coluna temporária..."
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
ALTER TABLE demandas 
RENAME COLUMN status_temp TO status;
SQL
    echo "   ✅ Coluna renomeada"
    echo ""
    
    echo "   Passo 5: Adicionando constraint NOT NULL..."
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
ALTER TABLE demandas 
ALTER COLUMN status SET NOT NULL;
SQL
    echo "   ✅ Constraint adicionada"
    echo ""
    
    echo "   Passo 6: Verificando/criando índice..."
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
CREATE INDEX IF NOT EXISTS idx_demandas_status ON demandas(status);
SQL
    echo "   ✅ Índice verificado/criado"
    echo ""
    
    echo "5️⃣  Verificando estrutura final..."
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
SELECT 
    column_name, 
    data_type, 
    udt_name
FROM information_schema.columns
WHERE table_name = 'demandas' AND column_name = 'status';
SQL
    echo ""
    
    echo "6️⃣  Verificando valores preservados..."
    psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
SELECT DISTINCT status, COUNT(*) as total
FROM demandas 
GROUP BY status
ORDER BY status;
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

