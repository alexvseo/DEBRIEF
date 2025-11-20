#!/bin/bash
# Script para verificar secretarias no banco de dados

echo "🔍 Verificando secretarias no banco de dados..."
echo ""

docker exec debrief-backend python3 << 'PYTHON_SCRIPT'
from app.core.database import SessionLocal
from app.models import Secretaria

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
echo "✅ Verificação concluída!"

