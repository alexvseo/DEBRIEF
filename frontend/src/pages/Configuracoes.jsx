import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ArrowLeft,
  Save,
  TestTube,
  Eye,
  EyeOff,
  CheckCircle,
  XCircle,
  Loader2,
  Settings,
  MessageSquare,
  Trello,
  RefreshCw,
  Building2,
  Briefcase,
  Tag,
  Plus,
  Edit,
  Trash2,
  ToggleLeft,
  ToggleRight,
  Users,
  Palette
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
  DialogBody,
  DialogFooter
} from '@/components/ui'
import { useAuth } from '@/hooks/useAuth'
import api from '@/services/api'

const Configuracoes = () => {
  const navigate = useNavigate()
  const { user, isMaster } = useAuth()
  
  const [loading, setLoading] = useState(true)
  const [salvando, setSalvando] = useState(false)
  const [testando, setTestando] = useState({})
  const [showPasswords, setShowPasswords] = useState({})
  const [configs, setConfigs] = useState({
    trello: [],
    whatsapp: [],
    sistema: []
  })
  const [valores, setValores] = useState({})
  const [testResult, setTestResult] = useState({})
  const [successMessage, setSuccessMessage] = useState('')
  
  // Estados para gerenciamento
  const [clientes, setClientes] = useState([])
  const [secretarias, setSecretarias] = useState([])
  const [tiposDemanda, setTiposDemanda] = useState([])
  const [prioridades, setPrioridades] = useState([])
  
  // Estados para modals
  const [modalCliente, setModalCliente] = useState({ open: false, item: null })
  const [modalSecretaria, setModalSecretaria] = useState({ open: false, item: null })
  const [modalTipo, setModalTipo] = useState({ open: false, item: null })
  const [modalPrioridade, setModalPrioridade] = useState({ open: false, item: null })
  
  // Verificar permissão
  useEffect(() => {
    if (!isMaster()) {
      navigate('/dashboard')
    }
  }, [isMaster, navigate])
  
  // Carregar todos os dados
  useEffect(() => {
    carregarTodosDados()
  }, [])
  
  const carregarTodosDados = async () => {
    try {
      setLoading(true)
      await Promise.all([
        carregarConfiguracoes(),
        carregarClientes(),
        carregarSecretarias(),
        carregarTiposDemanda(),
        carregarPrioridades()
      ])
    } catch (error) {
      console.error('Erro ao carregar dados:', error)
    } finally {
      setLoading(false)
    }
  }
  
  const carregarConfiguracoes = async () => {
    try {
      const response = await api.get('/api/configuracoes/agrupadas')
      
      const configsFormatadas = {
        trello: [],
        whatsapp: [],
        sistema: []
      }
      
      const valoresIniciais = {}
      
      response.data.forEach(grupo => {
        const tipo = grupo.tipo
        configsFormatadas[tipo] = grupo.configuracoes
        
        grupo.configuracoes.forEach(config => {
          valoresIniciais[config.chave] = config.valor || ''
        })
      })
      
      setConfigs(configsFormatadas)
      setValores(valoresIniciais)
    } catch (error) {
      console.error('Erro ao carregar configurações:', error)
    }
  }
  
  const carregarClientes = async () => {
    try {
      const response = await api.get('/clientes/')
      setClientes(response.data)
    } catch (error) {
      console.error('Erro ao carregar clientes:', error)
    }
  }
  
  const carregarSecretarias = async () => {
    try {
      const response = await api.get('/secretarias/')
      setSecretarias(response.data)
    } catch (error) {
      console.error('Erro ao carregar secretarias:', error)
    }
  }
  
  const carregarTiposDemanda = async () => {
    try {
      const response = await api.get('/tipos-demanda/')
      setTiposDemanda(response.data)
    } catch (error) {
      console.error('Erro ao carregar tipos:', error)
    }
  }
  
  const carregarPrioridades = async () => {
    try {
      const response = await api.get('/prioridades/')
      setPrioridades(response.data)
    } catch (error) {
      console.error('Erro ao carregar prioridades:', error)
    }
  }
  
  const handleChange = (chave, valor) => {
    setValores(prev => ({
      ...prev,
      [chave]: valor
    }))
  }
  
  const toggleShowPassword = (chave) => {
    setShowPasswords(prev => ({
      ...prev,
      [chave]: !prev[chave]
    }))
  }
  
  const salvarConfiguracao = async (config) => {
    try {
      setSalvando(true)
      
      await api.put(`/api/configuracoes/${config.id}`, {
        valor: valores[config.chave],
        is_sensivel: config.is_sensivel
      })
      
      setSuccessMessage(`✅ ${config.descricao} salva com sucesso!`)
      setTimeout(() => setSuccessMessage(''), 3000)
      
      await carregarConfiguracoes()
    } catch (error) {
      console.error('Erro ao salvar:', error)
      alert('Erro ao salvar configuração')
    } finally {
      setSalvando(false)
    }
  }
  
  const testarTrello = async () => {
    try {
      setTestando(prev => ({ ...prev, trello: true }))
      setTestResult(prev => ({ ...prev, trello: null }))
      
      const response = await api.post('/api/configuracoes/testar/trello', {
        api_key: valores.trello_api_key,
        token: valores.trello_token,
        board_id: valores.trello_board_id || null
      })
      
      setTestResult(prev => ({ ...prev, trello: response.data }))
    } catch (error) {
      console.error('Erro ao testar Trello:', error)
      setTestResult(prev => ({
        ...prev,
        trello: {
          sucesso: false,
          mensagem: 'Erro ao testar conexão',
          detalhes: { erro: error.message }
        }
      }))
    } finally {
      setTestando(prev => ({ ...prev, trello: false }))
    }
  }
  
  const testarWhatsApp = async () => {
    try {
      setTestando(prev => ({ ...prev, whatsapp: true }))
      setTestResult(prev => ({ ...prev, whatsapp: null }))
      
      const response = await api.post('/api/configuracoes/testar/whatsapp', {
        url: valores.wpp_url,
        instance: valores.wpp_instance,
        token: valores.wpp_token
      })
      
      setTestResult(prev => ({ ...prev, whatsapp: response.data }))
    } catch (error) {
      console.error('Erro ao testar WhatsApp:', error)
      setTestResult(prev => ({
        ...prev,
        whatsapp: {
          sucesso: false,
          mensagem: 'Erro ao testar conexão',
          detalhes: { erro: error.message }
        }
      }))
    } finally {
      setTestando(prev => ({ ...prev, whatsapp: false }))
    }
  }
  
  // ==================== FUNÇÕES DE GERENCIAMENTO ====================
  
  // CLIENTES
  const salvarCliente = async (dados) => {
    try {
      // Limpar campos vazios (enviar null em vez de string vazia)
      const dadosLimpos = {
        nome: dados.nome.trim(),
        whatsapp_group_id: dados.whatsapp_group_id?.trim() || null,
        trello_member_id: dados.trello_member_id?.trim() || null,
        ativo: dados.ativo !== undefined ? dados.ativo : true
      }
      
      if (modalCliente.item) {
        await api.put(`/clientes/${modalCliente.item.id}`, dadosLimpos)
        setSuccessMessage('✅ Cliente atualizado com sucesso!')
      } else {
        // Criar novo cliente
        const response = await api.post('/clientes/', dadosLimpos)
        setSuccessMessage('✅ Cliente criado com sucesso!')
      }
      
      setModalCliente({ open: false, item: null })
      await carregarClientes()
      setTimeout(() => setSuccessMessage(''), 3000)
    } catch (error) {
      console.error('Erro ao salvar cliente:', error)
      console.error('Dados enviados:', dados)
      console.error('Resposta do servidor:', error.response?.data)
      
      // Extrair mensagem de erro detalhada
      let errorMessage = 'Erro ao salvar cliente'
      
      if (error.response?.data) {
        // Se for array de erros de validação (422)
        if (Array.isArray(error.response.data.detail)) {
          const errors = error.response.data.detail.map(err => {
            const field = err.loc?.join('.') || 'campo'
            return `${field}: ${err.msg}`
          }).join('\n')
          errorMessage = `Erros de validação:\n${errors}`
        } else {
          // Mensagem única
          errorMessage = error.response.data.detail || error.response.data.message || errorMessage
        }
      } else if (error.message) {
        errorMessage = error.message
      }
      
      alert(`Erro ao salvar cliente:\n\n${errorMessage}\n\nVerifique o console para mais detalhes.`)
    }
  }
  
  const toggleCliente = async (cliente) => {
    try {
      if (cliente.ativo) {
        await api.delete(`/clientes/${cliente.id}`)
        setSuccessMessage('✅ Cliente desativado com sucesso!')
      } else {
        await api.post(`/clientes/${cliente.id}/reativar`)
        setSuccessMessage('✅ Cliente reativado com sucesso!')
      }
      await carregarClientes()
      setTimeout(() => setSuccessMessage(''), 3000)
    } catch (error) {
      console.error('Erro ao alterar status:', error)
      alert('Erro ao alterar status do cliente')
    }
  }
  
  // SECRETARIAS
  const salvarSecretaria = async (dados) => {
    try {
      // Validar que cliente_id foi selecionado
      if (!dados.cliente_id || dados.cliente_id.trim() === '') {
        alert('Por favor, selecione um cliente')
        return
      }

      // Limpar dados antes de enviar
      const dadosLimpos = {
        nome: dados.nome.trim(),
        cliente_id: dados.cliente_id.trim(),
        ativo: dados.ativo !== undefined ? dados.ativo : true
      }

      if (modalSecretaria.item) {
        await api.put(`/secretarias/${modalSecretaria.item.id}`, dadosLimpos)
        setSuccessMessage('✅ Secretaria atualizada com sucesso!')
      } else {
        await api.post('/secretarias/', dadosLimpos)
        setSuccessMessage('✅ Secretaria criada com sucesso!')
      }
      
      setModalSecretaria({ open: false, item: null })
      await carregarSecretarias()
      setTimeout(() => setSuccessMessage(''), 3000)
    } catch (error) {
      console.error('Erro ao salvar secretaria:', error)
      console.error('Dados enviados:', dados)
      console.error('Resposta do servidor:', error.response?.data)
      
      // Extrair mensagem de erro detalhada
      let errorMessage = 'Erro ao salvar secretaria'
      
      if (error.response?.data) {
        // Se for array de erros de validação (422)
        if (Array.isArray(error.response.data.detail)) {
          const errors = error.response.data.detail.map(err => {
            const field = err.loc?.join('.') || 'campo'
            return `${field}: ${err.msg}`
          }).join('\n')
          errorMessage = `Erros de validação:\n${errors}`
        } else {
          // Mensagem única
          errorMessage = error.response.data.detail || error.response.data.message || errorMessage
        }
      } else if (error.message) {
        errorMessage = error.message
      }
      
      alert(`Erro ao salvar secretaria:\n\n${errorMessage}\n\nVerifique o console para mais detalhes.`)
    }
  }
  
  const toggleSecretaria = async (secretaria) => {
    try {
      if (secretaria.ativo) {
        await api.delete(`/secretarias/${secretaria.id}`)
        setSuccessMessage('✅ Secretaria desativada com sucesso!')
      } else {
        await api.post(`/secretarias/${secretaria.id}/reativar`)
        setSuccessMessage('✅ Secretaria reativada com sucesso!')
      }
      await carregarSecretarias()
      setTimeout(() => setSuccessMessage(''), 3000)
    } catch (error) {
      console.error('Erro ao alterar status:', error)
      alert('Erro ao alterar status da secretaria')
    }
  }
  
  // TIPOS DE DEMANDA
  const salvarTipoDemanda = async (dados) => {
    try {
      if (modalTipo.item) {
        await api.put(`/tipos-demanda/${modalTipo.item.id}`, dados)
        setSuccessMessage('✅ Tipo de demanda atualizado com sucesso!')
      } else {
        await api.post('/tipos-demanda/', dados)
        setSuccessMessage('✅ Tipo de demanda criado com sucesso!')
      }
      
      setModalTipo({ open: false, item: null })
      await carregarTiposDemanda()
      setTimeout(() => setSuccessMessage(''), 3000)
    } catch (error) {
      console.error('Erro ao salvar tipo:', error)
      alert('Erro ao salvar tipo de demanda')
    }
  }
  
  const toggleTipoDemanda = async (tipo) => {
    try {
      if (tipo.ativo) {
        await api.delete(`/tipos-demanda/${tipo.id}`)
        setSuccessMessage('✅ Tipo desativado com sucesso!')
      } else {
        await api.post(`/tipos-demanda/${tipo.id}/reativar`)
        setSuccessMessage('✅ Tipo reativado com sucesso!')
      }
      await carregarTiposDemanda()
      setTimeout(() => setSuccessMessage(''), 3000)
    } catch (error) {
      console.error('Erro ao alterar status:', error)
      alert('Erro ao alterar status do tipo')
    }
  }
  
  // PRIORIDADES
  const salvarPrioridade = async (dados) => {
    try {
      if (modalPrioridade.item) {
        await api.put(`/prioridades/${modalPrioridade.item.id}`, dados)
        setSuccessMessage('✅ Prioridade atualizada com sucesso!')
      } else {
        await api.post('/prioridades/', dados)
        setSuccessMessage('✅ Prioridade criada com sucesso!')
      }
      
      setModalPrioridade({ open: false, item: null })
      await carregarPrioridades()
      setTimeout(() => setSuccessMessage(''), 3000)
    } catch (error) {
      console.error('Erro ao salvar prioridade:', error)
      alert('Erro ao salvar prioridade')
    }
  }
  
  const togglePrioridade = async (prioridade) => {
    try {
      if (prioridade.ativo) {
        await api.delete(`/prioridades/${prioridade.id}`)
        setSuccessMessage('✅ Prioridade desativada com sucesso!')
      } else {
        await api.post(`/prioridades/${prioridade.id}/reativar`)
        setSuccessMessage('✅ Prioridade reativada com sucesso!')
      }
      await carregarPrioridades()
      setTimeout(() => setSuccessMessage(''), 3000)
    } catch (error) {
      console.error('Erro ao alterar status:', error)
      alert('Erro ao alterar status da prioridade')
    }
  }
  
  const renderConfiguracao = (config) => {
    const valor = valores[config.chave] || ''
    const mostrar = showPasswords[config.chave]
    
    return (
      <div key={config.id} className="space-y-2">
        <div className="flex items-center justify-between">
          <label className="text-sm font-medium text-gray-700">
            {config.descricao}
            {config.is_sensivel && (
              <Badge variant="secondary" className="ml-2">🔒 Sensível</Badge>
            )}
          </label>
        </div>
        
        <div className="flex gap-2">
          <div className="relative flex-1">
            <Input
              type={config.is_sensivel && !mostrar ? 'password' : 'text'}
              value={valor}
              onChange={(e) => handleChange(config.chave, e.target.value)}
              placeholder={config.is_sensivel ? '••••••••' : 'Valor da configuração'}
              className={config.is_sensivel ? 'pr-10' : ''}
            />
            
            {config.is_sensivel && (
              <button
                type="button"
                onClick={() => toggleShowPassword(config.chave)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                {mostrar ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
              </button>
            )}
          </div>
          
          <Button
            onClick={() => salvarConfiguracao(config)}
            disabled={salvando || valor === config.valor}
            size="sm"
          >
            <Save className="h-4 w-4 mr-1" />
            Salvar
          </Button>
        </div>
        
        <p className="text-xs text-gray-500">
          <strong>Chave:</strong> {config.chave}
        </p>
      </div>
    )
  }
  
  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="h-8 w-8 animate-spin mx-auto text-primary" />
          <p className="mt-2 text-gray-600">Carregando configurações...</p>
        </div>
      </div>
    )
  }
  
  return (
    <div className="min-h-screen bg-gray-50 py-8 px-4">
      <div className="max-w-7xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <Button variant="ghost" onClick={() => navigate('/dashboard')}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Voltar para Dashboard
          </Button>
          <h1 className="text-3xl font-bold text-gray-900">Configurações do Sistema</h1>
        </div>
        
        {/* Mensagem de Sucesso */}
        {successMessage && (
          <Alert variant="success">
            <AlertDescription>{successMessage}</AlertDescription>
          </Alert>
        )}
        
        {/* Acesso Rápido - Gerenciar Usuários */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Card className="border-2 border-blue-200 bg-blue-50">
            <CardContent className="py-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-full bg-blue-500 flex items-center justify-center">
                    <Users className="h-6 w-6 text-white" />
                  </div>
                  <div>
                    <h3 className="font-semibold text-blue-900">Gerenciar Usuários</h3>
                    <p className="text-sm text-blue-700">
                      Criar, editar e gerenciar usuários do sistema
                    </p>
                  </div>
                </div>
                
                <Button
                  onClick={() => navigate('/gerenciar-usuarios')}
                  className="bg-blue-600 hover:bg-blue-700"
                >
                  <Users className="h-4 w-4 mr-2" />
                  Acessar
                </Button>
              </div>
            </CardContent>
          </Card>

          <Card className="border-2 border-purple-200 bg-purple-50">
            <CardContent className="py-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-full bg-purple-500 flex items-center justify-center">
                    <Palette className="h-6 w-6 text-white" />
                  </div>
                  <div>
                    <h3 className="font-semibold text-purple-900">Gerenciar Prioridades</h3>
                    <p className="text-sm text-purple-700">
                      Criar, editar e gerenciar níveis de prioridade
                    </p>
                  </div>
                </div>
                
                <Button
                  onClick={() => navigate('/gerenciar-prioridades')}
                  className="bg-purple-600 hover:bg-purple-700"
                >
                  <Palette className="h-4 w-4 mr-2" />
                  Acessar
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
        
        {/* ==================== GERENCIAMENTO DE CLIENTES ==================== */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-purple-100 flex items-center justify-center">
                <Building2 className="h-5 w-5 text-purple-600" />
              </div>
              <div>
                <CardTitle>Gerenciar Clientes</CardTitle>
                <p className="text-sm text-gray-500 mt-1">
                  Empresas e órgãos que utilizam o sistema
                </p>
              </div>
            </div>
            
            <Button onClick={() => setModalCliente({ open: true, item: null })}>
              <Plus className="h-4 w-4 mr-2" />
              Novo Cliente
            </Button>
          </CardHeader>
          
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-3 px-4 text-sm font-medium text-gray-700">Nome</th>
                    <th className="text-left py-3 px-4 text-sm font-medium text-gray-700">WhatsApp Group</th>
                    <th className="text-center py-3 px-4 text-sm font-medium text-gray-700">Status</th>
                    <th className="text-right py-3 px-4 text-sm font-medium text-gray-700">Ações</th>
                  </tr>
                </thead>
                <tbody>
                  {clientes.map(cliente => (
                    <tr key={cliente.id} className="border-b hover:bg-gray-50">
                      <td className="py-3 px-4">{cliente.nome}</td>
                      <td className="py-3 px-4 text-sm text-gray-600">{cliente.whatsapp_group_id || '-'}</td>
                      <td className="py-3 px-4 text-center">
                        <Badge variant={cliente.ativo ? 'success' : 'error'}>
                          {cliente.ativo ? 'Ativo' : 'Inativo'}
                        </Badge>
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex justify-end gap-2">
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => setModalCliente({ open: true, item: cliente })}
                          >
                            <Edit className="h-3 w-3" />
                          </Button>
                          <Button
                            size="sm"
                            variant={cliente.ativo ? 'error' : 'success'}
                            onClick={() => toggleCliente(cliente)}
                          >
                            {cliente.ativo ? <ToggleLeft className="h-3 w-3" /> : <ToggleRight className="h-3 w-3" />}
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              
              {clientes.length === 0 && (
                <div className="text-center py-8 text-gray-500">
                  Nenhum cliente cadastrado
                </div>
              )}
            </div>
          </CardContent>
        </Card>
        
        {/* ==================== GERENCIAMENTO DE SECRETARIAS ==================== */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-indigo-100 flex items-center justify-center">
                <Briefcase className="h-5 w-5 text-indigo-600" />
              </div>
              <div>
                <CardTitle>Gerenciar Secretarias</CardTitle>
                <p className="text-sm text-gray-500 mt-1">
                  Departamentos dos clientes
                </p>
              </div>
            </div>
            
            <Button onClick={() => setModalSecretaria({ open: true, item: null })}>
              <Plus className="h-4 w-4 mr-2" />
              Nova Secretaria
            </Button>
          </CardHeader>
          
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-3 px-4 text-sm font-medium text-gray-700">Nome</th>
                    <th className="text-left py-3 px-4 text-sm font-medium text-gray-700">Cliente</th>
                    <th className="text-center py-3 px-4 text-sm font-medium text-gray-700">Demandas</th>
                    <th className="text-center py-3 px-4 text-sm font-medium text-gray-700">Status</th>
                    <th className="text-right py-3 px-4 text-sm font-medium text-gray-700">Ações</th>
                  </tr>
                </thead>
                <tbody>
                  {secretarias.map(secretaria => (
                    <tr key={secretaria.id} className="border-b hover:bg-gray-50">
                      <td className="py-3 px-4">{secretaria.nome}</td>
                      <td className="py-3 px-4 text-sm text-gray-600">{secretaria.cliente_nome}</td>
                      <td className="py-3 px-4 text-center">
                        <Badge variant="secondary">{secretaria.total_demandas || 0}</Badge>
                      </td>
                      <td className="py-3 px-4 text-center">
                        <Badge variant={secretaria.ativo ? 'success' : 'error'}>
                          {secretaria.ativo ? 'Ativo' : 'Inativo'}
                        </Badge>
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex justify-end gap-2">
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => setModalSecretaria({ open: true, item: secretaria })}
                          >
                            <Edit className="h-3 w-3" />
                          </Button>
                          <Button
                            size="sm"
                            variant={secretaria.ativo ? 'error' : 'success'}
                            onClick={() => toggleSecretaria(secretaria)}
                          >
                            {secretaria.ativo ? <ToggleLeft className="h-3 w-3" /> : <ToggleRight className="h-3 w-3" />}
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              
              {secretarias.length === 0 && (
                <div className="text-center py-8 text-gray-500">
                  Nenhuma secretaria cadastrada
                </div>
              )}
            </div>
          </CardContent>
        </Card>
        
        {/* ==================== GERENCIAMENTO DE TIPOS DE DEMANDA ==================== */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-pink-100 flex items-center justify-center">
                <Tag className="h-5 w-5 text-pink-600" />
              </div>
              <div>
                <CardTitle>Gerenciar Tipos de Demanda</CardTitle>
                <p className="text-sm text-gray-500 mt-1">
                  Categorias de demandas (Design, Desenvolvimento, etc)
                </p>
              </div>
            </div>
            
            <Button onClick={() => setModalTipo({ open: true, item: null })}>
              <Plus className="h-4 w-4 mr-2" />
              Novo Tipo
            </Button>
          </CardHeader>
          
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {tiposDemanda.map(tipo => (
                <Card key={tipo.id} className={`border-2 ${tipo.ativo ? '' : 'opacity-50'}`}>
                  <CardContent className="pt-6">
                    <div className="flex items-center justify-between mb-4">
                      <div className="flex items-center gap-3">
                        <div
                          className="w-8 h-8 rounded"
                          style={{ backgroundColor: tipo.cor }}
                        />
                        <div>
                          <h3 className="font-medium">{tipo.nome}</h3>
                          <Badge variant={tipo.ativo ? 'success' : 'error'} className="mt-1">
                            {tipo.ativo ? 'Ativo' : 'Inativo'}
                          </Badge>
                        </div>
                      </div>
                    </div>
                    
                    <div className="flex gap-2">
                      <Button
                        size="sm"
                        variant="outline"
                        className="flex-1"
                        onClick={() => setModalTipo({ open: true, item: tipo })}
                      >
                        <Edit className="h-3 w-3 mr-1" />
                        Editar
                      </Button>
                      <Button
                        size="sm"
                        variant={tipo.ativo ? 'error' : 'success'}
                        onClick={() => toggleTipoDemanda(tipo)}
                      >
                        {tipo.ativo ? <ToggleLeft className="h-3 w-3" /> : <ToggleRight className="h-3 w-3" />}
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
            
            {tiposDemanda.length === 0 && (
              <div className="text-center py-8 text-gray-500">
                Nenhum tipo de demanda cadastrado
              </div>
            )}
          </CardContent>
        </Card>
        
        {/* ==================== CONFIGURAÇÕES TRELLO ==================== */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center">
                <Trello className="h-5 w-5 text-blue-600" />
              </div>
              <div>
                <CardTitle>Integração Trello</CardTitle>
                <p className="text-sm text-gray-500 mt-1">
                  Configure a integração com o Trello para criação automática de cards
                </p>
              </div>
            </div>
            
            <Button
              onClick={testarTrello}
              disabled={testando.trello || !valores.trello_api_key || !valores.trello_token}
              variant="outline"
            >
              {testando.trello ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Testando...
                </>
              ) : (
                <>
                  <TestTube className="h-4 w-4 mr-2" />
                  Testar Conexão
                </>
              )}
            </Button>
          </CardHeader>
          
          <CardContent className="space-y-6">
            {configs.trello.map(renderConfiguracao)}
            
            {testResult.trello && (
              <Alert variant={testResult.trello.sucesso ? 'success' : 'error'}>
                <div className="flex items-center gap-2">
                  {testResult.trello.sucesso ? (
                    <CheckCircle className="h-4 w-4" />
                  ) : (
                    <XCircle className="h-4 w-4" />
                  )}
                  <AlertTitle>{testResult.trello.mensagem}</AlertTitle>
                </div>
              </Alert>
            )}
            
            <div className="bg-blue-50 p-4 rounded-lg border border-blue-200">
              <p className="text-sm text-blue-800">
                <strong>💡 Como obter credenciais:</strong><br />
                1. Acesse <a href="https://trello.com/app-key" target="_blank" rel="noopener noreferrer" className="underline">https://trello.com/app-key</a><br />
                2. Copie a "API Key" e o "Token"<br />
                3. Cole nos campos acima e teste a conexão
              </p>
            </div>
          </CardContent>
        </Card>
        
        {/* ==================== CONFIGURAÇÕES WHATSAPP ==================== */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center">
                <MessageSquare className="h-5 w-5 text-green-600" />
              </div>
              <div>
                <CardTitle>Integração WhatsApp (WPPConnect)</CardTitle>
                <p className="text-sm text-gray-500 mt-1">
                  Configure o WPPConnect para envio de notificações via WhatsApp
                </p>
              </div>
            </div>
            
            <Button
              onClick={testarWhatsApp}
              disabled={testando.whatsapp || !valores.wpp_url || !valores.wpp_instance || !valores.wpp_token}
              variant="outline"
            >
              {testando.whatsapp ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Testando...
                </>
              ) : (
                <>
                  <TestTube className="h-4 w-4 mr-2" />
                  Testar Conexão
                </>
              )}
            </Button>
          </CardHeader>
          
          <CardContent className="space-y-6">
            {configs.whatsapp.map(renderConfiguracao)}
            
            {testResult.whatsapp && (
              <Alert variant={testResult.whatsapp.sucesso ? 'success' : 'error'}>
                <div className="flex items-center gap-2">
                  {testResult.whatsapp.sucesso ? (
                    <CheckCircle className="h-4 w-4" />
                  ) : (
                    <XCircle className="h-4 w-4" />
                  )}
                  <AlertTitle>{testResult.whatsapp.mensagem}</AlertTitle>
                </div>
              </Alert>
            )}
            
            <div className="bg-green-50 p-4 rounded-lg border border-green-200">
              <p className="text-sm text-green-800">
                <strong>💡 Como configurar WPPConnect:</strong><br />
                1. Instale o WPPConnect Server<br />
                2. Acesse http://localhost:21465<br />
                3. Escaneie o QR Code com seu WhatsApp<br />
                4. Configure as credenciais acima
              </p>
            </div>
          </CardContent>
        </Card>
        
        {/* ==================== CONFIGURAÇÕES DO SISTEMA ==================== */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-gray-100 flex items-center justify-center">
                <Settings className="h-5 w-5 text-gray-600" />
              </div>
              <div>
                <CardTitle>Configurações do Sistema</CardTitle>
                <p className="text-sm text-gray-500 mt-1">
                  Configurações gerais do aplicativo
                </p>
              </div>
            </div>
          </CardHeader>
          
          <CardContent className="space-y-6">
            {configs.sistema.map(renderConfiguracao)}
          </CardContent>
        </Card>
        
        {/* Rodapé */}
        <div className="flex justify-between items-center pt-4 border-t">
          <p className="text-sm text-gray-500">
            Última atualização: {new Date().toLocaleString('pt-BR')}
          </p>
          <Button variant="outline" onClick={carregarTodosDados}>
            <RefreshCw className="h-4 w-4 mr-2" />
            Recarregar
          </Button>
        </div>
      </div>
      
      {/* ==================== MODALS ==================== */}
      
      {/* Modal Cliente */}
      <ModalCliente
        open={modalCliente.open}
        item={modalCliente.item}
        onClose={() => setModalCliente({ open: false, item: null })}
        onSave={salvarCliente}
      />
      
      {/* Modal Secretaria */}
      <ModalSecretaria
        open={modalSecretaria.open}
        item={modalSecretaria.item}
        clientes={clientes}
        onClose={() => setModalSecretaria({ open: false, item: null })}
        onSave={salvarSecretaria}
      />
      
      {/* Modal Tipo Demanda */}
      <ModalTipoDemanda
        open={modalTipo.open}
        item={modalTipo.item}
        onClose={() => setModalTipo({ open: false, item: null })}
        onSave={salvarTipoDemanda}
      />
    </div>
  )
}

// ==================== COMPONENTES DE MODAL ====================

const ModalCliente = ({ open, item, onClose, onSave }) => {
  const [form, setForm] = useState({
    nome: '',
    whatsapp_group_id: '',
    trello_member_id: ''
  })
  
  useEffect(() => {
    if (item) {
      setForm({
        nome: item.nome || '',
        whatsapp_group_id: item.whatsapp_group_id || '',
        trello_member_id: item.trello_member_id || ''
      })
    } else {
      setForm({
        nome: '',
        whatsapp_group_id: '',
        trello_member_id: ''
      })
    }
  }, [item, open])
  
  const handleSubmit = (e) => {
    e.preventDefault()
    onSave(form)
  }
  
  return (
    <Dialog open={open} onClose={onClose}>
      <DialogContent size="lg">
        <DialogHeader>
          <DialogTitle>
            {item ? 'Editar Cliente' : 'Novo Cliente'}
          </DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit}>
          <DialogBody>
            <div className="space-y-4">
              <Input
                label="Nome do Cliente"
                required
                value={form.nome}
                onChange={(e) => setForm(prev => ({ ...prev, nome: e.target.value }))}
                placeholder="Ex: Prefeitura Municipal"
              />
              
              <Input
                label="WhatsApp Group ID"
                value={form.whatsapp_group_id}
                onChange={(e) => setForm(prev => ({ ...prev, whatsapp_group_id: e.target.value }))}
                placeholder="Ex: 5511999999999-1234567890@g.us"
                helperText="ID do grupo no WhatsApp para notificações"
              />
              
              <Input
                label="Trello Member ID"
                value={form.trello_member_id}
                onChange={(e) => setForm(prev => ({ ...prev, trello_member_id: e.target.value }))}
                placeholder="Ex: abc123def456"
                helperText="ID do membro no Trello para atribuição de cards"
              />
            </div>
          </DialogBody>
          
          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose}>
              Cancelar
            </Button>
            <Button type="submit">
              <Save className="h-4 w-4 mr-2" />
              Salvar
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

const ModalSecretaria = ({ open, item, clientes, onClose, onSave }) => {
  const [form, setForm] = useState({
    nome: '',
    cliente_id: ''
  })
  
  useEffect(() => {
    if (item) {
      setForm({
        nome: item.nome || '',
        cliente_id: item.cliente_id || ''
      })
    } else {
      setForm({
        nome: '',
        cliente_id: clientes[0]?.id || ''
      })
    }
  }, [item, open, clientes])
  
  const handleSubmit = (e) => {
    e.preventDefault()
    
    // Validar que cliente foi selecionado
    if (!form.cliente_id || form.cliente_id.trim() === '') {
      alert('Por favor, selecione um cliente')
      return
    }
    
    // Validar que nome foi preenchido
    if (!form.nome || form.nome.trim() === '') {
      alert('Por favor, preencha o nome da secretaria')
      return
    }
    
    onSave(form)
  }
  
  return (
    <Dialog open={open} onClose={onClose}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>
            {item ? 'Editar Secretaria' : 'Nova Secretaria'}
          </DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit}>
          <DialogBody>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Cliente <span className="text-red-500">*</span>
                </label>
                <select
                  required
                  value={form.cliente_id || ''}
                  onChange={(e) => setForm(prev => ({ ...prev, cliente_id: e.target.value }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary"
                >
                  <option value="">Selecione um cliente</option>
                  {clientes && clientes.filter(c => c.ativo).map(cliente => (
                    <option key={cliente.id} value={cliente.id}>
                      {cliente.nome}
                    </option>
                  ))}
                </select>
                {(!clientes || clientes.length === 0) && (
                  <p className="text-sm text-red-500 mt-1">
                    Nenhum cliente ativo disponível. Crie um cliente primeiro.
                  </p>
                )}
              </div>
              
              <Input
                label="Nome da Secretaria"
                required
                value={form.nome}
                onChange={(e) => setForm(prev => ({ ...prev, nome: e.target.value }))}
                placeholder="Ex: Secretaria de Saúde"
              />
            </div>
          </DialogBody>
          
          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose}>
              Cancelar
            </Button>
            <Button type="submit">
              <Save className="h-4 w-4 mr-2" />
              Salvar
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

const ModalTipoDemanda = ({ open, item, onClose, onSave }) => {
  const [form, setForm] = useState({
    nome: '',
    cor: '#3B82F6'
  })
  
  useEffect(() => {
    if (item) {
      setForm({
        nome: item.nome || '',
        cor: item.cor || '#3B82F6'
      })
    } else {
      setForm({
        nome: '',
        cor: '#3B82F6'
      })
    }
  }, [item, open])
  
  const handleSubmit = (e) => {
    e.preventDefault()
    onSave(form)
  }
  
  const cores = [
    { nome: 'Azul', valor: '#3B82F6' },
    { nome: 'Verde', valor: '#10B981' },
    { nome: 'Roxo', valor: '#8B5CF6' },
    { nome: 'Amarelo', valor: '#F59E0B' },
    { nome: 'Vermelho', valor: '#EF4444' },
    { nome: 'Rosa', valor: '#EC4899' },
    { nome: 'Indigo', valor: '#6366F1' },
    { nome: 'Teal', valor: '#14B8A6' }
  ]
  
  return (
    <Dialog open={open} onClose={onClose}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>
            {item ? 'Editar Tipo de Demanda' : 'Novo Tipo de Demanda'}
          </DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit}>
          <DialogBody>
            <div className="space-y-4">
              <Input
                label="Nome do Tipo"
                required
                value={form.nome}
                onChange={(e) => setForm(prev => ({ ...prev, nome: e.target.value }))}
                placeholder="Ex: Design, Desenvolvimento"
              />
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Cor <span className="text-red-500">*</span>
                </label>
                <div className="grid grid-cols-4 gap-2">
                  {cores.map(cor => (
                    <button
                      key={cor.valor}
                      type="button"
                      onClick={() => setForm(prev => ({ ...prev, cor: cor.valor }))}
                      className={`h-12 rounded-lg border-2 transition-all ${
                        form.cor === cor.valor ? 'border-gray-900 scale-110' : 'border-gray-200'
                      }`}
                      style={{ backgroundColor: cor.valor }}
                      title={cor.nome}
                    />
                  ))}
                </div>
                
                <Input
                  label="Ou insira um código hex"
                  type="text"
                  value={form.cor}
                  onChange={(e) => setForm(prev => ({ ...prev, cor: e.target.value }))}
                  placeholder="#3B82F6"
                  className="mt-2"
                  pattern="^#[0-9A-Fa-f]{6}$"
                />
              </div>
              
              <div 
                className="h-16 rounded-lg border-2 border-dashed flex items-center justify-center"
                style={{ backgroundColor: form.cor }}
              >
                <span className="text-white font-medium text-shadow">
                  Pré-visualização: {form.nome || 'Nome do Tipo'}
                </span>
              </div>
            </div>
          </DialogBody>
          
          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose}>
              Cancelar
            </Button>
            <Button type="submit">
              <Save className="h-4 w-4 mr-2" />
              Salvar
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

export default Configuracoes
