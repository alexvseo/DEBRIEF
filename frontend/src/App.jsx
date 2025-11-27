/**
 * App Principal
 * Configuração de rotas e navegação
 */
import { Routes, Route, Navigate } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'
import ProtectedRoute from '@/components/auth/ProtectedRoute'

// Páginas
import EmBreve from '@/pages/EmBreve'
import Login from '@/pages/Login'
import Dashboard from '@/pages/Dashboard'
import NovaDemanda from '@/pages/NovaDemanda'
import MinhasDemandas from '@/pages/MinhasDemandas'
import DemandaDetalhes from '@/pages/DemandaDetalhes'
import EditarDemanda from '@/pages/EditarDemanda'
import MeuPerfil from '@/pages/MeuPerfil'
import Configuracoes from '@/pages/Configuracoes'
import GerenciarUsuarios from '@/pages/GerenciarUsuarios'
import GerenciarPrioridades from '@/pages/GerenciarPrioridades'
import Relatorios from '@/pages/Relatorios'

// Páginas WhatsApp Admin
import ConfiguracaoWhatsApp from '@/pages/admin/ConfiguracaoWhatsApp'
import TemplatesWhatsApp from '@/pages/admin/TemplatesWhatsApp'
import HistoricoNotificacoes from '@/pages/admin/HistoricoNotificacoes'
import ConfiguracaoTrello from '@/pages/admin/ConfiguracaoTrello'
import EtiquetasTrelloClientes from '@/pages/admin/EtiquetasTrelloClientes'

// Página 404
const NotFound = () => (
  <div className="flex items-center justify-center min-h-screen bg-gray-50">
    <div className="text-center space-y-4 p-8">
      <div className="text-8xl">404</div>
      <h2 className="text-3xl font-bold text-gray-800">Página não encontrada</h2>
      <p className="text-gray-600">
        A página que você está procurando não existe.
      </p>
      <a 
        href="/"
        className="inline-block mt-4 px-6 py-3 bg-primary text-white rounded-lg hover:bg-primary-dark transition-colors"
      >
        Voltar para Home
      </a>
    </div>
  </div>
)

/**
 * Componente App Principal
 */
function App() {
  const { isAuthenticated, loading } = useAuth()

  // Mostrar loading enquanto verifica autenticação
  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-gray-50">
        <div className="text-center space-y-4">
          <div className="animate-spin rounded-full h-16 w-16 border-b-4 border-primary mx-auto"></div>
          <p className="text-gray-600 text-lg">Carregando...</p>
        </div>
      </div>
    )
  }

  return (
    <Routes>
      {/* Rota raiz - redireciona para página de manutenção */}
      <Route 
        path="/" 
        element={<Navigate to="/em-breve" replace />}
      />

      {/* Rota de Manutenção - Em Breve */}
      <Route path="/em-breve" element={<EmBreve />} />

      {/* Rota de Login */}
      <Route path="/login" element={<Login />} />

      {/* Rotas Protegidas */}
      <Route
        path="/dashboard"
        element={
          <ProtectedRoute>
            <Dashboard />
          </ProtectedRoute>
        }
      />

      <Route
        path="/nova-demanda"
        element={
          <ProtectedRoute>
            <NovaDemanda />
          </ProtectedRoute>
        }
      />

      <Route
        path="/minhas-demandas"
        element={
          <ProtectedRoute>
            <MinhasDemandas />
          </ProtectedRoute>
        }
      />

      <Route
        path="/demanda/:id"
        element={
          <ProtectedRoute>
            <DemandaDetalhes />
          </ProtectedRoute>
        }
      />

      <Route
        path="/editar-demanda/:id"
        element={
          <ProtectedRoute>
            <EditarDemanda />
          </ProtectedRoute>
        }
      />

            <Route
              path="/meu-perfil"
              element={
                <ProtectedRoute>
                  <MeuPerfil />
                </ProtectedRoute>
              }
            />

            <Route
              path="/configuracoes"
              element={
                <ProtectedRoute>
                  <Configuracoes />
                </ProtectedRoute>
              }
            />

            <Route
              path="/gerenciar-usuarios"
              element={
                <ProtectedRoute>
                  <GerenciarUsuarios />
                </ProtectedRoute>
              }
            />

            <Route
              path="/gerenciar-prioridades"
              element={
                <ProtectedRoute>
                  <GerenciarPrioridades />
                </ProtectedRoute>
              }
            />

            <Route
              path="/relatorios"
              element={
                <ProtectedRoute>
                  <Relatorios />
                </ProtectedRoute>
              }
            />

            {/* Rotas WhatsApp Admin */}
            <Route
              path="/admin/configuracao-whatsapp"
              element={
                <ProtectedRoute>
                  <ConfiguracaoWhatsApp />
                </ProtectedRoute>
              }
            />

            <Route
              path="/admin/templates-whatsapp"
              element={
                <ProtectedRoute>
                  <TemplatesWhatsApp />
                </ProtectedRoute>
              }
            />

            <Route
              path="/admin/historico-notificacoes"
              element={
                <ProtectedRoute>
                  <HistoricoNotificacoes />
                </ProtectedRoute>
              }
            />

            {/* Rotas Admin - Trello */}
            <Route
              path="/admin/trello-config"
              element={
                <ProtectedRoute>
                  <ConfiguracaoTrello />
                </ProtectedRoute>
              }
            />

            <Route
              path="/admin/trello-etiquetas"
              element={
                <ProtectedRoute>
                  <EtiquetasTrelloClientes />
                </ProtectedRoute>
              }
            />

      {/* Rota 404 */}
      <Route path="*" element={<NotFound />} />
    </Routes>
  )
}

export default App
