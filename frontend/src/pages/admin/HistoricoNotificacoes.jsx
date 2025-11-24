/**
 * Página de Histórico de Notificações WhatsApp
 * Exibe logs de todas as notificações enviadas
 */
import React, { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ArrowLeft,
  Search,
  Filter,
  Calendar,
  User,
  MessageSquare,
  CheckCircle,
  XCircle,
  Clock,
  Loader2,
  Download,
  RefreshCw,
  AlertTriangle
} from 'lucide-react'
import {
  Button,
  Card,
  CardHeader,
  CardTitle,
  CardContent,
  Input,
  Badge,
  Alert,
  AlertDescription
} from '@/components/ui'
import { useAuth } from '@/hooks/useAuth'
import api from '@/services/api'
import { toast } from 'sonner'

const HistoricoNotificacoes = () => {
  const navigate = useNavigate()
  const { isMaster } = useAuth()
  
  const [loading, setLoading] = useState(true)
  const [notificacoes, setNotificacoes] = useState([])
  const [filtros, setFiltros] = useState({
    busca: '',
    status: '',
    tipo_evento: '',
    data_inicio: '',
    data_fim: ''
  })
  const [paginacao, setPaginacao] = useState({
    pagina: 1,
    limite: 50,
    total: 0
  })
  const [estatisticas, setEstatisticas] = useState({
    total: 0,
    enviadas: 0,
    falhadas: 0,
    pendentes: 0
  })
  
  const tiposEvento = [
    { value: '', label: 'Todos os Eventos' },
    { value: 'demanda_criada', label: 'Demanda Criada' },
    { value: 'demanda_atualizada', label: 'Demanda Atualizada' },
    { value: 'demanda_concluida', label: 'Demanda Concluída' },
    { value: 'demanda_cancelada', label: 'Demanda Cancelada' }
  ]
  
  const statusOpcoes = [
    { value: '', label: 'Todos os Status' },
    { value: 'enviada', label: 'Enviada' },
    { value: 'falhada', label: 'Falhada' },
    { value: 'pendente', label: 'Pendente' }
  ]
  
  // Verificar permissão
  useEffect(() => {
    if (!isMaster()) {
      navigate('/dashboard')
    }
  }, [isMaster, navigate])
  
  // Carregar notificações
  useEffect(() => {
    carregarNotificacoes()
  }, [paginacao.pagina, filtros])
  
  const carregarNotificacoes = async () => {
    try {
      setLoading(true)
      
      const params = {
        skip: (paginacao.pagina - 1) * paginacao.limite,
        limit: paginacao.limite,
        ...filtros
      }
      
      // Remover filtros vazios
      Object.keys(params).forEach(key => {
        if (params[key] === '') delete params[key]
      })
      
      const response = await api.get('/whatsapp/notificacoes/historico', { params })
      
      setNotificacoes(response.data.notificacoes || [])
      setPaginacao(prev => ({
        ...prev,
        total: response.data.total || 0
      }))
      
      // Calcular estatísticas
      calcularEstatisticas(response.data.notificacoes || [])
    } catch (error) {
      console.error('Erro ao carregar notificações:', error)
      toast.error('Erro ao carregar histórico de notificações')
    } finally {
      setLoading(false)
    }
  }
  
  const calcularEstatisticas = (dados) => {
    const stats = {
      total: dados.length,
      enviadas: dados.filter(n => n.status === 'enviada').length,
      falhadas: dados.filter(n => n.status === 'falhada').length,
      pendentes: dados.filter(n => n.status === 'pendente').length
    }
    setEstatisticas(stats)
  }
  
  const handleFiltroChange = (campo, valor) => {
    setFiltros(prev => ({
      ...prev,
      [campo]: valor
    }))
    setPaginacao(prev => ({ ...prev, pagina: 1 }))
  }
  
  const limparFiltros = () => {
    setFiltros({
      busca: '',
      status: '',
      tipo_evento: '',
      data_inicio: '',
      data_fim: ''
    })
    setPaginacao(prev => ({ ...prev, pagina: 1 }))
  }
  
  const formatarData = (dataIso) => {
    if (!dataIso) return '-'
    const data = new Date(dataIso)
    return data.toLocaleString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }
  
  const exportarCSV = async () => {
    try {
      toast.info('Gerando arquivo CSV...')
      
      const params = { ...filtros }
      Object.keys(params).forEach(key => {
        if (params[key] === '') delete params[key]
      })
      
      const response = await api.get('/whatsapp/notificacoes/exportar-csv', {
        params,
        responseType: 'blob'
      })
      
      // Criar link de download
      const url = window.URL.createObjectURL(new Blob([response.data]))
      const link = document.createElement('a')
      link.href = url
      link.setAttribute('download', `historico-notificacoes-${new Date().getTime()}.csv`)
      document.body.appendChild(link)
      link.click()
      link.remove()
      
      toast.success('Arquivo CSV gerado com sucesso!')
    } catch (error) {
      console.error('Erro ao exportar CSV:', error)
      toast.error('Erro ao exportar dados')
    }
  }
  
  const getStatusBadge = (status) => {
    const configs = {
      enviada: { variant: 'success', icon: CheckCircle, label: 'Enviada' },
      falhada: { variant: 'error', icon: XCircle, label: 'Falhada' },
      pendente: { variant: 'warning', icon: Clock, label: 'Pendente' }
    }
    
    const config = configs[status] || configs.pendente
    const Icon = config.icon
    
    return (
      <Badge variant={config.variant} className="flex items-center gap-1">
        <Icon className="h-3 w-3" />
        {config.label}
      </Badge>
    )
  }
  
  const totalPaginas = Math.ceil(paginacao.total / paginacao.limite)
  
  if (loading && paginacao.pagina === 1) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="h-8 w-8 animate-spin mx-auto text-primary" />
          <p className="mt-2 text-gray-600">Carregando histórico...</p>
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
            <Button variant="ghost" onClick={() => navigate('/configuracoes')}>
              <ArrowLeft className="h-4 w-4 mr-2" />
              Voltar
            </Button>
            <div>
              <h1 className="text-3xl font-bold text-gray-900 flex items-center gap-2">
                <MessageSquare className="h-8 w-8 text-blue-600" />
                Histórico de Notificações
              </h1>
              <p className="text-gray-600 mt-1">
                Acompanhe todas as notificações WhatsApp enviadas
              </p>
            </div>
          </div>
          
          <div className="flex gap-2">
            <Button variant="outline" onClick={carregarNotificacoes}>
              <RefreshCw className="h-4 w-4 mr-2" />
              Atualizar
            </Button>
            <Button variant="outline" onClick={exportarCSV}>
              <Download className="h-4 w-4 mr-2" />
              Exportar CSV
            </Button>
          </div>
        </div>
        
        {/* Estatísticas */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <Card>
            <CardContent className="py-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Total</p>
                  <p className="text-2xl font-bold text-gray-900">{paginacao.total}</p>
                </div>
                <MessageSquare className="h-8 w-8 text-gray-400" />
              </div>
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="py-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Enviadas</p>
                  <p className="text-2xl font-bold text-green-600">{estatisticas.enviadas}</p>
                </div>
                <CheckCircle className="h-8 w-8 text-green-400" />
              </div>
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="py-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Falhadas</p>
                  <p className="text-2xl font-bold text-red-600">{estatisticas.falhadas}</p>
                </div>
                <XCircle className="h-8 w-8 text-red-400" />
              </div>
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="py-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Pendentes</p>
                  <p className="text-2xl font-bold text-yellow-600">{estatisticas.pendentes}</p>
                </div>
                <Clock className="h-8 w-8 text-yellow-400" />
              </div>
            </CardContent>
          </Card>
        </div>
        
        {/* Filtros */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Filter className="h-5 w-5" />
              Filtros
            </CardTitle>
          </CardHeader>
          
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
              {/* Busca */}
              <div className="md:col-span-2">
                <label className="text-sm font-medium text-gray-700 mb-1 block">
                  Buscar
                </label>
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                  <Input
                    value={filtros.busca}
                    onChange={(e) => handleFiltroChange('busca', e.target.value)}
                    placeholder="Usuário, telefone ou demanda..."
                    className="pl-10"
                  />
                </div>
              </div>
              
              {/* Status */}
              <div>
                <label className="text-sm font-medium text-gray-700 mb-1 block">
                  Status
                </label>
                <select
                  value={filtros.status}
                  onChange={(e) => handleFiltroChange('status', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary focus:border-transparent"
                >
                  {statusOpcoes.map(opt => (
                    <option key={opt.value} value={opt.value}>{opt.label}</option>
                  ))}
                </select>
              </div>
              
              {/* Tipo de Evento */}
              <div>
                <label className="text-sm font-medium text-gray-700 mb-1 block">
                  Tipo de Evento
                </label>
                <select
                  value={filtros.tipo_evento}
                  onChange={(e) => handleFiltroChange('tipo_evento', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary focus:border-transparent"
                >
                  {tiposEvento.map(tipo => (
                    <option key={tipo.value} value={tipo.value}>{tipo.label}</option>
                  ))}
                </select>
              </div>
              
              {/* Limpar Filtros */}
              <div className="flex items-end">
                <Button variant="outline" onClick={limparFiltros} className="w-full">
                  Limpar Filtros
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
        
        {/* Tabela de Notificações */}
        <Card>
          <CardContent className="p-0">
            {notificacoes.length === 0 ? (
              <div className="py-12 text-center">
                <MessageSquare className="h-12 w-12 mx-auto text-gray-400 mb-4" />
                <h3 className="text-lg font-semibold text-gray-900 mb-2">
                  Nenhuma notificação encontrada
                </h3>
                <p className="text-gray-600">
                  {Object.values(filtros).some(f => f !== '') 
                    ? 'Tente ajustar os filtros'
                    : 'As notificações aparecerão aqui quando forem enviadas'
                  }
                </p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-gray-50 border-b border-gray-200">
                    <tr>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                        Data/Hora
                      </th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                        Usuário
                      </th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                        Telefone
                      </th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                        Tipo
                      </th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                        Demanda
                      </th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                        Status
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {notificacoes.map((notif) => (
                      <tr key={notif.id} className="hover:bg-gray-50">
                        <td className="px-4 py-3 text-sm text-gray-900">
                          {formatarData(notif.created_at)}
                        </td>
                        <td className="px-4 py-3 text-sm text-gray-900">
                          {notif.usuario_nome || '-'}
                        </td>
                        <td className="px-4 py-3 text-sm text-gray-900 font-mono">
                          {notif.telefone_destinatario}
                        </td>
                        <td className="px-4 py-3 text-sm text-gray-600">
                          {tiposEvento.find(t => t.value === notif.tipo_evento)?.label || notif.tipo_evento}
                        </td>
                        <td className="px-4 py-3 text-sm text-gray-600">
                          {notif.demanda_titulo || '-'}
                        </td>
                        <td className="px-4 py-3">
                          {getStatusBadge(notif.status)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </CardContent>
        </Card>
        
        {/* Paginação */}
        {totalPaginas > 1 && (
          <div className="flex items-center justify-between">
            <p className="text-sm text-gray-600">
              Mostrando {(paginacao.pagina - 1) * paginacao.limite + 1} a{' '}
              {Math.min(paginacao.pagina * paginacao.limite, paginacao.total)} de{' '}
              {paginacao.total} notificações
            </p>
            
            <div className="flex gap-2">
              <Button
                variant="outline"
                onClick={() => setPaginacao(prev => ({ ...prev, pagina: prev.pagina - 1 }))}
                disabled={paginacao.pagina === 1}
              >
                Anterior
              </Button>
              
              <span className="flex items-center px-4">
                Página {paginacao.pagina} de {totalPaginas}
              </span>
              
              <Button
                variant="outline"
                onClick={() => setPaginacao(prev => ({ ...prev, pagina: prev.pagina + 1 }))}
                disabled={paginacao.pagina === totalPaginas}
              >
                Próxima
              </Button>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

export default HistoricoNotificacoes

