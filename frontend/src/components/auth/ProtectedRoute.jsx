/**
 * ProtectedRoute - Componente para proteger rotas
 * Redireciona para login se não autenticado
 */
import React from 'react'
import { Navigate, useLocation } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'

/**
 * Rota protegida que requer autenticação
 * 
 * @param {Object} props
 * @param {React.ReactNode} props.children - Componente filho
 * @param {string} props.redirectTo - Rota de redirecionamento (padrão: /login)
 * @param {string} props.requiredRole - Role necessária (master, cliente)
 * @param {string[]} props.requiredPermissions - Permissões necessárias
 * 
 * @example
 * <ProtectedRoute>
 *   <Dashboard />
 * </ProtectedRoute>
 * 
 * @example
 * <ProtectedRoute requiredRole="master">
 *   <AdminPanel />
 * </ProtectedRoute>
 */
const ProtectedRoute = ({ 
  children, 
  redirectTo = '/login',
  requiredRole = null,
  requiredPermissions = [],
}) => {
  const { isAuthenticated, loading, user, hasPermission } = useAuth()
  const location = useLocation()

  // Aguardar carregamento da autenticação
  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center space-y-4">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
          <p className="text-gray-600">Carregando...</p>
        </div>
      </div>
    )
  }

  // Redirecionar se não autenticado
  if (!isAuthenticated) {
    // Salvar a URL atual para redirecionar após login
    return <Navigate to={redirectTo} state={{ from: location }} replace />
  }

  // Verificar role se especificada
  if (requiredRole && user?.tipo !== requiredRole) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center space-y-4 p-8">
          <div className="text-6xl">🚫</div>
          <h2 className="text-2xl font-bold text-gray-800">Acesso Negado</h2>
          <p className="text-gray-600">
            Você não tem permissão para acessar esta página.
          </p>
          <button 
            onClick={() => window.history.back()}
            className="mt-4 px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary-dark"
          >
            Voltar
          </button>
        </div>
      </div>
    )
  }

  // Verificar permissões se especificadas
  if (requiredPermissions.length > 0) {
    const hasAllPermissions = requiredPermissions.every(permission => 
      hasPermission(permission)
    )

    if (!hasAllPermissions) {
      return (
        <div className="flex items-center justify-center min-h-screen">
          <div className="text-center space-y-4 p-8">
            <div className="text-6xl">🔒</div>
            <h2 className="text-2xl font-bold text-gray-800">Sem Permissão</h2>
            <p className="text-gray-600">
              Você não possui as permissões necessárias para acessar esta página.
            </p>
            <button 
              onClick={() => window.history.back()}
              className="mt-4 px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary-dark"
            >
              Voltar
            </button>
          </div>
        </div>
      )
    }
  }

  // Renderizar componente filho se todas as verificações passarem
  return <>{children}</>
}

export default ProtectedRoute

/**
 * EXEMPLOS DE USO:
 * 
 * // 1. Rota protegida simples (apenas autenticação)
 * <Route
 *   path="/dashboard"
 *   element={
 *     <ProtectedRoute>
 *       <Dashboard />
 *     </ProtectedRoute>
 *   }
 * />
 * 
 * // 2. Rota protegida com role específica
 * <Route
 *   path="/admin"
 *   element={
 *     <ProtectedRoute requiredRole="master">
 *       <AdminPanel />
 *     </ProtectedRoute>
 *   }
 * />
 * 
 * // 3. Rota protegida com permissões
 * <Route
 *   path="/users"
 *   element={
 *     <ProtectedRoute requiredPermissions={['users.read', 'users.write']}>
 *       <UsersPage />
 *     </ProtectedRoute>
 *   }
 * />
 * 
 * // 4. Rota protegida com redirecionamento customizado
 * <Route
 *   path="/premium"
 *   element={
 *     <ProtectedRoute redirectTo="/upgrade">
 *       <PremiumContent />
 *     </ProtectedRoute>
 *   }
 * />
 * 
 * // 5. Múltiplas rotas protegidas
 * <Routes>
 *   <Route path="/login" element={<Login />} />
 *   
 *   <Route element={<ProtectedRoute><Layout /></ProtectedRoute>}>
 *     <Route path="/dashboard" element={<Dashboard />} />
 *     <Route path="/demandas" element={<Demandas />} />
 *     <Route path="/perfil" element={<Perfil />} />
 *   </Route>
 * </Routes>
 */

