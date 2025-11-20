# 🔧 Scripts do Sistema DeBrief

Esta pasta contém todos os scripts auxiliares do projeto, organizados por categoria.

---

## 📂 Estrutura

```
scripts/
├── deploy/          # Scripts de deploy e setup
├── diagnostico/     # Scripts de diagnóstico e verificação
├── correcao/        # Scripts de correção de problemas
└── configuracao/    # Scripts de configuração
```

---

## 🚀 Scripts de Deploy

### `deploy/`
Scripts para deploy e inicialização do sistema.

- **`docker-deploy.sh`** - Script principal de deploy Docker
- **`deploy-final.sh`** - Deploy final completo
- **`rebuild-completo.sh`** - Rebuild completo do sistema
- **`setup-servidor.sh`** - Setup inicial do servidor

---

## 🔍 Scripts de Diagnóstico

### `diagnostico/`
Scripts para diagnosticar problemas e verificar status.

- **`diagnosticar-502.sh`** - Diagnosticar erro 502
- **`diagnosticar-conexao-completa.sh`** - Diagnóstico completo de conexão
- **`diagnostico_502.sh`** - Diagnóstico erro 502 (alternativo)
- **`diagnostico_backend_unhealthy.sh`** - Backend unhealthy
- **`diagnostico_login.sh`** - Diagnóstico de login
- **`verificar-caddy-completo.sh`** - Verificar Caddy completo
- **`verificar-e-corrigir-enum.sh`** - Verificar e corrigir enum
- **`verificar-erro-500-login.sh`** - Verificar erro 500 no login
- **`verificar-erro-backend.sh`** - Verificar erro backend
- **`verificar_logs_backend.sh`** - Verificar logs do backend
- **`verificar-postgresql-local.sh`** - Verificar PostgreSQL local
- **`testar-backend-local.sh`** - Testar backend localmente
- **`testar-conexao-banco.sh`** - Testar conexão com banco
- **`testar-conexao-docker.sh`** - Testar conexão Docker
- **`testar-usuario-postgres.sh`** - Testar usuário postgres
- **`debug-backend.sh`** - Debug do backend

---

## 🔧 Scripts de Correção

### `correcao/`
Scripts para corrigir problemas específicos.

- **`aplicar-correcao-404.sh`** - Aplicar correção 404
- **`aplicar-correcao-caddy.sh`** - Aplicar correção Caddy
- **`aplicar-correcoes-finais.sh`** - Aplicar todas as correções finais
- **`aplicar-todas-correcoes.sh`** - Aplicar todas as correções
- **`corrigir-404-caddy.sh`** - Corrigir 404 Caddy
- **`corrigir-502.sh`** - Corrigir erro 502
- **`corrigir-caddy-404.sh`** - Corrigir Caddy 404 (alternativo)
- **`corrigir-caddy-host.sh`** - Corrigir Caddy host
- **`corrigir-caddy-network.sh`** - Corrigir rede Caddy
- **`corrigir-enum-banco-completo.sh`** - Corrigir enum no banco completo
- **`corrigir-enum-usuario.sh`** - Corrigir enum usuário
- **`corrigir-porta-80-frontend.sh`** - Corrigir porta 80 frontend
- **`corrigir-todos-erros.sh`** - Corrigir todos os erros
- **`corrigir-todos-problemas.sh`** - Corrigir todos os problemas

---

## ⚙️ Scripts de Configuração

### `configuracao/`
Scripts para configurar o sistema.

- **`configurar-banco-completo.sh`** - Configurar banco completo
- **`configurar-postgresql-remoto.sh`** - Configurar PostgreSQL remoto
- **`criar-usuario-admin.sh`** - Criar usuário admin
- **`solucionar-acesso-banco.sh`** - Solucionar acesso banco
- **`resolver-conflito-git.sh`** - Resolver conflito Git
- **`limpar-servidor.sh`** - Limpar servidor

---

## 📋 Uso

### Executar um script

```bash
# Dar permissão de execução (se necessário)
chmod +x scripts/categoria/script.sh

# Executar
./scripts/categoria/script.sh
```

### Scripts mais usados

```bash
# Deploy completo
./scripts/deploy/docker-deploy.sh

# Rebuild completo
./scripts/deploy/rebuild-completo.sh

# Diagnosticar problemas
./scripts/diagnostico/diagnosticar-conexao-completa.sh

# Aplicar todas as correções
./scripts/correcao/aplicar-todas-correcoes.sh

# Criar usuário admin
./scripts/configuracao/criar-usuario-admin.sh
```

---

## ⚠️ Notas

- Todos os scripts devem ser executados com permissão de execução
- Alguns scripts requerem privilégios de root
- Leia os comentários dentro dos scripts para entender o que fazem
- Scripts de correção podem modificar configurações do sistema

---

## 🔒 Segurança

- Não execute scripts de fontes não confiáveis
- Revise scripts antes de executar em produção
- Faça backup antes de executar scripts de correção
- Scripts que modificam banco de dados requerem cuidado extra

---

**🔧 Scripts auxiliares do Sistema DeBrief**

