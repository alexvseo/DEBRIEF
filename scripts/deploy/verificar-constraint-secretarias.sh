#!/bin/bash

# Script para verificar constraints de unicidade na tabela secretarias

echo "🔍 Verificando constraints na tabela secretarias"
echo ""

DB_NAME="dbrief"
DB_USER="postgres"
DB_PASS="Mslestrategia.2025@"

export PGPASSWORD="$DB_PASS"

echo "1️⃣  Verificando constraints existentes..."
psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
SELECT
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'secretarias'::regclass
ORDER BY contype, conname;
SQL

echo ""
echo "2️⃣  Verificando índices únicos..."
psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'secretarias'
AND indexdef LIKE '%UNIQUE%';
SQL

echo ""
echo "3️⃣  Verificando duplicatas por cliente (ignorando acentuação)..."
psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
-- Buscar secretarias ativas com nomes similares (mesmo cliente)
SELECT 
    s1.cliente_id,
    c.nome AS cliente_nome,
    s1.id AS secretaria1_id,
    s1.nome AS secretaria1_nome,
    s2.id AS secretaria2_id,
    s2.nome AS secretaria2_nome,
    s1.ativo AS secretaria1_ativo,
    s2.ativo AS secretaria2_ativo
FROM secretarias s1
INNER JOIN secretarias s2 ON s1.cliente_id = s2.cliente_id AND s1.id < s2.id
INNER JOIN clientes c ON s1.cliente_id = c.id
WHERE 
    -- Comparar nomes normalizados (removendo acentos e convertendo para minúsculo)
    LOWER(TRANSLATE(s1.nome, 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ', 'aaaaaeeeeiiiioooouuuucAAAAAEEEEIIIIOOOOUUUUC')) = 
    LOWER(TRANSLATE(s2.nome, 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ'))
    AND s1.ativo = true
    AND s2.ativo = true
ORDER BY c.nome, s1.nome;
SQL

echo ""
echo "4️⃣  Verificando estrutura da tabela..."
psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_NAME" << 'SQL'
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'secretarias'
ORDER BY ordinal_position;
SQL

echo ""
echo "✅ Verificação concluída"
echo ""
echo "💡 Se não houver constraint de unicidade, o sistema usa validação no backend."
echo "   A validação no backend verifica nomes equivalentes (ignorando acentuação)."

unset PGPASSWORD

