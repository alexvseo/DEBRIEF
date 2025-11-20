#!/bin/bash
# Script para diagnosticar problemas com secretarias

echo "🔍 Diagnosticando problemas com secretarias..."
echo ""

echo "1️⃣  Verificando secretarias no banco..."
docker exec debrief-backend python3 << 'PYTHON_SCRIPT'
from app.core.database import SessionLocal
from app.models import Secretaria, Cliente

db = SessionLocal()
try:
    secretarias = db.query(Secretaria).all()
    print(f'Total de secretarias: {len(secretarias)}')
    print()
    
    if len(secretarias) == 0:
        print('⚠️  Nenhuma secretaria encontrada no banco de dados')
    else:
        for s in secretarias:
            cliente_nome = s.cliente.nome if s.cliente else "N/A"
            print(f'  - {s.nome}')
            print(f'    Cliente: {cliente_nome}')
            print(f'    Ativo: {s.ativo}')
            print(f'    ID: {s.id}')
            print()
finally:
    db.close()
PYTHON_SCRIPT

echo ""
echo "2️⃣  Verificando demandas no banco..."
docker exec debrief-backend python3 << 'PYTHON_SCRIPT'
from app.core.database import SessionLocal
from sqlalchemy import text

db = SessionLocal()
try:
    # Verificar valores de status
    result = db.execute(text("""
        SELECT DISTINCT status, COUNT(*) as total
        FROM demandas 
        GROUP BY status
        ORDER BY status
    """))
    
    print("Valores de status encontrados:")
    for row in result:
        print(f"  - {row[0]}: {row[1]} demanda(s)")
    
    # Verificar se há demandas vinculadas a secretarias
    result = db.execute(text("""
        SELECT secretaria_id, COUNT(*) as total
        FROM demandas 
        WHERE secretaria_id IS NOT NULL
        GROUP BY secretaria_id
    """))
    
    print()
    print("Demandas por secretaria:")
    for row in result:
        print(f"  - Secretaria ID {row[0]}: {row[1]} demanda(s)")
    
finally:
    db.close()
PYTHON_SCRIPT

echo ""
echo "3️⃣  Testando endpoint de secretarias..."
echo ""
echo "⚠️  Para testar o endpoint, você precisa de um token válido."
echo "   Execute: curl -X GET http://localhost:8000/api/secretarias/ -H 'Authorization: Bearer SEU_TOKEN'"
echo ""

echo "✅ Diagnóstico concluído!"

