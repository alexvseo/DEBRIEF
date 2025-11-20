#!/bin/bash
# Script para converter enum nativo do PostgreSQL para VARCHAR
# Isso resolve o problema de incompatibilidade entre enum nativo e TypeDecorator

echo "🔧 Convertendo enum nativo statusdemanda para VARCHAR..."
echo ""

docker exec debrief-backend python3 << 'PYTHON_SCRIPT'
from app.core.database import SessionLocal
from sqlalchemy import text

db = SessionLocal()
try:
    print("1️⃣  Verificando estrutura atual da tabela demandas...")
    result = db.execute(text("""
        SELECT column_name, data_type, udt_name
        FROM information_schema.columns
        WHERE table_name = 'demandas' AND column_name = 'status'
    """))
    
    row = result.fetchone()
    if row:
        print(f"   Coluna: {row[0]}")
        print(f"   Tipo atual: {row[1]}")
        print(f"   UDT: {row[2]}")
        print()
    
    # Verificar se é enum nativo
    if row and row[2] == 'statusdemanda':
        print("2️⃣  Enum nativo detectado. Convertendo para VARCHAR...")
        print()
        
        # Passo 1: Adicionar coluna temporária VARCHAR
        print("   Adicionando coluna temporária...")
        db.execute(text("""
            ALTER TABLE demandas 
            ADD COLUMN status_temp VARCHAR(50)
        """))
        db.commit()
        print("   ✅ Coluna temporária criada")
        print()
        
        # Passo 2: Copiar valores (já estão em minúsculo)
        print("   Copiando valores...")
        db.execute(text("""
            UPDATE demandas 
            SET status_temp = status::text
        """))
        db.commit()
        print("   ✅ Valores copiados")
        print()
        
        # Passo 3: Remover coluna antiga
        print("   Removendo coluna antiga...")
        db.execute(text("""
            ALTER TABLE demandas 
            DROP COLUMN status
        """))
        db.commit()
        print("   ✅ Coluna antiga removida")
        print()
        
        # Passo 4: Renomear coluna temporária
        print("   Renomeando coluna...")
        db.execute(text("""
            ALTER TABLE demandas 
            RENAME COLUMN status_temp TO status
        """))
        db.commit()
        print("   ✅ Coluna renomeada")
        print()
        
        # Passo 5: Adicionar NOT NULL constraint
        print("   Adicionando constraint NOT NULL...")
        db.execute(text("""
            ALTER TABLE demandas 
            ALTER COLUMN status SET NOT NULL
        """))
        db.commit()
        print("   ✅ Constraint adicionada")
        print()
        
        # Passo 6: Adicionar índice (se não existir)
        print("   Verificando índice...")
        result = db.execute(text("""
            SELECT indexname 
            FROM pg_indexes 
            WHERE tablename = 'demandas' AND indexname LIKE '%status%'
        """))
        
        if not result.fetchone():
            print("   Criando índice...")
            db.execute(text("""
                CREATE INDEX idx_demandas_status ON demandas(status)
            """))
            db.commit()
            print("   ✅ Índice criado")
        else:
            print("   ✅ Índice já existe")
        print()
        
        print("3️⃣  Verificando estrutura final...")
        result = db.execute(text("""
            SELECT column_name, data_type, udt_name
            FROM information_schema.columns
            WHERE table_name = 'demandas' AND column_name = 'status'
        """))
        
        row = result.fetchone()
        if row:
            print(f"   Coluna: {row[0]}")
            print(f"   Tipo final: {row[1]}")
            print(f"   UDT: {row[2]}")
            print()
        
        # Verificar valores
        result = db.execute(text("""
            SELECT DISTINCT status, COUNT(*) as total
            FROM demandas 
            GROUP BY status
            ORDER BY status
        """))
        
        print("4️⃣  Valores encontrados na coluna:")
        for row in result:
            print(f"   - {row[0]}: {row[1]} registro(s)")
        print()
        
        print("✅ Conversão concluída com sucesso!")
    else:
        print("⚠️  Coluna já é VARCHAR ou não é enum nativo")
        print("   Nenhuma conversão necessária")
    
except Exception as e:
    print(f"❌ Erro ao converter enum: {e}")
    import traceback
    traceback.print_exc()
    db.rollback()
finally:
    db.close()
PYTHON_SCRIPT

echo ""
echo "✅ Script concluído!"

