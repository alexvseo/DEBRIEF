/**
 * Página de Detalhes da Demanda
 * Visualização completa de uma demanda específica
 */
import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { 
  ArrowLeft, 
  Edit, 
  ExternalLink, 
  Calendar, 
  Clock, 
  User, 
  Building, 
  FileText,
  Download,
  Link as LinkIcon,
  CheckCircle,
  XCircle,
  AlertCircle
} from 'lucide-react'
import { 
  Button, 
  Card, 
  CardHeader, 
  CardTitle, 
  CardContent,
  Badge,
  Alert,
  AlertTitle,
  AlertDescription
} from '@/components/ui'
import { useAuth } from '@/hooks/useAuth'
import { demandaService } from '@/services/demandaService'
import { toast } from 'sonner'

const DemandaDetalhes = () => {
  const { id } = useParams()
  const navigate = useNavigate()
  const { user } = useAuth()
  const [demanda, setDemanda] = useState(null)
  const [loading, setLoading] = useState(true)
  const [processando, setProcessando] = useState(false)

  useEffect(() => {
    carregarDemanda()
  }, [id])

  const carregarDemanda = async () => {
    try {
      setLoading(true)
      const response = await demandaService.buscarPorId(id)
      setDemanda(response.data)
    } catch (error) {
      console.error('Erro ao carregar demanda:', error)
      toast.error('Erro ao carregar demanda')
      navigate('/minhas-demandas')
    } finally {
      setLoading(false)
    }
  }

  // Helper para status badge
  const getStatusBadge = (status) => {
    const configs = {
      aberta: { variant: 'default', icon: FileText, label: 'Aberta', color: 'bg-blue-100 text-blue-800' },
      em_andamento: { variant: 'warning', icon: Clock, label: 'Em Andamento', color: 'bg-yellow-100 text-yellow-800' },
      aguardando_cliente: { variant: 'warning', icon: AlertCircle, label: 'Aguardando Cliente', color: 'bg-orange-100 text-orange-800' },
      concluida: { variant: 'success', icon: CheckCircle, label: 'Concluída', color: 'bg-green-100 text-green-800' },
      cancelada: { variant: 'error', icon: XCircle, label: 'Cancelada', color: 'bg-red-100 text-red-800' }
    }
    const config = configs[status] || configs.aberta
    const Icon = config.icon
    return (
      <div className={`inline-flex items-center gap-2 px-4 py-2 rounded-lg ${config.color}`}>
        <Icon className="h-5 w-5" />
        <span className="font-semibold">{config.label}</span>
      </div>
    )
  }

  // Helper para prioridade badge
  const getPrioridadeBadge = (prioridade) => {
    const nome = prioridade?.nome || 'Média'
    const configs = {
      'Baixa': { color: 'bg-green-100 text-green-800', emoji: '🟢' },
      'Média': { color: 'bg-yellow-100 text-yellow-800', emoji: '🟡' },
      'Alta': { color: 'bg-orange-100 text-orange-800', emoji: '🟠' },
      'Urgente': { color: 'bg-red-100 text-red-800', emoji: '🔴' }
    }
    const config = configs[nome] || configs['Média']
    return (
      <div className={`inline-flex items-center gap-2 px-4 py-2 rounded-lg ${config.color}`}>
        <span className="text-lg">{config.emoji}</span>
        <span className="font-semibold">{nome}</span>
      </div>
    )
  }

  const handleConcluir = async () => {
    if (!confirm('Deseja marcar esta demanda como concluída?')) return
    
    try {
      setProcessando(true)
      await demandaService.atualizar(id, { status: 'concluida' })
      toast.success('Demanda concluída com sucesso!')
      carregarDemanda()
    } catch (error) {
      console.error('Erro ao concluir demanda:', error)
      toast.error('Erro ao concluir demanda')
    } finally {
      setProcessando(false)
    }
  }

  const handleCancelar = async () => {
    if (!confirm('Deseja cancelar esta demanda?')) return
    
    try {
      setProcessando(true)
      await demandaService.atualizar(id, { status: 'cancelada' })
      toast.success('Demanda cancelada com sucesso!')
      carregarDemanda()
    } catch (error) {
      console.error('Erro ao cancelar demanda:', error)
      toast.error('Erro ao cancelar demanda')
    } finally {
      setProcessando(false)
    }
  }

  // Loading state
  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 py-8 px-4 flex items-center justify-center">
        <div className="text-center space-y-4">
          <div className="animate-spin rounded-full h-16 w-16 border-b-4 border-primary mx-auto"></div>
          <p className="text-gray-600 text-lg">Carregando demanda...</p>
        </div>
      </div>
    )
  }

  if (!demanda) {
    return (
      <div className="min-h-screen bg-gray-50 py-8 px-4">
        <div className="max-w-4xl mx-auto">
          <Alert variant="error">
            <AlertTitle>Demanda não encontrada</AlertTitle>
            <AlertDescription>
              A demanda que você está procurando não existe ou foi removida.
            </AlertDescription>
          </Alert>
          <Button 
            className="mt-4"
            onClick={() => navigate('/minhas-demandas')}
          >
            <ArrowLeft className="h-4 w-4" />
            Voltar para Minhas Demandas
          </Button>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8 px-4">
      <div className="max-w-6xl mx-auto space-y-6">
        
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Button 
              variant="outline" 
              size="sm"
              onClick={() => navigate('/minhas-demandas')}
            >
              <ArrowLeft className="h-4 w-4" />
              Voltar
            </Button>
            
            <div>
              <h1 className="text-3xl font-bold text-gray-900">
                📋 Detalhes da Demanda
              </h1>
              <p className="text-gray-600 mt-1">
                ID: {demanda.id}
              </p>
            </div>
          </div>

          {/* Mostrar botão Editar para demandas abertas ou em andamento */}
          {(demanda.status === 'aberta' || demanda.status === 'em_andamento') && (
            <Button onClick={() => navigate(`/editar-demanda/${id}`)}>
              <Edit className="h-4 w-4" />
              Editar Demanda
            </Button>
          )}
        </div>

        {/* Status e Prioridade */}
        <div className="flex gap-4 flex-wrap">
          {getStatusBadge(demanda.status)}
          {getPrioridadeBadge(demanda.prioridade)}
        </div>

        {/* Informações Principais */}
        <Card>
          <CardHeader>
            <CardTitle className="text-2xl">{demanda.nome}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            
            {/* Grid de Informações */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              
              <div className="space-y-2">
                <div className="flex items-center gap-2 text-gray-600">
                  <Building className="h-4 w-4" />
                  <span className="font-semibold">Cliente</span>
                </div>
                <p className="text-lg text-gray-900">{demanda.cliente?.nome || 'N/A'}</p>
              </div>

              <div className="space-y-2">
                <div className="flex items-center gap-2 text-gray-600">
                  <Building className="h-4 w-4" />
                  <span className="font-semibold">Secretaria</span>
                </div>
                <p className="text-lg text-gray-900">{demanda.secretaria?.nome || 'N/A'}</p>
              </div>

              <div className="space-y-2">
                <div className="flex items-center gap-2 text-gray-600">
                  <FileText className="h-4 w-4" />
                  <span className="font-semibold">Tipo</span>
                </div>
                <Badge style={{ backgroundColor: demanda.tipo_demanda?.cor || '#3B82F6' }}>
                  {demanda.tipo_demanda?.nome || 'N/A'}
                </Badge>
              </div>

              <div className="space-y-2">
                <div className="flex items-center gap-2 text-gray-600">
                  <Calendar className="h-4 w-4" />
                  <span className="font-semibold">Prazo Final</span>
                </div>
                <p className="text-lg text-gray-900">
                  {new Date(demanda.prazo_final).toLocaleDateString('pt-BR')}
                </p>
              </div>

              <div className="space-y-2">
                <div className="flex items-center gap-2 text-gray-600">
                  <Clock className="h-4 w-4" />
                  <span className="font-semibold">Criada em</span>
                </div>
                <p className="text-lg text-gray-900">
                  {new Date(demanda.created_at).toLocaleString('pt-BR')}
                </p>
              </div>

              <div className="space-y-2">
                <div className="flex items-center gap-2 text-gray-600">
                  <Clock className="h-4 w-4" />
                  <span className="font-semibold">Atualizada em</span>
                </div>
                <p className="text-lg text-gray-900">
                  {new Date(demanda.updated_at).toLocaleString('pt-BR')}
                </p>
              </div>

            </div>

            {/* Descrição */}
            <div className="space-y-2">
              <h3 className="font-semibold text-gray-900 text-lg">Descrição</h3>
              <div className="p-4 bg-gray-50 rounded-lg">
                <p className="text-gray-900 whitespace-pre-wrap">{demanda.descricao}</p>
              </div>
            </div>

            {/* Links de Referência */}
            {demanda.links_referencia && (
              <div className="space-y-2">
                <h3 className="font-semibold text-gray-900 text-lg flex items-center gap-2">
                  <LinkIcon className="h-5 w-5" />
                  Links de Referência
                </h3>
                <div className="space-y-2">
                  {(() => {
                    try {
                      const links = typeof demanda.links_referencia === 'string' 
                        ? JSON.parse(demanda.links_referencia) 
                        : demanda.links_referencia
                      return links.map((link, index) => (
                        <a
                          key={index}
                          href={link.url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="flex items-center gap-2 p-3 bg-blue-50 hover:bg-blue-100 rounded-lg transition-colors"
                        >
                          <ExternalLink className="h-4 w-4 text-blue-600" />
                          <span className="text-blue-600 hover:underline">
                            {link.titulo || link.url}
                          </span>
                        </a>
                      ))
                    } catch (e) {
                      return <p className="text-gray-500">Nenhum link disponível</p>
                    }
                  })()}
                </div>
              </div>
            )}

            {/* Card do Trello */}
            {demanda.trello_card_url && (
              <div className="space-y-2">
                <h3 className="font-semibold text-gray-900 text-lg">Card no Trello</h3>
                <a
                  href={demanda.trello_card_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 px-4 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors"
                >
                  <ExternalLink className="h-4 w-4" />
                  Ver Card no Trello
                </a>
              </div>
            )}

          </CardContent>
        </Card>

        {/* Anexos */}
        {demanda.anexos && demanda.anexos.length > 0 && (
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Download className="h-5 w-5" />
                Anexos ({demanda.anexos.length})
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {demanda.anexos.map((anexo) => (
                  <div
                    key={anexo.id}
                    className="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      <FileText className="h-8 w-8 text-gray-600" />
                      <div>
                        <p className="font-medium text-gray-900">{anexo.nome_arquivo}</p>
                        <p className="text-sm text-gray-600">
                          {(anexo.tamanho / 1024).toFixed(2)} KB
                        </p>
                      </div>
                    </div>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => window.open(anexo.url || `${import.meta.env.VITE_API_URL}/uploads/${anexo.caminho}`, '_blank')}
                    >
                      <Download className="h-4 w-4" />
                    </Button>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        )}

        {/* Ações */}
        {(demanda.status === 'aberta' || demanda.status === 'em_andamento') && (
          <Card>
            <CardHeader>
              <CardTitle>Ações</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex gap-4">
                <Button
                  variant="default"
                  onClick={handleConcluir}
                  disabled={processando}
                >
                  <CheckCircle className="h-4 w-4" />
                  Marcar como Concluída
                </Button>
                <Button
                  variant="outline"
                  onClick={handleCancelar}
                  disabled={processando}
                >
                  <XCircle className="h-4 w-4" />
                  Cancelar Demanda
                </Button>
              </div>
            </CardContent>
          </Card>
        )}

      </div>
    </div>
  )
}

export default DemandaDetalhes

