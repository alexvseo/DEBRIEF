# 📋 FORMATO DO CARD TRELLO - ESPECIFICAÇÃO FINAL

## 🎯 **FORMATO COMPLETO**

---

## 📌 **TÍTULO DO CARD**

### **Formato**
```
Nome do Cliente - TIPO DE DEMANDA - Nome da Demanda
```

### **Exemplos**
```
RUSSAS - DESIGN - Criação de um card teste
RUSSAS - DESENVOLVIMENTO - Sistema de gestão municipal
Prefeitura - CONSULTORIA - Planejamento estratégico 2025
Câmara - SOCIAL MEDIA - Campanha institucional
```

### **Componentes**
1. **Nome do Cliente**: Nome do cliente cadastrado no sistema
2. **TIPO DE DEMANDA**: Tipo em MAIÚSCULAS (DESIGN, DESENVOLVIMENTO, CONSULTORIA, etc)
3. **Nome da Demanda**: Título da demanda informado no formulário

---

## 📝 **DESCRIÇÃO DO CARD**

### **Estrutura Completa**

```markdown
**Secretaria:** Secretaria de Comunicação
**Tipo:** Design
**Prioridade:** Alta
**Prazo:** 30/11/2025

**Descrição:**
Criar um novo design para o portal da prefeitura com foco em
acessibilidade e responsividade. O design deve seguir as
diretrizes de identidade visual do município.

**Links de Referência:**
- [Documentação](https://exemplo.com/doc)
- [Referência Visual](https://exemplo.com/mockup.png)
- [Guidelines de Acessibilidade](https://exemplo.com/wcag)

**Solicitante:** João Silva
**Email:** joao.silva@prefeitura.gov.br

---
**ID da Demanda:** a1b2c3d4-e5f6-7890-abcd-ef1234567890
**Status:** aberta
```

### **Componentes da Descrição**

#### **1. Informações Principais** ✅
- **Secretaria**: Departamento responsável
- **Tipo**: Tipo de demanda
- **Prioridade**: Nível de prioridade
- **Prazo**: Data limite formatada (DD/MM/AAAA)

#### **2. Descrição Detalhada** ✅
- Texto completo fornecido pelo usuário no formulário
- Sem limite de tamanho (até 2000 caracteres no sistema)

#### **3. Links de Referência** ✅ *(se houver)*
- Lista com título e URL
- Links clicáveis
- Formato Markdown `[Título](URL)`

#### **4. Informações do Solicitante** ✅
- Nome completo do usuário
- Email para contato

#### **5. Metadados** ✅
- ID único da demanda
- Status atual

---

## 📎 **ANEXOS DO CARD**

### **Imagens e Arquivos** ✅
- Todos os arquivos anexados no formulário são vinculados ao card
- Formatos suportados: PDF, JPG, JPEG, PNG
- Máximo: 5 arquivos por demanda
- Tamanho máximo: 50MB por arquivo

### **Como são anexados**
1. Sistema faz upload do arquivo para o servidor
2. Gera URL pública do arquivo
3. Anexa a URL ao card do Trello
4. Nome do arquivo original é preservado

---

## 🏷️ **ETIQUETA DO CARD**

### **Aplicação Automática** ✅
- **Etiqueta do Cliente**: Aplicada automaticamente baseada no cliente
- **Etiqueta de Prioridade** *(opcional)*: Se houver label com nome da prioridade

### **Exemplo**
```
Cliente: RUSSAS → Etiqueta: "RUSSAS" (cor verde)
Prioridade: Alta → Etiqueta: "Alta" (cor vermelha)
```

---

## 📅 **PRAZO (DUE DATE)**

### **Configuração** ✅
- **Campo**: Prazo Final da demanda
- **Formato**: Data convertida automaticamente
- **Alertas**: Trello envia notificações de prazo automaticamente

---

## 👤 **MEMBRO ATRIBUÍDO** *(opcional)*

### **Atribuição** ✅
- Se o cliente tiver `trello_member_id` configurado
- Membro do Trello é automaticamente atribuído ao card
- Receberá notificações do Trello sobre o card

---

## 🎯 **EXEMPLO COMPLETO DE CARD**

### **Título**
```
RUSSAS - DESIGN - Portal da Transparência
```

### **Descrição**
```markdown
**Secretaria:** Secretaria de Comunicação
**Tipo:** Design
**Prioridade:** Alta
**Prazo:** 15/12/2025

**Descrição:**
Desenvolver o layout completo para o novo Portal da Transparência
da Prefeitura Municipal de Russas. O portal deve conter:
- Página inicial com destaques
- Seção de documentos públicos
- Área de consulta de processos
- Sistema de busca avançada
- Design responsivo (mobile e desktop)

**Links de Referência:**
- [Portal Modelo](https://exemplo.gov.br/transparencia)
- [Guia de Acessibilidade WCAG](https://www.w3.org/WAI/WCAG21/)
- [Paleta de Cores](https://coolors.co/palette/abc123)
- [Mockup Inicial](https://figma.com/file/example)

**Solicitante:** Maria Santos
**Email:** maria.santos@russas.ce.gov.br

---
**ID da Demanda:** 7f8e9d0c-1b2a-3c4d-5e6f-708192a3b4c5
**Status:** aberta
```

### **Etiquetas**
- 🟢 RUSSAS (verde)
- 🔴 Alta (vermelho)

### **Anexos**
- `logo_prefeitura.png` (2.5 MB)
- `wireframe_portal.pdf` (1.8 MB)
- `referencia_01.jpg` (3.2 MB)

### **Prazo**
- 📅 15 de Dezembro de 2025

### **Lista**
- 📋 ENVIOS DOS CLIENTES VIA DEBRIEF

### **Membro**
- 👤 João Trello (@joaotrello)

---

## 🔄 **PROCESSO DE CRIAÇÃO**

```
1. Usuário preenche formulário no DeBrief
   ├─ Nome da demanda
   ├─ Descrição detalhada
   ├─ Links de referência (opcional)
   └─ Anexos (opcional)
   ↓
2. Sistema salva demanda no banco
   ↓
3. TrelloService.criar_card() é executado
   ├─ Monta título: "Cliente - TIPO - Nome"
   ├─ Monta descrição com todas as informações
   ├─ Cria card na lista configurada
   ├─ Aplica etiqueta do cliente
   ├─ Anexa arquivos (se houver)
   ├─ Define prazo (due date)
   └─ Atribui membro (se configurado)
   ↓
4. ✅ Card criado com sucesso!
   ├─ URL do card salva na demanda
   └─ Logs registrados
```

---

## 📊 **INFORMAÇÕES TÉCNICAS**

### **Código de Criação**
```python
# backend/app/services/trello.py

# Título
card_name = f"{demanda.cliente.nome} - {demanda.tipo_demanda.nome.upper()} - {demanda.nome}"

# Descrição (Markdown)
card_desc = """
**Secretaria:** {secretaria}
**Tipo:** {tipo}
**Prioridade:** {prioridade}
**Prazo:** {prazo}

**Descrição:**
{descricao}

**Links de Referência:**
- [Título](URL)

**Solicitante:** {nome}
**Email:** {email}

---
**ID da Demanda:** {id}
**Status:** {status}
"""

# Criar card
card = self.list.add_card(
    name=card_name,
    desc=card_desc,
    position='top'
)

# Aplicar etiqueta do cliente
etiqueta = EtiquetaTrelloCliente.get_by_cliente(db, cliente_id)
if etiqueta:
    card.add_label(etiqueta.etiqueta_trello_id)

# Anexar arquivos
for anexo in demanda.anexos:
    card.attach(url=anexo_url, name=anexo.nome_arquivo)

# Definir prazo
card.set_due(demanda.prazo_final)

# Atribuir membro
if demanda.cliente.trello_member_id:
    card.add_member(demanda.cliente.trello_member_id)
```

---

## ✅ **CHECKLIST DE VALIDAÇÃO**

Ao criar um card no Trello, verificar:

- [ ] Título tem formato correto: "Cliente - TIPO - Nome"
- [ ] TIPO está em MAIÚSCULAS
- [ ] Descrição contém todas as seções
- [ ] Links de referência estão formatados como Markdown
- [ ] Todos os anexos foram vinculados
- [ ] Etiqueta do cliente foi aplicada
- [ ] Prazo (due date) está definido
- [ ] Membro foi atribuído (se configurado)
- [ ] Card está na lista correta
- [ ] Card está no topo da lista (position: 'top')

---

**Data**: 23 de Novembro de 2025  
**Status**: ✅ Especificação Final Aprovada  
**Arquivo de Referência**: `backend/app/services/trello.py` - método `criar_card()`

