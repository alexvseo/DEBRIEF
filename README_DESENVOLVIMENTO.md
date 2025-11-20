# 🚀 Início Rápido - Desenvolvimento Local

## Configuração Rápida

### 1. Criar arquivos de ambiente (se ainda não existirem)

```bash
# Backend
cp backend/.env.dev.example backend/.env.dev 2>/dev/null || cat > backend/.env.dev << 'EOF'
DATABASE_URL=postgresql://postgres:Mslestrategia.2025%40@82.25.92.217:5432/dbrief
SECRET_KEY=dev-secret-key-local-change-me
FRONTEND_URL=http://localhost:5173
EOF

# Frontend
cp frontend/.env.dev.example frontend/.env.dev 2>/dev/null || cat > frontend/.env.dev << 'EOF'
VITE_API_URL=http://localhost:8000/api
VITE_ENV=development
EOF
```

### 2. Testar conexão com banco remoto

```bash
./scripts/dev/testar-conexao-banco-remoto.sh
```

### 3. Iniciar ambiente de desenvolvimento

```bash
./scripts/dev/iniciar-dev-local.sh
```

### 4. Acessar aplicação

- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:8000
- **API Docs**: http://localhost:8000/api/docs

## Documentação Completa

Consulte `docs/DESENVOLVIMENTO_LOCAL.md` para documentação detalhada.

