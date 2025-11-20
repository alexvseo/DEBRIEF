# 🔒 Segurança e Performance - DeBrief

Documentação das funcionalidades de segurança e performance implementadas no sistema.

---

## ✅ Funcionalidades Implementadas

### 1. 🔐 Rate Limiting

**Arquivo:** `backend/app/core/rate_limit.py`

Protege a API contra abuso e ataques de força bruta limitando o número de requisições por IP.

#### Configurações:
- **Padrão:** 100 requisições/minuto
- **Login:** 5 tentativas/minuto
- **Upload:** 10 arquivos/minuto
- **Relatórios:** 20 requisições/minuto

#### Uso:
```python
from app.core.rate_limit import limiter

@router.post("/login")
@limiter.limit("5/minute")
async def login(request: Request, ...):
    ...
```

#### Dependência:
- `slowapi==0.1.9`

---

### 2. 🔄 Sistema de Retry para Notificações

**Arquivo:** `backend/app/services/notification.py`

Sistema automático de retry com backoff exponencial para notificações.

#### Características:
- **3 tentativas** por notificação
- **Backoff exponencial:** 1s, 2s, 4s
- **Log automático** em `NotificationLog`
- **Sucesso/Erro** registrado no banco

#### Exemplo:
```python
notification_service = NotificationService()
resultado = await notification_service.notificar_nova_demanda(demanda, db)
# Tenta 3 vezes automaticamente se falhar
```

---

### 3. 🚫 Blacklist de Tokens JWT

**Arquivo:** `backend/app/core/security.py`

Sistema para invalidar tokens JWT antes da expiração (útil para logout).

#### Funções:
- `blacklist_token(token)` - Adicionar token à blacklist
- `is_token_blacklisted(token)` - Verificar se token está na blacklist
- `clear_blacklist()` - Limpar blacklist (testes)

#### Uso:
```python
from app.core.security import blacklist_token

# No logout
blacklist_token(token)
```

#### Endpoint:
- `POST /api/auth/logout` - Invalida token atual

---

### 4. 🛡️ CSRF Protection

**Arquivo:** `backend/app/core/csrf.py`

Proteção contra Cross-Site Request Forgery.

#### Funções:
- `get_csrf_token(session_id)` - Gerar token CSRF
- `verify_csrf(request, session_id)` - Verificar token
- `clear_csrf_token(session_id)` - Limpar token

#### Middleware:
- `CSRFMiddleware` - Middleware para verificação automática

#### Uso:
```python
from app.core.csrf import get_csrf_token, verify_csrf

# Gerar token
token = get_csrf_token(session_id)

# Verificar na requisição
verify_csrf(request, session_id)
```

---

### 5. ✅ reCAPTCHA Validation

**Arquivo:** `backend/app/core/security.py`

Validação de reCAPTCHA no login para prevenir bots.

#### Função:
- `verify_recaptcha(token)` - Verificar token com Google

#### Uso no Login:
O frontend deve enviar o token reCAPTCHA via header:
```
X-Recaptcha-Token: <token>
```

#### Configuração:
```env
RECAPTCHA_SECRET_KEY=sua-chave-secreta
RECAPTCHA_SITE_KEY=sua-chave-publica
```

#### Nota:
- Em desenvolvimento, se `RECAPTCHA_SECRET_KEY` não estiver configurado, a verificação é pulada (permite desenvolvimento)

---

### 6. 📊 Logging Middleware

**Arquivo:** `backend/app/core/middleware.py`

Middleware para logging de todas as requisições.

#### Funcionalidades:
- Registra método, path e IP
- Calcula tempo de processamento
- Adiciona header `X-Process-Time`
- Logs estruturados

#### Exemplo de Log:
```
INFO: GET /api/demandas - IP: 192.168.1.1
INFO: GET /api/demandas - Status: 200 - Time: 0.123s
```

---

## 📋 Configurações

### Variáveis de Ambiente

```env
# Rate Limiting
RATE_LIMIT_ENABLED=true
RATE_LIMIT_DEFAULT=100/minute
RATE_LIMIT_AUTH=5/minute
RATE_LIMIT_UPLOAD=10/minute
RATE_LIMIT_REPORTS=20/minute

# CSRF
CSRF_ENABLED=true
CSRF_TOKEN_EXPIRE_SECONDS=3600

# reCAPTCHA
RECAPTCHA_SECRET_KEY=sua-chave-secreta
RECAPTCHA_SITE_KEY=sua-chave-publica
```

---

## 🔧 Dependências Adicionadas

```txt
slowapi==0.1.9  # Rate limiting
httpx==0.27.0   # Para reCAPTCHA (async HTTP)
```

---

## 📊 Endpoints de Segurança

### Logout
```http
POST /api/auth/logout
Authorization: Bearer <token>

Response:
{
  "message": "Logout realizado com sucesso",
  "token_invalidated": true
}
```

### Login (com Rate Limit e reCAPTCHA)
```http
POST /api/auth/login
Content-Type: application/x-www-form-urlencoded
X-Recaptcha-Token: <token-opcional>

Body:
username=admin&password=admin123

Response:
{
  "access_token": "...",
  "token_type": "bearer",
  "user": {...}
}
```

**Rate Limit:** 5 tentativas por minuto por IP

---

## 🎯 Próximos Passos

### Melhorias Futuras:
1. **Redis para Rate Limiting** - Rate limiting distribuído
2. **Redis para Blacklist** - Blacklist persistente
3. **Sessões para CSRF** - Tokens CSRF por sessão
4. **Fila Assíncrona** - Celery para notificações
5. **Monitoramento** - Métricas de segurança

---

## 📝 Notas Importantes

1. **Rate Limiting em Memória:**
   - Atualmente usa memória (`memory://`)
   - Para produção com múltiplos workers, usar Redis

2. **Blacklist em Memória:**
   - Tokens invalidados são perdidos ao reiniciar
   - Para produção, usar Redis ou banco de dados

3. **CSRF Opcional:**
   - Middleware criado mas não ativado por padrão
   - Pode ser ativado quando sessões forem implementadas

4. **reCAPTCHA Opcional:**
   - Se não configurado, verificação é pulada
   - Permite desenvolvimento sem reCAPTCHA

---

**🔒 Sistema DeBrief - Segurança e Performance Implementadas**

