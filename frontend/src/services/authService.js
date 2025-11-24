/**
 * Auth Service
 * Serviço para comunicação com API de autenticação
 */
import api from './api'

// Flag para usar mock (desenvolvimento sem backend)
const USE_MOCK = false // Backend está pronto e rodando!

/**
 * Mock de dados de usuários para desenvolvimento
 */
const MOCK_USERS = {
  admin: {
    username: 'admin',
    password: 'admin123',
    user: {
      id: '1',
      username: 'admin',
      email: 'admin@debrief.com',
      nome_completo: 'Administrador Master',
      tipo: 'master',
      cliente_id: null,
      ativo: true,
      created_at: '2025-01-01T00:00:00Z',
      updated_at: '2025-01-01T00:00:00Z',
    },
    access_token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwidXNlcm5hbWUiOiJhZG1pbiIsInR5cGUiOiJtYXN0ZXIiLCJleHAiOjk5OTk5OTk5OTl9.mock'
  },
  cliente: {
    username: 'cliente',
    password: 'cliente123',
    user: {
      id: '2',
      username: 'cliente',
      email: 'cliente@exemplo.com',
      nome_completo: 'Cliente Exemplo',
      tipo: 'cliente',
      cliente_id: '100',
      ativo: true,
      created_at: '2025-01-01T00:00:00Z',
      updated_at: '2025-01-01T00:00:00Z',
    },
    access_token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIyIiwidXNlcm5hbWUiOiJjbGllbnRlIiwidHlwZSI6ImNsaWVudGUiLCJleHAiOjk5OTk5OTk5OTl9.mock'
  }
}

/**
 * Mock de login para desenvolvimento
 */
const mockLogin = async (username, password) => {
  // Simular delay de rede
  await new Promise(resolve => setTimeout(resolve, 800))
  
  // Buscar usuário
  const mockUser = Object.values(MOCK_USERS).find(
    u => u.username === username && u.password === password
  )
  
  if (!mockUser) {
    throw new Error('Usuário ou senha inválidos')
  }
  
  return {
    access_token: mockUser.access_token,
    user: mockUser.user
  }
}

/**
 * Serviço de autenticação
 */
export const authService = {
  /**
   * Login - Autenticar usuário
   * 
   * @param {string} username - Username ou email
   * @param {string} password - Senha
   * @returns {Promise<Object>} - { access_token, user }
   * 
   * @example
   * const { access_token, user } = await authService.login('usuario', 'senha')
   */
  login: async (username, password) => {
    // Usar mock se ativado
    if (USE_MOCK) {
      return mockLogin(username, password)
    }
    
    // Código real da API (quando backend estiver pronto)
    try {
      // FastAPI OAuth2PasswordRequestForm espera application/x-www-form-urlencoded
      // Usar URLSearchParams ao invés de FormData
      const params = new URLSearchParams()
      params.append('username', username)
      params.append('password', password)
      
      const response = await api.post('/auth/login', params.toString(), {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      })
      
      return response.data
    } catch (error) {
      // Tratar erros de autenticação
      if (error.response?.status === 401) {
        throw new Error('Usuário ou senha inválidos')
      }
      
      throw new Error(
        error.response?.data?.detail || 
        error.response?.data?.message || 
        'Erro ao fazer login'
      )
    }
  },

  /**
   * Logout - Deslogar usuário (se API tiver endpoint)
   * 
   * @returns {Promise<void>}
   * 
   * @example
   * await authService.logout()
   */
  logout: async () => {
    try {
      // Se o backend tiver endpoint de logout, chamar aqui
      // await api.post('/auth/logout')
      return Promise.resolve()
    } catch (error) {
      console.error('Erro ao fazer logout:', error)
      // Não throw erro, permitir logout local mesmo se API falhar
      return Promise.resolve()
    }
  },

  /**
   * Refresh Token - Renovar token de acesso
   * 
   * @param {string} refreshToken - Refresh token
   * @returns {Promise<Object>} - { access_token }
   * 
   * @example
   * const { access_token } = await authService.refreshToken(oldToken)
   */
  refreshToken: async (refreshToken) => {
    if (USE_MOCK) {
      // Mock de refresh
      await new Promise(resolve => setTimeout(resolve, 500))
      return {
        access_token: refreshToken // Retornar o mesmo token no mock
      }
    }
    
    try {
      const response = await api.post('/auth/refresh', {
        refresh_token: refreshToken,
      })
      
      return response.data
    } catch (error) {
      throw new Error(
        error.response?.data?.detail || 
        'Erro ao renovar token'
      )
    }
  },

  /**
   * Obter perfil do usuário autenticado
   * 
   * @returns {Promise<Object>} - Dados do usuário
   * 
   * @example
   * const user = await authService.getProfile()
   */
  getProfile: async () => {
    if (USE_MOCK) {
      // Retornar usuário do token mock
      const token = localStorage.getItem('debrief_auth')
      if (token) {
        const auth = JSON.parse(token)
        return auth.user
      }
      throw new Error('Não autenticado')
    }
    
    try {
      const response = await api.get('/auth/me')
      return response.data
    } catch (error) {
      throw new Error(
        error.response?.data?.detail || 
        'Erro ao buscar perfil'
      )
    }
  },

  /**
   * Atualizar perfil do usuário
   * 
   * @param {Object} userData - Dados a atualizar
   * @returns {Promise<Object>} - Usuário atualizado
   * 
   * @example
   * const updated = await authService.updateProfile({
   *   nome_completo: 'Novo Nome'
   * })
   */
  updateProfile: async (userData) => {
    if (USE_MOCK) {
      // Mock de update
      await new Promise(resolve => setTimeout(resolve, 500))
      const token = localStorage.getItem('debrief_auth')
      if (token) {
        const auth = JSON.parse(token)
        const updatedUser = { ...auth.user, ...userData }
        localStorage.setItem('debrief_auth', JSON.stringify({
          ...auth,
          user: updatedUser
        }))
        return updatedUser
      }
      throw new Error('Não autenticado')
    }
    
    try {
      const response = await api.put('/auth/me', userData)
      return response.data
    } catch (error) {
      throw new Error(
        error.response?.data?.detail || 
        'Erro ao atualizar perfil'
      )
    }
  },

  /**
   * Alterar senha
   * 
   * @param {string} currentPassword - Senha atual
   * @param {string} newPassword - Nova senha
   * @returns {Promise<void>}
   * 
   * @example
   * await authService.changePassword('senhaAntiga', 'senhaNova')
   */
  changePassword: async (currentPassword, newPassword) => {
    if (USE_MOCK) {
      // Mock de change password
      await new Promise(resolve => setTimeout(resolve, 500))
      return Promise.resolve()
    }
    
    try {
      await api.post('/auth/change-password', {
        current_password: currentPassword,
        new_password: newPassword,
      })
    } catch (error) {
      throw new Error(
        error.response?.data?.detail || 
        'Erro ao alterar senha'
      )
    }
  },

  /**
   * Solicitar recuperação de senha
   * 
   * @param {string} email - Email do usuário
   * @returns {Promise<void>}
   * 
   * @example
   * await authService.requestPasswordReset('usuario@email.com')
   */
  requestPasswordReset: async (email) => {
    if (USE_MOCK) {
      await new Promise(resolve => setTimeout(resolve, 500))
      return Promise.resolve()
    }
    
    try {
      await api.post('/auth/forgot-password', { email })
    } catch (error) {
      throw new Error(
        error.response?.data?.detail || 
        'Erro ao solicitar recuperação de senha'
      )
    }
  },

  /**
   * Resetar senha com token
   * 
   * @param {string} token - Token de recuperação
   * @param {string} newPassword - Nova senha
   * @returns {Promise<void>}
   * 
   * @example
   * await authService.resetPassword(token, 'novaSenha123')
   */
  resetPassword: async (token, newPassword) => {
    if (USE_MOCK) {
      await new Promise(resolve => setTimeout(resolve, 500))
      return Promise.resolve()
    }
    
    try {
      await api.post('/auth/reset-password', {
        token,
        new_password: newPassword,
      })
    } catch (error) {
      throw new Error(
        error.response?.data?.detail || 
        'Erro ao resetar senha'
      )
    }
  },

  /**
   * Validar token
   * 
   * @param {string} token - Token a validar
   * @returns {Promise<boolean>}
   * 
   * @example
   * const isValid = await authService.validateToken(token)
   */
  validateToken: async (token) => {
    if (USE_MOCK) {
      return Promise.resolve(true)
    }
    
    try {
      await api.post('/auth/validate-token', { token })
      return true
    } catch (error) {
      return false
    }
  },
}

export default authService
