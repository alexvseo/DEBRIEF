# 🎨 Componentes UI - DeBrief

Biblioteca de componentes UI reutilizáveis baseada no padrão shadcn/ui.

## 📦 Componentes Disponíveis

### ✅ Criados e Funcionando

1. **Button** - Botões com múltiplas variantes
2. **Input** - Inputs com validação e ícones  
3. **Card** - Cards com subcomponentes

---

## 🎯 Button

Botão flexível com 7 variantes e 4 tamanhos.

### Variantes

- `default` - Botão primário azul (padrão)
- `secondary` - Botão secundário roxo
- `outline` - Botão com borda
- `ghost` - Botão sem fundo
- `destructive` - Botão vermelho (ações destrutivas)
- `success` - Botão verde (ações de sucesso)
- `link` - Link estilizado

### Tamanhos

- `sm` - Pequeno (h-8)
- `default` - Padrão (h-10)
- `lg` - Grande (h-12)
- `icon` - Apenas ícone (h-10 w-10)

### Exemplos

```jsx
import { Button } from '@/components/ui'

// Botão padrão
<Button>Clique aqui</Button>

// Botão com variante
<Button variant="secondary">Secundário</Button>

// Botão com tamanho
<Button size="lg">Grande</Button>

// Botão com ícone
<Button>
  <Plus className="h-4 w-4" />
  Nova Demanda
</Button>

// Botão desabilitado
<Button disabled>Processando...</Button>

// Botão submit
<Button type="submit">Enviar</Button>
```

### Props

| Prop | Tipo | Padrão | Descrição |
|------|------|--------|-----------|
| variant | string | 'default' | Variante visual |
| size | string | 'default' | Tamanho do botão |
| disabled | boolean | false | Se está desabilitado |
| type | string | 'button' | Tipo HTML (button, submit) |
| onClick | function | - | Handler de clique |
| className | string | - | Classes CSS adicionais |

---

## 📝 Input

Input de texto com label, validação, ícones e mensagens de erro.

### Características

- ✅ Label automático
- ✅ Indicador de campo obrigatório (*)
- ✅ Mensagem de erro com ícone
- ✅ Texto de ajuda (helper text)
- ✅ Suporte a ícones (esquerda e direita)
- ✅ Estados visuais (focus, error, disabled)
- ✅ Acessibilidade (ARIA)

### Exemplos

```jsx
import { Input } from '@/components/ui'
import { Mail, Lock } from 'lucide-react'

// Input básico
<Input placeholder="Digite algo..." />

// Input com label
<Input 
  label="Nome completo"
  placeholder="João Silva"
/>

// Input obrigatório
<Input 
  label="Email"
  type="email"
  required
/>

// Input com erro (React Hook Form)
<Input 
  label="Senha"
  type="password"
  error={errors.password?.message}
  {...register('password')}
/>

// Input com ícone
<Input 
  label="Email"
  type="email"
  icon={<Mail className="h-4 w-4" />}
/>

// Input com texto de ajuda
<Input 
  label="Username"
  helperText="Apenas letras minúsculas e números"
/>

// Input desabilitado
<Input 
  label="Campo bloqueado"
  value="Valor fixo"
  disabled
/>
```

### Props

| Prop | Tipo | Padrão | Descrição |
|------|------|--------|-----------|
| type | string | 'text' | Tipo do input HTML |
| label | string | - | Label do campo |
| error | string | - | Mensagem de erro |
| helperText | string | - | Texto de ajuda |
| required | boolean | false | Se é obrigatório |
| disabled | boolean | false | Se está desabilitado |
| icon | ReactNode | - | Ícone à esquerda |
| rightIcon | ReactNode | - | Ícone à direita |
| className | string | - | Classes CSS adicionais |

---

## 🎴 Card

Container para agrupar conteúdo relacionado com 5 subcomponentes.

### Subcomponentes

- `Card` - Container principal
- `CardHeader` - Cabeçalho
- `CardTitle` - Título
- `CardDescription` - Descrição/subtítulo
- `CardContent` - Conteúdo principal
- `CardFooter` - Rodapé (geralmente com botões)

### Exemplos

```jsx
import { 
  Card, 
  CardHeader, 
  CardTitle, 
  CardDescription, 
  CardContent, 
  CardFooter 
} from '@/components/ui'

// Card básico
<Card>
  <CardHeader>
    <CardTitle>Título</CardTitle>
  </CardHeader>
  <CardContent>
    Conteúdo aqui
  </CardContent>
</Card>

// Card completo
<Card>
  <CardHeader>
    <CardTitle>Minhas Demandas</CardTitle>
    <CardDescription>
      Acompanhe suas solicitações
    </CardDescription>
  </CardHeader>
  <CardContent>
    <p>Lista de demandas...</p>
  </CardContent>
  <CardFooter>
    <Button>Nova Demanda</Button>
  </CardFooter>
</Card>

// Card de estatística
<Card>
  <CardHeader>
    <CardDescription>Total</CardDescription>
    <CardTitle className="text-4xl">150</CardTitle>
  </CardHeader>
</Card>

// Grid de cards
<div className="grid grid-cols-3 gap-4">
  <Card>...</Card>
  <Card>...</Card>
  <Card>...</Card>
</div>
```

### Props

Todos os subcomponentes aceitam:

| Prop | Tipo | Descrição |
|------|------|-----------|
| className | string | Classes CSS adicionais |
| children | ReactNode | Conteúdo do componente |

---

## 🎨 Personalização

### Cores do Tailwind

As cores estão definidas em `tailwind.config.js`:

```javascript
colors: {
  primary: '#3B82F6',    // Azul
  secondary: '#8B5CF6',  // Roxo
  accent: '#10B981',     // Verde
  success: '#10B981',    // Verde
  warning: '#F59E0B',    // Amarelo
  error: '#EF4444',      // Vermelho
  info: '#3B82F6',       // Azul
}
```

### Classes Customizadas

Todos os componentes aceitam `className` para extensão:

```jsx
// Button customizado
<Button className="bg-gradient-to-r from-blue-500 to-purple-500">
  Botão Gradiente
</Button>

// Input maior
<Input className="h-14 text-lg" />

// Card com fundo colorido
<Card className="bg-blue-50 border-blue-200">
  ...
</Card>
```

---

## 🔧 Utilitários

### Função cn()

Localização: `src/lib/utils.js`

Combina classes CSS resolvendo conflitos do Tailwind:

```javascript
import { cn } from '@/lib/utils'

// Resolve conflitos
cn("px-4 py-2", "px-6") 
// Result: "px-6 py-2"

// Classes condicionais
cn("base-class", condition && "conditional-class")

// Múltiplas classes
cn(
  "base",
  isActive && "active",
  isDisabled && "disabled"
)
```

---

## 📖 Como Importar

### Import centralizado (recomendado)

```jsx
import { Button, Input, Card } from '@/components/ui'
```

### Import individual

```jsx
import Button from '@/components/ui/Button'
import Input from '@/components/ui/Input'
```

### Import de subcomponentes

```jsx
import { 
  Card, 
  CardHeader, 
  CardTitle, 
  CardContent 
} from '@/components/ui'
```

---

## 🚀 Próximos Componentes a Criar

- [ ] Textarea - Área de texto multilinha
- [ ] Select - Dropdown customizado
- [ ] Badge - Etiquetas coloridas
- [ ] Alert - Alertas e notificações
- [ ] Dialog/Modal - Janelas modais
- [ ] Dropdown Menu - Menus suspensos
- [ ] Table - Tabelas responsivas
- [ ] Tabs - Navegação por abas
- [ ] Toast - Notificações temporárias
- [ ] Calendar - Seletor de data
- [ ] Checkbox - Caixas de seleção
- [ ] Radio - Botões de rádio
- [ ] Switch - Interruptor on/off
- [ ] Progress - Barra de progresso
- [ ] Skeleton - Loading placeholders

---

## 📚 Referências

- **shadcn/ui**: https://ui.shadcn.com
- **Tailwind CSS**: https://tailwindcss.com
- **Lucide Icons**: https://lucide.dev
- **Radix UI**: https://www.radix-ui.com (para componentes avançados)

---

## ✨ Exemplo Completo

```jsx
import { useState } from 'react'
import { 
  Button, 
  Input, 
  Card, 
  CardHeader, 
  CardTitle, 
  CardContent, 
  CardFooter 
} from '@/components/ui'
import { Mail, Lock } from 'lucide-react'

function LoginForm() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')

  const handleSubmit = (e) => {
    e.preventDefault()
    // Lógica de login...
  }

  return (
    <Card className="max-w-md mx-auto">
      <CardHeader>
        <CardTitle>Login</CardTitle>
      </CardHeader>
      
      <form onSubmit={handleSubmit}>
        <CardContent className="space-y-4">
          <Input 
            label="Email"
            type="email"
            icon={<Mail className="h-4 w-4" />}
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            error={error}
            required
          />
          
          <Input 
            label="Senha"
            type="password"
            icon={<Lock className="h-4 w-4" />}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
        </CardContent>
        
        <CardFooter>
          <Button type="submit" className="w-full">
            Entrar
          </Button>
        </CardFooter>
      </form>
    </Card>
  )
}
```

---

**Criado com ❤️ para o sistema DeBrief** ✨

