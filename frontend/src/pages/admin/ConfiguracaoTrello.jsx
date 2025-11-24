/**
 * Página de Configuração Trello
 * Gerencia credenciais, board e lista do Trello
 */
import React, { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ArrowLeft,
  Save,
  TestTube,
  Loader2,
  CheckCircle,
  XCircle,
  Settings,
  AlertTriangle,
  List,
  Trello
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
  Select,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectItem
} from '@/components/ui'
import { useAuth } from '@/hooks/useAuth'
import api from '@/services/api'
import { toast } from 'sonner'

const ConfiguracaoTrello = () => {
  const navigate = useNavigate()
  const { isMaster } = useAuth()
  
  const [loading, setLoading] = useState(true)
  const [salvando, setSalvando] = useState(false)
  const [testando, setTestando] = useState(false)
  const [configuracaoAtiva, setConfiguracaoAtiva] = useState(null)
  
  // Etapas do processo
  const [etapa, setEtapa] = useState(1) // 1: Credenciais, 2: Board, 3: Lista, 4: Confirmar
  
  const [formData, setFormData] = useState({
    api_key: '',
    token: '',
    board_id: '',
    board_nome: '',
    lista_id: '',
    lista_nome: ''
  })
  
  const [boards, setBoards] = useState([])
  const [listas, setListas] = useState([])
  const [testeResultado, setTesteResultado] = useState(null)
  
  // Verificar permissão
  useEffect(() => {
    if (!isMaster()) {
      navigate('/dashboard')
      toast.error('Acesso negado: Apenas Master pode acessar')
    }
  }, [isMaster, navigate])
  
  // Carregar configuração ativa
  useEffect(() => {
    carregarConfiguracao()
  }, [])
  
  const carregarConfiguracao = async () => {
    try {
      setLoading(true)
      const response = await api.get('/trello-config/ativa')
      
      if (response.data) {
        setConfiguracaoAtiva(response.data)
        setFormData({
          api_key: response.data.api_key || '',
          token: response.data.token || '',
          board_id: response.data.board_id || '',
          board_nome: response.data.board_nome || '',
          lista_id: response.data.lista_id || '',
          lista_nome: response.data.lista_nome || ''
        })
        setEtapa(4) // Ir direto para tela de confirmação se já existe config
      }
    } catch (error) {
      // Se não encontrar configuração ativa, não é erro
      if (error.response?.status !== 404) {
        console.error('Erro ao carregar configuração:', error)
      }
    } finally {
      setLoading(false)
    }
  }
  
  const testarConexao = async () => {
    if (!formData.api_key || !formData.token) {
      toast.error('Preencha a API Key e o Token')
      return
    }
    
    try {
      setTestando(true)
      setTesteResultado(null)
      
      const response = await api.post('/trello-config/testar', {
        api_key: formData.api_key,
        token: formData.token
      })
      
      if (response.data.sucesso) {
        setTesteResultado({ sucesso: true, mensagem: response.data.mensagem })
        
        if (response.data.boards) {
          setBoards(response.data.boards)
          setEtapa(2) // Avançar para seleção de board
          toast.success('Conexão estabelecida! Selecione um board')
        }
      }
    } catch (error) {
      setTesteResultado({
        sucesso: false,
        mensagem: error.response?.data?.detail || 'Erro ao testar conexão'
      })
      toast.error('Falha na conexão com Trello')
    } finally {
      setTestando(false)
    }
  }
  
  const selecionarBoard = async (boardId) => {
    const board = boards.find(b => b.id === boardId)
    
    setFormData(prev => ({
      ...prev,
      board_id: boardId,
      board_nome: board?.nome || ''
    }))
    
    try {
      setLoading(true)
      
      // Buscar listas do board
      const response = await api.get(`/trello-config/boards/${boardId}/listas`)
      
      if (response.data.listas) {
        setListas(response.data.listas)
        setEtapa(3) // Avançar para seleção de lista
        toast.success(`Board "${response.data.board_nome}" selecionado`)
      }
    } catch (error) {
      toast.error('Erro ao buscar listas do board')
      console.error('Erro ao buscar listas:', error)
    } finally {
      setLoading(false)
    }
  }
  
  const selecionarLista = (listaId) => {
    const lista = listas.find(l => l.id === listaId)
    
    setFormData(prev => ({
      ...prev,
      lista_id: listaId,
      lista_nome: lista?.nome || ''
    }))
    
    setEtapa(4) // Avançar para confirmação
  }
  
  const salvarConfiguracao = async () => {
    if (!formData.api_key || !formData.token || !formData.board_id || !formData.lista_id) {
      toast.error('Preencha todos os campos obrigatórios')
      return
    }
    
    try {
      setSalvando(true)
      
      await api.post('/trello-config/', formData)
      
      toast.success('Configuração salva com sucesso!')
      await carregarConfiguracao()
      
    } catch (error) {
      toast.error(error.response?.data?.detail || 'Erro ao salvar configuração')
      console.error('Erro ao salvar:', error)
    } finally {
      setSalvando(false)
    }
  }
  
  const reiniciarConfiguracao = () => {
    setFormData({
      api_key: '',
      token: '',
      board_id: '',
      board_nome: '',
      lista_id: '',
      lista_nome: ''
    })
    setBoards([])
    setListas([])
    setTesteResultado(null)
    setEtapa(1)
  }
  
  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="h-8 w-8 animate-spin text-blue-600" />
          <p className="text-gray-600">Carregando configuração...</p>
        </div>
      </div>
    )
  }
  
  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="mb-6">
          <Button
            variant="ghost"
            onClick={() => navigate('/configuracoes')}
            className="mb-4"
          >
            <ArrowLeft className="h-4 w-4 mr-2" />
            Voltar para Configurações
          </Button>
          
          <div className="flex items-center gap-3">
            <div className="p-3 bg-blue-600 text-white rounded-lg">
              <Trello className="h-6 w-6" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">
                Configuração do Trello
              </h1>
              <p className="text-gray-600">
                Configure a integração com o Trello para criação automática de cards
              </p>
            </div>
          </div>
        </div>
        
        {/* Indicador de Etapas */}
        <Card className="mb-6">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              {[
                { num: 1, label: 'Credenciais' },
                { num: 2, label: 'Board' },
                { num: 3, label: 'Lista' },
                { num: 4, label: 'Confirmar' }
              ].map((step, index) => (
                <React.Fragment key={step.num}>
                  <div className="flex flex-col items-center">
                    <div className={`
                      w-10 h-10 rounded-full flex items-center justify-center font-bold
                      ${etapa >= step.num ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-500'}
                    `}>
                      {etapa > step.num ? <CheckCircle className="h-5 w-5" /> : step.num}
                    </div>
                    <span className={`text-sm mt-2 ${etapa >= step.num ? 'text-blue-600 font-medium' : 'text-gray-500'}`}>
                      {step.label}
                    </span>
                  </div>
                  {index < 3 && (
                    <div className={`flex-1 h-1 mx-2 ${etapa > step.num ? 'bg-blue-600' : 'bg-gray-200'}`} />
                  )}
                </React.Fragment>
              ))}
            </div>
          </CardContent>
        </Card>
        
        {/* Configuração Ativa */}
        {configuracaoAtiva && etapa === 4 && (
          <Alert className="mb-6 bg-blue-50 border-blue-200">
            <CheckCircle className="h-4 w-4 text-blue-600" />
            <AlertTitle className="text-blue-900">Configuração Ativa</AlertTitle>
            <AlertDescription className="text-blue-800">
              <strong>Board:</strong> {configuracaoAtiva.board_nome}<br />
              <strong>Lista:</strong> {configuracaoAtiva.lista_nome}
            </AlertDescription>
          </Alert>
        )}
        
        {/* ETAPA 1: Credenciais */}
        {etapa === 1 && (
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Settings className="h-5 w-5" />
                1. Credenciais do Trello
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <Alert>
                <AlertTriangle className="h-4 w-4" />
                <AlertTitle>Como obter as credenciais</AlertTitle>
                <AlertDescription>
                  1. Acesse: <a href="https://trello.com/app-key" target="_blank" rel="noopener noreferrer" className="text-blue-600 underline">https://trello.com/app-key</a><br />
                  2. Copie a <strong>API Key</strong><br />
                  3. Clique em <strong>Token</strong> e autorize o aplicativo<br />
                  4. Copie o <strong>Token</strong> gerado
                </AlertDescription>
              </Alert>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  API Key *
                </label>
                <Input
                  type="text"
                  placeholder="Cole aqui sua API Key do Trello"
                  value={formData.api_key}
                  onChange={(e) => setFormData(prev => ({ ...prev, api_key: e.target.value }))}
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Token *
                </label>
                <Input
                  type="password"
                  placeholder="Cole aqui seu Token do Trello"
                  value={formData.token}
                  onChange={(e) => setFormData(prev => ({ ...prev, token: e.target.value }))}
                />
              </div>
              
              {testeResultado && (
                <Alert className={testeResultado.sucesso ? 'bg-green-50 border-green-200' : 'bg-red-50 border-red-200'}>
                  {testeResultado.sucesso ? (
                    <CheckCircle className="h-4 w-4 text-green-600" />
                  ) : (
                    <XCircle className="h-4 w-4 text-red-600" />
                  )}
                  <AlertDescription className={testeResultado.sucesso ? 'text-green-800' : 'text-red-800'}>
                    {testeResultado.mensagem}
                  </AlertDescription>
                </Alert>
              )}
              
              <div className="flex gap-3">
                <Button
                  onClick={testarConexao}
                  disabled={testando || !formData.api_key || !formData.token}
                  className="flex-1"
                >
                  {testando ? (
                    <>
                      <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                      Testando Conexão...
                    </>
                  ) : (
                    <>
                      <TestTube className="h-4 w-4 mr-2" />
                      Testar Conexão
                    </>
                  )}
                </Button>
              </div>
            </CardContent>
          </Card>
        )}
        
        {/* ETAPA 2: Seleção de Board */}
        {etapa === 2 && (
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Trello className="h-5 w-5" />
                2. Selecionar Board
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-sm text-gray-600">
                Selecione o board do Trello onde as demandas serão criadas:
              </p>
              
              <div className="space-y-2">
                {boards.map((board) => (
                  <button
                    key={board.id}
                    onClick={() => selecionarBoard(board.id)}
                    className="w-full p-4 text-left border rounded-lg hover:border-blue-500 hover:bg-blue-50 transition-colors"
                  >
                    <div className="font-medium text-gray-900">{board.nome}</div>
                    <div className="text-sm text-gray-500 mt-1">ID: {board.id}</div>
                  </button>
                ))}
              </div>
              
              <Button
                variant="outline"
                onClick={() => setEtapa(1)}
                className="w-full"
              >
                <ArrowLeft className="h-4 w-4 mr-2" />
                Voltar para Credenciais
              </Button>
            </CardContent>
          </Card>
        )}
        
        {/* ETAPA 3: Seleção de Lista */}
        {etapa === 3 && (
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <List className="h-5 w-5" />
                3. Selecionar Lista
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <Alert>
                <AlertTriangle className="h-4 w-4" />
                <AlertDescription>
                  <strong>Board selecionado:</strong> {formData.board_nome}
                </AlertDescription>
              </Alert>
              
              <p className="text-sm text-gray-600">
                Selecione a lista onde os cards serão criados:
              </p>
              
              <div className="space-y-2">
                {listas.map((lista) => (
                  <button
                    key={lista.id}
                    onClick={() => selecionarLista(lista.id)}
                    className="w-full p-4 text-left border rounded-lg hover:border-blue-500 hover:bg-blue-50 transition-colors"
                  >
                    <div className="font-medium text-gray-900">{lista.nome}</div>
                    <div className="text-sm text-gray-500 mt-1">ID: {lista.id}</div>
                  </button>
                ))}
              </div>
              
              <Button
                variant="outline"
                onClick={() => setEtapa(2)}
                className="w-full"
              >
                <ArrowLeft className="h-4 w-4 mr-2" />
                Voltar para Boards
              </Button>
            </CardContent>
          </Card>
        )}
        
        {/* ETAPA 4: Confirmação e Salvamento */}
        {etapa === 4 && (
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <CheckCircle className="h-5 w-5" />
                4. Confirmar Configuração
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <Alert>
                <AlertTriangle className="h-4 w-4" />
                <AlertDescription>
                  Revise as informações antes de salvar
                </AlertDescription>
              </Alert>
              
              <div className="bg-gray-50 p-4 rounded-lg space-y-3">
                <div>
                  <div className="text-sm font-medium text-gray-500">API Key</div>
                  <div className="text-gray-900 font-mono text-sm">
                    {formData.api_key ? `${formData.api_key.substring(0, 8)}...` : '-'}
                  </div>
                </div>
                
                <div>
                  <div className="text-sm font-medium text-gray-500">Token</div>
                  <div className="text-gray-900 font-mono text-sm">
                    {formData.token ? `${formData.token.substring(0, 12)}...` : '-'}
                  </div>
                </div>
                
                <div>
                  <div className="text-sm font-medium text-gray-500">Board</div>
                  <div className="text-gray-900">{formData.board_nome || '-'}</div>
                </div>
                
                <div>
                  <div className="text-sm font-medium text-gray-500">Lista</div>
                  <div className="text-gray-900">{formData.lista_nome || '-'}</div>
                </div>
              </div>
              
              <div className="flex gap-3">
                <Button
                  variant="outline"
                  onClick={reiniciarConfiguracao}
                  className="flex-1"
                >
                  Reconfigurar
                </Button>
                
                <Button
                  onClick={salvarConfiguracao}
                  disabled={salvando}
                  className="flex-1"
                >
                  {salvando ? (
                    <>
                      <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                      Salvando...
                    </>
                  ) : (
                    <>
                      <Save className="h-4 w-4 mr-2" />
                      Salvar Configuração
                    </>
                  )}
                </Button>
              </div>
            </CardContent>
          </Card>
        )}
        
        {/* Link para Etiquetas */}
        {configuracaoAtiva && (
          <Card className="mt-6">
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-semibold text-gray-900">Próximo passo</h3>
                  <p className="text-sm text-gray-600">
                    Configure as etiquetas do Trello por cliente
                  </p>
                </div>
                <Button onClick={() => navigate('/admin/trello-etiquetas')}>
                  Gerenciar Etiquetas
                </Button>
              </div>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  )
}

export default ConfiguracaoTrello

