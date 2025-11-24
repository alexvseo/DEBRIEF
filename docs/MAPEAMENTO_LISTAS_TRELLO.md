# 🗺️ MAPEAMENTO DE LISTAS TRELLO - CONFIGURAÇÃO FINAL

**Data**: 24 de Novembro de 2025  
**Board Trello ID**: 5ea0970cc7f8bd3bf93752a4  
**Status**: ✅ **CONFIGURADO**

---

## 📋 **LISTAS CONFIGURADAS**

### **Lista 1: ENVIOS DOS CLIENTES VIA DEBRIEF**
```json
{
  "id": "6810f40131d456a240f184ba",
  "name": "ENVIOS DOS CLIENTES VIA DEBRIEF",
  "idBoard": "5ea0970cc7f8bd3bf93752a4"
}
```
- **Status no DeBrief**: `aberta` 📂
- **Quando usar**: Cards recém-criados pelo DeBrief
- **Quando mover**: Quando iniciar o trabalho

---

### **Lista 2: EM DESENVOLVIMENTO**
```json
{
  "id": "68b82f29253b5480f0c06f3d",
  "name": "EM DESENVOLVIMENTO",
  "idBoard": "5ea0970cc7f8bd3bf93752a4"
}
```
- **Status no DeBrief**: `em_andamento` ⚙️
- **Quando usar**: Demandas em execução
- **Quando mover**: Quando concluir o trabalho

---

### **Lista 3: EM ESPERA**
```json
{
  "id": "5ea097406d864d89b0017aa3",
  "name": "EM ESPERA",
  "idBoard": "5ea0970cc7f8bd3bf93752a4"
}
```
- **Status no DeBrief**: `concluida` ✅
- **Quando usar**: Demandas finalizadas/entregues
- **Nota importante**: Esta lista representa demandas **CONCLUÍDAS** no DeBrief

---

## 🔄 **FLUXO DE SINCRONIZAÇÃO**

### **Trello → DeBrief** (Webhook)

| Ação no Trello | Status no DeBrief | Notificação WhatsApp |
|---------------|-------------------|---------------------|
| Move para "ENVIOS DOS CLIENTES VIA DEBRIEF" | `aberta` | ✅ Sim |
| Move para "EM DESENVOLVIMENTO" | `em_andamento` | ✅ Sim |
| Move para "EM ESPERA" | `concluida` | ✅ Sim |

### **DeBrief → Trello** (Sincronização automática)

| Status no DeBrief | Lista no Trello | Ação |
|------------------|----------------|------|
| `aberta` | ENVIOS DOS CLIENTES VIA DEBRIEF | Move card |
| `em_andamento` | EM DESENVOLVIMENTO | Move card |
| `aguardando_cliente` | EM DESENVOLVIMENTO | Mantém em desenvolvimento |
| `concluida` | EM ESPERA | Move card |
| `cancelada` | - | **Arquiva card** (sem lista) |

---

## ⚙️ **ARQUIVOS ATUALIZADOS**

### **1. Backend - Webhook (Trello → DeBrief)**

**Arquivo**: `backend/app/api/endpoints/trello_webhook.py`

```python
# Linha ~62-90
mapeamento = {
    # Lista: ENVIOS DOS CLIENTES VIA DEBRIEF
    'envios dos clientes via debrief': StatusDemanda.ABERTA.value,
    'envios dos clientes': StatusDemanda.ABERTA.value,
    'envios': StatusDemanda.ABERTA.value,
    
    # Lista: EM DESENVOLVIMENTO
    'em desenvolvimento': StatusDemanda.EM_ANDAMENTO.value,
    'desenvolvimento': StatusDemanda.EM_ANDAMENTO.value,
    
    # Lista: EM ESPERA (= CONCLUÍDA no DeBrief)
    'em espera': StatusDemanda.CONCLUIDA.value,
    'espera': StatusDemanda.CONCLUIDA.value,
}
```

### **2. Backend - Serviço (DeBrief → Trello)**

**Arquivo**: `backend/app/services/trello.py`

```python
# Linha ~444-450
mapeamento = {
    'aberta': 'ENVIOS DOS CLIENTES VIA DEBRIEF',
    'em_andamento': 'EM DESENVOLVIMENTO',
    'aguardando_cliente': 'EM DESENVOLVIMENTO',  # Mantém em desenvolvimento
    'concluida': 'EM ESPERA',
    # 'cancelada' → card será arquivado
}
```

---

## 📝 **OBSERVAÇÕES IMPORTANTES**

### **1. Status "Cancelada"**
- ✅ **Não tem lista no Trello** (conforme solicitado)
- ✅ Quando uma demanda é cancelada no DeBrief, o card é **arquivado automaticamente**
- ✅ Isso remove o card das listas visíveis no board

### **2. Lista "EM ESPERA" = Demandas Concluídas**
- ✅ A lista "EM ESPERA" no Trello representa demandas **CONCLUÍDAS** no DeBrief
- ✅ Quando você move um card para "EM ESPERA", o status muda para `concluida`
- ✅ Quando você marca uma demanda como concluída no DeBrief, o card vai para "EM ESPERA"

### **3. Status "Aguardando Cliente"**
- ✅ Cards com status `aguardando_cliente` **permanecem em "EM DESENVOLVIMENTO"**
- ✅ Não foi criada uma lista separada para esse status
- ✅ Você pode criar uma lista específica no futuro, se desejar

---

## ✅ **VERIFICAÇÃO**

### **Checklist de Configuração**

- [x] Mapeamento Trello → DeBrief configurado
- [x] Mapeamento DeBrief → Trello configurado
- [x] IDs das listas corretos
- [x] Nomes das listas case-insensitive
- [x] Status "cancelada" sem lista (arquiva card)
- [x] Lista "EM ESPERA" = Concluída
- [x] Documentação atualizada
- [x] Código sem erros de lint

### **Próximo Passo: Deploy**

```bash
# 1. Commit
git add .
git commit -m "config: Configurar listas específicas do Trello"
git push origin main

# 2. Deploy
./scripts/deploy.sh

# 3. Registrar webhook
ssh root@82.25.92.217
cd /var/www/debrief
source venv/bin/activate
python scripts/registrar_webhook_trello.py
```

---

## 🧪 **TESTE SUGERIDO**

### **Cenário de Teste Completo**

1. **Criar demanda no DeBrief**
   - ✅ Card criado em "ENVIOS DOS CLIENTES VIA DEBRIEF"

2. **Mover card para "EM DESENVOLVIMENTO" no Trello**
   - ✅ Status atualizado para `em_andamento` no DeBrief
   - ✅ Notificação WhatsApp: "Aberta → Em Andamento"

3. **Mover card para "EM ESPERA" no Trello**
   - ✅ Status atualizado para `concluida` no DeBrief
   - ✅ Notificação WhatsApp: "Em Andamento → Concluída"

4. **Editar demanda no DeBrief (mudar para "Em Andamento")**
   - ✅ Card movido para "EM DESENVOLVIMENTO" no Trello
   - ✅ Notificação WhatsApp enviada

5. **Cancelar demanda no DeBrief**
   - ✅ Card **arquivado** no Trello (não visível)
   - ✅ Status `cancelada` no DeBrief

---

## 📊 **ESTATÍSTICAS FINAIS**

| Item | Valor |
|------|-------|
| Total de listas configuradas | **3** |
| Status mapeados | **4** (aberta, em_andamento, concluida, cancelada) |
| Arquivos modificados | **6** |
| Linhas de código atualizadas | ~50 |
| Documentação atualizada | **4 arquivos** |

---

## 🎯 **RESULTADO**

✅ **Mapeamento específico configurado com sucesso!**  
✅ **Todas as 3 listas do seu board estão mapeadas corretamente**  
✅ **Sistema pronto para sincronização bidirecional**  

🚀 **Pronto para deploy!**

---

**📌 Referência Rápida**:
- ENVIOS DOS CLIENTES VIA DEBRIEF → aberta 📂
- EM DESENVOLVIMENTO → em_andamento ⚙️
- EM ESPERA → concluida ✅
- (cancelada → arquiva card) 🗑️

