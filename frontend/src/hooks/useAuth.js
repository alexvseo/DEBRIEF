/**
 * useAuth Hook
 * Hook para acessar o contexto de autenticação
 */
import { useContext } from 'react'
import AuthContext from '@/contexts/AuthContext'

/**
 * Hook para acessar autenticação
 * 
 * @returns {Object} - Contexto de autenticação
 * @throws {Error} - Se usado fora do AuthProvider
 * 
 * @example
 * function MyComponent() {
 *   const { user, login, logout, isAuthenticated } = useAuth()
 *   
 *   return (
 *     <div>
 *       {isAuthenticated ? (
 *         <button onClick={logout}>Sair</button>
 *       ) : (
 *         <button onClick={() => login('user', 'pass')}>Entrar</button>
 *       )}
 *     </div>
 *   )
 * }
 */
export const useAuth = () => {
  const context = useContext(AuthContext)
  
  if (context === undefined) {
    throw new Error('useAuth deve ser usado dentro de um AuthProvider')
  }
  
  return context
}

export default useAuth

