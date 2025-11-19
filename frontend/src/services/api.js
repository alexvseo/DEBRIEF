/**
 * Configuração do Axios
 * Instância configurada do axios com interceptors para autenticação
 */
import axios from 'axios'
import { getToken, clearStoredAuth, isTokenExpired } from '@/utils/auth'
import { toast } from 'sonner'

// URL base da API (definida no .env)
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api'

/**
 * Instância do axios configurada
 */
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000, // 30 segundos
})

/**
 * Interceptor de Request
 * Adiciona token de autenticação em todas as requisições
 */
api.interceptors.request.use(
  (config) => {
    // Obter token do localStorage
    const token = getToken()
    
    // Se tiver token e não for a rota de login, adicionar header
    if (token && !config.url?.includes('/auth/login')) {
      // Verificar se token está expirado (ignorar tokens mock)
      if (!token.includes('mock') && isTokenExpired(token)) {
        console.warn('Token expirado, redirecionando para login...')
        clearStoredAuth()
        window.location.href = '/login'
        return Promise.reject(new Error('Token expirado'))
      }
      
      config.headers.Authorization = `Bearer ${token}`
    }
    
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

/**
 * Interceptor de Response
 * Trata erros globalmente e exibe mensagens
 */
api.interceptors.response.use(
  (response) => {
    // Retornar resposta normalmente se sucesso
    return response
  },
  (error) => {
    // Extrair informações do erro
    const status = error.response?.status
    const message = error.response?.data?.detail || 
                    error.response?.data?.message || 
                    error.message ||
                    'Erro desconhecido'
    
    // Tratar erros por status code
    switch (status) {
      case 401:
        // Não autorizado - redirecionar para login
        console.error('401: Não autorizado')
        clearStoredAuth()
        
        // Não redirecionar se já estiver na página de login
        if (!window.location.pathname.includes('/login')) {
          toast.error('Sessão expirada. Faça login novamente.')
          setTimeout(() => {
            window.location.href = '/login'
          }, 1000)
        }
        break
        
      case 403:
        // Proibido - sem permissão
        console.error('403: Sem permissão')
        toast.error('Você não tem permissão para acessar este recurso.')
        break
        
      case 404:
        // Não encontrado
        console.error('404: Recurso não encontrado')
        toast.error('Recurso não encontrado.')
        break
        
      case 422:
        // Erro de validação
        console.error('422: Erro de validação', error.response?.data)
        
        // Extrair erros de validação do FastAPI
        const validationErrors = error.response?.data?.detail
        if (Array.isArray(validationErrors)) {
          const errorMessages = validationErrors
            .map(err => `${err.loc?.[1] || 'Campo'}: ${err.msg}`)
            .join('; ')
          toast.error(`Erro de validação: ${errorMessages}`)
        } else {
          toast.error('Erro de validação nos dados enviados.')
        }
        break
        
      case 500:
        // Erro interno do servidor
        console.error('500: Erro interno do servidor')
        toast.error('Erro no servidor. Tente novamente mais tarde.')
        break
        
      case 503:
        // Serviço indisponível
        console.error('503: Serviço indisponível')
        toast.error('Serviço temporariamente indisponível.')
        break
        
      default:
        // Outros erros
        if (error.code === 'ECONNABORTED') {
          toast.error('Tempo de espera excedido. Tente novamente.')
        } else if (error.code === 'ERR_NETWORK') {
          toast.error('Erro de conexão. Verifique sua internet.')
        } else {
          console.error('Erro na requisição:', error)
          toast.error(message)
        }
    }
    
    return Promise.reject(error)
  }
)

export default api

/**
 * EXEMPLOS DE USO:
 * 
 * // 1. GET simples
 * const response = await api.get('/demandas')
 * const demandas = response.data
 * 
 * // 2. GET com parâmetros
 * const response = await api.get('/demandas', {
 *   params: { status: 'aberta', page: 1 }
 * })
 * 
 * // 3. POST
 * const response = await api.post('/demandas', {
 *   nome: 'Nova Demanda',
 *   descricao: 'Descrição...'
 * })
 * 
 * // 4. PUT
 * const response = await api.put('/demandas/123', {
 *   nome: 'Nome Atualizado'
 * })
 * 
 * // 5. DELETE
 * await api.delete('/demandas/123')
 * 
 * // 6. Upload de arquivo
 * const formData = new FormData()
 * formData.append('file', file)
 * 
 * const response = await api.post('/upload', formData, {
 *   headers: {
 *     'Content-Type': 'multipart/form-data'
 *   }
 * })
 * 
 * // 7. Request com configurações customizadas
 * const response = await api.get('/data', {
 *   timeout: 5000,
 *   headers: {
 *     'Custom-Header': 'value'
 *   }
 * })
 * 
 * // 8. Cancelar requisição
 * const controller = new AbortController()
 * 
 * api.get('/data', {
 *   signal: controller.signal
 * })
 * 
 * // Cancelar
 * controller.abort()
 */

