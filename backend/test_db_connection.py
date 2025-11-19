"""
Script para testar conexão com o banco de dados
Execute: python test_db_connection.py
"""
import sys
from sqlalchemy import create_engine, text
from app.core.config import settings

def test_connection():
    """Testa a conexão com o banco de dados"""
    print("=" * 60)
    print("🔍 TESTE DE CONEXÃO COM BANCO DE DADOS")
    print("=" * 60)
    print()
    
    # Mostrar configuração (sem senha)
    db_url_display = settings.DATABASE_URL
    if "@" in db_url_display:
        # Ocultar senha na exibição
        parts = db_url_display.split("@")
        if len(parts) == 2:
            user_part = parts[0].split("://")[1] if "://" in parts[0] else parts[0]
            if ":" in user_part:
                user = user_part.split(":")[0]
                db_url_display = db_url_display.replace(user_part, f"{user}:***")
    
    print(f"📊 URL do Banco: {db_url_display}")
    print()
    
    try:
        # Criar engine
        print("1️⃣  Criando engine SQLAlchemy...")
        engine = create_engine(
            settings.DATABASE_URL,
            pool_pre_ping=True,
            connect_args={"connect_timeout": 10}
        )
        print("   ✅ Engine criado com sucesso")
        print()
        
        # Testar conexão
        print("2️⃣  Testando conexão...")
        with engine.connect() as conn:
            result = conn.execute(text("SELECT version();"))
            version = result.fetchone()[0]
            print(f"   ✅ Conectado com sucesso!")
            print(f"   📌 PostgreSQL: {version.split(',')[0]}")
            print()
        
        # Testar banco específico
        print("3️⃣  Verificando banco 'dbrief'...")
        with engine.connect() as conn:
            result = conn.execute(text("SELECT current_database();"))
            db_name = result.fetchone()[0]
            print(f"   ✅ Banco atual: {db_name}")
            print()
        
        # Verificar tabelas
        print("4️⃣  Verificando tabelas...")
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_type = 'BASE TABLE'
                ORDER BY table_name;
            """))
            tables = [row[0] for row in result.fetchall()]
            
            if tables:
                print(f"   ✅ {len(tables)} tabela(s) encontrada(s):")
                for table in tables:
                    print(f"      - {table}")
            else:
                print("   ⚠️  Nenhuma tabela encontrada")
                print("   💡 Execute o script database_schema.sql para criar as tabelas")
            print()
        
        # Testar query simples
        print("5️⃣  Testando query simples...")
        with engine.connect() as conn:
            try:
                result = conn.execute(text("SELECT COUNT(*) FROM users;"))
                count = result.fetchone()[0]
                print(f"   ✅ Query executada com sucesso")
                print(f"   📊 Total de usuários: {count}")
            except Exception as e:
                if "does not exist" in str(e) or "não existe" in str(e):
                    print("   ⚠️  Tabela 'users' não existe ainda")
                    print("   💡 Execute o script database_schema.sql para criar as tabelas")
                else:
                    raise
            print()
        
        print("=" * 60)
        print("✅ CONEXÃO COM BANCO DE DADOS: OK")
        print("=" * 60)
        print()
        print("🎯 Próximos Passos:")
        print("   1. Se as tabelas não existem, execute: database_schema.sql")
        print("   2. Inicie o backend: python -m uvicorn app.main:app --reload")
        print("   3. Teste a API: http://localhost:8000/docs")
        print()
        
        return True
        
    except Exception as e:
        print("=" * 60)
        print("❌ ERRO NA CONEXÃO COM BANCO DE DADOS")
        print("=" * 60)
        print()
        print(f"🔴 Erro: {str(e)}")
        print()
        print("🔍 Verificações:")
        print("   1. Verifique se o servidor PostgreSQL está acessível")
        print("   2. Verifique se o firewall permite conexões na porta 5432")
        print("   3. Verifique se as credenciais estão corretas no .env")
        print("   4. Verifique se o banco 'dbrief' existe")
        print()
        print("📝 Configuração esperada:")
        print("   Host: 82.25.92.217")
        print("   Port: 5432")
        print("   Database: dbrief")
        print("   User: root")
        print()
        
        return False

if __name__ == "__main__":
    success = test_connection()
    sys.exit(0 if success else 1)

