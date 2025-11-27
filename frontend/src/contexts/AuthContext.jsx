/**
 * AuthContext - Contexto de Autenticação
 * Gerencia estado global de autenticação, usuário e tokens JWT
 */
import React, { createContext, useState, useEffect, useCallback } from 'react'
import { authService } from '@/services/authService'
import { getStoredAuth, setStoredAuth, clearStoredAuth } from '@/utils/auth'

// Criar contexto
const AuthContext = createContext(undefined)

/**
 * AuthProvider - Provider do contexto de autenticação
 * 
 * @param {Object} props
 * @param {React.ReactNode} props.children - Componentes filhos
 * 
 * @example
 * <AuthProvider>
 *   <App />
 * </AuthProvider>
 */
export const AuthProvider = ({ children }) => {
  // Estados
  const [user, setUser] = useState(null)
  const [token, setToken] = useState(null)
  const [refreshTokenValue, setRefreshTokenValue] = useState(null)
  const [loading, setLoading] = useState(true)
  const [isAuthenticated, setIsAuthenticated] = useState(false)

  /**
   * Inicializar autenticação ao carregar
   * Verifica se há dados salvos no localStorage
   */
  useEffect(() => {
    const initAuth = () => {
      try {
        const storedAuth = getStoredAuth()
        
        if (storedAuth?.token && storedAuth?.user) {
          setToken(storedAuth.token)
          setRefreshTokenValue(storedAuth.refreshToken || null)
          setUser(storedAuth.user)
          setIsAuthenticated(true)
        }
      } catch (error) {
        console.error('Erro ao inicializar autenticação:', error)
        clearStoredAuth()
      } finally {
        setLoading(false)
      }
    }

    initAuth()
  }, [])

  /**
   * Login - Autenticar usuário
   * 
   * @param {string} username - Username ou email
   * @param {string} password - Senha
   * @returns {Promise<Object>} - Dados do usuário autenticado
   * 
   * @example
   * const { user } = await login('usuario', 'senha123')
   */
  const login = useCallback(async (username, password, options = {}) => {
    try {
      setLoading(true)

      // Chamar API de login
      const response = await authService.login(username, password, options)
      
      // Extrair dados da resposta
      const { access_token, refresh_token, user: userData } = response

      // Salvar no estado
      setToken(access_token)
      setRefreshTokenValue(refresh_token)
      setUser(userData)
      setIsAuthenticated(true)

      // Salvar no localStorage
      setStoredAuth({
        token: access_token,
        refreshToken: refresh_token,
        user: userData
      })

      return { user: userData, token: access_token, refreshToken: refresh_token }
    } catch (error) {
      // Limpar autenticação em caso de erro
      clearStoredAuth()
      setToken(null)
      setUser(null)
      setIsAuthenticated(false)
      
      throw error
    } finally {
      setLoading(false)
    }
  }, [])

  /**
   * Logout - Deslogar usuário
   * 
   * @example
   * logout()
   */
  const logout = useCallback(() => {
    try {
      authService.logout(refreshTokenValue).catch((error) => {
        console.error('Erro ao notificar logout:', error)
      })
      // Limpar localStorage
      clearStoredAuth()
      
      // Limpar estado
      setToken(null)
      setRefreshTokenValue(null)
      setUser(null)
      setIsAuthenticated(false)
    } catch (error) {
      console.error('Erro ao fazer logout:', error)
    }
  }, [refreshTokenValue])

  /**
   * Atualizar dados do usuário
   * 
   * @param {Object} userData - Novos dados do usuário
   * 
   * @example
   * updateUser({ nome_completo: 'Novo Nome' })
   */
  const updateUser = useCallback((userData) => {
    setUser(prev => {
      const updatedUser = { ...prev, ...userData }
      
      // Atualizar localStorage
      const storedAuth = getStoredAuth()
      if (storedAuth) {
        setStoredAuth({
          ...storedAuth,
          user: updatedUser
        })
      }
      
      return updatedUser
    })
  }, [])

  /**
   * Verificar se o usuário tem uma permissão específica
   * 
   * @param {string} permission - Permissão a verificar
   * @returns {boolean}
   * 
   * @example
   * if (hasPermission('admin')) {
   *   // Mostrar painel admin
   * }
   */
  const hasPermission = useCallback((permission) => {
    if (!user) return false
    
    // Master tem todas as permissões
    if (user.tipo === 'master') return true
    
    // Verificar permissões específicas
    return user.permissoes?.includes(permission) || false
  }, [user])

  /**
   * Verificar se é usuário master
   * 
   * @returns {boolean}
   */
  const isMaster = useCallback(() => {
    return user?.tipo === 'master'
  }, [user])

  /**
   * Verificar se é usuário cliente
   * 
   * @returns {boolean}
   */
  const isCliente = useCallback(() => {
    return user?.tipo === 'cliente'
  }, [user])

  /**
   * Verificar se o token está expirado
   * 
   * @returns {boolean}
   */
  const isTokenExpired = useCallback(() => {
    if (!token) return true
    
    // Tokens mock nunca expiram (para desenvolvimento)
    if (token.includes('mock')) {
      return false
    }
    
    try {
      // Decodificar JWT (parte do payload)
      const base64Url = token.split('.')[1]
      const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/')
      const jsonPayload = decodeURIComponent(
        atob(base64)
          .split('')
          .map(c => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
          .join('')
      )
      
      const { exp } = JSON.parse(jsonPayload)
      
      // Verificar se expirou (exp está em segundos)
      return Date.now() >= exp * 1000
    } catch (error) {
      console.error('Erro ao verificar token:', error)
      return true
    }
  }, [token])

  /**
   * Refresh token (renovar token)
   * 
   * @returns {Promise<string>} - Novo token
   */
  const refreshSession = useCallback(async () => {
    if (!refreshTokenValue) {
      throw new Error('Nenhum refresh token disponível')
    }
    try {
      const response = await authService.refreshToken(refreshTokenValue)
      const { access_token, refresh_token, user: userData } = response
      
      setToken(access_token)
      setRefreshTokenValue(refresh_token)
      setUser(userData)
      
      setStoredAuth({
        token: access_token,
        refreshToken: refresh_token,
        user: userData,
      })
      
      return access_token
    } catch (error) {
      console.error('Erro ao renovar token:', error)
      logout()
      throw error
    }
  }, [refreshTokenValue, logout])

  // Valor do contexto
  const value = {
    // Estados
    user,
    token,
    loading,
    isAuthenticated,
    
    // Funções
    login,
    logout,
    updateUser,
    hasPermission,
    isMaster,
    isCliente,
    isTokenExpired,
    refreshToken: refreshSession,
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}

export default AuthContext

/**
 * EXEMPLOS DE USO:
 * 
 * // 1. Envolver App com Provider
 * import { AuthProvider } from '@/contexts/AuthContext'
 * 
 * <AuthProvider>
 *   <App />
 * </AuthProvider>
 * 
 * // 2. Usar no componente
 * import { useAuth } from '@/hooks/useAuth'
 * 
 * function MyComponent() {
 *   const { user, login, logout, isAuthenticated } = useAuth()
 *   
 *   if (!isAuthenticated) {
 *     return <div>Não autenticado</div>
 *   }
 *   
 *   return (
 *     <div>
 *       <p>Olá, {user.nome_completo}!</p>
 *       <button onClick={logout}>Sair</button>
 *     </div>
 *   )
 * }
 * 
 * // 3. Verificar permissões
 * function AdminPanel() {
 *   const { hasPermission, isMaster } = useAuth()
 *   
 *   if (!isMaster()) {
 *     return <div>Acesso negado</div>
 *   }
 *   
 *   return <div>Painel Admin</div>
 * }
 * 
 * // 4. Login
 * async function handleLogin(username, password) {
 *   try {
 *     const { user } = await login(username, password)
 *     console.log('Logado:', user)
 *   } catch (error) {
 *     console.error('Erro no login:', error)
 *   }
 * }
 */

