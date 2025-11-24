/**
 * Utilitários de autenticação
 * Funções para gerenciar tokens e dados no localStorage
 */

// Chave para armazenar dados no localStorage
const AUTH_STORAGE_KEY = 'debrief_auth'

/**
 * Obter dados de autenticação do localStorage
 * 
 * @returns {Object|null} - Dados de autenticação ou null
 * 
 * @example
 * const auth = getStoredAuth()
 * if (auth) {
 *   console.log(auth.user, auth.token)
 * }
 */
export const getStoredAuth = () => {
  try {
    const stored = localStorage.getItem(AUTH_STORAGE_KEY)
    
    if (!stored) return null
    
    return JSON.parse(stored)
  } catch (error) {
    console.error('Erro ao ler autenticação do localStorage:', error)
    return null
  }
}

/**
 * Salvar dados de autenticação no localStorage
 * 
 * @param {Object} authData - Dados de autenticação
 * @param {string} authData.token - Token JWT
 * @param {Object} authData.user - Dados do usuário
 * 
 * @example
 * setStoredAuth({
 *   token: 'eyJhbGc...',
 *   user: { id: 1, nome: 'João' }
 * })
 */
export const setStoredAuth = (authData) => {
  try {
    localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(authData))
  } catch (error) {
    console.error('Erro ao salvar autenticação no localStorage:', error)
  }
}

/**
 * Limpar dados de autenticação do localStorage
 * 
 * @example
 * clearStoredAuth()
 */
export const clearStoredAuth = () => {
  try {
    localStorage.removeItem(AUTH_STORAGE_KEY)
  } catch (error) {
    console.error('Erro ao limpar autenticação do localStorage:', error)
  }
}

/**
 * Obter apenas o token do localStorage
 * 
 * @returns {string|null} - Token JWT ou null
 * 
 * @example
 * const token = getToken()
 * if (token) {
 *   // Fazer requisição com token
 * }
 */
export const getToken = () => {
  const auth = getStoredAuth()
  return auth?.token || null
}

/**
 * Obter apenas o usuário do localStorage
 * 
 * @returns {Object|null} - Dados do usuário ou null
 * 
 * @example
 * const user = getUser()
 * if (user) {
 *   console.log(user.nome_completo)
 * }
 */
export const getUser = () => {
  const auth = getStoredAuth()
  return auth?.user || null
}

/**
 * Verificar se está autenticado
 * 
 * @returns {boolean}
 * 
 * @example
 * if (isAuthenticated()) {
 *   // Usuário está logado
 * }
 */
export const isAuthenticated = () => {
  const auth = getStoredAuth()
  return !!(auth?.token && auth?.user)
}

/**
 * Decodificar token JWT
 * 
 * @param {string} token - Token JWT
 * @returns {Object|null} - Payload do token ou null
 * 
 * @example
 * const payload = decodeToken(token)
 * console.log(payload.exp, payload.user_id)
 */
export const decodeToken = (token) => {
  try {
    // Dividir o token em partes
    const parts = token.split('.')
    if (parts.length !== 3) return null
    
    // Decodificar a parte do payload (parte do meio)
    const base64Url = parts[1]
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/')
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split('')
        .map(c => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    )
    
    return JSON.parse(jsonPayload)
  } catch (error) {
    console.error('Erro ao decodificar token:', error)
    return null
  }
}

/**
 * Verificar se o token está expirado
 * 
 * @param {string} token - Token JWT
 * @returns {boolean}
 * 
 * @example
 * if (isTokenExpired(token)) {
 *   // Token expirado, fazer refresh
 * }
 */
export const isTokenExpired = (token) => {
  try {
    // Tokens mock nunca expiram (para desenvolvimento)
    if (token && token.includes('mock')) {
      return false
    }
    
    const payload = decodeToken(token)
    if (!payload || !payload.exp) return true
    
    // exp está em segundos, Date.now() em milissegundos
    return Date.now() >= payload.exp * 1000
  } catch (error) {
    console.error('Erro ao verificar expiração do token:', error)
    return true
  }
}

/**
 * Obter tempo restante do token em minutos
 * 
 * @param {string} token - Token JWT
 * @returns {number} - Minutos restantes (0 se expirado)
 * 
 * @example
 * const minutos = getTokenRemainingTime(token)
 * console.log(`Token expira em ${minutos} minutos`)
 */
export const getTokenRemainingTime = (token) => {
  try {
    const payload = decodeToken(token)
    if (!payload || !payload.exp) return 0
    
    const now = Date.now()
    const exp = payload.exp * 1000
    
    if (now >= exp) return 0
    
    // Retornar em minutos
    return Math.floor((exp - now) / 1000 / 60)
  } catch (error) {
    console.error('Erro ao calcular tempo restante:', error)
    return 0
  }
}

/**
 * Formatar header de autorização
 * 
 * @param {string} token - Token JWT
 * @returns {string} - Header formatado
 * 
 * @example
 * const authHeader = getAuthHeader(token)
 * // 'Bearer eyJhbGc...'
 */
export const getAuthHeader = (token) => {
  return `Bearer ${token}`
}

/**
 * Verificar se o usuário tem uma role específica
 * 
 * @param {string} role - Role a verificar
 * @returns {boolean}
 * 
 * @example
 * if (hasRole('master')) {
 *   // Usuário é master
 * }
 */
export const hasRole = (role) => {
  const user = getUser()
  return user?.tipo === role
}

/**
 * Verificar se é usuário master
 * 
 * @returns {boolean}
 */
export const isMaster = () => {
  return hasRole('master')
}

/**
 * Verificar se é usuário cliente
 * 
 * @returns {boolean}
 */
export const isCliente = () => {
  return hasRole('cliente')
}

