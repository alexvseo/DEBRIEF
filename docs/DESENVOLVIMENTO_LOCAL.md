# 🛠️ Desenvolvimento Local

Este guia explica como configurar e usar o ambiente de desenvolvimento local conectado ao banco de dados remoto do servidor.

## 📋 Pré-requisitos

- Docker e Docker Compose instalados
- Acesso à internet (para conectar ao banco remoto)
- Portas 8000 e 5173 livres no seu computador
- Acesso ao banco de dados remoto (82.25.92.217:5432)

## 🚀 Início Rápido

### 1. Testar Conexão com Banco Remoto

Antes de iniciar, teste se consegue conectar ao banco de dados:

```bash
./scripts/dev/testar-conexao-banco-remoto.sh
```

Este script verifica:
- Se a porta 5432 está acessível
- Se as credenciais estão corretas
- Se o banco de dados existe e tem as tabelas necessárias

### 2. Iniciar Ambiente de Desenvolvimento

```bash
./scripts/dev/iniciar-dev-local.sh
```

Este script:
- Testa a conexão com o banco remoto
- Verifica se as portas estão livres
- Constrói as imagens Docker (se necessário)
- Inicia os containers
- Verifica se os serviços estão respondendo

### 3. Acessar a Aplicação

Após iniciar, acesse:

- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:8000
- **Documentação API**: http://localhost:8000/api/docs
- **Health Check**: http://localhost:8000/api/health

## 📁 Estrutura de Arquivos

### Arquivos de Configuração

- `docker-compose.dev.yml` - Configuração Docker para desenvolvimento
- `backend/.env.dev` - Variáveis de ambiente do backend (não versionado)
- `frontend/.env.dev` - Variáveis de ambiente do frontend (não versionado)

### Scripts

- `scripts/dev/testar-conexao-banco-remoto.sh` - Testa conexão com banco
- `scripts/dev/iniciar-dev-local.sh` - Inicia ambiente de desenvolvimento

## ⚙️ Configuração Detalhada

### Backend

O backend está configurado para:

- **Porta**: 8000
- **Banco de Dados**: `postgresql://postgres:Mslestrategia.2025%40@82.25.92.217:5432/dbrief`
- **Hot Reload**: Habilitado (código montado como volume)
- **CORS**: Permite `http://localhost:5173`

### Frontend

O frontend está configurado para:

- **Porta**: 5173 (Vite padrão)
- **API URL**: `http://localhost:8000/api`
- **Hot Reload**: Habilitado (código montado como volume)

## 🔧 Comandos Úteis

### Ver Logs

```bash
# Todos os serviços
docker-compose -f docker-compose.dev.yml logs -f

# Apenas backend
docker-compose -f docker-compose.dev.yml logs -f backend

# Apenas frontend
docker-compose -f docker-compose.dev.yml logs -f frontend
```

### Parar Ambiente

```bash
docker-compose -f docker-compose.dev.yml down
```

### Reiniciar Serviços

```bash
# Reiniciar todos
docker-compose -f docker-compose.dev.yml restart

# Reiniciar apenas backend
docker-compose -f docker-compose.dev.yml restart backend

# Reiniciar apenas frontend
docker-compose -f docker-compose.dev.yml restart frontend
```

### Reconstruir Imagens

```bash
# Reconstruir todas as imagens
docker-compose -f docker-compose.dev.yml build --no-cache

# Reconstruir apenas backend
docker-compose -f docker-compose.dev.yml build --no-cache backend

# Reconstruir apenas frontend
docker-compose -f docker-compose.dev.yml build --no-cache frontend
```

### Acessar Container

```bash
# Backend
docker exec -it debrief-backend-dev bash

# Frontend
docker exec -it debrief-frontend-dev sh
```

## 🐛 Troubleshooting

### Porta já em uso

Se a porta 8000 ou 5173 estiver em uso:

```bash
# Verificar qual processo está usando a porta
lsof -i :8000
lsof -i :5173

# Parar o processo (substitua PID pelo número do processo)
kill -9 PID
```

### Backend não conecta ao banco

1. Verifique a conexão com o banco:
   ```bash
   ./scripts/dev/testar-conexao-banco-remoto.sh
   ```

2. Verifique os logs do backend:
   ```bash
   docker-compose -f docker-compose.dev.yml logs backend
   ```

3. Verifique se o firewall permite conexão com 82.25.92.217:5432

### Frontend não conecta ao backend

1. Verifique se o backend está rodando:
   ```bash
   curl http://localhost:8000/api/health
   ```

2. Verifique a variável `VITE_API_URL` no `frontend/.env.dev`

3. Verifique os logs do frontend:
   ```bash
   docker-compose -f docker-compose.dev.yml logs frontend
   ```

### Hot Reload não funciona

1. Verifique se os volumes estão montados corretamente:
   ```bash
   docker-compose -f docker-compose.dev.yml config
   ```

2. Verifique permissões dos arquivos:
   ```bash
   ls -la backend/
   ls -la frontend/
   ```

### Erro de permissão no Docker

No Linux/Mac, pode ser necessário ajustar permissões:

```bash
sudo chown -R $USER:$USER backend/ frontend/
```

## ⚠️ Avisos Importantes

### Banco de Dados de Produção

**ATENÇÃO**: O ambiente de desenvolvimento está conectado ao banco de dados de **PRODUÇÃO**!

- Todas as alterações afetarão dados reais
- Tenha cuidado ao criar, editar ou deletar registros
- Considere usar um banco local para testes mais arriscados

### Segurança

- Os arquivos `.env.dev` contêm credenciais e **NÃO** devem ser commitados
- Mantenha as credenciais seguras
- Não compartilhe arquivos `.env.dev`

### Performance

- A conexão remota pode ser mais lenta que um banco local
- Operações de banco podem ter latência maior
- Considere usar um banco local para testes de performance

## 🔄 Fluxo de Trabalho Recomendado

1. **Antes de começar**:
   ```bash
   git pull origin main
   ./scripts/dev/testar-conexao-banco-remoto.sh
   ```

2. **Iniciar ambiente**:
   ```bash
   ./scripts/dev/iniciar-dev-local.sh
   ```

3. **Desenvolver**:
   - Faça alterações no código
   - Hot reload atualizará automaticamente
   - Teste no navegador (http://localhost:5173)

4. **Antes de commitar**:
   ```bash
   # Parar ambiente
   docker-compose -f docker-compose.dev.yml down
   
   # Verificar mudanças
   git status
   git diff
   ```

5. **Commitar e enviar**:
   ```bash
   git add .
   git commit -m "sua mensagem"
   git push origin main
   ```

## 📚 Recursos Adicionais

- [Documentação Docker Compose](https://docs.docker.com/compose/)
- [Documentação FastAPI](https://fastapi.tiangolo.com/)
- [Documentação Vite](https://vitejs.dev/)
- [Documentação PostgreSQL](https://www.postgresql.org/docs/)

## 🆘 Suporte

Se encontrar problemas:

1. Verifique os logs dos containers
2. Teste a conexão com o banco
3. Verifique se as portas estão livres
4. Consulte a seção de Troubleshooting acima
5. Verifique a documentação do projeto em `docs/`

---

**Última atualização**: 2025-01-XX

