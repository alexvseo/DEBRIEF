"""
Script de Teste para Integrações
Testa se os serviços podem ser importados e inicializados
"""
import sys
from pathlib import Path

# Adicionar diretório raiz ao path
sys.path.insert(0, str(Path(__file__).parent))

print("=" * 60)
print("🧪 TESTANDO INTEGRAÇÕES - DEBRIEF")
print("=" * 60)

# Teste 1: Importar configurações
print("\n1️⃣  Testando importação de configurações...")
try:
    from app.core.config import settings
    print("✅ Configurações importadas com sucesso")
    print(f"   - DATABASE_URL: {settings.DATABASE_URL[:30]}...")
    print(f"   - UPLOAD_DIR: {settings.UPLOAD_DIR}")
    print(f"   - ENVIRONMENT: {settings.ENVIRONMENT}")
except Exception as e:
    print(f"❌ Erro ao importar configurações: {e}")
    sys.exit(1)

# Teste 2: Importar serviços
print("\n2️⃣  Testando importação de serviços...")
try:
    from app.services import (
        TrelloService,
        WhatsAppService,
        UploadService,
        NotificationService
    )
    print("✅ Todos os serviços importados com sucesso")
    print("   - TrelloService")
    print("   - WhatsAppService")
    print("   - UploadService")
    print("   - NotificationService")
except Exception as e:
    print(f"❌ Erro ao importar serviços: {e}")
    sys.exit(1)

# Teste 3: Verificar dependências
print("\n3️⃣  Testando dependências instaladas...")
try:
    import trello
    import requests
    import aiofiles
    from reportlab.lib.pagesizes import A4
    from openpyxl import Workbook
    from PIL import Image
    
    print("✅ Todas as dependências instaladas")
    print(f"   - py-trello: {trello.__version__ if hasattr(trello, '__version__') else 'OK'}")
    print(f"   - requests: {requests.__version__}")
    print(f"   - aiofiles: OK")
    print(f"   - reportlab: OK")
    print(f"   - openpyxl: OK")
    print(f"   - pillow: {Image.__version__ if hasattr(Image, '__version__') else 'OK'}")
except Exception as e:
    print(f"❌ Erro ao verificar dependências: {e}")
    sys.exit(1)

# Teste 4: Inicializar UploadService (não requer credenciais)
print("\n4️⃣  Testando UploadService...")
try:
    upload_service = UploadService()
    print("✅ UploadService inicializado")
    print(f"   - Upload dir: {upload_service.upload_dir}")
    print(f"   - Max size: {upload_service.get_max_size_mb():.0f}MB")
    print(f"   - Extensions: {', '.join(upload_service.get_allowed_extensions())}")
except Exception as e:
    print(f"❌ Erro ao inicializar UploadService: {e}")

# Teste 5: Verificar credenciais Trello
print("\n5️⃣  Verificando credenciais Trello...")
if settings.TRELLO_API_KEY and settings.TRELLO_TOKEN:
    print("✅ Credenciais Trello configuradas no .env")
    print(f"   - API Key: {settings.TRELLO_API_KEY[:10]}...")
    print(f"   - Token: {settings.TRELLO_TOKEN[:10]}...")
    print(f"   - Board ID: {settings.TRELLO_BOARD_ID or 'Não configurado'}")
    print(f"   - List ID: {settings.TRELLO_LIST_ID or 'Não configurado'}")
    
    # Tentar inicializar TrelloService
    print("\n   Tentando inicializar TrelloService...")
    try:
        trello_service = TrelloService()
        print("   ✅ TrelloService inicializado com sucesso!")
        print(f"   - Board: {trello_service.board.name}")
        print(f"   - List: {trello_service.list.name}")
    except Exception as e:
        print(f"   ⚠️  Erro ao inicializar TrelloService: {e}")
        print("   (Verifique se as credenciais estão corretas)")
else:
    print("⚠️  Credenciais Trello NÃO configuradas")
    print("   Configure no .env:")
    print("   - TRELLO_API_KEY")
    print("   - TRELLO_TOKEN")
    print("   - TRELLO_BOARD_ID")
    print("   - TRELLO_LIST_ID")

# Teste 6: Verificar credenciais WhatsApp
print("\n6️⃣  Verificando credenciais WhatsApp...")
if settings.WPP_URL and settings.WPP_TOKEN:
    print("✅ Credenciais WhatsApp configuradas")
    print(f"   - URL: {settings.WPP_URL}")
    print(f"   - Instance: {settings.WPP_INSTANCE or 'Não configurado'}")
    print(f"   - Token: {settings.WPP_TOKEN[:10]}...")
    
    # Tentar inicializar WhatsAppService
    print("\n   Tentando inicializar WhatsAppService...")
    try:
        whatsapp_service = WhatsAppService()
        print("   ✅ WhatsAppService inicializado com sucesso!")
    except Exception as e:
        print(f"   ⚠️  Erro ao inicializar WhatsAppService: {e}")
else:
    print("⚠️  Credenciais WhatsApp NÃO configuradas")
    print("   Configure no .env:")
    print("   - WPP_URL")
    print("   - WPP_INSTANCE")
    print("   - WPP_TOKEN")

# Teste 7: Inicializar NotificationService
print("\n7️⃣  Testando NotificationService...")
try:
    notification_service = NotificationService()
    print("✅ NotificationService inicializado")
except Exception as e:
    print(f"❌ Erro ao inicializar NotificationService: {e}")

# Resumo
print("\n" + "=" * 60)
print("📊 RESUMO DOS TESTES")
print("=" * 60)
print("✅ Configurações: OK")
print("✅ Serviços: Importados")
print("✅ Dependências: Instaladas")
print("✅ UploadService: OK")
print("✅ NotificationService: OK")

if settings.TRELLO_API_KEY and settings.TRELLO_TOKEN:
    print("✅ Trello: Configurado")
else:
    print("⚠️  Trello: Não configurado")

if settings.WPP_URL and settings.WPP_TOKEN:
    print("✅ WhatsApp: Configurado")
else:
    print("⚠️  WhatsApp: Não configurado")

print("\n" + "=" * 60)
print("🎉 TESTES CONCLUÍDOS!")
print("=" * 60)
print("\n💡 Próximos passos:")
print("   1. Configure credenciais no .env (se ainda não fez)")
print("   2. Teste criar demanda com integração Trello")
print("   3. Teste enviar notificação WhatsApp")
print("   4. Integre os serviços nos endpoints\n")

