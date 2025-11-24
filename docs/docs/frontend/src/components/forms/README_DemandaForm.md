# 📝 DemandaForm.jsx - Documentação Completa

Componente de formulário para criar e editar demandas no sistema DeBrief.

## 🎯 Funcionalidades

### ✅ Recursos Implementados

1. **Validação Completa com Zod**
   - Validação de campos obrigatórios
   - Validação de tamanhos (min/max)
   - Validação de UUIDs
   - Validação de data (não permite datas passadas)
   - Mensagens de erro personalizadas

2. **Upload de Arquivos Avançado**
   - Drag & Drop funcional
   - Validação de tipo (PDF, JPG, PNG)
   - Validação de tamanho (máx 50MB por arquivo)
   - Limite de 5 arquivos
   - Preview de imagens
   - Ícones para PDFs
   - Remoção individual de arquivos
   - Detecção de duplicatas
   - Formatação de tamanho de arquivo

3. **Carregamento Dinâmico de Dados**
   - Secretarias do cliente logado
   - Tipos de demanda ativos
   - Prioridades ordenadas por nível
   - Loading states durante carregamento

4. **UX/UI Aprimorado**
   - Design responsivo (mobile-first)
   - Feedback visual em todas as ações
   - Estados de loading
   - Mensagens de erro claras
   - Contador de caracteres
   - Alertas informativos
   - Ícones ilustrativos

5. **Integração com API**
   - Criação de novas demandas
   - Edição de demandas existentes
   - Upload de múltiplos arquivos
   - Tratamento de erros HTTP específicos
   - Notificações toast de sucesso/erro

6. **Acessibilidade**
   - Labels associados aos inputs
   - IDs únicos para cada campo
   - Indicação visual de campos obrigatórios
   - Estados disabled claros
   - Mensagens de erro legíveis

---

## 📦 Dependências

```javascript
// React e Hooks
import React, { useState, useEffect } from 'react'
import { useForm, Controller } from 'react-hook-form'

// Validação
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'

// UI e Notificações
import { toast } from 'sonner'
import { 
  Calendar, Upload, X, FileText, 
  Image as ImageIcon, Loader2, AlertCircle 
} from 'lucide-react'

// Utilitários
import { format } from 'date-fns'
import { ptBR } from 'date-fns/locale'

// Componentes customizados
import Button from '@/components/ui/button'
import Input from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Alert, AlertDescription } from '@/components/ui/alert'

// Services
import { demandaService } from '@/services/demandaService'

// Hooks
import { useAuth } from '@/hooks/useAuth'
```

---

## 🚀 Como Usar

### Exemplo Básico - Criar Nova Demanda

```javascript
import React from 'react'
import { useNavigate } from 'react-router-dom'
import DemandaForm from '@/components/forms/DemandaForm'

function NovaDemandaPage() {
  const navigate = useNavigate()
  
  const handleSuccess = (demanda) => {
    console.log('Demanda criada:', demanda)
    // Redirecionar para lista de demandas
    navigate('/demandas')
  }
  
  const handleCancel = () => {
    // Voltar para página anterior
    navigate(-1)
  }
  
  return (
    <div className="container mx-auto py-8">
      <DemandaForm 
        onSuccess={handleSuccess}
        onCancel={handleCancel}
      />
    </div>
  )
}

export default NovaDemandaPage
```

### Exemplo - Editar Demanda Existente

```javascript
import React, { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import DemandaForm from '@/components/forms/DemandaForm'
import { demandaService } from '@/services/demandaService'
import Loading from '@/components/common/Loading'

function EditarDemandaPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [demanda, setDemanda] = useState(null)
  const [isLoading, setIsLoading] = useState(true)
  
  useEffect(() => {
    const loadDemanda = async () => {
      try {
        const data = await demandaService.getById(id)
        setDemanda(data)
      } catch (error) {
        console.error('Erro ao carregar demanda:', error)
        navigate('/demandas')
      } finally {
        setIsLoading(false)
      }
    }
    
    loadDemanda()
  }, [id])
  
  const handleSuccess = (demandaAtualizada) => {
    console.log('Demanda atualizada:', demandaAtualizada)
    navigate('/demandas')
  }
  
  const handleCancel = () => {
    navigate('/demandas')
  }
  
  if (isLoading) {
    return <Loading />
  }
  
  return (
    <div className="container mx-auto py-8">
      <DemandaForm 
        demanda={demanda}
        onSuccess={handleSuccess}
        onCancel={handleCancel}
      />
    </div>
  )
}

export default EditarDemandaPage
```

### Exemplo - Usar em Modal

```javascript
import React, { useState } from 'react'
import { Dialog, DialogContent } from '@/components/ui/dialog'
import DemandaForm from '@/components/forms/DemandaForm'

function MeuComponente() {
  const [isModalOpen, setIsModalOpen] = useState(false)
  
  const handleSuccess = (demanda) => {
    console.log('Demanda criada:', demanda)
    setIsModalOpen(false)
    // Atualizar lista, etc.
  }
  
  return (
    <>
      <button onClick={() => setIsModalOpen(true)}>
        Nova Demanda
      </button>
      
      <Dialog open={isModalOpen} onOpenChange={setIsModalOpen}>
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
          <DemandaForm 
            onSuccess={handleSuccess}
            onCancel={() => setIsModalOpen(false)}
          />
        </DialogContent>
      </Dialog>
    </>
  )
}
```

---

## 🎨 Props do Componente

| Prop | Tipo | Obrigatório | Padrão | Descrição |
|------|------|-------------|---------|-----------|
| `demanda` | Object \| null | Não | `null` | Dados da demanda para edição. Se `null`, cria nova demanda |
| `onSuccess` | Function | Não | - | Callback executado após criar/editar com sucesso. Recebe dados da demanda criada/atualizada |
| `onCancel` | Function | Não | - | Callback para cancelar operação. Se não fornecido, botão Cancelar não aparece |

### Estrutura do Objeto `demanda`

```javascript
{
  id: "uuid-da-demanda",
  secretaria_id: "uuid-da-secretaria",
  nome: "Nome da Demanda",
  tipo_demanda_id: "uuid-do-tipo",
  prioridade_id: "uuid-da-prioridade",
  descricao: "Descrição detalhada...",
  prazo_final: "2024-12-31",
  // ... outros campos
}
```

---

## 🎨 Campos do Formulário

### 1. Secretaria (Obrigatório)
- **Tipo:** Select/Dropdown
- **Validação:** UUID válido, não vazio
- **Carregamento:** Dinâmico via API (filtrado por cliente do usuário)

### 2. Tipo de Demanda (Obrigatório)
- **Tipo:** Select/Dropdown
- **Validação:** UUID válido, não vazio
- **Carregamento:** Dinâmico via API (apenas tipos ativos)
- **Exemplos:** Design, Desenvolvimento, Conteúdo, Vídeo

### 3. Prioridade (Obrigatório)
- **Tipo:** Select/Dropdown
- **Validação:** UUID válido, não vazio
- **Carregamento:** Dinâmico via API (ordenado por nível)
- **Níveis:** Baixa 🟢, Média 🟡, Alta 🟠, Urgente 🔴

### 4. Prazo Final (Obrigatório)
- **Tipo:** Date input
- **Validação:** Data atual ou futura
- **Formato:** yyyy-MM-dd
- **Restrição:** `min` definido como data de hoje

### 5. Nome da Demanda (Obrigatório)
- **Tipo:** Text input
- **Validação:** 5-200 caracteres
- **Contador:** Exibe caracteres digitados
- **Placeholder:** "Ex: Criação de arte para campanha de vacinação"

### 6. Descrição (Obrigatório)
- **Tipo:** Textarea
- **Validação:** 10-2000 caracteres
- **Contador:** Exibe caracteres digitados com alerta em 1900+
- **Rows:** 6 (expansível)
- **Dica:** "Quanto mais detalhes, melhor será o resultado"

### 7. Anexos (Opcional)
- **Tipo:** File upload múltiplo
- **Formatos:** PDF, JPG, JPEG, PNG
- **Tamanho máx:** 50MB por arquivo
- **Quantidade máx:** 5 arquivos
- **Recursos:**
  - Drag & Drop
  - Preview de imagens
  - Ícone para PDFs
  - Informação de tamanho
  - Remoção individual
  - Detecção de duplicatas

---

## 🔒 Validações Implementadas

### Schema Zod

```javascript
const demandaSchema = z.object({
  secretaria_id: z.string()
    .min(1, 'Selecione uma secretaria')
    .uuid('ID de secretaria inválido'),
  
  nome: z.string()
    .min(5, 'Nome deve ter pelo menos 5 caracteres')
    .max(200, 'Nome deve ter no máximo 200 caracteres')
    .trim(),
  
  tipo_demanda_id: z.string()
    .min(1, 'Selecione um tipo de demanda')
    .uuid('ID de tipo inválido'),
  
  prioridade_id: z.string()
    .min(1, 'Selecione uma prioridade')
    .uuid('ID de prioridade inválido'),
  
  descricao: z.string()
    .min(10, 'Descrição deve ter pelo menos 10 caracteres')
    .max(2000, 'Descrição deve ter no máximo 2000 caracteres')
    .trim(),
  
  prazo_final: z.string()
    .min(1, 'Selecione uma data')
    .refine(
      (date) => new Date(date) >= new Date().setHours(0, 0, 0, 0),
      'Prazo deve ser hoje ou uma data futura'
    ),
})
```

### Validações de Arquivo

```javascript
// Tamanho máximo
const MAX_FILE_SIZE = 52428800 // 50MB

// Tipos MIME permitidos
const ALLOWED_MIME_TYPES = [
  'application/pdf',
  'image/jpeg',
  'image/png',
  'image/jpg'
]

// Extensões permitidas (fallback)
const ALLOWED_EXTENSIONS = ['.pdf', '.jpg', '.jpeg', '.png']

// Limite de arquivos
const MAX_FILES = 5
```

---

## 🎯 Estados do Componente

### Estados Principais

```javascript
const [isSubmitting, setIsSubmitting] = useState(false)
// Estado de envio do formulário

const [files, setFiles] = useState([])
// Array de arquivos selecionados (File objects)

const [filePreviews, setFilePreviews] = useState([])
// Array de previews dos arquivos

const [isDragging, setIsDragging] = useState(false)
// Estado de drag & drop

const [secretarias, setSecretarias] = useState([])
const [tiposDemanda, setTiposDemanda] = useState([])
const [prioridades, setPrioridades] = useState([])
// Dados dos dropdowns

const [isLoadingData, setIsLoadingData] = useState(true)
// Estado de carregamento inicial dos dados
```

---

## 🚀 Fluxo de Submissão

1. **Validação Frontend (Zod)**
   - Valida todos os campos antes de submeter
   - Exibe mensagens de erro específicas
   - Previne submissão se houver erros

2. **Preparação dos Dados**
   - Cria `FormData` para suportar arquivos
   - Adiciona campos do formulário
   - Adiciona ID do usuário logado
   - Adiciona todos os arquivos selecionados

3. **Envio para API**
   - POST `/api/demandas` (criação)
   - PUT `/api/demandas/:id` (edição)
   - Headers: `Content-Type: multipart/form-data`
   - Autenticação via JWT token (automático)

4. **Processamento Backend**
   - Valida dados novamente
   - Salva no PostgreSQL
   - Cria card no Trello
   - Upload de anexos no Trello
   - Envia notificação WhatsApp
   - Registra logs

5. **Feedback ao Usuário**
   - Toast de sucesso
   - Callback `onSuccess` executado
   - Formulário resetado (se criação)
   - Arquivos limpos

---

## 🎨 Tratamento de Erros

### Erros de Validação

Exibidos abaixo de cada campo com ícone de alerta:

```javascript
{errors.nome && (
  <p className="mt-1 text-sm text-red-500 flex items-center">
    <AlertCircle className="h-3 w-3 mr-1" />
    {errors.nome.message}
  </p>
)}
```

### Erros de API

Tratamento específico por código HTTP:

```javascript
// 400 - Dados inválidos
toast.error('Dados inválidos. Verifique os campos e tente novamente.')

// 401 - Não autenticado
toast.error('Sessão expirada. Faça login novamente.')

// 413 - Payload muito grande
toast.error('Arquivos muito grandes. Reduza o tamanho e tente novamente.')

// Outros erros
toast.error(error.response?.data?.detail || 'Erro ao salvar demanda.')
```

### Erros de Upload

Validações antes de adicionar arquivo:

```javascript
// Tamanho
if (file.size > 52428800) {
  toast.error(`${file.name} é muito grande (máx 50MB)`)
  return false
}

// Tipo
if (!allowedTypes.includes(file.type)) {
  toast.error(`${file.name} tem tipo não permitido. Use PDF, JPG ou PNG`)
  return false
}

// Limite
if (files.length >= 5) {
  toast.error('Máximo de 5 arquivos permitido')
  return
}

// Duplicata
if (isDuplicate) {
  toast.warning(`${newFile.name} já foi adicionado`)
}
```

---

## 🎯 Notificações (Toasts)

### Sucesso
- ✅ Demanda criada: "Demanda criada com sucesso! Card criado no Trello e notificação enviada no WhatsApp."
- ✅ Demanda atualizada: "Demanda atualizada com sucesso!"
- ✅ Arquivo adicionado: "X arquivo(s) adicionado(s)"

### Informação
- ℹ️ Arquivo removido: "Arquivo removido"
- ⚠️ Arquivo duplicado: "{nome} já foi adicionado"

### Erro
- ❌ Arquivo muito grande
- ❌ Tipo não permitido
- ❌ Limite excedido
- ❌ Erro ao salvar

---

## 📱 Responsividade

### Breakpoints

- **Mobile (< 640px):** 1 coluna, botões full-width
- **Tablet (640px - 768px):** 2 colunas no grid de campos
- **Desktop (> 768px):** 2 colunas, layout otimizado

### Adaptações Mobile

```javascript
// Grid responsivo
<div className="grid grid-cols-1 md:grid-cols-2 gap-4">

// Botões responsivos
<div className="flex flex-col sm:flex-row justify-end gap-3">
  <Button className="w-full sm:w-auto">
```

---

## ♿ Acessibilidade

- ✅ Labels associados via `htmlFor` e `id`
- ✅ Indicação visual de campos obrigatórios (*)
- ✅ Mensagens de erro descritivas
- ✅ Estados disabled visualmente claros
- ✅ Ícones com significado semântico
- ✅ Cores de contraste adequadas
- ✅ Foco visível nos elementos interativos

---

## 🎨 Personalização

### Cores e Estilos

O componente usa classes do TailwindCSS. Para personalizar:

```javascript
// Cores de erro
className="border-red-500 text-red-500"

// Cores de sucesso
className="border-green-500 text-green-500"

// Cores primárias
className="border-blue-500 focus:ring-blue-500"
```

### Mensagens

Todas as mensagens estão hardcoded em português. Para i18n, extrair para arquivo de tradução.

---

## 🧪 Testes Sugeridos

### Testes Unitários

```javascript
describe('DemandaForm', () => {
  it('deve renderizar todos os campos obrigatórios', () => {})
  it('deve validar campos vazios', () => {})
  it('deve validar tamanho do nome (5-200)', () => {})
  it('deve validar tamanho da descrição (10-2000)', () => {})
  it('deve validar data futura', () => {})
  it('deve permitir upload de PDF', () => {})
  it('deve permitir upload de JPG/PNG', () => {})
  it('deve rejeitar arquivo > 50MB', () => {})
  it('deve limitar a 5 arquivos', () => {})
  it('deve detectar duplicatas', () => {})
})
```

### Testes de Integração

```javascript
it('deve criar demanda com sucesso', async () => {})
it('deve editar demanda existente', async () => {})
it('deve fazer upload de múltiplos arquivos', async () => {})
it('deve exibir toast de sucesso', async () => {})
it('deve chamar callback onSuccess', async () => {})
```

---

## 📚 Recursos Adicionais

### Documentação Relacionada
- [React Hook Form](https://react-hook-form.com)
- [Zod Validation](https://zod.dev)
- [Lucide Icons](https://lucide.dev)
- [date-fns](https://date-fns.org)
- [Sonner Toasts](https://sonner.emilkowal.ski/)

### Próximos Passos
1. Implementar editor rico para descrição (TipTap/Quill)
2. Adicionar campo de tags/etiquetas
3. Implementar salvamento de rascunho
4. Adicionar preview do card do Trello antes de criar
5. Implementar upload por URL
6. Adicionar compressão automática de imagens

---

**Componente criado com ❤️ para o sistema DeBrief**

