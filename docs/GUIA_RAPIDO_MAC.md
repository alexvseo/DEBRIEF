# 🚀 Guia Rápido - Mac Mini

## Início Rápido (3 Passos)

### 1. Diagnóstico

```bash
./scripts/dev/diagnosticar-conexao-mac.sh
```

### 2. Se conexão direta falhar, use túnel SSH

```bash
# Opção A: Automático (recomendado)
./scripts/dev/iniciar-tunel-ssh.sh

# Opção B: Manual
ssh -L 5432:localhost:5432 -N root@82.25.92.217
```

### 3. Iniciar ambiente

```bash
./scripts/dev/iniciar-dev-local.sh
```

O script detecta automaticamente se precisa usar túnel SSH e configura tudo.

## URLs de Acesso

- **Frontend**: http://localhost:5173
- **Backend**: http://localhost:8000/api/docs
- **Health**: http://localhost:8000/health

## Comandos Úteis

```bash
# Parar túnel SSH
./scripts/dev/parar-tunel-ssh.sh

# Ver logs
docker-compose -f docker-compose.dev.yml logs -f

# Parar ambiente
docker-compose -f docker-compose.dev.yml down
```

## Troubleshooting

Se tiver problemas, consulte:
- `docs/SOLUCAO_CONEXAO_MAC.md` - Soluções detalhadas
- `docs/DESENVOLVIMENTO_LOCAL.md` - Documentação completa

