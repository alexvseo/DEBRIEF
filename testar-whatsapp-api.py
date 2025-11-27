#!/usr/bin/env python3
"""
Script para testar a API WhatsApp wpapi
Testa conexão, lista grupos e envia mensagem de teste
"""
import requests
import json

# Configurações
API_URL = "http://82.25.92.217:3001"
API_KEY = "HUxJYioH28+/q45I46lAw5eCOGrHeeFpNPmfWVc/0Ck="

headers = {
    "X-API-Key": API_KEY,
    "Content-Type": "application/json"
}

def testar_status():
    """Testa o status da API"""
    print("=" * 60)
    print("1. TESTANDO STATUS DA API")
    print("=" * 60)
    
    try:
        response = requests.get(f"{API_URL}/status", timeout=10)
        data = response.json()
        
        print(f"Status Code: {response.status_code}")
        print(f"Conectado: {data.get('connected')}")
        print(f"Timestamp: {data.get('timestamp')}")
        
        if data.get('connected'):
            print("✅ WhatsApp está conectado!")
            return True
        else:
            print("❌ WhatsApp NÃO está conectado")
            print("   Escaneie o QR Code primeiro!")
            return False
            
    except Exception as e:
        print(f"❌ Erro ao conectar: {e}")
        return False

def listar_grupos():
    """Lista todos os grupos WhatsApp"""
    print("\n" + "=" * 60)
    print("2. LISTANDO GRUPOS WHATSAPP")
    print("=" * 60)
    
    try:
        response = requests.get(
            f"{API_URL}/groups",
            headers=headers,
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            grupos = data.get('groups', [])
            
            print(f"Total de grupos: {len(grupos)}\n")
            
            for i, grupo in enumerate(grupos, 1):
                print(f"{i}. {grupo.get('name')}")
                print(f"   ID: {grupo.get('id')}")
                print(f"   Participantes: {grupo.get('participantsCount')}")
                print()
            
            return grupos
        else:
            print(f"❌ Erro {response.status_code}: {response.text}")
            return []
            
    except Exception as e:
        print(f"❌ Erro ao listar grupos: {e}")
        return []

def enviar_teste(chat_id):
    """Envia mensagem de teste"""
    print("\n" + "=" * 60)
    print("3. ENVIANDO MENSAGEM DE TESTE")
    print("=" * 60)
    
    mensagem = """
🤖 *Teste de Integração DeBrief*

✅ API WhatsApp funcionando corretamente!

_Este é um teste automático do sistema DeBrief._
    """.strip()
    
    payload = {
        "chatId": chat_id,
        "message": mensagem
    }
    
    try:
        print(f"Enviando para: {chat_id}")
        print(f"Mensagem: {mensagem[:50]}...")
        
        response = requests.post(
            f"{API_URL}/send-message",
            headers=headers,
            json=payload,
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                print(f"✅ Mensagem enviada com sucesso!")
                print(f"   Message ID: {result.get('messageId')}")
                return True
            else:
                print(f"❌ Erro: {result.get('error')}")
                return False
        else:
            print(f"❌ Erro {response.status_code}: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro ao enviar: {e}")
        return False

def main():
    """Função principal"""
    print("\n🚀 TESTE DA API WHATSAPP - DeBrief")
    print("=" * 60)
    
    # 1. Testar status
    if not testar_status():
        print("\n⚠️ WhatsApp não conectado. Configure primeiro!")
        return
    
    # 2. Listar grupos
    grupos = listar_grupos()
    
    if not grupos:
        print("\n⚠️ Nenhum grupo encontrado")
        return
    
    # 3. Perguntar qual grupo testar
    print("\n" + "=" * 60)
    print("Escolha um grupo para enviar mensagem de teste:")
    print("=" * 60)
    
    try:
        escolha = int(input("Digite o número do grupo (0 para cancelar): "))
        
        if escolha == 0:
            print("❌ Teste cancelado")
            return
        
        if 1 <= escolha <= len(grupos):
            grupo = grupos[escolha - 1]
            chat_id = grupo.get('id')
            
            print(f"\n📱 Grupo selecionado: {grupo.get('name')}")
            confirma = input("Confirma envio da mensagem de teste? (s/N): ")
            
            if confirma.lower() == 's':
                enviar_teste(chat_id)
            else:
                print("❌ Envio cancelado")
        else:
            print("❌ Opção inválida")
            
    except ValueError:
        print("❌ Digite um número válido")
    except KeyboardInterrupt:
        print("\n❌ Teste cancelado pelo usuário")

if __name__ == "__main__":
    main()




