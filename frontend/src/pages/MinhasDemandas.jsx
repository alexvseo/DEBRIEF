/**
 * Página de Minhas Demandas
 * Lista todas as demandas do usuário
 */
import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, Plus, Search, Filter, FileText, Clock, CheckCircle, XCircle } from 'lucide-react'
import { 
  Button, 
  Card, 
  CardHeader, 
  CardTitle, 
  CardContent,
  Badge,
  Input,
  Alert,
  AlertTitle,
  AlertDescription
} from '@/components/ui'
import { useAuth } from '@/hooks/useAuth'
import { demandaService } from '@/services/demandaService'

const MinhasDemandas = () => {
  const navigate = useNavigate()
  const { user } = useAuth()
  const [demandas, setDemandas] = useState([])
  const [loading, setLoading] = useState(true)
  const [filtroStatus, setFiltroStatus] = useState('todas')
  const [busca, setBusca] = useState('')

  // Carregar demandas ao montar componente
  useEffect(() => {
    carregarDemandas()
  }, [])

  const carregarDemandas = async () => {
    try {
      setLoading(true)
      const response = await demandaService.listar()
      setDemandas(response.data.items || response.data)
    } catch (error) {
      console.error('Erro ao carregar demandas:', error)
    } finally {
      setLoading(false)
    }
  }

  // Filtrar demandas
  const demandasFiltradas = demandas.filter(demanda => {
    const matchStatus = filtroStatus === 'todas' || demanda.status === filtroStatus
    const matchBusca = demanda.nome.toLowerCase().includes(busca.toLowerCase()) ||
                      demanda.descricao.toLowerCase().includes(busca.toLowerCase())
    return matchStatus && matchBusca
  })

  // Estatísticas
  const stats = {
    total: demandas.length,
    abertas: demandas.filter(d => d.status === 'aberta').length,
    em_andamento: demandas.filter(d => d.status === 'em_andamento').length,
    concluidas: demandas.filter(d => d.status === 'concluida').length,
    canceladas: demandas.filter(d => d.status === 'cancelada').length,
  }

  // Helper para status badge
  const getStatusBadge = (status) => {
    const configs = {
      aberta: { variant: 'default', icon: FileText, label: 'Aberta' },
      em_andamento: { variant: 'warning', icon: Clock, label: 'Em Andamento' },
      concluida: { variant: 'success', icon: CheckCircle, label: 'Concluída' },
      cancelada: { variant: 'error', icon: XCircle, label: 'Cancelada' }
    }
    const config = configs[status] || configs.aberta
    const Icon = config.icon
    return (
      <Badge variant={config.variant}>
        <Icon className="h-3 w-3 mr-1" />
        {config.label}
      </Badge>
    )
  }

  // Helper para prioridade badge
  const getPrioridadeBadge = (prioridade) => {
    // prioridade pode ser objeto ou string
    const nome = typeof prioridade === 'string' ? prioridade : prioridade?.nome
    
    const configs = {
      'Baixa': { variant: 'success', emoji: '🟢' },
      'Média': { variant: 'warning', emoji: '🟡' },
      'Alta': { variant: 'error', emoji: '🟠' },
      'Urgente': { variant: 'error', emoji: '🔴' }
    }
    const config = configs[nome] || configs['Média']
    return (
      <Badge variant={config.variant} size="sm">
        {config.emoji} {nome}
      </Badge>
    )
  }

  // Loading state
  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 py-8 px-4 flex items-center justify-center">
        <div className="text-center space-y-4">
          <div className="animate-spin rounded-full h-16 w-16 border-b-4 border-primary mx-auto"></div>
          <p className="text-gray-600 text-lg">Carregando demandas...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8 px-4">
      <div className="max-w-7xl mx-auto space-y-6">
        
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Button 
              variant="outline" 
              size="sm"
              onClick={() => navigate('/dashboard')}
            >
              <ArrowLeft className="h-4 w-4" />
              Voltar
            </Button>
            
            <div>
              <h1 className="text-3xl font-bold text-gray-900">
                📋 Minhas Demandas
              </h1>
              <p className="text-gray-600 mt-1">
                Gerencie suas solicitações
              </p>
            </div>
          </div>

          <Button onClick={() => navigate('/nova-demanda')}>
            <Plus className="h-4 w-4" />
            Nova Demanda
          </Button>
        </div>

        {/* Estatísticas */}
        <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
          <Card className="hover:shadow-md transition-shadow cursor-pointer" onClick={() => setFiltroStatus('todas')}>
            <CardContent className="pt-6">
              <div className="text-center">
                <div className="text-3xl font-bold text-blue-600">{stats.total}</div>
                <div className="text-sm text-gray-600 mt-1">Total</div>
              </div>
            </CardContent>
          </Card>

          <Card className="hover:shadow-md transition-shadow cursor-pointer" onClick={() => setFiltroStatus('aberta')}>
            <CardContent className="pt-6">
              <div className="text-center">
                <div className="text-3xl font-bold text-gray-600">{stats.abertas}</div>
                <div className="text-sm text-gray-600 mt-1">Abertas</div>
              </div>
            </CardContent>
          </Card>

          <Card className="hover:shadow-md transition-shadow cursor-pointer" onClick={() => setFiltroStatus('em_andamento')}>
            <CardContent className="pt-6">
              <div className="text-center">
                <div className="text-3xl font-bold text-orange-600">{stats.em_andamento}</div>
                <div className="text-sm text-gray-600 mt-1">Em Andamento</div>
              </div>
            </CardContent>
          </Card>

          <Card className="hover:shadow-md transition-shadow cursor-pointer" onClick={() => setFiltroStatus('concluida')}>
            <CardContent className="pt-6">
              <div className="text-center">
                <div className="text-3xl font-bold text-green-600">{stats.concluidas}</div>
                <div className="text-sm text-gray-600 mt-1">Concluídas</div>
              </div>
            </CardContent>
          </Card>

          <Card className="hover:shadow-md transition-shadow cursor-pointer" onClick={() => setFiltroStatus('cancelada')}>
            <CardContent className="pt-6">
              <div className="text-center">
                <div className="text-3xl font-bold text-red-600">{stats.canceladas}</div>
                <div className="text-sm text-gray-600 mt-1">Canceladas</div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Filtros e Busca */}
        <Card>
          <CardContent className="pt-6">
            <div className="flex flex-col md:flex-row gap-4">
              <div className="flex-1">
                <Input
                  placeholder="🔍 Buscar demanda..."
                  value={busca}
                  onChange={(e) => setBusca(e.target.value)}
                  leftIcon={Search}
                />
              </div>
              <div className="flex gap-2">
                <Button 
                  variant={filtroStatus === 'todas' ? 'default' : 'outline'}
                  onClick={() => setFiltroStatus('todas')}
                >
                  Todas
                </Button>
                <Button 
                  variant={filtroStatus === 'aberta' ? 'default' : 'outline'}
                  onClick={() => setFiltroStatus('aberta')}
                >
                  Abertas
                </Button>
                <Button 
                  variant={filtroStatus === 'em_andamento' ? 'default' : 'outline'}
                  onClick={() => setFiltroStatus('em_andamento')}
                >
                  Em Andamento
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Lista de Demandas */}
        {demandasFiltradas.length === 0 ? (
          <Alert>
            <AlertTitle>Nenhuma demanda encontrada</AlertTitle>
            <AlertDescription>
              {busca 
                ? `Não encontramos demandas com "${busca}"`
                : 'Você ainda não tem demandas. Clique em "Nova Demanda" para criar sua primeira solicitação!'
              }
            </AlertDescription>
          </Alert>
        ) : (
          <div className="space-y-4">
            {demandasFiltradas.map((demanda) => (
              <Card key={demanda.id} className="hover:shadow-lg transition-shadow cursor-pointer">
                <CardHeader>
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <CardTitle className="text-lg">{demanda.nome}</CardTitle>
                      <p className="text-sm text-gray-600 mt-2">{demanda.descricao}</p>
                    </div>
                    <div className="ml-4 flex flex-col gap-2">
                      {getStatusBadge(demanda.status)}
                      {getPrioridadeBadge(demanda.prioridade)}
                    </div>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-1 md:grid-cols-4 gap-4 text-sm">
                    <div>
                      <span className="font-semibold text-gray-700">Tipo:</span>
                      <p className="text-gray-900">{demanda.tipo_demanda?.nome || demanda.tipo || 'N/A'}</p>
                    </div>
                    <div>
                      <span className="font-semibold text-gray-700">Secretaria:</span>
                      <p className="text-gray-900">{demanda.secretaria?.nome || demanda.secretaria || 'N/A'}</p>
                    </div>
                    <div>
                      <span className="font-semibold text-gray-700">Prazo:</span>
                      <p className="text-gray-900">{new Date(demanda.prazo_final).toLocaleDateString('pt-BR')}</p>
                    </div>
                    <div>
                      <span className="font-semibold text-gray-700">Criada em:</span>
                      <p className="text-gray-900">{new Date(demanda.created_at).toLocaleDateString('pt-BR')}</p>
                    </div>
                  </div>

                  <div className="flex gap-2 mt-4">
                    <Button variant="outline" size="sm">
                      Ver Detalhes
                    </Button>
                    {demanda.status === 'aberta' && (
                      <Button variant="outline" size="sm">
                        Editar
                      </Button>
                    )}
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        )}

      </div>
    </div>
  )
}

export default MinhasDemandas

