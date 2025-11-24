/**
 * Página de Minhas Demandas
 * Lista todas as demandas do usuário
 */
import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, Plus, Search, Filter, FileText, Clock, CheckCircle, XCircle, ChevronLeft, ChevronRight, Trash2, Eye, Edit } from 'lucide-react'
import { toast } from 'sonner'
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
  const { user, isMaster } = useAuth()
  const [demandas, setDemandas] = useState([])
  const [loading, setLoading] = useState(true)
  const [filtroStatus, setFiltroStatus] = useState('todas')
  const [busca, setBusca] = useState('')
  const [paginaAtual, setPaginaAtual] = useState(1)
  const [demandaParaExcluir, setDemandaParaExcluir] = useState(null)
  const [excluindo, setExcluindo] = useState(false)
  const [demandaExcluindo, setDemandaExcluindo] = useState(null)
  const ITENS_POR_PAGINA = 5

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

  // Função para excluir demanda com animação suave
  const handleExcluirDemanda = async () => {
    if (!demandaParaExcluir) return

    try {
      setExcluindo(true)
      
      // Iniciar animação de exclusão
      setDemandaExcluindo(demandaParaExcluir.id)
      
      // Aguardar um pouco para a animação começar
      await new Promise(resolve => setTimeout(resolve, 100))
      
      // Fechar modal
      setDemandaParaExcluir(null)
      
      // Executar a exclusão no backend
      await demandaService.deletar(demandaParaExcluir.id)
      
      // Aguardar a animação completar (800ms)
      await new Promise(resolve => setTimeout(resolve, 800))
      
      // Atualizar lista de demandas
      await carregarDemandas()
      
      // Limpar estado de animação
      setDemandaExcluindo(null)
      
      // Mostrar feedback com toast
      toast.success('Demanda excluída com sucesso!', {
        description: 'A demanda foi removida permanentemente.',
        duration: 3000,
      })
    } catch (error) {
      console.error('Erro ao excluir demanda:', error)
      toast.error('Erro ao excluir demanda', {
        description: 'Não foi possível excluir a demanda. Tente novamente.',
        duration: 4000,
      })
      setDemandaExcluindo(null)
    } finally {
      setExcluindo(false)
    }
  }

  // Filtrar demandas
  const demandasFiltradas = demandas.filter(demanda => {
    const matchStatus = filtroStatus === 'todas' || demanda.status === filtroStatus
    const matchBusca = demanda.nome.toLowerCase().includes(busca.toLowerCase()) ||
                      demanda.descricao.toLowerCase().includes(busca.toLowerCase())
    return matchStatus && matchBusca
  })

  // Paginação
  const totalPaginas = Math.ceil(demandasFiltradas.length / ITENS_POR_PAGINA)
  const indiceInicio = (paginaAtual - 1) * ITENS_POR_PAGINA
  const indiceFim = indiceInicio + ITENS_POR_PAGINA
  const demandasPaginadas = demandasFiltradas.slice(indiceInicio, indiceFim)

  // Resetar página ao filtrar
  useEffect(() => {
    setPaginaAtual(1)
  }, [filtroStatus, busca])

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
          <Alert dismissible>
            <AlertTitle>Nenhuma demanda encontrada</AlertTitle>
            <AlertDescription>
              {busca 
                ? `Não encontramos demandas com "${busca}"`
                : 'Você ainda não tem demandas. Clique em "Nova Demanda" para criar sua primeira solicitação!'
              }
            </AlertDescription>
          </Alert>
        ) : (
          <>
            <div className="space-y-4">
              {demandasPaginadas.map((demanda) => (
                <Card 
                  key={demanda.id} 
                  className={`hover:shadow-lg transition-all duration-700 ease-in-out ${
                    demandaExcluindo === demanda.id 
                      ? 'opacity-0 scale-95 -translate-x-8 bg-red-50 border-red-200' 
                      : 'opacity-100 scale-100 translate-x-0'
                  }`}
                  style={{
                    transition: 'all 0.7s cubic-bezier(0.4, 0, 0.2, 1)',
                  }}
                >
                  <CardHeader>
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <CardTitle className="text-lg">{demanda.nome}</CardTitle>
                        <p className="text-sm text-gray-600 mt-2 line-clamp-2">{demanda.descricao}</p>
                      </div>
                      <div className="ml-4 flex flex-col gap-2">
                        {getStatusBadge(demanda.status)}
                        {getPrioridadeBadge(demanda.prioridade)}
                      </div>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <div className="grid grid-cols-1 md:grid-cols-5 gap-4 text-sm mb-4">
                      <div>
                        <span className="font-semibold text-gray-700">Cliente:</span>
                        <p className="text-gray-900">{demanda.cliente?.nome || 'N/A'}</p>
                      </div>
                      <div>
                        <span className="font-semibold text-gray-700">Secretaria:</span>
                        <p className="text-gray-900">{demanda.secretaria?.nome || 'N/A'}</p>
                      </div>
                      <div>
                        <span className="font-semibold text-gray-700">Tipo:</span>
                        <p className="text-gray-900">{demanda.tipo_demanda?.nome || 'N/A'}</p>
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

                    <div className="flex gap-2">
                      <Button 
                        variant="outline" 
                        size="sm"
                        onClick={() => navigate(`/demanda/${demanda.id}`)}
                        className="border-blue-500 text-blue-600 hover:bg-blue-50 hover:border-blue-600"
                      >
                        <Eye className="h-4 w-4 mr-1" />
                        Ver Detalhes
                      </Button>
                      {/* Mostrar botão Editar para demandas abertas ou em andamento */}
                      {(demanda.status === 'aberta' || demanda.status === 'em_andamento') && (
                        <Button 
                          variant="outline" 
                          size="sm"
                          onClick={() => navigate(`/editar-demanda/${demanda.id}`)}
                          className="border-orange-500 text-orange-600 hover:bg-orange-50 hover:border-orange-600"
                        >
                          <Edit className="h-4 w-4 mr-1" />
                          Editar
                        </Button>
                      )}
                      {/* Mostrar botão Excluir APENAS para Masters e demandas abertas ou em andamento */}
                      {isMaster() && (demanda.status === 'aberta' || demanda.status === 'em_andamento') && (
                        <Button 
                          variant="outline" 
                          size="sm"
                          onClick={() => setDemandaParaExcluir(demanda)}
                          className="border-red-500 text-red-600 hover:bg-red-50 hover:border-red-600"
                        >
                          <Trash2 className="h-4 w-4 mr-1" />
                          Excluir
                        </Button>
                      )}
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>

            {/* Paginação */}
            {totalPaginas > 1 && (
              <Card>
                <CardContent className="pt-6">
                  <div className="flex items-center justify-between">
                    <div className="text-sm text-gray-600">
                      Mostrando {indiceInicio + 1}-{Math.min(indiceFim, demandasFiltradas.length)} de {demandasFiltradas.length} demandas
                    </div>
                    <div className="flex gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setPaginaAtual(p => Math.max(1, p - 1))}
                        disabled={paginaAtual === 1}
                      >
                        <ChevronLeft className="h-4 w-4" />
                        Anterior
                      </Button>
                      
                      <div className="flex items-center gap-2">
                        {Array.from({ length: totalPaginas }, (_, i) => i + 1).map(pagina => (
                          <Button
                            key={pagina}
                            variant={paginaAtual === pagina ? 'default' : 'outline'}
                            size="sm"
                            onClick={() => setPaginaAtual(pagina)}
                            className="w-10"
                          >
                            {pagina}
                          </Button>
                        ))}
                      </div>

                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setPaginaAtual(p => Math.min(totalPaginas, p + 1))}
                        disabled={paginaAtual === totalPaginas}
                      >
                        Próxima
                        <ChevronRight className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            )}
          </>
        )}

      </div>

      {/* Modal de Confirmação de Exclusão */}
      {demandaParaExcluir && (
        <div 
          className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4 animate-in fade-in duration-200"
          onClick={(e) => {
            if (e.target === e.currentTarget && !excluindo) {
              setDemandaParaExcluir(null)
            }
          }}
        >
          <Card className="max-w-md w-full animate-in zoom-in-95 duration-300">
            <CardHeader>
              <CardTitle className="text-xl flex items-center gap-2 text-red-600">
                <Trash2 className="h-6 w-6" />
                Confirmar Exclusão
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <p className="text-gray-700 mb-2">
                  Tem certeza que deseja excluir a demanda:
                </p>
                <p className="font-semibold text-gray-900 bg-gray-50 p-3 rounded-md">
                  {demandaParaExcluir.nome}
                </p>
              </div>
              
              <Alert variant="warning">
                <AlertTitle>⚠️ Atenção</AlertTitle>
                <AlertDescription>
                  Esta ação não pode ser desfeita. A demanda será excluída permanentemente.
                </AlertDescription>
              </Alert>

              <div className="flex gap-3 justify-end pt-2">
                <Button
                  variant="outline"
                  onClick={() => setDemandaParaExcluir(null)}
                  disabled={excluindo}
                >
                  Cancelar
                </Button>
                <Button
                  onClick={handleExcluirDemanda}
                  disabled={excluindo}
                  className={`bg-red-600 hover:bg-red-700 text-white transition-all duration-300 ${
                    excluindo ? 'scale-95 opacity-90' : 'scale-100 opacity-100'
                  }`}
                >
                  {excluindo ? (
                    <>
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                      <span className="animate-pulse">Excluindo...</span>
                    </>
                  ) : (
                    <>
                      <Trash2 className="h-4 w-4 mr-2" />
                      Confirmar Exclusão
                    </>
                  )}
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  )
}

export default MinhasDemandas

