# 🎨 FRONTEND GUIDE - DeBrief Sistema

## 📋 ÍNDICE

1. [Setup Inicial](#setup-inicial)
2. [Estrutura de Pastas Detalhada](#estrutura-de-pastas-detalhada)
3. [Configurações Iniciais](#configurações-iniciais)
4. [Componentes Base (UI)](#componentes-base-ui)
5. [Sistema de Rotas](#sistema-de-rotas)
6. [Autenticação Frontend](#autenticação-frontend)
7. [Formulários](#formulários)
8. [Tabelas e Listagens](#tabelas-e-listagens)
9. [Gráficos e Dashboards](#gráficos-e-dashboards)
10. [Integração com API](#integração-com-api)
11. [Estado Global](#estado-global)
12. [Estilização](#estilização)
13. [Checklist de Desenvolvimento](#checklist-de-desenvolvimento)

---

## 🚀 SETUP INICIAL

### 1. Criar Projeto com Vite

```bash
# Navegar para a pasta do projeto
cd /home/seu-usuario/debrief

# Criar projeto React com Vite
npm create vite@latest frontend -- --template react

# Entrar na pasta
cd frontend

# Instalar dependências base
npm install
```

### 2. Instalar Dependências

```bash
# React Router para navegação
npm install react-router-dom

# Axios para requisições HTTP
npm install axios

# React Query para gerenciamento de estado do servidor
npm install @tanstack/react-query

# Formulários e validação
npm install react-hook-form zod @hookform/resolvers

# UI Components (shadcn/ui)
npm install @radix-ui/react-slot class-variance-authority clsx tailwind-merge

# Ícones
npm install lucide-react

# Gráficos
npm install recharts

# Manipulação de datas
npm install date-fns

# reCAPTCHA
npm install react-google-recaptcha

# Toast notifications
npm install sonner

# Utilitários
npm install nanoid
```

### 3. Instalar Dependências de Desenvolvimento

```bash
# TailwindCSS
npm install -D tailwindcss postcss autoprefixer

# Inicializar Tailwind
npx tailwindcss init -p
```

### 4. Estrutura de Pastas Completa

```
frontend/
├── public/
│   └── logo-debrief.svg
│
├── src/
│   ├── assets/              # Imagens, fontes, etc
│   │   └── images/
│   │
│   ├── components/          # Componentes reutilizáveis
│   │   ├── ui/             # Componentes base (shadcn)
│   │   │   ├── button.jsx
│   │   │   ├── input.jsx
│   │   │   ├── card.jsx
│   │   │   ├── select.jsx
│   │   │   ├── textarea.jsx
│   │   │   ├── dialog.jsx
│   │   │   ├── dropdown-menu.jsx
│   │   │   ├── table.jsx
│   │   │   ├── badge.jsx
│   │   │   ├── calendar.jsx
│   │   │   ├── alert.jsx
│   │   │   └── skeleton.jsx
│   │   │
│   │   ├── forms/          # Componentes de formulário
│   │   │   ├── DemandaForm.jsx
│   │   │   ├── LoginForm.jsx
│   │   │   ├── UsuarioForm.jsx
│   │   │   ├── ClienteForm.jsx
│   │   │   ├── SecretariaForm.jsx
│   │   │   └── FileUpload.jsx
│   │   │
│   │   ├── tables/         # Tabelas customizadas
│   │   │   ├── DemandaTable.jsx
│   │   │   ├── UsuarioTable.jsx
│   │   │   └── RelatorioTable.jsx
│   │   │
│   │   ├── charts/         # Gráficos
│   │   │   ├── BarChart.jsx
│   │   │   ├── PieChart.jsx
│   │   │   ├── LineChart.jsx
│   │   │   └── DashboardCards.jsx
│   │   │
│   │   ├── layout/         # Layout components
│   │   │   ├── Sidebar.jsx
│   │   │   ├── Header.jsx
│   │   │   ├── Footer.jsx
│   │   │   └── MainLayout.jsx
│   │   │
│   │   └── common/         # Componentes comuns
│   │       ├── Loading.jsx
│   │       ├── ErrorBoundary.jsx
│   │       ├── ProtectedRoute.jsx
│   │       └── NotFound.jsx
│   │
│   ├── pages/              # Páginas completas
│   │   ├── auth/
│   │   │   └── Login.jsx
│   │   │
│   │   ├── user/           # Páginas de usuário normal
│   │   │   ├── Dashboard.jsx
│   │   │   ├── NovaDemanda.jsx
│   │   │   ├── MinhasDemandas.jsx
│   │   │   └── Relatorios.jsx
│   │   │
│   │   └── admin/          # Páginas de admin
│   │       ├── AdminDashboard.jsx
│   │       ├── Usuarios.jsx
│   │       ├── Clientes.jsx
│   │       ├── Secretarias.jsx
│   │       ├── TiposDemanda.jsx
│   │       ├── Prioridades.jsx
│   │       ├── Configuracoes.jsx
│   │       └── RelatoriosMaster.jsx
│   │
│   ├── services/           # Serviços de API
│   │   ├── api.js          # Config axios
│   │   ├── authService.js
│   │   ├── demandaService.js
│   │   ├── usuarioService.js
│   │   ├── clienteService.js
│   │   ├── relatorioService.js
│   │   └── configService.js
│   │
│   ├── hooks/              # Custom Hooks
│   │   ├── useAuth.js
│   │   ├── useDemandas.js
│   │   ├── useUsuarios.js
│   │   ├── useClientes.js
│   │   └── useRelatorios.js
│   │
│   ├── contexts/           # Contexts React
│   │   └── AuthContext.jsx
│   │
│   ├── utils/              # Funções auxiliares
│   │   ├── formatters.js   # Formatar datas, moeda, etc
│   │   ├── validators.js   # Validações customizadas
│   │   ├── constants.js    # Constantes do app
│   │   └── helpers.js      # Funções helper
│   │
│   ├── lib/                # Configurações de libs
│   │   └── utils.js        # Função cn() do shadcn
│   │
│   ├── styles/             # Estilos globais
│   │   ├── globals.css
│   │   └── animations.css
│   │
│   ├── App.jsx             # Componente raiz
│   ├── main.jsx            # Entry point
│   └── routes.jsx          # Definição de rotas
│
├── .env                    # Variáveis de ambiente
├── .env.example            # Exemplo de variáveis
├── .gitignore
├── index.html
├── package.json
├── postcss.config.js
├── tailwind.config.js
├── vite.config.js
└── README.md
```

---

## ⚙️ CONFIGURAÇÕES INICIAIS

### 1. tailwind.config.js

```javascript
/** @type {import('tailwindcss').Config} */
export default {
  // Modo dark baseado em classe
  darkMode: ["class"],
  
  // Arquivos que o Tailwind vai escanear
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  
  theme: {
    extend: {
      // Cores customizadas do projeto
      colors: {
        // Cores principais
        primary: {
          DEFAULT: '#3B82F6',
          light: '#60A5FA',
          dark: '#2563EB',
        },
        secondary: {
          DEFAULT: '#8B5CF6',
          light: '#A78BFA',
          dark: '#7C3AED',
        },
        accent: {
          DEFAULT: '#10B981',
          light: '#34D399',
          dark: '#059669',
        },
        
        // Cores de status
        success: '#10B981',
        warning: '#F59E0B',
        error: '#EF4444',
        info: '#3B82F6',
        
        // Prioridades
        priority: {
          low: '#10B981',
          medium: '#F59E0B',
          high: '#F97316',
          urgent: '#EF4444',
        },
        
        // Background e texto
        background: '#FFFFFF',
        foreground: '#111827',
      },
      
      // Animações customizadas
      keyframes: {
        "fade-in": {
          "0%": { opacity: "0" },
          "100%": { opacity: "1" },
        },
        "slide-in": {
          "0%": { transform: "translateX(-100%)" },
          "100%": { transform: "translateX(0)" },
        },
      },
      animation: {
        "fade-in": "fade-in 0.3s ease-in-out",
        "slide-in": "slide-in 0.3s ease-in-out",
      },
    },
  },
  
  plugins: [],
}
```

### 2. src/styles/globals.css

```css
/* Importar Tailwind */
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Estilos base customizados */
@layer base {
  * {
    @apply border-gray-200;
  }
  
  body {
    @apply bg-gray-50 text-gray-900 antialiased;
  }
  
  /* Scrollbar customizada */
  ::-webkit-scrollbar {
    @apply w-2 h-2;
  }
  
  ::-webkit-scrollbar-track {
    @apply bg-gray-100;
  }
  
  ::-webkit-scrollbar-thumb {
    @apply bg-gray-300 rounded-full;
  }
  
  ::-webkit-scrollbar-thumb:hover {
    @apply bg-gray-400;
  }
}

/* Utilitários customizados */
@layer utilities {
  /* Animação de loading */
  .animate-pulse-slow {
    animation: pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite;
  }
  
  /* Glassmorphism */
  .glass {
    @apply bg-white/80 backdrop-blur-lg;
  }
  
  /* Sombras customizadas */
  .shadow-card {
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1),
                0 2px 4px -1px rgba(0, 0, 0, 0.06);
  }
}

/* Componentes reutilizáveis */
@layer components {
  /* Container responsivo */
  .container-custom {
    @apply container mx-auto px-4 sm:px-6 lg:px-8;
  }
  
  /* Card padrão */
  .card {
    @apply bg-white rounded-lg shadow-card p-6;
  }
  
  /* Botão primário */
  .btn-primary {
    @apply bg-primary text-white px-4 py-2 rounded-lg
           hover:bg-primary-dark transition-colors
           focus:ring-2 focus:ring-primary focus:ring-offset-2
           disabled:opacity-50 disabled:cursor-not-allowed;
  }
  
  /* Input padrão */
  .input {
    @apply w-full px-3 py-2 border border-gray-300 rounded-lg
           focus:ring-2 focus:ring-primary focus:border-transparent
           disabled:bg-gray-100 disabled:cursor-not-allowed;
  }
}
```

### 3. vite.config.js

```javascript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  
  // Alias para imports mais limpos
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@components': path.resolve(__dirname, './src/components'),
      '@pages': path.resolve(__dirname, './src/pages'),
      '@services': path.resolve(__dirname, './src/services'),
      '@hooks': path.resolve(__dirname, './src/hooks'),
      '@utils': path.resolve(__dirname, './src/utils'),
      '@contexts': path.resolve(__dirname, './src/contexts'),
    },
  },
  
  // Configuração do servidor de desenvolvimento
  server: {
    port: 5173,
    host: true, // Permite acesso externo
    proxy: {
      // Proxy para API do backend
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      },
    },
  },
  
  // Build otimizado
  build: {
    outDir: 'dist',
    sourcemap: false, // Desabilitar em produção
    rollupOptions: {
      output: {
        manualChunks: {
          // Separar vendors em chunks
          'react-vendor': ['react', 'react-dom', 'react-router-dom'],
          'ui-vendor': ['lucide-react', 'recharts'],
        },
      },
    },
  },
})
```

### 4. .env.example

```bash
# URL da API Backend
VITE_API_URL=http://localhost:8000/api

# Google reCAPTCHA Site Key (público)
VITE_RECAPTCHA_SITE_KEY=sua-chave-do-site-aqui

# Ambiente
VITE_ENV=development

# Configurações de upload
VITE_MAX_FILE_SIZE=52428800  # 50MB em bytes
VITE_ALLOWED_FILE_TYPES=.pdf,.jpg,.jpeg,.png
```

### 5. src/lib/utils.js

```javascript
// Função para combinar classes CSS (shadcn/ui)
// Muito útil para componentes condicionais
import { clsx } from "clsx"
import { twMerge } from "tailwind-merge"

/**
 * Combina classes CSS com Tailwind, resolvendo conflitos
 * Exemplo: cn("px-4 py-2", "px-6") => "px-6 py-2"
 */
export function cn(...inputs) {
  return twMerge(clsx(inputs))
}
```

---

## 🧩 COMPONENTES BASE (UI)

### Exemplo: src/components/ui/button.jsx

```javascript
import React from 'react'
import { cn } from '@/lib/utils'

/**
 * Componente Button reutilizável
 * Suporta diferentes variantes e tamanhos
 */
const Button = React.forwardRef(
  ({ className, variant = 'default', size = 'default', disabled, children, ...props }, ref) => {
    
    // Classes base do botão
    const baseClasses = 'inline-flex items-center justify-center rounded-lg font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50'
    
    // Variantes de estilo
    const variants = {
      default: 'bg-primary text-white hover:bg-primary-dark focus-visible:ring-primary',
      secondary: 'bg-secondary text-white hover:bg-secondary-dark focus-visible:ring-secondary',
      outline: 'border border-gray-300 bg-white hover:bg-gray-50 focus-visible:ring-primary',
      ghost: 'hover:bg-gray-100 focus-visible:ring-primary',
      destructive: 'bg-error text-white hover:bg-red-600 focus-visible:ring-error',
      success: 'bg-success text-white hover:bg-green-600 focus-visible:ring-success',
    }
    
    // Tamanhos
    const sizes = {
      default: 'h-10 px-4 py-2',
      sm: 'h-8 px-3 text-sm',
      lg: 'h-12 px-6 text-lg',
      icon: 'h-10 w-10',
    }
    
    return (
      <button
        className={cn(
          baseClasses,
          variants[variant],
          sizes[size],
          className
        )}
        ref={ref}
        disabled={disabled}
        {...props}
      >
        {children}
      </button>
    )
  }
)

Button.displayName = 'Button'

export default Button

// Exemplo de uso:
// <Button variant="default" size="lg" onClick={handleClick}>
//   Criar Demanda
// </Button>
```

### Exemplo: src/components/ui/input.jsx

```javascript
import React from 'react'
import { cn } from '@/lib/utils'

/**
 * Componente Input reutilizável
 * Wrapper para input HTML com estilos consistentes
 */
const Input = React.forwardRef(
  ({ className, type = 'text', error, label, ...props }, ref) => {
    return (
      <div className="w-full">
        {/* Label se fornecido */}
        {label && (
          <label className="block text-sm font-medium text-gray-700 mb-1">
            {label}
            {props.required && <span className="text-error ml-1">*</span>}
          </label>
        )}
        
        {/* Input */}
        <input
          type={type}
          className={cn(
            'flex h-10 w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm',
            'placeholder:text-gray-400',
            'focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent',
            'disabled:cursor-not-allowed disabled:bg-gray-100 disabled:text-gray-500',
            error && 'border-error focus:ring-error',
            className
          )}
          ref={ref}
          {...props}
        />
        
        {/* Mensagem de erro */}
        {error && (
          <p className="mt-1 text-sm text-error">{error}</p>
        )}
      </div>
    )
  }
)

Input.displayName = 'Input'

export default Input

// Exemplo de uso:
// <Input
//   label="Nome da Demanda"
//   placeholder="Digite o nome..."
//   required
//   error={errors.nome?.message}
// />
```

### Exemplo: src/components/ui/card.jsx

```javascript
import React from 'react'
import { cn } from '@/lib/utils'

/**
 * Componente Card - container com sombra e padding
 */
const Card = React.forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      'rounded-lg border bg-white shadow-card',
      className
    )}
    {...props}
  />
))
Card.displayName = 'Card'

/**
 * Cabeçalho do Card
 */
const CardHeader = React.forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn('flex flex-col space-y-1.5 p-6', className)}
    {...props}
  />
))
CardHeader.displayName = 'CardHeader'

/**
 * Título do Card
 */
const CardTitle = React.forwardRef(({ className, ...props }, ref) => (
  <h3
    ref={ref}
    className={cn('text-2xl font-semibold leading-none tracking-tight', className)}
    {...props}
  />
))
CardTitle.displayName = 'CardTitle'

/**
 * Descrição do Card
 */
const CardDescription = React.forwardRef(({ className, ...props }, ref) => (
  <p
    ref={ref}
    className={cn('text-sm text-gray-500', className)}
    {...props}
  />
))
CardDescription.displayName = 'CardDescription'

/**
 * Conteúdo do Card
 */
const CardContent = React.forwardRef(({ className, ...props }, ref) => (
  <div ref={ref} className={cn('p-6 pt-0', className)} {...props} />
))
CardContent.displayName = 'CardContent'

/**
 * Rodapé do Card
 */
const CardFooter = React.forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn('flex items-center p-6 pt-0', className)}
    {...props}
  />
))
CardFooter.displayName = 'CardFooter'

export { Card, CardHeader, CardFooter, CardTitle, CardDescription, CardContent }

// Exemplo de uso:
// <Card>
//   <CardHeader>
//     <CardTitle>Minhas Demandas</CardTitle>
//     <CardDescription>Acompanhe suas solicitações</CardDescription>
//   </CardHeader>
//   <CardContent>
//     {/* Conteúdo aqui */}
//   </CardContent>
// </Card>
```

**NOTA:** Para outros componentes UI (Select, Dialog, Badge, etc.), você pode usar o CLI do shadcn/ui:

```bash
npx shadcn-ui@latest init
npx shadcn-ui@latest add button input card select dialog badge calendar table
```

---

## 🛣️ SISTEMA DE ROTAS

### src/routes.jsx

```javascript
import React from 'react'
import { createBrowserRouter, Navigate } from 'react-router-dom'

// Layouts
import MainLayout from '@/components/layout/MainLayout'

// Páginas públicas
import Login from '@/pages/auth/Login'

// Páginas de usuário
import Dashboard from '@/pages/user/Dashboard'
import NovaDemanda from '@/pages/user/NovaDemanda'
import MinhasDemandas from '@/pages/user/MinhasDemandas'
import Relatorios from '@/pages/user/Relatorios'

// Páginas de admin
import AdminDashboard from '@/pages/admin/AdminDashboard'
import Usuarios from '@/pages/admin/Usuarios'
import Clientes from '@/pages/admin/Clientes'
import Secretarias from '@/pages/admin/Secretarias'
import TiposDemanda from '@/pages/admin/TiposDemanda'
import Prioridades from '@/pages/admin/Prioridades'
import Configuracoes from '@/pages/admin/Configuracoes'
import RelatoriosMaster from '@/pages/admin/RelatoriosMaster'

// Componente de rota protegida
import ProtectedRoute from '@/components/common/ProtectedRoute'
import NotFound from '@/components/common/NotFound'

/**
 * Definição de todas as rotas do aplicativo
 */
const router = createBrowserRouter([
  // Rota raiz - redireciona para login
  {
    path: '/',
    element: <Navigate to="/login" replace />,
  },
  
  // Login (pública)
  {
    path: '/login',
    element: <Login />,
  },
  
  // Rotas protegidas (usuários normais)
  {
    path: '/',
    element: (
      <ProtectedRoute>
        <MainLayout />
      </ProtectedRoute>
    ),
    children: [
      {
        path: 'dashboard',
        element: <Dashboard />,
      },
      {
        path: 'demandas/nova',
        element: <NovaDemanda />,
      },
      {
        path: 'demandas',
        element: <MinhasDemandas />,
      },
      {
        path: 'relatorios',
        element: <Relatorios />,
      },
    ],
  },
  
  // Rotas protegidas (admin master)
  {
    path: '/admin',
    element: (
      <ProtectedRoute adminOnly>
        <MainLayout />
      </ProtectedRoute>
    ),
    children: [
      {
        path: 'dashboard',
        element: <AdminDashboard />,
      },
      {
        path: 'usuarios',
        element: <Usuarios />,
      },
      {
        path: 'clientes',
        element: <Clientes />,
      },
      {
        path: 'secretarias',
        element: <Secretarias />,
      },
      {
        path: 'tipos-demanda',
        element: <TiposDemanda />,
      },
      {
        path: 'prioridades',
        element: <Prioridades />,
      },
      {
        path: 'configuracoes',
        element: <Configuracoes />,
      },
      {
        path: 'relatorios',
        element: <RelatoriosMaster />,
      },
    ],
  },
  
  // Página 404
  {
    path: '*',
    element: <NotFound />,
  },
])

export default router
```

### src/components/common/ProtectedRoute.jsx

```javascript
import React from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'
import Loading from './Loading'

/**
 * Componente que protege rotas autenticadas
 * Redireciona para login se não autenticado
 * Verifica permissão de admin se adminOnly=true
 */
const ProtectedRoute = ({ children, adminOnly = false }) => {
  const { user, isLoading } = useAuth()
  
  // Mostra loading enquanto verifica autenticação
  if (isLoading) {
    return <Loading fullScreen />
  }
  
  // Não autenticado - redireciona para login
  if (!user) {
    return <Navigate to="/login" replace />
  }
  
  // Rota admin mas usuário não é admin
  if (adminOnly && user.tipo !== 'master') {
    return <Navigate to="/dashboard" replace />
  }
  
  // Tudo ok - renderiza componente filho
  return children
}

export default ProtectedRoute
```

### src/App.jsx

```javascript
import React from 'react'
import { RouterProvider } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Toaster } from 'sonner'
import router from './routes'
import { AuthProvider } from '@/contexts/AuthContext'

// Configurar React Query
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1, // Tentar 1 vez se falhar
      refetchOnWindowFocus: false, // Não refetch ao focar janela
      staleTime: 5 * 60 * 1000, // Dados válidos por 5 min
    },
  },
})

/**
 * Componente raiz do aplicativo
 * Configura providers globais
 */
function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        {/* Sistema de rotas */}
        <RouterProvider router={router} />
        
        {/* Notificações toast */}
        <Toaster 
          position="top-right"
          richColors
          closeButton
        />
      </AuthProvider>
    </QueryClientProvider>
  )
}

export default App
```

---

## 🔐 AUTENTICAÇÃO FRONTEND

### src/contexts/AuthContext.jsx

```javascript
import React, { createContext, useState, useEffect } from 'react'
import { authService } from '@/services/authService'

// Criar contexto
export const AuthContext = createContext({})

/**
 * Provider de autenticação
 * Gerencia estado do usuário logado
 */
export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null)
  const [isLoading, setIsLoading] = useState(true)
  
  // Carregar usuário do localStorage ao iniciar
  useEffect(() => {
    const loadUser = async () => {
      try {
        const token = localStorage.getItem('token')
        
        if (token) {
          // Validar token e obter dados do usuário
          const userData = await authService.me()
          setUser(userData)
        }
      } catch (error) {
        // Token inválido - limpar
        localStorage.removeItem('token')
      } finally {
        setIsLoading(false)
      }
    }
    
    loadUser()
  }, [])
  
  /**
   * Função de login
   * Salva token e dados do usuário
   */
  const login = async (username, password) => {
    const response = await authService.login(username, password)
    
    // Salvar token
    localStorage.setItem('token', response.access_token)
    
    // Buscar dados completos do usuário
    const userData = await authService.me()
    setUser(userData)
    
    return userData
  }
  
  /**
   * Função de logout
   * Limpa token e dados do usuário
   */
  const logout = () => {
    localStorage.removeItem('token')
    setUser(null)
  }
  
  /**
   * Atualizar dados do usuário
   */
  const updateUser = (newData) => {
    setUser(prev => ({ ...prev, ...newData }))
  }
  
  return (
    <AuthContext.Provider
      value={{
        user,
        isLoading,
        login,
        logout,
        updateUser,
        isAdmin: user?.tipo === 'master',
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}
```

### src/hooks/useAuth.js

```javascript
import { useContext } from 'react'
import { AuthContext } from '@/contexts/AuthContext'

/**
 * Hook para acessar contexto de autenticação
 * Facilita uso em componentes
 */
export const useAuth = () => {
  const context = useContext(AuthContext)
  
  if (!context) {
    throw new Error('useAuth deve ser usado dentro de AuthProvider')
  }
  
  return context
}

// Exemplo de uso em componente:
// const { user, login, logout, isAdmin } = useAuth()
```

---

## 📝 FORMULÁRIOS

### Exemplo Completo: src/components/forms/DemandaForm.jsx

```javascript
import React, { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'
import { toast } from 'sonner'
import { Calendar, Upload, X } from 'lucide-react'
import { format } from 'date-fns'
import { ptBR } from 'date-fns/locale'

// Componentes UI
import Button from '@/components/ui/button'
import Input from '@/components/ui/input'
import { Select } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

// Services
import { demandaService } from '@/services/demandaService'

// Hooks
import { useAuth } from '@/hooks/useAuth'

/**
 * Schema de validação Zod
 * Define regras de validação do formulário
 */
const demandaSchema = z.object({
  secretaria_id: z.string().min(1, 'Selecione uma secretaria'),
  nome: z.string()
    .min(5, 'Nome deve ter pelo menos 5 caracteres')
    .max(200, 'Nome deve ter no máximo 200 caracteres'),
  tipo_demanda_id: z.string().min(1, 'Selecione um tipo'),
  prioridade_id: z.string().min(1, 'Selecione uma prioridade'),
  descricao: z.string()
    .min(10, 'Descrição deve ter pelo menos 10 caracteres')
    .max(2000, 'Descrição deve ter no máximo 2000 caracteres'),
  prazo_final: z.date({
    required_error: 'Selecione uma data',
    invalid_type_error: 'Data inválida',
  }).refine(
    (date) => date > new Date(),
    'Prazo deve ser uma data futura'
  ),
})

/**
 * Componente de formulário para criar/editar demanda
 */
const DemandaForm = ({ demanda = null, onSuccess, onCancel }) => {
  const { user } = useAuth()
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [files, setFiles] = useState([])
  
  // Configurar React Hook Form com Zod
  const {
    register,
    handleSubmit,
    formState: { errors },
    setValue,
    watch,
  } = useForm({
    resolver: zodResolver(demandaSchema),
    defaultValues: demanda || {
      secretaria_id: '',
      nome: '',
      tipo_demanda_id: '',
      prioridade_id: '',
      descricao: '',
      prazo_final: null,
    },
  })
  
  /**
   * Handler de upload de arquivos
   * Valida tamanho e tipo antes de adicionar
   */
  const handleFileChange = (e) => {
    const selectedFiles = Array.from(e.target.files)
    
    // Validar cada arquivo
    const validFiles = selectedFiles.filter(file => {
      // Tamanho máximo 50MB
      if (file.size > 52428800) {
        toast.error(`${file.name} é muito grande (máx 50MB)`)
        return false
      }
      
      // Tipos permitidos
      const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png', 'image/jpg']
      if (!allowedTypes.includes(file.type)) {
        toast.error(`${file.name} tem tipo não permitido`)
        return false
      }
      
      return true
    })
    
    // Verificar limite de 5 arquivos
    if (files.length + validFiles.length > 5) {
      toast.error('Máximo de 5 arquivos permitido')
      return
    }
    
    setFiles(prev => [...prev, ...validFiles])
  }
  
  /**
   * Remover arquivo da lista
   */
  const removeFile = (index) => {
    setFiles(prev => prev.filter((_, i) => i !== index))
  }
  
  /**
   * Submeter formulário
   */
  const onSubmit = async (data) => {
    try {
      setIsSubmitting(true)
      
      // Criar FormData para enviar arquivos
      const formData = new FormData()
      
      // Adicionar dados do formulário
      Object.keys(data).forEach(key => {
        if (key === 'prazo_final') {
          formData.append(key, format(data[key], 'yyyy-MM-dd'))
        } else {
          formData.append(key, data[key])
        }
      })
      
      // Adicionar arquivos
      files.forEach((file) => {
        formData.append('files', file)
      })
      
      // Enviar para API
      let result
      if (demanda) {
        // Editar demanda existente
        result = await demandaService.update(demanda.id, formData)
        toast.success('Demanda atualizada com sucesso!')
      } else {
        // Criar nova demanda
        result = await demandaService.create(formData)
        toast.success('Demanda criada com sucesso!')
      }
      
      // Callback de sucesso
      if (onSuccess) {
        onSuccess(result)
      }
      
    } catch (error) {
      console.error('Erro ao salvar demanda:', error)
      toast.error(
        error.response?.data?.detail || 
        'Erro ao salvar demanda. Tente novamente.'
      )
    } finally {
      setIsSubmitting(false)
    }
  }
  
  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>
            {demanda ? 'Editar Demanda' : 'Nova Demanda'}
          </CardTitle>
        </CardHeader>
        
        <CardContent className="space-y-4">
          {/* Grid de 2 colunas em telas grandes */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            
            {/* Secretaria */}
            <div>
              <label className="block text-sm font-medium mb-1">
                Secretaria <span className="text-error">*</span>
              </label>
              <Select
                {...register('secretaria_id')}
                error={errors.secretaria_id?.message}
              >
                <option value="">Selecione...</option>
                {/* Carregar secretarias do usuário */}
                {/* Exemplo simplificado */}
                <option value="1">Secretaria A</option>
                <option value="2">Secretaria B</option>
              </Select>
            </div>
            
            {/* Tipo de Demanda */}
            <div>
              <label className="block text-sm font-medium mb-1">
                Tipo de Demanda <span className="text-error">*</span>
              </label>
              <Select
                {...register('tipo_demanda_id')}
                error={errors.tipo_demanda_id?.message}
              >
                <option value="">Selecione...</option>
                <option value="1">Design</option>
                <option value="2">Desenvolvimento</option>
                <option value="3">Conteúdo</option>
              </Select>
            </div>
            
            {/* Prioridade */}
            <div>
              <label className="block text-sm font-medium mb-1">
                Prioridade <span className="text-error">*</span>
              </label>
              <Select
                {...register('prioridade_id')}
                error={errors.prioridade_id?.message}
              >
                <option value="">Selecione...</option>
                <option value="1">🟢 Baixa</option>
                <option value="2">🟡 Média</option>
                <option value="3">🟠 Alta</option>
                <option value="4">🔴 Urgente</option>
              </Select>
            </div>
            
            {/* Prazo Final */}
            <div>
              <label className="block text-sm font-medium mb-1">
                Prazo Final <span className="text-error">*</span>
              </label>
              <Input
                type="date"
                {...register('prazo_final', {
                  valueAsDate: true,
                })}
                min={format(new Date(), 'yyyy-MM-dd')}
                error={errors.prazo_final?.message}
              />
            </div>
          </div>
          
          {/* Nome da Demanda (largura total) */}
          <Input
            label="Nome da Demanda"
            placeholder="Ex: Criação de arte para campanha X"
            {...register('nome')}
            error={errors.nome?.message}
            required
          />
          
          {/* Descrição (largura total) */}
          <div>
            <label className="block text-sm font-medium mb-1">
              Descrição <span className="text-error">*</span>
            </label>
            <Textarea
              {...register('descricao')}
              placeholder="Descreva detalhadamente sua demanda..."
              rows={5}
              error={errors.descricao?.message}
            />
            <p className="text-xs text-gray-500 mt-1">
              {watch('descricao')?.length || 0} / 2000 caracteres
            </p>
          </div>
          
          {/* Upload de Arquivos */}
          <div>
            <label className="block text-sm font-medium mb-2">
              Anexos (Opcional)
            </label>
            
            {/* Input file oculto */}
            <input
              type="file"
              id="file-upload"
              multiple
              accept=".pdf,.jpg,.jpeg,.png"
              onChange={handleFileChange}
              className="hidden"
            />
            
            {/* Botão customizado de upload */}
            <label
              htmlFor="file-upload"
              className="flex items-center justify-center w-full p-6 border-2 border-dashed border-gray-300 rounded-lg cursor-pointer hover:border-primary hover:bg-gray-50 transition-colors"
            >
              <div className="text-center">
                <Upload className="mx-auto h-12 w-12 text-gray-400" />
                <p className="mt-2 text-sm text-gray-600">
                  Clique para selecionar arquivos
                </p>
                <p className="text-xs text-gray-500 mt-1">
                  PDF, JPG, PNG (máx 50MB cada)
                </p>
              </div>
            </label>
            
            {/* Lista de arquivos selecionados */}
            {files.length > 0 && (
              <div className="mt-3 space-y-2">
                {files.map((file, index) => (
                  <div
                    key={index}
                    className="flex items-center justify-between p-2 bg-gray-50 rounded-lg"
                  >
                    <div className="flex items-center space-x-2">
                      <span className="text-sm text-gray-700">
                        {file.name}
                      </span>
                      <span className="text-xs text-gray-500">
                        ({(file.size / 1024 / 1024).toFixed(2)} MB)
                      </span>
                    </div>
                    
                    <button
                      type="button"
                      onClick={() => removeFile(index)}
                      className="text-error hover:text-red-700"
                    >
                      <X className="h-4 w-4" />
                    </button>
                  </div>
                ))}
                
                <p className="text-xs text-gray-500">
                  {files.length} / 5 arquivos
                </p>
              </div>
            )}
          </div>
          
        </CardContent>
      </Card>
      
      {/* Botões de ação */}
      <div className="flex justify-end space-x-3">
        {onCancel && (
          <Button
            type="button"
            variant="outline"
            onClick={onCancel}
            disabled={isSubmitting}
          >
            Cancelar
          </Button>
        )}
        
        <Button
          type="submit"
          disabled={isSubmitting}
        >
          {isSubmitting ? 'Salvando...' : demanda ? 'Atualizar' : 'Criar Demanda'}
        </Button>
      </div>
    </form>
  )
}

export default DemandaForm
```

---

## 📊 INTEGRAÇÃO COM API

### src/services/api.js

```javascript
import axios from 'axios'
import { toast } from 'sonner'

/**
 * URL base da API (vem do .env)
 */
const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api'

/**
 * Instância do Axios configurada
 */
const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

/**
 * Interceptor de requisição
 * Adiciona token JWT automaticamente
 */
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token')
    
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

/**
 * Interceptor de resposta
 * Trata erros globalmente
 */
api.interceptors.response.use(
  (response) => {
    return response
  },
  (error) => {
    // Erro 401 - Não autenticado
    if (error.response?.status === 401) {
      localStorage.removeItem('token')
      window.location.href = '/login'
      toast.error('Sessão expirada. Faça login novamente.')
    }
    
    // Erro 403 - Sem permissão
    if (error.response?.status === 403) {
      toast.error('Você não tem permissão para esta ação')
    }
    
    // Erro 500 - Erro no servidor
    if (error.response?.status === 500) {
      toast.error('Erro no servidor. Tente novamente mais tarde.')
    }
    
    return Promise.reject(error)
  }
)

export default api
```

### src/services/demandaService.js

```javascript
import api from './api'

/**
 * Serviço para operações relacionadas a demandas
 */
export const demandaService = {
  /**
   * Criar nova demanda
   * @param {FormData} formData - Dados da demanda com arquivos
   * @returns {Promise} Demanda criada
   */
  async create(formData) {
    const response = await api.post('/demandas', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    })
    return response.data
  },
  
  /**
   * Listar demandas do usuário
   * @param {Object} filters - Filtros opcionais
   * @returns {Promise} Lista de demandas
   */
  async list(filters = {}) {
    const response = await api.get('/demandas', {
      params: filters,
    })
    return response.data
  },
  
  /**
   * Buscar demanda por ID
   * @param {string} id - ID da demanda
   * @returns {Promise} Dados da demanda
   */
  async getById(id) {
    const response = await api.get(`/demandas/${id}`)
    return response.data
  },
  
  /**
   * Atualizar demanda
   * @param {string} id - ID da demanda
   * @param {FormData} formData - Dados atualizados
   * @returns {Promise} Demanda atualizada
   */
  async update(id, formData) {
    const response = await api.put(`/demandas/${id}`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    })
    return response.data
  },
  
  /**
   * Deletar demanda (soft delete)
   * @param {string} id - ID da demanda
   * @returns {Promise} Confirmação
   */
  async delete(id) {
    const response = await api.delete(`/demandas/${id}`)
    return response.data
  },
  
  /**
   * Buscar secretarias do cliente
   * @returns {Promise} Lista de secretarias
   */
  async getSecretarias() {
    const response = await api.get('/secretarias')
    return response.data
  },
  
  /**
   * Buscar tipos de demanda
   * @returns {Promise} Lista de tipos
   */
  async getTipos() {
    const response = await api.get('/tipos-demanda')
    return response.data
  },
  
  /**
   * Buscar prioridades
   * @returns {Promise} Lista de prioridades
   */
  async getPrioridades() {
    const response = await api.get('/prioridades')
    return response.data
  },
}
```

---

## 📈 GRÁFICOS E DASHBOARDS

### Exemplo: src/components/charts/DashboardCards.jsx

```javascript
import React from 'react'
import { FileText, Clock, CheckCircle, AlertCircle } from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

/**
 * Cards de métricas do dashboard
 * Mostra totais de demandas por status
 */
const DashboardCards = ({ stats }) => {
  const cards = [
    {
      title: 'Total de Demandas',
      value: stats.total || 0,
      icon: FileText,
      color: 'text-blue-600',
      bgColor: 'bg-blue-100',
    },
    {
      title: 'Em Andamento',
      value: stats.em_andamento || 0,
      icon: Clock,
      color: 'text-yellow-600',
      bgColor: 'bg-yellow-100',
    },
    {
      title: 'Concluídas',
      value: stats.concluidas || 0,
      icon: CheckCircle,
      color: 'text-green-600',
      bgColor: 'bg-green-100',
    },
    {
      title: 'Atrasadas',
      value: stats.atrasadas || 0,
      icon: AlertCircle,
      color: 'text-red-600',
      bgColor: 'bg-red-100',
    },
  ]
  
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      {cards.map((card, index) => {
        const Icon = card.icon
        
        return (
          <Card key={index}>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-gray-600">
                {card.title}
              </CardTitle>
              <div className={`p-2 rounded-lg ${card.bgColor}`}>
                <Icon className={`h-4 w-4 ${card.color}`} />
              </div>
            </CardHeader>
            
            <CardContent>
              <div className={`text-3xl font-bold ${card.color}`}>
                {card.value}
              </div>
            </CardContent>
          </Card>
        )
      })}
    </div>
  )
}

export default DashboardCards
```

### Exemplo: src/components/charts/BarChart.jsx

```javascript
import React from 'react'
import {
  BarChart as RechartsBarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts'

/**
 * Gráfico de barras para evolução de demandas
 */
const BarChart = ({ data, title }) => {
  return (
    <div className="w-full h-80">
      <h3 className="text-lg font-semibold mb-4">{title}</h3>
      
      <ResponsiveContainer width="100%" height="100%">
        <RechartsBarChart
          data={data}
          margin={{ top: 5, right: 30, left: 20, bottom: 5 }}
        >
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="mes" />
          <YAxis />
          <Tooltip />
          <Legend />
          <Bar dataKey="quantidade" fill="#3B82F6" name="Demandas" />
        </RechartsBarChart>
      </ResponsiveContainer>
    </div>
  )
}

export default BarChart

// Exemplo de dados:
// const data = [
//   { mes: 'Jan', quantidade: 12 },
//   { mes: 'Fev', quantidade: 19 },
//   { mes: 'Mar', quantidade: 15 },
//   // ...
// ]
```

---

## ✅ CHECKLIST DE DESENVOLVIMENTO FRONTEND

### Fase 1: Setup ✅
- [ ] Criar projeto com Vite
- [ ] Instalar todas as dependências
- [ ] Configurar TailwindCSS
- [ ] Configurar alias de imports
- [ ] Criar estrutura de pastas
- [ ] Configurar .env

### Fase 2: Componentes Base ✅
- [ ] Criar componentes UI (Button, Input, Card, etc)
- [ ] Criar layout (Sidebar, Header)
- [ ] Criar componente Loading
- [ ] Criar componente ProtectedRoute
- [ ] Testar responsividade

### Fase 3: Autenticação ✅
- [ ] Criar AuthContext
- [ ] Criar hook useAuth
- [ ] Criar página de Login
- [ ] Implementar LoginForm com validação
- [ ] Adicionar reCAPTCHA
- [ ] Testar fluxo de login/logout

### Fase 4: Rotas ✅
- [ ] Configurar React Router
- [ ] Criar rotas públicas
- [ ] Criar rotas protegidas (user)
- [ ] Criar rotas protegidas (admin)
- [ ] Testar redirecionamentos

### Fase 5: Dashboard ✅
- [ ] Criar página Dashboard
- [ ] Criar cards de métricas
- [ ] Criar gráficos
- [ ] Integrar com API
- [ ] Adicionar filtros

### Fase 6: CRUD Demandas ✅
- [ ] Criar formulário de nova demanda
- [ ] Validar formulário com Zod
- [ ] Implementar upload de arquivos
- [ ] Criar listagem de demandas
- [ ] Criar tabela com filtros
- [ ] Criar modal de edição
- [ ] Testar todas as operações

### Fase 7: Relatórios ✅
- [ ] Criar página de relatórios
- [ ] Implementar filtros dinâmicos
- [ ] Criar gráficos (Recharts)
- [ ] Botão de exportar PDF
- [ ] Botão de exportar Excel
- [ ] Testar geração de relatórios

### Fase 8: Área Admin ✅
- [ ] CRUD de Usuários
- [ ] CRUD de Clientes
- [ ] CRUD de Secretarias
- [ ] CRUD de Tipos de Demanda
- [ ] CRUD de Prioridades
- [ ] Página de Configurações
- [ ] Testar todas as operações

### Fase 9: Polimento ✅
- [ ] Adicionar loading states
- [ ] Melhorar feedbacks visuais
- [ ] Tratar todos os erros
- [ ] Adicionar animações
- [ ] Otimizar performance
- [ ] Testar em diferentes navegadores
- [ ] Testar responsividade completa

---

## 🎓 RECURSOS E DOCUMENTAÇÃO

### React
- Docs: https://react.dev
- Hooks: https://react.dev/reference/react

### React Router
- Docs: https://reactrouter.com

### React Hook Form
- Docs: https://react-hook-form.com

### Zod
- Docs: https://zod.dev

### TailwindCSS
- Docs: https://tailwindcss.com/docs

### shadcn/ui
- Docs: https://ui.shadcn.com
- Componentes: https://ui.shadcn.com/docs/components

### Recharts
- Docs: https://recharts.org

### React Query
- Docs: https://tanstack.com/query/latest

---

## 🚀 PRÓXIMOS PASSOS

Após criar todo o frontend:

1. **Testar localmente:** `npm run dev`
2. **Criar build de produção:** `npm run build`
3. **Testar build:** `npm run preview`
4. **Avançar para o Backend:** Ler o `BACKEND_GUIDE.md`

---

**Boa sorte com o desenvolvimento! 🎨✨**
