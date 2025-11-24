#!/usr/bin/env python3
"""
Script para Registrar Webhook do Trello

Este script registra um webhook no Trello para sincronização bidirecional.
O webhook notifica o DeBrief sempre que um card é movido entre listas.

Uso:
    python scripts/registrar_webhook_trello.py

Ou:
    python scripts/registrar_webhook_trello.py --delete <webhook_id>  # Para deletar
    python scripts/registrar_webhook_trello.py --list                # Para listar

Requisitos:
    - Configuração Trello ativa no banco de dados
    - API Key e Token do Trello
    - URL pública do DeBrief acessível

Autor: DeBrief Sistema
Data: 2025-11-24
"""

import os
import sys
import requests
import argparse
from pathlib import Path

# Adicionar diretório raiz ao path para importar módulos
root_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(root_dir))

from backend.app.core.database import SessionLocal
from backend.app.models.configuracao_trello import ConfiguracaoTrello


def obter_configuracao_trello():
    """
    Buscar configuração ativa do Trello no banco de dados
    
    Returns:
        ConfiguracaoTrello ou None
    """
    db = SessionLocal()
    try:
        config = ConfiguracaoTrello.get_ativa(db)
        if not config:
            print("❌ Nenhuma configuração Trello ativa encontrada no banco de dados")
            print("   Configure o Trello primeiro em: https://debrief.interce.com.br/admin/trello-config")
            return None
        return config
    finally:
        db.close()


def listar_webhooks(api_key: str, token: str):
    """
    Listar todos os webhooks registrados
    
    Args:
        api_key: API Key do Trello
        token: Token do Trello
    """
    print("\n📋 Listando webhooks registrados...\n")
    
    url = f"https://api.trello.com/1/tokens/{token}/webhooks"
    params = {
        'key': api_key,
        'token': token
    }
    
    try:
        response = requests.get(url, params=params)
        response.raise_for_status()
        
        webhooks = response.json()
        
        if not webhooks:
            print("   Nenhum webhook registrado.")
            return
        
        for webhook in webhooks:
            print(f"   ID: {webhook['id']}")
            print(f"   URL: {webhook['callbackURL']}")
            print(f"   Model ID: {webhook['idModel']}")
            print(f"   Ativo: {'✅ Sim' if webhook.get('active') else '❌ Não'}")
            print(f"   Descrição: {webhook.get('description', 'N/A')}")
            print("-" * 80)
        
        print(f"\n✅ Total: {len(webhooks)} webhook(s)")
        
    except Exception as e:
        print(f"❌ Erro ao listar webhooks: {e}")


def deletar_webhook(webhook_id: str, api_key: str, token: str):
    """
    Deletar um webhook específico
    
    Args:
        webhook_id: ID do webhook
        api_key: API Key do Trello
        token: Token do Trello
    """
    print(f"\n🗑️  Deletando webhook {webhook_id}...\n")
    
    url = f"https://api.trello.com/1/webhooks/{webhook_id}"
    params = {
        'key': api_key,
        'token': token
    }
    
    try:
        response = requests.delete(url, params=params)
        response.raise_for_status()
        
        print(f"✅ Webhook {webhook_id} deletado com sucesso!")
        
    except Exception as e:
        print(f"❌ Erro ao deletar webhook: {e}")


def registrar_webhook(
    board_id: str,
    api_key: str,
    token: str,
    callback_url: str = "https://debrief.interce.com.br/api/trello/webhook",
    descricao: str = "DeBrief - Sincronização Bidirecional"
):
    """
    Registrar webhook no Trello
    
    Args:
        board_id: ID do board do Trello
        api_key: API Key do Trello
        token: Token do Trello
        callback_url: URL do webhook no DeBrief
        descricao: Descrição do webhook
        
    Returns:
        dict: Informações do webhook criado ou None se falhar
    """
    print("\n🔔 Registrando webhook no Trello...\n")
    print(f"   Board ID: {board_id}")
    print(f"   Callback URL: {callback_url}")
    print(f"   Descrição: {descricao}\n")
    
    # URL da API do Trello para criar webhook
    url = "https://api.trello.com/1/webhooks/"
    
    # Dados do webhook
    data = {
        'key': api_key,
        'token': token,
        'callbackURL': callback_url,
        'idModel': board_id,
        'description': descricao
    }
    
    try:
        # Criar webhook
        response = requests.post(url, data=data)
        response.raise_for_status()
        
        webhook_info = response.json()
        
        print("✅ Webhook registrado com sucesso!\n")
        print(f"   Webhook ID: {webhook_info['id']}")
        print(f"   URL: {webhook_info['callbackURL']}")
        print(f"   Model ID: {webhook_info['idModel']}")
        print(f"   Ativo: {'✅ Sim' if webhook_info.get('active') else '❌ Não'}\n")
        
        print("📌 IMPORTANTE:")
        print("   1. O webhook está ativo e começará a enviar notificações")
        print("   2. Certifique-se de que a URL está acessível publicamente")
        print("   3. Teste movendo um card entre listas no Trello")
        print(f"   4. Guarde o Webhook ID para deletar no futuro: {webhook_info['id']}\n")
        
        return webhook_info
        
    except requests.exceptions.HTTPError as e:
        print(f"❌ Erro HTTP ao registrar webhook: {e}")
        print(f"   Status Code: {e.response.status_code}")
        print(f"   Resposta: {e.response.text}\n")
        
        if e.response.status_code == 400:
            print("💡 Dica: Verifique se:")
            print("   - A API Key e Token estão corretos")
            print("   - O Board ID está correto")
            print("   - A URL do callback está acessível publicamente")
            print("   - Você não está tentando registrar um webhook duplicado\n")
        
        return None
        
    except Exception as e:
        print(f"❌ Erro ao registrar webhook: {e}\n")
        return None


def main():
    """Função principal"""
    parser = argparse.ArgumentParser(
        description="Gerenciar webhooks do Trello para sincronização bidirecional"
    )
    
    parser.add_argument(
        '--list',
        action='store_true',
        help='Listar todos os webhooks registrados'
    )
    
    parser.add_argument(
        '--delete',
        type=str,
        metavar='WEBHOOK_ID',
        help='Deletar um webhook específico'
    )
    
    parser.add_argument(
        '--url',
        type=str,
        default='https://debrief.interce.com.br/api/trello/webhook',
        help='URL do callback do webhook (padrão: https://debrief.interce.com.br/api/trello/webhook)'
    )
    
    args = parser.parse_args()
    
    print("=" * 80)
    print("🔗 GERENCIADOR DE WEBHOOK TRELLO - DEBRIEF")
    print("=" * 80)
    
    # Buscar configuração do Trello
    config = obter_configuracao_trello()
    if not config:
        sys.exit(1)
    
    # Listar webhooks
    if args.list:
        listar_webhooks(config.api_key, config.token)
        sys.exit(0)
    
    # Deletar webhook
    if args.delete:
        deletar_webhook(args.delete, config.api_key, config.token)
        sys.exit(0)
    
    # Registrar webhook (padrão)
    resultado = registrar_webhook(
        board_id=config.board_id,
        api_key=config.api_key,
        token=config.token,
        callback_url=args.url
    )
    
    if resultado:
        print("✅ Webhook configurado com sucesso! Sincronização bidirecional ativada.\n")
        sys.exit(0)
    else:
        print("❌ Falha ao configurar webhook.\n")
        sys.exit(1)


if __name__ == "__main__":
    main()

