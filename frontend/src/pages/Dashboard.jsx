import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'
import {
  Button,
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardContent,
  Badge,
  Alert,
  AlertTitle,
  AlertDescription,
} from '@/components/ui'
import { 
  LogOut, 
  User, 
  FileText, 
  Clock, 
  CheckCircle, 
  AlertTriangle,
  Plus,
  Settings,
  BarChart3,
  Users,
  Building2,
  TrendingUp,
  XCircle,
  Loader2,
  RefreshCw,
  AlertCircle
} from 'lucide-react'
import api from '@/services/api'
import { toast } from 'sonner'
import {
  PieChart,
  Pie,
  Cell,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer
} from 'recharts'

const Dashboard = () => {
  const navigate = useNavigate()
  const { user, logout, isMaster } = useAuth()
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  
  // Estados para métricas
  const [metricas, setMetricas] = useState({
    usuarios: { total: 0, ativos: 0, inativos: 0, masters: 0, clientes: 0 },
    clientes: { total: 0, ativos: 0 },
    demandas: { total: 0, abertas: 0, em_andamento: 0, concluidas: 0, canceladas: 0 },
    secretarias: { total: 0 },
    tipos: { total: 0 },
    prioridades: { total: 0 }
  })
  
  // Estados para gráficos
  const [dadosGraficos, setDadosGraficos] = useState({
    demandasPorStatus: [],
    demandasPorTipo: [],
    demandasPorPrioridade: [],
    demandasRecentes: []
  })

  useEffect(() => {
    carregarDados()
  }, [])

  const carregarDados = async () => {
    try {
      setLoading(true)
      
      const endpoints = [
        api.get('/demandas'),
        api.get('/tipos-demanda/'),
        api.get('/prioridades/')
      ]

      // Adiciona endpoints admin apenas se for master
      if (isMaster()) {
        endpoints.push(
          api.get('/usuarios/'),
          api.get('/usuarios/estatisticas/geral'),
          api.get('/clientes/'),
          api.get('/secretarias/')
        )
      }

      const responses = await Promise.all(endpoints)
      
      const [demandas, tipos, prioridades, usuarios, estatisticasUsuarios, clientes, secretarias] = responses

      // Processar métricas
      const metricasProcessadas = {
        demandas: {
          total: demandas.data.length,
          abertas: demandas.data.filter(d => d.status === 'ABERTA').length,
          em_andamento: demandas.data.filter(d => d.status === 'EM_ANDAMENTO').length,
          concluidas: demandas.data.filter(d => d.status === 'CONCLUIDA').length,
          canceladas: demandas.data.filter(d => d.status === 'CANCELADA').length
        },
        tipos: { total: tipos.data.length },
        prioridades: { total: prioridades.data.length }
      }

      if (isMaster() && estatisticasUsuarios && clientes && secretarias) {
        metricasProcessadas.usuarios = estatisticasUsuarios.data
        metricasProcessadas.clientes = {
          total: clientes.data.length,
          ativos: clientes.data.filter(c => c.ativo).length
        }
        metricasProcessadas.secretarias = { total: secretarias.data.length }
      }

      setMetricas(metricasProcessadas)
      processarDadosGraficos(demandas.data, tipos.data, prioridades.data)
      
    } catch (error) {
      console.error('Erro ao carregar dados:', error)
      toast.error("Erro ao carregar dados", { description: error.response?.data?.detail || "Tente novamente." })
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }

  const processarDadosGraficos = (demandas, tipos, prioridades) => {
    // Demandas por Status
    const porStatus = [
      { name: 'Abertas', value: demandas.filter(d => d.status === 'ABERTA').length, color: '#3B82F6' },
      { name: 'Em Andamento', value: demandas.filter(d => d.status === 'EM_ANDAMENTO').length, color: '#F59E0B' },
      { name: 'Concluídas', value: demandas.filter(d => d.status === 'CONCLUIDA').length, color: '#10B981' },
      { name: 'Canceladas', value: demandas.filter(d => d.status === 'CANCELADA').length, color: '#EF4444' }
    ]

    // Demandas por Tipo
    const porTipo = tipos.map(tipo => ({
      name: tipo.nome,
      quantidade: demandas.filter(d => d.tipo_demanda_id === tipo.id).length,
      fill: tipo.cor
    }))

    // Demandas por Prioridade
    const porPrioridade = prioridades
      .sort((a, b) => a.nivel - b.nivel)
      .map(p => ({
        name: p.nome,
        quantidade: demandas.filter(d => d.prioridade_id === p.id).length,
        fill: p.cor
      }))

    // Demandas Recentes (últimas 10)
    const recentes = demandas
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
      .slice(0, 10)

    setDadosGraficos({
      demandasPorStatus: porStatus,
      demandasPorTipo: porTipo,
      demandasPorPrioridade: porPrioridade,
      demandasRecentes: recentes
    })
  }

  const handleRefresh = () => {
    setRefreshing(true)
    carregarDados()
  }

  const formatarData = (data) => {
    return new Date(data).toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    })
  }

  const getStatusBadge = (status) => {
    const statusMap = {
      'ABERTA': { variant: 'default', icon: '🔵', label: 'Aberta' },
      'EM_ANDAMENTO': { variant: 'warning', icon: '🟡', label: 'Em Andamento' },
      'CONCLUIDA': { variant: 'success', icon: '🟢', label: 'Concluída' },
      'CANCELADA': { variant: 'error', icon: '🔴', label: 'Cancelada' }
    }
    const s = statusMap[status] || statusMap['ABERTA']
    return <Badge variant={s.variant}>{s.icon} {s.label}</Badge>
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <Loader2 className="h-12 w-12 animate-spin text-blue-500" />
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-7xl mx-auto space-y-8">
        
        {/* Header */}
        <div className="flex justify-between items-start">
          <div>
            <h1 className="text-4xl font-bold text-gray-900">
              Dashboard
            </h1>
            <p className="text-gray-600 mt-2">
              Bem-vindo(a), {user?.nome_completo}!
            </p>
          </div>
          
          <div className="flex items-center gap-3">
            <Button variant="outline" onClick={handleRefresh} disabled={refreshing} size="sm">
              <RefreshCw className={`h-4 w-4 mr-2 ${refreshing ? 'animate-spin' : ''}`} />
              Atualizar
            </Button>
            <Badge variant={isMaster() ? 'default' : 'secondary'}>
              {isMaster() ? '👑 Master' : '👤 Cliente'}
            </Badge>
            <Button variant="outline" onClick={logout}>
              <LogOut className="h-4 w-4" />
              Sair
            </Button>
          </div>
        </div>

        {/* Alert de Boas-Vindas */}
        <Alert variant="success">
          <AlertTitle>✅ Sistema Operacional!</AlertTitle>
          <AlertDescription>
            Todos os módulos estão funcionando. Dashboard com métricas em tempo real!
          </AlertDescription>
        </Alert>

        {/* Cards de Estatísticas Principais */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* Card Demandas */}
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Demandas</p>
                  <h3 className="text-3xl font-bold text-gray-900 mt-2">{metricas.demandas.total}</h3>
                  <p className="text-xs text-gray-500 mt-1">
                    {metricas.demandas.abertas + metricas.demandas.em_andamento} ativas
                  </p>
                </div>
                <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
                  <FileText className="h-6 w-6 text-green-600" />
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Card Em Andamento */}
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Em Andamento</p>
                  <h3 className="text-3xl font-bold text-orange-600 mt-2">{metricas.demandas.em_andamento}</h3>
                  <p className="text-xs text-gray-500 mt-1">
                    {metricas.demandas.total > 0 
                      ? Math.round((metricas.demandas.em_andamento / metricas.demandas.total) * 100)
                      : 0}% do total
                  </p>
                </div>
                <div className="w-12 h-12 bg-orange-100 rounded-full flex items-center justify-center">
                  <Clock className="h-6 w-6 text-orange-600" />
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Card Concluídas */}
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Concluídas</p>
                  <h3 className="text-3xl font-bold text-green-600 mt-2">{metricas.demandas.concluidas}</h3>
                  <p className="text-xs text-gray-500 mt-1">
                    {metricas.demandas.total > 0 
                      ? Math.round((metricas.demandas.concluidas / metricas.demandas.total) * 100)
                      : 0}% do total
                  </p>
                </div>
                <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
                  <CheckCircle className="h-6 w-6 text-green-600" />
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Card Taxa de Conclusão */}
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Taxa de Conclusão</p>
                  <h3 className="text-3xl font-bold text-gray-900 mt-2">
                    {metricas.demandas.total > 0
                      ? Math.round((metricas.demandas.concluidas / metricas.demandas.total) * 100)
                      : 0}%
                  </h3>
                  <p className="text-xs text-gray-500 mt-1">
                    {metricas.demandas.concluidas} de {metricas.demandas.total}
                  </p>
                </div>
                <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
                  <TrendingUp className="h-6 w-6 text-blue-600" />
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Cards de Estatísticas Admin (apenas para Master) */}
        {isMaster() && metricas.usuarios && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Card>
              <CardContent className="pt-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-gray-600">Usuários</p>
                    <h3 className="text-3xl font-bold text-gray-900 mt-2">{metricas.usuarios.total}</h3>
                    <p className="text-xs text-gray-500 mt-1">
                      {metricas.usuarios.ativos} ativos
                    </p>
                  </div>
                  <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
                    <Users className="h-6 w-6 text-blue-600" />
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="pt-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-gray-600">Clientes</p>
                    <h3 className="text-3xl font-bold text-gray-900 mt-2">{metricas.clientes.total}</h3>
                    <p className="text-xs text-gray-500 mt-1">
                      {metricas.clientes.ativos} ativos
                    </p>
                  </div>
                  <div className="w-12 h-12 bg-purple-100 rounded-full flex items-center justify-center">
                    <Building2 className="h-6 w-6 text-purple-600" />
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="pt-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-gray-600">Secretarias</p>
                    <h3 className="text-3xl font-bold text-gray-900 mt-2">{metricas.secretarias.total}</h3>
                    <p className="text-xs text-gray-500 mt-1">
                      Cadastradas
                    </p>
                  </div>
                  <div className="w-12 h-12 bg-indigo-100 rounded-full flex items-center justify-center">
                    <Building2 className="h-6 w-6 text-indigo-600" />
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        )}

        {/* Ações Rápidas */}
        <Card>
          <CardHeader>
            <CardTitle>Ações Rápidas</CardTitle>
            <CardDescription>
              Acesso rápido às principais funcionalidades
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className={`grid grid-cols-1 ${isMaster() ? 'md:grid-cols-4' : 'md:grid-cols-3'} gap-4`}>
              <Button 
                className="h-20" 
                size="lg"
                onClick={() => navigate('/nova-demanda')}
              >
                <Plus className="h-5 w-5" />
                Nova Demanda
              </Button>
              <Button 
                variant="outline"
                className="h-20"
                size="lg"
                onClick={() => navigate('/minhas-demandas')}
              >
                <FileText className="h-5 w-5" />
                Minhas Demandas
              </Button>
              <Button 
                variant="outline"
                className="h-20"
                size="lg"
                onClick={() => navigate('/meu-perfil')}
              >
                <User className="h-5 w-5" />
                Meu Perfil
              </Button>
              
              {isMaster() && (
                <Button 
                  variant="outline"
                  className="h-20 border-blue-300 text-blue-700 hover:bg-blue-50"
                  size="lg"
                  onClick={() => navigate('/configuracoes')}
                >
                  <Settings className="h-5 w-5" />
                  Configurações
                </Button>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Gráficos */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Gráfico de Pizza - Demandas por Status */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <BarChart3 className="h-5 w-5" />
                Demandas por Status
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <PieChart>
                  <Pie
                    data={dadosGraficos.demandasPorStatus}
                    cx="50%"
                    cy="50%"
                    labelLine={false}
                    label={({ name, value }) => `${name}: ${value}`}
                    outerRadius={80}
                    fill="#8884d8"
                    dataKey="value"
                  >
                    {dadosGraficos.demandasPorStatus.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip />
                  <Legend />
                </PieChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          {/* Gráfico de Barras - Demandas por Tipo */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <BarChart3 className="h-5 w-5" />
                Demandas por Tipo
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={dadosGraficos.demandasPorTipo}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="quantidade" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          {/* Gráfico de Barras Horizontais - Demandas por Prioridade */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <AlertCircle className="h-5 w-5" />
                Demandas por Prioridade
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={dadosGraficos.demandasPorPrioridade} layout="vertical">
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis type="number" />
                  <YAxis dataKey="name" type="category" />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="quantidade" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          {/* Resumo de Atividades */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Clock className="h-5 w-5" />
                Resumo de Atividades
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div className="flex items-center justify-between py-3 border-b">
                  <div className="flex items-center gap-3">
                    <CheckCircle className="h-5 w-5 text-green-600" />
                    <span className="font-medium">Demandas Concluídas</span>
                  </div>
                  <span className="text-2xl font-bold text-green-600">{metricas.demandas.concluidas}</span>
                </div>

                <div className="flex items-center justify-between py-3 border-b">
                  <div className="flex items-center gap-3">
                    <Clock className="h-5 w-5 text-yellow-600" />
                    <span className="font-medium">Em Andamento</span>
                  </div>
                  <span className="text-2xl font-bold text-yellow-600">{metricas.demandas.em_andamento}</span>
                </div>

                <div className="flex items-center justify-between py-3 border-b">
                  <div className="flex items-center gap-3">
                    <FileText className="h-5 w-5 text-blue-600" />
                    <span className="font-medium">Abertas</span>
                  </div>
                  <span className="text-2xl font-bold text-blue-600">{metricas.demandas.abertas}</span>
                </div>

                <div className="flex items-center justify-between py-3">
                  <div className="flex items-center gap-3">
                    <XCircle className="h-5 w-5 text-red-600" />
                    <span className="font-medium">Canceladas</span>
                  </div>
                  <span className="text-2xl font-bold text-red-600">{metricas.demandas.canceladas}</span>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Tabela de Demandas Recentes */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <FileText className="h-5 w-5" />
              Demandas Recentes
            </CardTitle>
          </CardHeader>
          <CardContent>
            {dadosGraficos.demandasRecentes.length === 0 ? (
              <Alert variant="info">
                <AlertDescription>Nenhuma demanda cadastrada ainda.</AlertDescription>
              </Alert>
            ) : (
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Nome
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Status
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Data
                      </th>
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {dadosGraficos.demandasRecentes.map((demanda) => (
                      <tr key={demanda.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                          {demanda.nome}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm">
                          {getStatusBadge(demanda.status)}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {formatarData(demanda.created_at)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Informações do Sistema */}
        {isMaster() && (
          <Card>
            <CardHeader>
              <CardTitle>Informações do Sistema</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="text-center p-4 bg-gray-50 rounded-lg">
                  <p className="text-sm text-gray-600">Secretarias</p>
                  <p className="text-2xl font-bold text-gray-900">{metricas.secretarias.total}</p>
                </div>
                <div className="text-center p-4 bg-gray-50 rounded-lg">
                  <p className="text-sm text-gray-600">Tipos de Demanda</p>
                  <p className="text-2xl font-bold text-gray-900">{metricas.tipos.total}</p>
                </div>
                <div className="text-center p-4 bg-gray-50 rounded-lg">
                  <p className="text-sm text-gray-600">Níveis de Prioridade</p>
                  <p className="text-2xl font-bold text-gray-900">{metricas.prioridades.total}</p>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Mensagem para Master */}
        {isMaster() && (
          <Alert variant="info">
            <AlertTitle>👑 Acesso Master</AlertTitle>
            <AlertDescription>
              Você tem acesso completo ao sistema. Todas as funcionalidades de administração estão disponíveis.
            </AlertDescription>
          </Alert>
        )}

      </div>
    </div>
  )
}

export default Dashboard
