# 🔧 SERVICES - GUIA DE USO

## 📦 Serviços Disponíveis

Este diretório contém todos os serviços de integração e lógica de negócio do sistema DeBrief.

---

## 1️⃣ TrelloService

**Arquivo:** `trello.py`

### Descrição
Gerencia integração com Trello API para criação e gerenciamento de cards vinculados às demandas.

### Inicialização
```python
from app.services.trello import TrelloService

trello = TrelloService()
```

### Métodos Principais

#### Criar Card
```python
card = await trello.criar_card(demanda, db)
# Retorna: {'id': 'card_id', 'url': 'https://trello.com/c/...'}
```

#### Atualizar Card
```python
success = await trello.atualizar_card(demanda, db)
# Retorna: True/False
```

#### Adicionar Comentário
```python
success = await trello.adicionar_comentario(
    demanda,
    "Comentário aqui",
    autor="João Silva"
)
```

#### Arquivar Card
```python
success = await trello.arquivar_card(demanda)
```

### Exemplo Completo
```python
from app.services.trello import TrelloService

async def criar_demanda_com_trello(demanda, db):
    try:
        # Inicializar serviço
        trello = TrelloService()
        
        # Criar card
        card = await trello.criar_card(demanda, db)
        
        # Salvar IDs do Trello na demanda
        demanda.trello_card_id = card['id']
        demanda.trello_card_url = card['url']
        db.commit()
        
        print(f"Card criado: {card['url']}")
        
    except Exception as e:
        print(f"Erro: {e}")
```

### Configuração Necessária (.env)
```bash
TRELLO_API_KEY=sua-api-key
TRELLO_TOKEN=seu-token
TRELLO_BOARD_ID=id-do-board
TRELLO_LIST_ID=id-da-lista
```

---

## 2️⃣ WhatsAppService

**Arquivo:** `whatsapp.py`

### Descrição
Gerencia envio de notificações via WhatsApp usando WPPConnect.

### Inicialização
```python
from app.services.whatsapp import WhatsAppService

whatsapp = WhatsAppService()
```

### Métodos Principais

#### Enviar Nova Demanda
```python
success = await whatsapp.enviar_nova_demanda(demanda, db)
# Envia mensagem formatada para o grupo do cliente
```

#### Atualizar Status
```python
success = await whatsapp.enviar_atualizacao_status(
    demanda,
    db,
    status_antigo="aberta"
)
```

#### Lembrete de Prazo
```python
success = await whatsapp.enviar_lembrete_prazo(
    demanda,
    db,
    dias_faltando=3
)
```

#### Mensagem Customizada
```python
success = await whatsapp.enviar_mensagem_customizada(
    group_id="123456@g.us",
    titulo="Título da Mensagem",
    corpo="Conteúdo aqui",
    emoji="🎉"
)
```

#### Verificar Status
```python
status = await whatsapp.verificar_status_instancia()
print(status)
```

### Exemplo Completo
```python
from app.services.whatsapp import WhatsAppService

async def notificar_nova_demanda(demanda, db):
    try:
        whatsapp = WhatsAppService()
        
        # Enviar notificação
        success = await whatsapp.enviar_nova_demanda(demanda, db)
        
        if success:
            print("Notificação enviada com sucesso!")
        else:
            print("Falha ao enviar notificação")
            
    except Exception as e:
        print(f"Erro: {e}")
```

### Configuração Necessária (.env)
```bash
WPP_URL=http://localhost:21465
WPP_INSTANCE=debrief-instance
WPP_TOKEN=seu-token-wppconnect
```

---

## 3️⃣ UploadService

**Arquivo:** `upload.py`

### Descrição
Gerencia upload, armazenamento e exclusão de arquivos enviados pelos usuários.

### Inicialização
```python
from app.services.upload import UploadService

upload = UploadService()
```

### Métodos Principais

#### Salvar Arquivo
```python
file_path = await upload.save_file(
    file=uploaded_file,
    cliente_id="cli-123",
    demanda_id="dem-456"
)
# Retorna: "cli-123/dem-456/uuid-123.pdf"
```

#### Validar Arquivo
```python
try:
    upload.validate_file(file)
    print("Arquivo válido")
except HTTPException as e:
    print(f"Arquivo inválido: {e.detail}")
```

#### Deletar Arquivo
```python
success = upload.delete_file("cli-123/dem-456/uuid-123.pdf")
```

#### Obter Informações
```python
info = upload.get_file_info("cli-123/dem-456/uuid-123.pdf")
print(f"Tamanho: {info['size']} bytes")
print(f"Existe: {info['exists']}")
```

### Exemplo Completo
```python
from app.services.upload import UploadService
from fastapi import UploadFile

async def processar_upload(file: UploadFile, cliente_id: str, demanda_id: str):
    try:
        upload = UploadService()
        
        # Salvar arquivo
        file_path = await upload.save_file(file, cliente_id, demanda_id)
        
        # Criar registro no banco
        anexo = Anexo(
            demanda_id=demanda_id,
            nome_arquivo=file.filename,
            caminho=file_path,
            tamanho=file.size,
            tipo_mime=file.content_type
        )
        db.add(anexo)
        db.commit()
        
        print(f"Arquivo salvo: {file_path}")
        
    except HTTPException as e:
        print(f"Erro de validação: {e.detail}")
    except Exception as e:
        print(f"Erro: {e}")
```

### Configuração Necessária (.env)
```bash
UPLOAD_DIR=./uploads
MAX_UPLOAD_SIZE=52428800  # 50MB em bytes
ALLOWED_EXTENSIONS=pdf,jpg,jpeg,png
```

---

## 4️⃣ NotificationService

**Arquivo:** `notification.py`

### Descrição
Serviço centralizado para envio de notificações através de múltiplos canais (WhatsApp, Email, etc).

### Inicialização
```python
from app.services.notification import NotificationService

notification = NotificationService()
```

### Métodos Principais

#### Notificar Nova Demanda
```python
resultados = await notification.notificar_nova_demanda(
    demanda,
    db,
    canais=['whatsapp']  # ou ['whatsapp', 'email']
)
# Retorna: {'whatsapp': {'success': True, 'message': '...'}}
```

#### Notificar Atualização de Status
```python
resultados = await notification.notificar_atualizacao_status(
    demanda,
    db,
    status_antigo="aberta",
    canais=['whatsapp']
)
```

#### Notificar Lembrete de Prazo
```python
resultados = await notification.notificar_lembrete_prazo(
    demanda,
    db,
    dias_faltando=3,
    canais=['whatsapp']
)
```

### Exemplo Completo
```python
from app.services.notification import NotificationService

async def enviar_notificacoes(demanda, db):
    try:
        notification = NotificationService()
        
        # Enviar por todos os canais
        resultados = await notification.notificar_nova_demanda(
            demanda,
            db,
            canais=['whatsapp', 'email']
        )
        
        # Verificar resultados
        for canal, resultado in resultados.items():
            if resultado['success']:
                print(f"✓ {canal}: {resultado['message']}")
            else:
                print(f"✗ {canal}: {resultado['message']}")
                
    except Exception as e:
        print(f"Erro: {e}")
```

---

## 🔄 FLUXO COMPLETO DE INTEGRAÇÃO

### Exemplo: Criar Demanda com Todas as Integrações

```python
from app.services import TrelloService, WhatsAppService, UploadService, NotificationService
from fastapi import APIRouter, Depends, UploadFile, File, Form
from typing import List

router = APIRouter()

@router.post("/demandas", response_model=DemandaResponse)
async def criar_demanda(
    nome: str = Form(...),
    descricao: str = Form(...),
    secretaria_id: str = Form(...),
    tipo_demanda_id: str = Form(...),
    prioridade_id: str = Form(...),
    prazo_final: date = Form(...),
    files: List[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        # 1️⃣ CRIAR DEMANDA NO BANCO
        demanda = Demanda(
            nome=nome,
            descricao=descricao,
            secretaria_id=secretaria_id,
            tipo_demanda_id=tipo_demanda_id,
            prioridade_id=prioridade_id,
            prazo_final=prazo_final,
            usuario_id=current_user.id,
            cliente_id=current_user.cliente_id,
            status=StatusDemanda.ABERTA
        )
        db.add(demanda)
        db.commit()
        db.refresh(demanda)
        
        # 2️⃣ UPLOAD DE ARQUIVOS
        if files:
            upload_service = UploadService()
            
            for file in files:
                # Salvar arquivo
                file_path = await upload_service.save_file(
                    file,
                    cliente_id=current_user.cliente_id,
                    demanda_id=demanda.id
                )
                
                # Criar registro de anexo
                anexo = Anexo(
                    demanda_id=demanda.id,
                    nome_arquivo=file.filename,
                    caminho=file_path,
                    tamanho=file.size,
                    tipo_mime=file.content_type
                )
                db.add(anexo)
            
            db.commit()
        
        # 3️⃣ CRIAR CARD NO TRELLO
        try:
            trello_service = TrelloService()
            card = await trello_service.criar_card(demanda, db)
            
            # Atualizar demanda com IDs do Trello
            demanda.trello_card_id = card['id']
            demanda.trello_card_url = card['url']
            db.commit()
            
            print(f"✓ Card criado no Trello: {card['url']}")
            
        except Exception as e:
            # Log erro mas não falha a operação
            print(f"✗ Erro ao criar card no Trello: {e}")
        
        # 4️⃣ ENVIAR NOTIFICAÇÕES
        try:
            notification_service = NotificationService()
            resultados = await notification_service.notificar_nova_demanda(
                demanda,
                db,
                canais=['whatsapp']
            )
            
            for canal, resultado in resultados.items():
                if resultado['success']:
                    print(f"✓ Notificação {canal} enviada")
                else:
                    print(f"✗ Falha na notificação {canal}: {resultado['message']}")
                    
        except Exception as e:
            print(f"✗ Erro ao enviar notificações: {e}")
        
        # 5️⃣ RECARREGAR DEMANDA COM RELACIONAMENTOS
        db.refresh(demanda)
        
        return demanda
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao criar demanda: {str(e)}"
        )
```

---

## 🔧 TRATAMENTO DE ERROS

### Padrão Recomendado

```python
try:
    # Operação crítica (banco de dados)
    demanda = Demanda(...)
    db.add(demanda)
    db.commit()
    
except Exception as e:
    db.rollback()
    raise HTTPException(status_code=500, detail=str(e))

# Operações não-críticas (integrações)
try:
    trello_service = TrelloService()
    await trello_service.criar_card(demanda, db)
except Exception as e:
    # Log mas não falha
    logger.error(f"Erro ao criar card: {e}")

try:
    notification_service = NotificationService()
    await notification_service.notificar_nova_demanda(demanda, db)
except Exception as e:
    # Log mas não falha
    logger.error(f"Erro ao notificar: {e}")
```

---

## 📊 LOGGING

Todos os serviços incluem logging detalhado:

```python
import logging

# Configurar logger no main.py
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Logs automáticos dos serviços:
# INFO: TrelloService inicializado com sucesso
# INFO: Criando card no Trello para demanda abc-123
# INFO: Card criado com sucesso: https://trello.com/c/xyz
# WARNING: Cliente sem grupo WhatsApp configurado
# ERROR: Erro ao criar card no Trello: [erro]
```

---

## ✅ CHECKLIST DE INTEGRAÇÃO

### Antes de Usar:
- [ ] Instalar dependências: `pip install -r requirements.txt`
- [ ] Configurar variáveis no `.env`
- [ ] Testar credenciais Trello
- [ ] Testar instância WPPConnect (se aplicável)
- [ ] Criar diretório de uploads: `mkdir -p uploads`

### Ao Integrar:
- [ ] Importar serviços necessários
- [ ] Inicializar serviços dentro de try/except
- [ ] Salvar IDs de retorno no banco (trello_card_id, trello_card_url)
- [ ] Fazer log de erros
- [ ] Não falhar operação se integração falhar

### Testes:
- [ ] Criar demanda → verificar card no Trello
- [ ] Atualizar demanda → verificar card atualizado
- [ ] Upload de arquivo → verificar arquivo salvo
- [ ] Notificação WhatsApp → verificar mensagem recebida
- [ ] Deletar demanda → verificar arquivos removidos

---

## 📚 REFERÊNCIAS

- **Trello API:** https://developer.atlassian.com/cloud/trello/rest/
- **py-trello:** https://github.com/sarumont/py-trello
- **WPPConnect:** https://wppconnect.io/
- **FastAPI:** https://fastapi.tiangolo.com/

---

## 🆘 SUPORTE

Se encontrar problemas:
1. Verificar logs do servidor
2. Verificar variáveis no `.env`
3. Testar credenciais manualmente
4. Consultar documentação da API específica

---

**Última atualização:** 19/11/2024  
**Versão:** 1.0.0

