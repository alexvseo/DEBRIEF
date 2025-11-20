import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ArrowLeft,
  Plus,
  Edit,
  ToggleLeft,
  ToggleRight,
  Key,
  Save,
  Loader2,
  Users,
  Search,
  Filter,
  UserCheck,
  UserX,
  Crown,
  User as UserIcon,
  RefreshCw
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
  AlertTitle,
  AlertDescription,
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogBody,
  DialogFooter
} from '@/components/ui'
import { useAuth } from '@/hooks/useAuth'
import api from '@/services/api'

const GerenciarUsuarios = () => {
  const navigate = useNavigate()
  const { user: currentUser, isMaster } = useAuth()
  
  const [loading, setLoading] = useState(true)
  const [usuarios, setUsuarios] = useState([])
  const [clientes, setClientes] = useState([])
  const [estatisticas, setEstatisticas] = useState({})
  const [successMessage, setSuccessMessage] = useState('')
  
  // Filtros
  const [busca, setBusca] = useState('')
  const [filtroTipo, setFiltroTipo] = useState('todos')
  const [filtroStatus, setFiltroStatus] = useState('ativos')
  
  // Modals
  const [modalUsuario, setModalUsuario] = useState({ open: false, item: null })
  const [modalSenha, setModalSenha] = useState({ open: false, item: null })
  
  // Verificar permissão
  useEffect(() => {
    if (!isMaster()) {
      navigate('/dashboard')
    }
  }, [isMaster, navigate])
  
  // Carregar dados
  useEffect(() => {
    carregarTodosDados()
  }, [])
  
  const carregarTodosDados = async () => {
    try {
      setLoading(true)
      await Promise.all([
        carregarUsuarios(),
        carregarClientes(),
        carregarEstatisticas()
      ])
    } catch (error) {
      console.error('Erro ao carregar dados:', error)
    } finally {
      setLoading(false)
    }
  }
  
  const carregarUsuarios = async () => {
    try {
      const response = await api.get('/usuarios/', {
        params: { apenas_ativos: false }
      })
      setUsuarios(response.data)
    } catch (error) {
      console.error('Erro ao carregar usuários:', error)
    }
  }
  
  const carregarClientes = async () => {
    try {
      const response = await api.get('/clientes/', {
        params: { apenas_ativos: true }
      })
      setClientes(response.data)
    } catch (error) {
      console.error('Erro ao carregar clientes:', error)
    }
  }
  
  const carregarEstatisticas = async () => {
    try {
      const response = await api.get('/usuarios/estatisticas/geral')
      setEstatisticas(response.data)
    } catch (error) {
      console.error('Erro ao carregar estatísticas:', error)
    }
  }
  
  const salvarUsuario = async (dados) => {
    try {
      if (modalUsuario.item) {
        await api.put(`/usuarios/${modalUsuario.item.id}`, dados)
        setSuccessMessage('✅ Usuário atualizado com sucesso!')
      } else {
        await api.post('/usuarios/', dados)
        setSuccessMessage('✅ Usuário criado com sucesso!')
      }
      
      setModalUsuario({ open: false, item: null })
      await carregarTodosDados()
      setTimeout(() => setSuccessMessage(''), 3000)
    } catch (error) {
      console.error('Erro ao salvar usuário:', error)
      alert(error.response?.data?.detail || 'Erro ao salvar usuário')
    }
  }
  
  const toggleUsuario = async (usuario) => {
    try {
      if (usuario.ativo) {
        await api.delete(`/usuarios/${usuario.id}`)
        setSuccessMessage('✅ Usuário desativado com sucesso!')
      } else {
        await api.post(`/usuarios/${usuario.id}/reativar`)
        setSuccessMessage('✅ Usuário reativado com sucesso!')
      }
      await carregarTodosDados()
      setTimeout(() => setSuccessMessage(''), 3000)
    } catch (error) {
      console.error('Erro ao alterar status:', error)
      alert(error.response?.data?.detail || 'Erro ao alterar status do usuário')
    }
  }
  
  const resetarSenha = async (userId, newPassword) => {
    try {
      await api.post(`/usuarios/${userId}/reset-password`, {
        new_password: newPassword
      })
      
      setSuccessMessage('✅ Senha resetada com sucesso!')
      setModalSenha({ open: false, item: null })
      setTimeout(() => setSuccessMessage(''), 3000)
    } catch (error) {
      console.error('Erro ao resetar senha:', error)
      alert(error.response?.data?.detail || 'Erro ao resetar senha')
    }
  }
  
  // Filtrar usuários
  const usuariosFiltrados = usuarios.filter(usuario => {
    // Filtro de busca
    if (busca) {
      const buscaLower = busca.toLowerCase()
      const match = 
        usuario.nome_completo.toLowerCase().includes(buscaLower) ||
        usuario.email.toLowerCase().includes(buscaLower) ||
        usuario.username.toLowerCase().includes(buscaLower)
      
      if (!match) return false
    }
    
    // Filtro de tipo
    if (filtroTipo !== 'todos') {
      if (usuario.tipo !== filtroTipo) return false
    }
    
    // Filtro de status
    if (filtroStatus === 'ativos' && !usuario.ativo) return false
    if (filtroStatus === 'inativos' && usuario.ativo) return false
    
    return true
  })
  
  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="h-8 w-8 animate-spin mx-auto text-primary" />
          <p className="mt-2 text-gray-600">Carregando usuários...</p>
        </div>
      </div>
    )
  }
  
  return (
    <div className="min-h-screen bg-gray-50 py-8 px-4">
      <div className="max-w-7xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <Button variant="ghost" onClick={() => navigate('/configuracoes')}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Voltar
          </Button>
          <h1 className="text-3xl font-bold text-gray-900">Gerenciar Usuários</h1>
        </div>
        
        {/* Mensagem de Sucesso */}
        {successMessage && (
          <Alert variant="success">
            <AlertDescription>{successMessage}</AlertDescription>
          </Alert>
        )}
        
        {/* Estatísticas */}
        <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <Users className="h-8 w-8 mx-auto text-gray-600 mb-2" />
                <p className="text-2xl font-bold text-gray-900">{estatisticas.total || 0}</p>
                <p className="text-sm text-gray-500">Total</p>
              </div>
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <UserCheck className="h-8 w-8 mx-auto text-green-600 mb-2" />
                <p className="text-2xl font-bold text-green-600">{estatisticas.ativos || 0}</p>
                <p className="text-sm text-gray-500">Ativos</p>
              </div>
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <UserX className="h-8 w-8 mx-auto text-red-600 mb-2" />
                <p className="text-2xl font-bold text-red-600">{estatisticas.inativos || 0}</p>
                <p className="text-sm text-gray-500">Inativos</p>
              </div>
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <Crown className="h-8 w-8 mx-auto text-yellow-600 mb-2" />
                <p className="text-2xl font-bold text-yellow-600">{estatisticas.masters || 0}</p>
                <p className="text-sm text-gray-500">Masters</p>
              </div>
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <UserIcon className="h-8 w-8 mx-auto text-blue-600 mb-2" />
                <p className="text-2xl font-bold text-blue-600">{estatisticas.clientes || 0}</p>
                <p className="text-sm text-gray-500">Clientes</p>
              </div>
            </CardContent>
          </Card>
        </div>
        
        {/* Card Principal */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0">
            <div>
              <CardTitle>Lista de Usuários</CardTitle>
              <p className="text-sm text-gray-500 mt-1">
                {usuariosFiltrados.length} de {usuarios.length} usuários
              </p>
            </div>
            
            <Button onClick={() => setModalUsuario({ open: true, item: null })}>
              <Plus className="h-4 w-4 mr-2" />
              Novo Usuário
            </Button>
          </CardHeader>
          
          <CardContent>
            {/* Filtros */}
            <div className="mb-6 grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <Input
                  placeholder="Buscar por nome, email ou username"
                  value={busca}
                  onChange={(e) => setBusca(e.target.value)}
                  className="pl-10"
                />
              </div>
              
              <div>
                <select
                  value={filtroTipo}
                  onChange={(e) => setFiltroTipo(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary"
                >
                  <option value="todos">Todos os tipos</option>
                  <option value="master">Master</option>
                  <option value="cliente">Cliente</option>
                </select>
              </div>
              
              <div>
                <select
                  value={filtroStatus}
                  onChange={(e) => setFiltroStatus(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary"
                >
                  <option value="todos">Todos os status</option>
                  <option value="ativos">Apenas ativos</option>
                  <option value="inativos">Apenas inativos</option>
                </select>
              </div>
            </div>
            
            {/* Tabela */}
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-3 px-4 text-sm font-medium text-gray-700">Usuário</th>
                    <th className="text-left py-3 px-4 text-sm font-medium text-gray-700">Email</th>
                    <th className="text-center py-3 px-4 text-sm font-medium text-gray-700">Tipo</th>
                    <th className="text-center py-3 px-4 text-sm font-medium text-gray-700">Status</th>
                    <th className="text-right py-3 px-4 text-sm font-medium text-gray-700">Ações</th>
                  </tr>
                </thead>
                <tbody>
                  {usuariosFiltrados.map(usuario => (
                    <tr key={usuario.id} className="border-b hover:bg-gray-50">
                      <td className="py-3 px-4">
                        <div>
                          <div className="font-medium text-gray-900">{usuario.nome_completo}</div>
                          <div className="text-sm text-gray-500">@{usuario.username}</div>
                        </div>
                      </td>
                      <td className="py-3 px-4 text-sm text-gray-600">{usuario.email}</td>
                      <td className="py-3 px-4 text-center">
                        <Badge variant={usuario.tipo === 'master' ? 'default' : 'secondary'}>
                          {usuario.tipo === 'master' ? (
                            <><Crown className="h-3 w-3 mr-1 inline" /> Master</>
                          ) : (
                            <><UserIcon className="h-3 w-3 mr-1 inline" /> Cliente</>
                          )}
                        </Badge>
                      </td>
                      <td className="py-3 px-4 text-center">
                        <Badge variant={usuario.ativo ? 'success' : 'error'}>
                          {usuario.ativo ? 'Ativo' : 'Inativo'}
                        </Badge>
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex justify-end gap-2">
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => setModalUsuario({ open: true, item: usuario })}
                            title="Editar"
                          >
                            <Edit className="h-3 w-3" />
                          </Button>
                          
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => setModalSenha({ open: true, item: usuario })}
                            title="Resetar senha"
                          >
                            <Key className="h-3 w-3" />
                          </Button>
                          
                          <Button
                            size="sm"
                            variant={usuario.ativo ? 'error' : 'success'}
                            onClick={() => toggleUsuario(usuario)}
                            disabled={usuario.id === currentUser?.id}
                            title={usuario.ativo ? 'Desativar' : 'Reativar'}
                          >
                            {usuario.ativo ? <ToggleLeft className="h-3 w-3" /> : <ToggleRight className="h-3 w-3" />}
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              
              {usuariosFiltrados.length === 0 && (
                <div className="text-center py-12 text-gray-500">
                  {busca || filtroTipo !== 'todos' || filtroStatus !== 'todos' ? (
                    <>
                      <Filter className="h-12 w-12 mx-auto mb-2 text-gray-300" />
                      <p>Nenhum usuário encontrado com os filtros aplicados</p>
                    </>
                  ) : (
                    <>
                      <Users className="h-12 w-12 mx-auto mb-2 text-gray-300" />
                      <p>Nenhum usuário cadastrado</p>
                    </>
                  )}
                </div>
              )}
            </div>
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
      
      {/* Modals */}
      <ModalUsuario
        open={modalUsuario.open}
        item={modalUsuario.item}
        clientes={clientes}
        onClose={() => setModalUsuario({ open: false, item: null })}
        onSave={salvarUsuario}
      />
      
      <ModalResetSenha
        open={modalSenha.open}
        item={modalSenha.item}
        onClose={() => setModalSenha({ open: false, item: null })}
        onSave={resetarSenha}
      />
    </div>
  )
}

// ==================== MODAL USUÁRIO ====================

const ModalUsuario = ({ open, item, clientes, onClose, onSave }) => {
  const [form, setForm] = useState({
    username: '',
    email: '',
    nome_completo: '',
    password: '',
    tipo: 'cliente',
    cliente_id: ''
  })
  
  useEffect(() => {
    if (item) {
      setForm({
        username: item.username || '',
        email: item.email || '',
        nome_completo: item.nome_completo || '',
        password: '', // Não preencher senha em edição
        tipo: item.tipo || 'cliente',
        cliente_id: item.cliente_id || ''
      })
    } else {
      setForm({
        username: '',
        email: '',
        nome_completo: '',
        password: '',
        tipo: 'cliente',
        cliente_id: clientes[0]?.id || ''
      })
    }
  }, [item, open, clientes])
  
  const handleSubmit = (e) => {
    e.preventDefault()
    
    // Preparar dados para envio
    let dadosParaEnvio = { ...form }
    
    // Se tipo for master, não enviar cliente_id
    if (dadosParaEnvio.tipo === 'master') {
      dadosParaEnvio.cliente_id = null
    }
    
    // Se cliente_id estiver vazio, enviar null
    if (!dadosParaEnvio.cliente_id || dadosParaEnvio.cliente_id === '') {
      dadosParaEnvio.cliente_id = null
    }
    
    // Se for edição, não enviar senha se estiver vazia
    if (item && !form.password) {
      const { password, ...dadosSemSenha } = dadosParaEnvio
      onSave(dadosSemSenha)
    } else {
      onSave(dadosParaEnvio)
    }
  }
  
  return (
    <Dialog open={open} onClose={onClose}>
      <DialogContent size="lg">
        <DialogHeader>
          <DialogTitle>
            {item ? 'Editar Usuário' : 'Novo Usuário'}
          </DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit}>
          <DialogBody>
            <div className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <Input
                  label="Username"
                  required
                  value={form.username}
                  onChange={(e) => setForm(prev => ({ ...prev, username: e.target.value }))}
                  placeholder="Ex: joao.silva"
                  helperText="Nome de usuário único para login"
                />
                
                <Input
                  label="Email"
                  type="email"
                  required
                  value={form.email}
                  onChange={(e) => setForm(prev => ({ ...prev, email: e.target.value }))}
                  placeholder="Ex: joao@email.com"
                />
              </div>
              
              <Input
                label="Nome Completo"
                required
                value={form.nome_completo}
                onChange={(e) => setForm(prev => ({ ...prev, nome_completo: e.target.value }))}
                placeholder="Ex: João da Silva"
              />
              
              <Input
                label={item ? "Senha (deixe vazio para não alterar)" : "Senha"}
                type="password"
                required={!item}
                value={form.password}
                onChange={(e) => setForm(prev => ({ ...prev, password: e.target.value }))}
                placeholder="Mínimo 6 caracteres"
                helperText={item ? "Deixe em branco para manter a senha atual" : "Mínimo 6 caracteres"}
              />
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Tipo de Usuário <span className="text-red-500">*</span>
                </label>
                <select
                  required
                  value={form.tipo}
                  onChange={(e) => {
                    const novoTipo = e.target.value
                    setForm(prev => ({ 
                      ...prev, 
                      tipo: novoTipo,
                      // Limpar cliente_id se mudar para master
                      cliente_id: novoTipo === 'master' ? '' : prev.cliente_id
                    }))
                  }}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary"
                >
                  <option value="master">Master (Administrador)</option>
                  <option value="cliente">Cliente</option>
                </select>
              </div>
              
              {form.tipo === 'cliente' && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Cliente <span className="text-red-500">*</span>
                  </label>
                  <select
                    required={form.tipo === 'cliente'}
                    value={form.cliente_id}
                    onChange={(e) => setForm(prev => ({ ...prev, cliente_id: e.target.value }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary"
                  >
                    <option value="">Selecione um cliente</option>
                    {clientes.filter(c => c.ativo).map(cliente => (
                      <option key={cliente.id} value={cliente.id}>
                        {cliente.nome}
                      </option>
                    ))}
                  </select>
                </div>
              )}
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

// ==================== MODAL RESET SENHA ====================

const ModalResetSenha = ({ open, item, onClose, onSave }) => {
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  
  useEffect(() => {
    if (!open) {
      setNewPassword('')
      setConfirmPassword('')
    }
  }, [open])
  
  const handleSubmit = (e) => {
    e.preventDefault()
    
    if (newPassword !== confirmPassword) {
      alert('As senhas não coincidem!')
      return
    }
    
    if (newPassword.length < 6) {
      alert('A senha deve ter no mínimo 6 caracteres!')
      return
    }
    
    onSave(item?.id, newPassword)
  }
  
  return (
    <Dialog open={open} onClose={onClose}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>
            <Key className="h-5 w-5 inline mr-2" />
            Resetar Senha
          </DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit}>
          <DialogBody>
            <Alert variant="info" className="mb-4">
              <AlertDescription>
                Você está resetando a senha do usuário: <strong>{item?.nome_completo}</strong>
              </AlertDescription>
            </Alert>
            
            <div className="space-y-4">
              <Input
                label="Nova Senha"
                type="password"
                required
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                placeholder="Mínimo 6 caracteres"
                helperText="Mínimo 6 caracteres"
              />
              
              <Input
                label="Confirmar Senha"
                type="password"
                required
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                placeholder="Digite a senha novamente"
              />
            </div>
          </DialogBody>
          
          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose}>
              Cancelar
            </Button>
            <Button type="submit">
              <Key className="h-4 w-4 mr-2" />
              Resetar Senha
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

export default GerenciarUsuarios

