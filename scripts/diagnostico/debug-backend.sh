#!/bin/bash

# Script para Debug do Backend - DeBrief
# Inicia backend sem -d para ver erros em tempo real
# Execute no servidor: ./debug-backend.sh

echo "=========================================="
echo "🐛 DEBUG DO BACKEND - DeBrief"
echo "=========================================="
echo ""
echo "Este script irá iniciar o backend sem -d para mostrar erros em tempo real"
echo "Pressione Ctrl+C para parar"
echo ""
read -p "Pressione ENTER para continuar..."

# Parar backend se estiver rodando
echo "Parando backend atual..."
docker-compose stop backend 2>/dev/null || true
docker-compose rm -f backend 2>/dev/null || true

echo ""
echo "=========================================="
echo "Iniciando backend (modo debug)..."
echo "=========================================="
echo ""
echo "Os erros aparecerão abaixo:"
echo ""

# Iniciar backend sem -d para ver erros
docker-compose up backend

