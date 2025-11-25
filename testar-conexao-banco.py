#!/usr/bin/env python3
"""
Script para testar conexão com banco de dados PostgreSQL
e descobrir onde os dados estão sendo salvos
"""

import psycopg2
from psycopg2 import sql
import sys

# Configurações do banco
DB_CONFIG = {
    'host': '82.25.92.217',
    'port': 5432,
    'database': 'dbrief',
    'user': 'postgres',
    'password': 'Mslestra@2025db'
}

def print_separator():
    print("=" * 60)

def test_connection():
    """Testa conexão com o banco de dados"""
    print_separator()
    print("🔍 TESTANDO CONEXÃO COM BANCO DE DADOS")
    print_separator()
    print(f"Host: {DB_CONFIG['host']}")
    print(f"Porta: {DB_CONFIG['port']}")
    print(f"Banco: {DB_CONFIG['database']}")
    print(f"Usuário: {DB_CONFIG['user']}")
    print()
    
    try:
        # Conectar ao banco
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        print("✅ CONEXÃO ESTABELECIDA COM SUCESSO!")
        print()
        
        # 1. Verificar versão do PostgreSQL
        print("📌 Versão do PostgreSQL:")
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        print(f"   {version}")
        print()
        
        # 2. Listar todos os bancos de dados
        print("📌 Bancos de dados disponíveis:")
        cursor.execute("SELECT datname FROM pg_database WHERE datistemplate = false ORDER BY datname;")
        databases = cursor.fetchall()
        for db in databases:
            print(f"   - {db[0]}")
        print()
        
        # 3. Listar schemas no banco atual
        print(f"📌 Schemas no banco '{DB_CONFIG['database']}':")
        cursor.execute("""
            SELECT schema_name 
            FROM information_schema.schemata 
            WHERE schema_name NOT IN ('pg_catalog', 'information_schema')
            ORDER BY schema_name;
        """)
        schemas = cursor.fetchall()
        for schema in schemas:
            print(f"   - {schema[0]}")
        print()
        
        # 4. Listar tabelas
        print("📌 Tabelas no banco:")
        cursor.execute("""
            SELECT table_schema, table_name 
            FROM information_schema.tables 
            WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
            ORDER BY table_schema, table_name;
        """)
        tables = cursor.fetchall()
        
        if not tables:
            print("   ⚠️  NENHUMA TABELA ENCONTRADA!")
            print("   Isso pode significar que os dados estão em outro lugar.")
        else:
            for schema, table in tables:
                print(f"   - {schema}.{table}")
        print()
        
        # 5. Contar registros nas tabelas principais (se existirem)
        if tables:
            print("📌 Contagem de registros nas tabelas principais:")
            main_tables = ['usuarios', 'demandas', 'secretarias', 'configuracoes', 'notificacoes']
            
            for table_name in main_tables:
                try:
                    cursor.execute(sql.SQL("SELECT COUNT(*) FROM {}").format(sql.Identifier(table_name)))
                    count = cursor.fetchone()[0]
                    print(f"   - {table_name}: {count} registros")
                except psycopg2.Error as e:
                    print(f"   - {table_name}: (tabela não existe)")
            print()
        
        # 6. Verificar últimas inserções (se houver tabela de demandas)
        try:
            print("📌 Últimas 5 demandas criadas:")
            cursor.execute("""
                SELECT id, titulo, status, created_at 
                FROM demandas 
                ORDER BY created_at DESC 
                LIMIT 5;
            """)
            demandas = cursor.fetchall()
            if demandas:
                for demanda in demandas:
                    print(f"   - ID: {demanda[0]} | {demanda[1]} | Status: {demanda[2]} | Data: {demanda[3]}")
            else:
                print("   Nenhuma demanda encontrada")
            print()
        except psycopg2.Error:
            print("   (Tabela 'demandas' não existe ou erro ao consultar)")
            print()
        
        # 7. Verificar se há outros schemas ou bancos com dados
        print("📌 Procurando por outros bancos com nome similar:")
        cursor.execute("""
            SELECT datname 
            FROM pg_database 
            WHERE datname LIKE '%brief%' OR datname LIKE '%deb%'
            ORDER BY datname;
        """)
        similar_dbs = cursor.fetchall()
        if similar_dbs:
            for db in similar_dbs:
                print(f"   - {db[0]}")
        else:
            print("   Nenhum banco similar encontrado")
        print()
        
        # Fechar conexão
        cursor.close()
        conn.close()
        
        print_separator()
        print("✅ DIAGNÓSTICO COMPLETO!")
        print_separator()
        
        if not tables:
            print("\n⚠️  ATENÇÃO:")
            print("Nenhuma tabela foi encontrada no banco 'dbrief'.")
            print("Os dados podem estar em:")
            print("1. Um banco de dados diferente")
            print("2. Um container Docker local (debrief_db)")
            print("3. O banco ainda não foi inicializado")
            print("\nVerifique qual docker-compose está sendo usado no servidor.")
        
        return True
        
    except psycopg2.OperationalError as e:
        print(f"❌ ERRO DE CONEXÃO: {e}")
        print("\nPossíveis causas:")
        print("1. Credenciais incorretas")
        print("2. Firewall bloqueando a porta 5432")
        print("3. PostgreSQL não está aceitando conexões remotas")
        print("4. Host ou porta incorretos")
        return False
        
    except Exception as e:
        print(f"❌ ERRO INESPERADO: {e}")
        return False

if __name__ == "__main__":
    success = test_connection()
    sys.exit(0 if success else 1)


