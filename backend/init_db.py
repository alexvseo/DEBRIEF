"""
Script para inicializar banco de dados com dados de teste
"""
from app.core.database import SessionLocal, init_db
from app.models.user import User, TipoUsuario
from app.models.demanda import Demanda, StatusDemanda, PrioridadeDemanda
from datetime import date, timedelta

def create_test_users(db):
    """Criar usuários de teste"""
    print("📝 Criando usuários de teste...")
    
    # Verificar se usuários já existem
    if db.query(User).filter(User.username == "admin").first():
        print("   ⚠️  Usuários já existem, pulando...")
        return
    
    # Usuário Master
    admin = User(
        username="admin",
        email="admin@debrief.com",
        nome_completo="Administrador Master",
        tipo=TipoUsuario.MASTER,
        ativo=True
    )
    admin.set_password("admin123")
    db.add(admin)
    
    db.commit()
    print("   ✅ Usuário admin criado com sucesso!")

def create_test_demandas(db):
    """Criar demandas de teste"""
    print("📝 Criando demandas de teste...")
    
    # Buscar usuários
    admin = db.query(User).filter(User.username == "admin").first()
    cliente = db.query(User).filter(User.username == "cliente").first()
    
    if not admin or not cliente:
        print("   ⚠️  Usuários não encontrados, pulando demandas...")
        return
    
    # Verificar se demandas já existem
    if db.query(Demanda).count() > 0:
        print("   ⚠️  Demandas já existem, pulando...")
        return
    
    # Demandas do admin
    demandas_admin = [
        Demanda(
            nome="Desenvolvimento de Site Institucional",
            descricao="Criar novo site institucional com design moderno e responsivo",
            status=StatusDemanda.EM_ANDAMENTO,
            prioridade=PrioridadeDemanda.ALTA,
            prazo_final=date.today() + timedelta(days=30),
            usuario_id=admin.id,
            tipo_demanda_id="1"
        ),
        Demanda(
            nome="Campanha de Marketing Digital",
            descricao="Planejar e executar campanha nas redes sociais",
            status=StatusDemanda.ABERTA,
            prioridade=PrioridadeDemanda.MEDIA,
            prazo_final=date.today() + timedelta(days=45),
            usuario_id=admin.id,
            tipo_demanda_id="2"
        ),
    ]
    
    # Demandas do cliente
    demandas_cliente = [
        Demanda(
            nome="Logo da Empresa",
            descricao="Criar identidade visual e logo profissional",
            status=StatusDemanda.CONCLUIDA,
            prioridade=PrioridadeDemanda.ALTA,
            prazo_final=date.today() - timedelta(days=10),
            usuario_id=cliente.id,
            tipo_demanda_id="3"
        ),
        Demanda(
            nome="Material para Evento",
            descricao="Criar banners, folders e cartazes para evento",
            status=StatusDemanda.EM_ANDAMENTO,
            prioridade=PrioridadeDemanda.URGENTE,
            prazo_final=date.today() + timedelta(days=7),
            usuario_id=cliente.id,
            tipo_demanda_id="4"
        ),
    ]
    
    # Adicionar todas as demandas
    for demanda in demandas_admin + demandas_cliente:
        db.add(demanda)
    
    db.commit()
    print(f"   ✅ {len(demandas_admin + demandas_cliente)} demandas criadas")

def main():
    """Função principal"""
    print("🚀 Inicializando banco de dados...")
    
    # Criar tabelas
    print("📦 Criando tabelas...")
    init_db()
    print("   ✅ Tabelas criadas")
    
    # Criar sessão
    db = SessionLocal()
    
    try:
        # Criar dados de teste
        create_test_users(db)
        create_test_demandas(db)
        
        print("\n✅ Banco de dados inicializado com sucesso!")
        print("\n📝 Credenciais de acesso:")
        print("   👑 Admin: admin / admin123")
        
    except Exception as e:
        print(f"\n❌ Erro ao inicializar banco: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    main()

