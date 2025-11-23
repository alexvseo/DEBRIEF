/**
 * Página de Login
 * Interface de autenticação usando componentes UI
 */
import { useState } from 'react'
import { useNavigate, useLocation, Link } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'
import {
  Button,
  Input,
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardContent,
  CardFooter,
  Alert,
  AlertDescription,
} from '@/components/ui'
import { Mail, Lock, Eye, EyeOff, LogIn } from 'lucide-react'
import { toast } from 'sonner'

/**
 * Página de Login
 */
const Login = () => {
  const navigate = useNavigate()
  const location = useLocation()
  const { login, isAuthenticated } = useAuth()

  // Estados do formulário
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  // Redirecionar se já autenticado
  if (isAuthenticated) {
    const from = location.state?.from?.pathname || '/dashboard'
    navigate(from, { replace: true })
  }

  /**
   * Handler do formulário de login
   */
  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')

    // Validações básicas
    if (!username.trim()) {
      setError('Digite seu usuário ou email')
      return
    }

    if (!password) {
      setError('Digite sua senha')
      return
    }

    try {
      setLoading(true)

      // Fazer login
      const { user } = await login(username, password)

      // Mostrar mensagem de sucesso
      toast.success(`Bem-vindo(a), ${user.nome_completo}!`)

      // Redirecionar
      const from = location.state?.from?.pathname || '/dashboard'
      navigate(from, { replace: true })
    } catch (err) {
      console.error('Erro no login:', err)
      setError(err.message || 'Erro ao fazer login. Tente novamente.')
      toast.error(err.message || 'Erro ao fazer login')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-purple-50 to-pink-50 flex items-center justify-center p-4">
      <div className="w-full max-w-md space-y-6">
        
        {/* Logo e Título */}
        <div className="text-center space-y-2">
          <h1 className="text-4xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600">
            🎯 DeBrief
          </h1>
          <p className="text-gray-600">
            Sistema de Demandas e Briefings
          </p>
        </div>

        {/* Card de Login */}
        <Card>
          <CardHeader>
            <CardTitle>Entrar</CardTitle>
            <CardDescription>
              Digite suas credenciais para acessar o sistema
            </CardDescription>
          </CardHeader>

          <form onSubmit={handleSubmit}>
            <CardContent className="space-y-4">
              
              {/* Mensagem de erro */}
              {error && (
                <Alert variant="error">
                  <AlertDescription>{error}</AlertDescription>
                </Alert>
              )}

              {/* Campo de Usuário/Email */}
              <Input
                label="Usuário ou Email"
                type="text"
                placeholder="seu.usuario ou email@exemplo.com"
                icon={<Mail className="h-4 w-4" />}
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                disabled={loading}
                required
                autoFocus
              />

              {/* Campo de Senha */}
              <div className="relative">
                <Input
                  label="Senha"
                  type={showPassword ? 'text' : 'password'}
                  placeholder="••••••••"
                  icon={<Lock className="h-4 w-4" />}
                  rightIcon={
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="cursor-pointer hover:text-gray-700 transition-colors"
                      tabIndex={-1}
                    >
                      {showPassword ? (
                        <EyeOff className="h-4 w-4" />
                      ) : (
                        <Eye className="h-4 w-4" />
                      )}
                    </button>
                  }
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  disabled={loading}
                  required
                />
              </div>

              {/* Link de Esqueci a Senha */}
              <div className="text-right">
                <Link 
                  to="/forgot-password" 
                  className="text-sm text-primary hover:underline"
                >
                  Esqueci minha senha
                </Link>
              </div>

            </CardContent>

            <CardFooter className="flex-col gap-3">
              {/* Botão de Login */}
              <Button
                type="submit"
                className="w-full"
                size="lg"
                disabled={loading}
              >
                {loading ? (
                  <>
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                    Entrando...
                  </>
                ) : (
                  <>
                    <LogIn className="h-4 w-4" />
                    Entrar
                  </>
                )}
              </Button>

              {/* Divider */}
              <div className="relative w-full">
                <div className="absolute inset-0 flex items-center">
                  <div className="w-full border-t border-gray-200"></div>
                </div>
                <div className="relative flex justify-center text-sm">
                  <span className="px-2 bg-white text-gray-500">
                    ou
                  </span>
                </div>
              </div>

              {/* Link para Criar Conta (se aplicável) */}
              <div className="text-center text-sm text-gray-600">
                Não tem uma conta?{' '}
                <Link 
                  to="/register" 
                  className="text-primary font-medium hover:underline"
                >
                  Solicite acesso
                </Link>
              </div>
            </CardFooter>
          </form>
        </Card>

        {/* Informações Adicionais */}
        <div className="text-center text-xs text-gray-500 space-y-1">
          <p>© 2025 DeBrief. Todos os direitos reservados.</p>
          <p>
            <Link to="/privacy" className="hover:underline">Privacidade</Link>
            {' • '}
            <Link to="/terms" className="hover:underline">Termos</Link>
          </p>
        </div>



      </div>
    </div>
  )
}

export default Login

