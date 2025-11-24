#!/bin/bash
# Script para corrigir valores de enum no banco de dados
# Converte valores em minúsculo para maiúsculo no enum statusdemanda

echo "🔧 Corrigindo valores de enum no banco de dados..."
echo ""

docker exec debrief-backend python3 << 'PYTHON_SCRIPT'
from app.core.database import SessionLocal
from sqlalchemy import text

db = SessionLocal()
try:
    # Verificar valores atuais
    print("1️⃣  Verificando valores atuais no banco...")
    result = db.execute(text("""
        SELECT DISTINCT status 
        FROM demandas 
        ORDER BY status
    """))
    valores_atuais = [row[0] for row in result]
    print(f"   Valores encontrados: {valores_atuais}")
    print()
    
    # Mapear valores minúsculos para maiúsculos
    mapeamento = {
        'aberta': 'ABERTA',
        'em_andamento': 'EM_ANDAMENTO',
        'aguardando_cliente': 'AGUARDANDO_CLIENTE',
        'concluida': 'CONCLUIDA',
        'cancelada': 'CANCELADA'
    }
    
    # Corrigir cada valor
    print("2️⃣  Corrigindo valores...")
    for valor_min, valor_maius in mapeamento.items():
        if valor_min in valores_atuais:
            count = db.execute(text("""
                UPDATE demandas 
                SET status = :novo_valor 
                WHERE status = :valor_antigo
            """), {"novo_valor": valor_maius, "valor_antigo": valor_min}).rowcount
            
            if count > 0:
                print(f"   ✅ {count} registro(s) atualizado(s): '{valor_min}' → '{valor_maius}'")
    
    db.commit()
    print()
    
    # Verificar valores após correção
    print("3️⃣  Verificando valores após correção...")
    result = db.execute(text("""
        SELECT DISTINCT status 
        FROM demandas 
        ORDER BY status
    """))
    valores_finais = [row[0] for row in result]
    print(f"   Valores finais: {valores_finais}")
    print()
    
    print("✅ Correção concluída!")
    
except Exception as e:
    print(f"❌ Erro ao corrigir enum: {e}")
    db.rollback()
finally:
    db.close()
PYTHON_SCRIPT

echo ""
echo "✅ Script concluído!"

