#!/bin/bash
# Script para verificar e converter enum nativo do PostgreSQL para VARCHAR
# Versão melhorada com mais logs e verificações

echo "🔧 Verificando e convertendo enum nativo statusdemanda para VARCHAR..."
echo ""

docker exec debrief-backend python3 << 'PYTHON_SCRIPT'
from app.core.database import SessionLocal
from sqlalchemy import text
import sys

db = SessionLocal()
try:
    print("1️⃣  Verificando estrutura atual da tabela demandas...")
    result = db.execute(text("""
        SELECT column_name, data_type, udt_name
        FROM information_schema.columns
        WHERE table_name = 'demandas' AND column_name = 'status'
    """))
    
    row = result.fetchone()
    if not row:
        print("❌ Coluna 'status' não encontrada na tabela 'demandas'")
        sys.exit(1)
    
    print(f"   Coluna: {row[0]}")
    print(f"   Tipo atual: {row[1]}")
    print(f"   UDT: {row[2]}")
    print()
    
    # Verificar se é enum nativo
    if row[2] == 'statusdemanda':
        print("2️⃣  Enum nativo detectado. Convertendo para VARCHAR...")
        print()
        
        # Verificar se há dados
        result = db.execute(text("SELECT COUNT(*) FROM demandas"))
        count = result.fetchone()[0]
        print(f"   Total de registros: {count}")
        print()
        
        # Passo 1: Adicionar coluna temporária VARCHAR
        print("   Passo 1: Adicionando coluna temporária...")
        try:
            db.execute(text("""
                ALTER TABLE demandas 
                ADD COLUMN status_temp VARCHAR(50)
            """))
            db.commit()
            print("   ✅ Coluna temporária criada")
        except Exception as e:
            if "already exists" in str(e).lower() or "duplicate" in str(e).lower():
                print("   ⚠️  Coluna temporária já existe, continuando...")
                db.rollback()
            else:
                raise
        print()
        
        # Passo 2: Copiar valores (já estão em minúsculo)
        print("   Passo 2: Copiando valores...")
        db.execute(text("""
            UPDATE demandas 
            SET status_temp = status::text
        """))
        db.commit()
        print("   ✅ Valores copiados")
        print()
        
        # Passo 3: Remover coluna antiga
        print("   Passo 3: Removendo coluna antiga...")
        db.execute(text("""
            ALTER TABLE demandas 
            DROP COLUMN status
        """))
        db.commit()
        print("   ✅ Coluna antiga removida")
        print()
        
        # Passo 4: Renomear coluna temporária
        print("   Passo 4: Renomeando coluna...")
        db.execute(text("""
            ALTER TABLE demandas 
            RENAME COLUMN status_temp TO status
        """))
        db.commit()
        print("   ✅ Coluna renomeada")
        print()
        
        # Passo 5: Adicionar NOT NULL constraint
        print("   Passo 5: Adicionando constraint NOT NULL...")
        db.execute(text("""
            ALTER TABLE demandas 
            ALTER COLUMN status SET NOT NULL
        """))
        db.commit()
        print("   ✅ Constraint adicionada")
        print()
        
        # Passo 6: Adicionar índice (se não existir)
        print("   Passo 6: Verificando índice...")
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
            
            if row[1] == 'character varying' or row[2] == 'varchar':
                print("   ✅ Conversão bem-sucedida! Coluna é agora VARCHAR")
            else:
                print(f"   ⚠️  Coluna ainda não é VARCHAR (tipo: {row[1]})")
        print()
        
        # Verificar valores
        result = db.execute(text("""
            SELECT DISTINCT status, COUNT(*) as total
            FROM demandas 
            GROUP BY status
            ORDER BY status
        """))
        
        print("4️⃣  Valores encontrados na coluna:")
        valores = []
        for row in result:
            print(f"   - {row[0]}: {row[1]} registro(s)")
            valores.append(row[0])
        print()
        
        if valores:
            print(f"✅ Conversão concluída com sucesso! {len(valores)} valor(es) único(s) preservado(s)")
        else:
            print("⚠️  Nenhum valor encontrado na coluna")
    else:
        print("ℹ️  Coluna já é VARCHAR ou não é enum nativo")
        print(f"   Tipo atual: {row[1]}, UDT: {row[2]}")
        print("   Nenhuma conversão necessária")
    
except Exception as e:
    print(f"❌ Erro ao converter enum: {e}")
    import traceback
    traceback.print_exc()
    db.rollback()
    sys.exit(1)
finally:
    db.close()
PYTHON_SCRIPT

echo ""
echo "✅ Script concluído!"

