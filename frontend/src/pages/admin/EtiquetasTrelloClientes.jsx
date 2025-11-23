/**
 * Página de Gerenciamento de Etiquetas Trello por Cliente
 * Vincula etiquetas do Trello aos clientes do sistema
 */
import React, { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ArrowLeft,
  Plus,
  Edit,
  Trash2,
  Loader2,
  Tag,
  CheckCircle,
  XCircle,
  AlertTriangle
} from 'lucide-react'
import {
  Button,
  Card,
  CardHeader,
  CardTitle,
  CardContent,
  Input,
  Alert,
  AlertTitle,
  AlertDescription,
  Badge,
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  Select,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectItem,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow
} from '@/components/ui'
import { useAuth } from '@/hooks/useAuth'
import api from '@/services/api'
import { toast } from 'sonner'

const EtiquetasTrelloClientes = () => {
  const navigate = useNavigate()
  const { isMaster } = useAuth()
  
  const [loading, setLoading] = useState(true)
  const [etiquetas, setEtiquetas] = useState([])
  const [clientes, setClientes] = useState([])
  const [etiquetasDisponiveis, setEtiquetasDisponiveis] = useState([])
  const [configuracaoAtiva, setConfiguracaoAtiva] = useState(null)
  
  // Modal de vincular/editar etiqueta
  const [modalAberto, setModalAberto] = useState(false)
  const [salvando, setSalvando] = useState(false)
  const [etiquetaAtual, setEtiquetaAtual] = useState({
    cliente_id: '',
    etiqueta_trello_id: '',
    etiqueta_nome: '',
    etiqueta_cor: ''
  })
  const [modoEdicao, setModoEdicao] = useState(false)
  
  // Verificar permissão
  useEffect(() => {
    if (!isMaster()) {
      navigate('/dashboard')
      toast.error('Acesso negado: Apenas Master pode acessar')
    }
  }, [isMaster, navigate])
  
  // Carregar dados
  useEffect(() => {
    carregarDados()
  }, [])
  
  const carregarDados = async () => {
    try {
      setLoading(true)
      
      // Carregar configuração ativa
      const configResponse = await api.get('/trello-config/ativa')
      setConfiguracaoAtiva(configResponse.data)
      
      // Carregar etiquetas vinculadas
      const etiquetasResponse = await api.get('/trello-etiquetas/')
      setEtiquetas(etiquetasResponse.data)
      
      // Carregar clientes
      const clientesResponse = await api.get('/clientes/')
      setClientes(clientesResponse.data)
      
      // Carregar etiquetas disponíveis no Trello
      if (configResponse.data) {
        const etiquetasTrelloResponse = await api.get(
          `/trello-config/boards/${configResponse.data.board_id}/etiquetas`
        )
        setEtiquetasDisponiveis(etiquetasTrelloResponse.data.etiquetas)
      }
      
    } catch (error) {
      if (error.response?.status === 404) {
        toast.error('Configure o Trello primeiro!')
        navigate('/admin/trello-config')
      } else {
        toast.error('Erro ao carregar dados')
        console.error('Erro ao carregar:', error)
      }
    } finally {
      setLoading(false)
    }
  }
  
  const abrirModalNovo = () => {
    setEtiquetaAtual({
      cliente_id: '',
      etiqueta_trello_id: '',
      etiqueta_nome: '',
      etiqueta_cor: ''
    })
    setModoEdicao(false)
    setModalAberto(true)
  }
  
  const abrirModalEditar = (etiqueta) => {
    setEtiquetaAtual({
      id: etiqueta.id,
      cliente_id: etiqueta.cliente_id,
      etiqueta_trello_id: etiqueta.etiqueta_trello_id,
      etiqueta_nome: etiqueta.etiqueta_nome,
      etiqueta_cor: etiqueta.etiqueta_cor
    })
    setModoEdicao(true)
    setModalAberto(true)
  }
  
  const fecharModal = () => {
    setModalAberto(false)
    setEtiquetaAtual({
      cliente_id: '',
      etiqueta_trello_id: '',
      etiqueta_nome: '',
      etiqueta_cor: ''
    })
    setModoEdicao(false)
  }
  
  const selecionarEtiquetaTrello = (etiquetaId) => {
    const etiqueta = etiquetasDisponiveis.find(e => e.id === etiquetaId)
    if (etiqueta) {
      setEtiquetaAtual(prev => ({
        ...prev,
        etiqueta_trello_id: etiqueta.id,
        etiqueta_nome: etiqueta.nome,
        etiqueta_cor: etiqueta.cor
      }))
    }
  }
  
  const salvarEtiqueta = async () => {
    if (!etiquetaAtual.cliente_id || !etiquetaAtual.etiqueta_trello_id) {
      toast.error('Selecione um cliente e uma etiqueta')
      return
    }
    
    try {
      setSalvando(true)
      
      await api.post('/trello-etiquetas/', {
        cliente_id: etiquetaAtual.cliente_id,
        etiqueta_trello_id: etiquetaAtual.etiqueta_trello_id,
        etiqueta_nome: etiquetaAtual.etiqueta_nome,
        etiqueta_cor: etiquetaAtual.etiqueta_cor
      })
      
      toast.success(modoEdicao ? 'Etiqueta atualizada!' : 'Etiqueta vinculada com sucesso!')
      fecharModal()
      carregarDados()
      
    } catch (error) {
      toast.error(error.response?.data?.detail || 'Erro ao salvar etiqueta')
      console.error('Erro ao salvar:', error)
    } finally {
      setSalvando(false)
    }
  }
  
  const deletarEtiqueta = async (etiquetaId, clienteNome) => {
    if (!window.confirm(`Deseja realmente remover a etiqueta do cliente "${clienteNome}"?`)) {
      return
    }
    
    try {
      await api.delete(`/trello-etiquetas/${etiquetaId}`)
      toast.success('Etiqueta removida com sucesso!')
      carregarDados()
    } catch (error) {
      toast.error('Erro ao remover etiqueta')
      console.error('Erro ao deletar:', error)
    }
  }
  
  const getCorClasse = (cor) => {
    const cores = {
      green: 'bg-green-500',
      yellow: 'bg-yellow-500',
      orange: 'bg-orange-500',
      red: 'bg-red-500',
      purple: 'bg-purple-500',
      blue: 'bg-blue-500',
      sky: 'bg-sky-500',
      lime: 'bg-lime-500',
      pink: 'bg-pink-500',
      black: 'bg-gray-800'
    }
    return cores[cor] || 'bg-gray-400'
  }
  
  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="h-8 w-8 animate-spin text-blue-600" />
          <p className="text-gray-600">Carregando etiquetas...</p>
        </div>
      </div>
    )
  }
  
  if (!configuracaoAtiva) {
    return (
      <div className="min-h-screen bg-gray-50 p-6">
        <div className="max-w-4xl mx-auto">
          <Alert className="bg-yellow-50 border-yellow-200">
            <AlertTriangle className="h-4 w-4 text-yellow-600" />
            <AlertTitle className="text-yellow-900">Trello não configurado</AlertTitle>
            <AlertDescription className="text-yellow-800">
              Configure o Trello primeiro antes de gerenciar etiquetas.
            </AlertDescription>
          </Alert>
          <Button
            onClick={() => navigate('/admin/trello-config')}
            className="mt-4"
          >
            Ir para Configuração do Trello
          </Button>
        </div>
      </div>
    )
  }
  
  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="mb-6">
          <Button
            variant="ghost"
            onClick={() => navigate('/admin/trello-config')}
            className="mb-4"
          >
            <ArrowLeft className="h-4 w-4 mr-2" />
            Voltar para Configuração Trello
          </Button>
          
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="p-3 bg-purple-600 text-white rounded-lg">
                <Tag className="h-6 w-6" />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-gray-900">
                  Etiquetas Trello por Cliente
                </h1>
                <p className="text-gray-600">
                  Vincule etiquetas do Trello aos clientes para organização automática
                </p>
              </div>
            </div>
            
            <Button onClick={abrirModalNovo}>
              <Plus className="h-4 w-4 mr-2" />
              Nova Etiqueta
            </Button>
          </div>
        </div>
        
        {/* Info da configuração ativa */}
        <Alert className="mb-6 bg-blue-50 border-blue-200">
          <CheckCircle className="h-4 w-4 text-blue-600" />
          <AlertDescription className="text-blue-800">
            <strong>Board:</strong> {configuracaoAtiva.board_nome} | <strong>Lista:</strong> {configuracaoAtiva.lista_nome}
          </AlertDescription>
        </Alert>
        
        {/* Tabela de Etiquetas */}
        <Card>
          <CardHeader>
            <CardTitle>Etiquetas Configuradas</CardTitle>
          </CardHeader>
          <CardContent>
            {etiquetas.length === 0 ? (
              <div className="text-center py-12">
                <Tag className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  Nenhuma etiqueta configurada
                </h3>
                <p className="text-gray-600 mb-4">
                  Vincule etiquetas do Trello aos seus clientes
                </p>
                <Button onClick={abrirModalNovo}>
                  <Plus className="h-4 w-4 mr-2" />
                  Adicionar Primeira Etiqueta
                </Button>
              </div>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Cliente</TableHead>
                    <TableHead>Etiqueta</TableHead>
                    <TableHead>Cor</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead className="text-right">Ações</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {etiquetas.map((etiqueta) => (
                    <TableRow key={etiqueta.id}>
                      <TableCell className="font-medium">
                        {etiqueta.cliente_nome}
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <div className={`w-4 h-4 rounded ${getCorClasse(etiqueta.etiqueta_cor)}`} />
                          {etiqueta.etiqueta_nome}
                        </div>
                      </TableCell>
                      <TableCell>
                        <code className="text-xs bg-gray-100 px-2 py-1 rounded">
                          {etiqueta.etiqueta_cor}
                        </code>
                      </TableCell>
                      <TableCell>
                        {etiqueta.ativo ? (
                          <Badge variant="success">Ativo</Badge>
                        ) : (
                          <Badge variant="secondary">Inativo</Badge>
                        )}
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex items-center justify-end gap-2">
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => abrirModalEditar(etiqueta)}
                          >
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => deletarEtiqueta(etiqueta.id, etiqueta.cliente_nome)}
                            className="text-red-600 hover:text-red-700 hover:bg-red-50"
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>
      </div>
      
      {/* Modal de Vincular/Editar Etiqueta */}
      <Dialog open={modalAberto} onOpenChange={setModalAberto}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {modoEdicao ? 'Editar Etiqueta' : 'Vincular Etiqueta a Cliente'}
            </DialogTitle>
          </DialogHeader>
          
          <div className="space-y-4 py-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Cliente *
              </label>
              <Select
                value={etiquetaAtual.cliente_id}
                onValueChange={(value) => setEtiquetaAtual(prev => ({ ...prev, cliente_id: value }))}
                disabled={modoEdicao}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Selecione um cliente" />
                </SelectTrigger>
                <SelectContent>
                  {clientes.map((cliente) => (
                    <SelectItem key={cliente.id} value={cliente.id}>
                      {cliente.nome}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Etiqueta do Trello *
              </label>
              <Select
                value={etiquetaAtual.etiqueta_trello_id}
                onValueChange={selecionarEtiquetaTrello}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Selecione uma etiqueta" />
                </SelectTrigger>
                <SelectContent>
                  {etiquetasDisponiveis.map((etiqueta) => (
                    <SelectItem key={etiqueta.id} value={etiqueta.id}>
                      <div className="flex items-center gap-2">
                        <div className={`w-4 h-4 rounded ${getCorClasse(etiqueta.cor)}`} />
                        {etiqueta.nome || `Etiqueta ${etiqueta.cor}`}
                      </div>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            
            {etiquetaAtual.etiqueta_trello_id && (
              <Alert>
                <CheckCircle className="h-4 w-4" />
                <AlertDescription>
                  <div className="flex items-center gap-2">
                    <div className={`w-4 h-4 rounded ${getCorClasse(etiquetaAtual.etiqueta_cor)}`} />
                    <strong>{etiquetaAtual.etiqueta_nome}</strong>
                    <span className="text-gray-500">({etiquetaAtual.etiqueta_cor})</span>
                  </div>
                </AlertDescription>
              </Alert>
            )}
          </div>
          
          <DialogFooter>
            <Button variant="outline" onClick={fecharModal}>
              Cancelar
            </Button>
            <Button
              onClick={salvarEtiqueta}
              disabled={salvando || !etiquetaAtual.cliente_id || !etiquetaAtual.etiqueta_trello_id}
            >
              {salvando ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Salvando...
                </>
              ) : (
                <>
                  <CheckCircle className="h-4 w-4 mr-2" />
                  {modoEdicao ? 'Atualizar' : 'Vincular'}
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}

export default EtiquetasTrelloClientes

