from app.core.database import SessionLocal
from app.models.user import User, TipoUsuario
from app.schemas.user import UserCreate

def debug_create_user():
    print("🚀 Iniciando debug de criação de usuário...")
    db = SessionLocal()
    
    try:
        # Simular dados vindos do frontend
        user_data = UserCreate(
            username="alex_debug",
            email="alex_debug@gmail.com",
            nome_completo="Alex Debug",
            password="senha123",
            tipo=TipoUsuario.MASTER,
            cliente_id=None
        )
        print(f"📦 Dados validados: {user_data}")
        
        # Preparar kwargs (mesma lógica do endpoint)
        user_kwargs = {
            'username': user_data.username,
            'email': user_data.email,
            'nome_completo': user_data.nome_completo,
            'tipo': user_data.tipo
        }
        
        if user_data.tipo == TipoUsuario.MASTER:
            user_kwargs['cliente_id'] = None
            
        print(f"🔧 Kwargs para o modelo: {user_kwargs}")
        
        # Criar usuário
        new_user = User(**user_kwargs)
        new_user.set_password(user_data.password)
        print("✅ Usuário instanciado")
        
        db.add(new_user)
        print("✅ Usuário adicionado à sessão")
        
        db.commit()
        print("✅ Commit realizado com sucesso!")
        
        db.refresh(new_user)
        print(f"🎉 Usuário criado com ID: {new_user.id}")
        
    except Exception as e:
        print(f"❌ ERRO: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    debug_create_user()
