"""
Script para popular banco de dados com dados iniciais (seeds)
Executa após as migrations serem aplicadas
"""
from app.core.database import SessionLocal
from app.models import (
    User,
    TipoUsuario,
    Cliente,
    Secretaria,
    TipoDemanda,
    Prioridade,
    Demanda,
    StatusDemanda
)
from datetime import date, timedelta
import sys


def criar_tipos_e_prioridades(db):
    """Criar tipos de demanda e prioridades padrões"""
    print("🎨 Criando Tipos de Demanda e Prioridades...")
    
    # Tipos de Demanda
    tipos = TipoDemanda.criar_tipos_padroes(db)
    if tipos:
        print(f"   ✅ {len(tipos)} tipos de demanda criados")
    else:
        print("   ℹ️  Tipos de demanda já existem")
    
    # Prioridades
    prioridades = Prioridade.criar_prioridades_padroes(db)
    if prioridades:
        print(f"   ✅ {len(prioridades)} prioridades criadas")
    else:
        print("   ℹ️  Prioridades já existem")
    
    return tipos, prioridades


def criar_cliente_exemplo(db):
    """Criar cliente de exemplo"""
    print("🏢 Criando Cliente de Exemplo...")
    
    # Verificar se já existe
    cliente_existente = db.query(Cliente).filter(Cliente.nome.ilike("Prefeitura Municipal Exemplo")).first()
    if cliente_existente:
        print("   ℹ️  Cliente já existe")
        return cliente_existente
    
    # Criar cliente
    cliente = Cliente(
        nome="Prefeitura Municipal Exemplo",
        whatsapp_group_id="5511999999999-1234567890@g.us",
        trello_member_id="exemplo123abc",
        ativo=True
    )
    
    db.add(cliente)
    db.commit()
    db.refresh(cliente)
    
    print(f"   ✅ Cliente criado: {cliente.nome}")
    return cliente


def criar_secretarias(db, cliente_id):
    """Criar secretarias de exemplo"""
    print("🏛️  Criando Secretarias...")
    
    # Verificar se já existem
    secretarias_existentes = db.query(Secretaria).filter(Secretaria.cliente_id == cliente_id).count()
    if secretarias_existentes > 0:
        print(f"   ℹ️  {secretarias_existentes} secretarias já existem")
        return
    
    secretarias_nomes = [
        "Secretaria de Saúde",
        "Secretaria de Educação",
        "Secretaria de Cultura",
        "Secretaria de Assistência Social",
        "Gabinete do Prefeito",
        "Secretaria de Obras",
    ]
    
    secretarias = []
    for nome in secretarias_nomes:
        secretaria = Secretaria(
            nome=nome,
            cliente_id=cliente_id,
            ativo=True
        )
        secretarias.append(secretaria)
        db.add(secretaria)
    
    db.commit()
    print(f"   ✅ {len(secretarias)} secretarias criadas")
    return secretarias


def criar_usuarios(db, cliente_id):
    """Criar usuários de teste"""
    print("👥 Criando Usuários...")
    
    # Verificar se já existem
    if db.query(User).filter(User.username == "admin").first():
        print("   ℹ️  Usuários já existem")
        return
    
    # Usuário Master
    admin = User(
        username="admin",
        email="admin@debrief.com",
        nome_completo="Administrador Master",
        tipo=TipoUsuario.MASTER,
        cliente_id=None,  # Master não tem cliente
        ativo=True
    )
    admin.set_password("admin123")
    db.add(admin)
    
    # Usuário Cliente
    cliente_user = User(
        username="cliente",
        email="cliente@prefeitura.com",
        nome_completo="João Silva",
        tipo=TipoUsuario.CLIENTE,
        cliente_id=cliente_id,
        ativo=True
    )
    cliente_user.set_password("cliente123")
    db.add(cliente_user)
    
    db.commit()
    print("   ✅ 2 usuários criados: admin e cliente")


def criar_demandas_exemplo(db, cliente_id):
    """Criar demandas de exemplo"""
    print("📋 Criando Demandas de Exemplo...")
    
    # Verificar se já existem
    if db.query(Demanda).count() > 0:
        print("   ℹ️  Demandas já existem")
        return
    
    # Buscar dados necessários
    cliente_user = db.query(User).filter(User.username == "cliente").first()
    secretarias = db.query(Secretaria).filter(Secretaria.cliente_id == cliente_id).all()
    tipos = db.query(TipoDemanda).filter(TipoDemanda.ativo == True).all()
    prioridades = db.query(Prioridade).all()
    
    if not cliente_user or not secretarias or not tipos or not prioridades:
        print("   ⚠️  Dados insuficientes para criar demandas")
        return
    
    # Buscar IDs
    secretaria_saude_id = next((s.id for s in secretarias if "Saúde" in s.nome), secretarias[0].id)
    secretaria_cultura_id = next((s.id for s in secretarias if "Cultura" in s.nome), secretarias[1].id)
    
    tipo_design_id = next((t.id for t in tipos if "Design" in t.nome), tipos[0].id)
    tipo_dev_id = next((t.id for t in tipos if "Desenvolvimento" in t.nome), tipos[1].id if len(tipos) > 1 else tipos[0].id)
    
    prioridade_baixa_id = next((p.id for p in prioridades if p.nivel == 1), prioridades[0].id)
    prioridade_media_id = next((p.id for p in prioridades if p.nivel == 2), prioridades[1].id if len(prioridades) > 1 else prioridades[0].id)
    prioridade_alta_id = next((p.id for p in prioridades if p.nivel == 3), prioridades[2].id if len(prioridades) > 2 else prioridades[0].id)
    
    # Criar demandas
    demandas = [
        Demanda(
            nome="Design de Banner para Campanha de Vacinação",
            descricao="Criar conjunto de banners para redes sociais promovendo a campanha de vacinação contra gripe",
            secretaria_id=secretaria_saude_id,
            tipo_demanda_id=tipo_design_id,
            prioridade_id=prioridade_alta_id,
            prazo_final=date.today() + timedelta(days=15),
            usuario_id=cliente_user.id,
            cliente_id=cliente_id,
            status=StatusDemanda.EM_ANDAMENTO
        ),
        Demanda(
            nome="Desenvolvimento de Landing Page para Festival Cultural",
            descricao="Criar página responsiva para divulgar o Festival de Inverno com formulário de inscrição",
            secretaria_id=secretaria_cultura_id,
            tipo_demanda_id=tipo_dev_id,
            prioridade_id=prioridade_media_id,
            prazo_final=date.today() + timedelta(days=30),
            usuario_id=cliente_user.id,
            cliente_id=cliente_id,
            status=StatusDemanda.ABERTA
        ),
        Demanda(
            nome="Posts para Redes Sociais - Dezembro",
            descricao="Criação de 15 posts (texto e imagem) para Instagram e Facebook",
            secretaria_id=secretaria_saude_id,
            tipo_demanda_id=tipo_design_id,
            prioridade_id=prioridade_baixa_id,
            prazo_final=date.today() + timedelta(days=45),
            usuario_id=cliente_user.id,
            cliente_id=cliente_id,
            status=StatusDemanda.ABERTA
        ),
    ]
    
    for demanda in demandas:
        db.add(demanda)
    
    db.commit()
    print(f"   ✅ {len(demandas)} demandas criadas")


def main():
    """Função principal"""
    print("\n" + "="*60)
    print("🌱 SEED DATABASE - POPULANDO COM DADOS INICIAIS")
    print("="*60 + "\n")
    
    # Criar sessão
    db = SessionLocal()
    
    try:
        # 1. Criar tipos e prioridades
        criar_tipos_e_prioridades(db)
        
        # 2. Criar cliente
        cliente = criar_cliente_exemplo(db)
        
        # 3. Criar secretarias
        criar_secretarias(db, cliente.id)
        
        # 4. Criar usuários
        criar_usuarios(db, cliente.id)
        
        # 5. Criar demandas de exemplo
        criar_demandas_exemplo(db, cliente.id)
        
        print("\n" + "="*60)
        print("✅ BANCO DE DADOS POPULADO COM SUCESSO!")
        print("="*60 + "\n")
        
        print("📝 Credenciais de Acesso:")
        print("   👑 Master:  admin / admin123")
        print("   👤 Cliente: cliente / cliente123\n")
        
        print("🎯 Dados Criados:")
        print(f"   - 4 Tipos de Demanda")
        print(f"   - 4 Prioridades")
        print(f"   - 1 Cliente")
        print(f"   - 6 Secretarias")
        print(f"   - 2 Usuários")
        print(f"   - 3 Demandas de exemplo\n")
        
        print("🚀 Próximos Passos:")
        print("   1. Iniciar backend: python -m uvicorn app.main:app --reload")
        print("   2. Acessar API Docs: http://localhost:8000/api/docs")
        print("   3. Testar login no frontend\n")
        
    except Exception as e:
        print(f"\n❌ Erro ao popular banco: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
        sys.exit(1)
    finally:
        db.close()


if __name__ == "__main__":
    main()

