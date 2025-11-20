import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ArrowLeft,
  FileText,
  Download,
  Filter,
  RefreshCw,
  Loader2,
  Calendar,
  FileDown
} from 'lucide-react'
import {
  Button,
  Card,
  CardHeader,
  CardTitle,
  CardContent,
  Badge,
  Input,
  Select,
  Alert,
  AlertDescription
} from '@/components/ui'
import { useAuth } from '@/hooks/useAuth'
import api from '@/services/api'
import { toast } from 'sonner'
import {
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer
} from 'recharts'

const Relatorios = () => {
  const navigate = useNavigate()
  const { isMaster } = useAuth()
  
  // Estados
  const [loading, setLoading] = useState(true)
  const [gerando, setGerando] = useState(false)
  const [demandas, setDemandas] = useState([])
  const [demandasFiltradas, setDemandasFiltradas] = useState([])
  
  // Opções para filtros
  const [clientes, setClientes] = useState([])
  const [secretarias, setSecretarias] = useState([])
  const [tipos, setTipos] = useState([])
  const [prioridades, setPrioridades] = useState([])
  
  // Filtros
  const [filtros, setFiltros] = useState({
    dataInicio: '',
    dataFim: '',
    status: '',
    cliente_id: '',
    secretaria_id: '',
    tipo_demanda_id: '',
    prioridade_id: ''
  })

  useEffect(() => {
    if (!isMaster()) {
      navigate('/dashboard')
      toast.error("Acesso negado", { description: "Apenas usuários master podem acessar relatórios." })
    } else {
      carregarDados()
    }
  }, [isMaster, navigate])

  const carregarDados = async () => {
    try {
      setLoading(true)
      const [demandasRes, clientesRes, secretariasRes, tiposRes, prioridadesRes] = await Promise.all([
        api.get('/demandas'),
        api.get('/clientes/'),
        api.get('/secretarias/'),
        api.get('/tipos-demanda/'),
        api.get('/prioridades/')
      ])

      setDemandas(demandasRes.data)
      setDemandasFiltradas(demandasRes.data)
      setClientes(clientesRes.data)
      setSecretarias(secretariasRes.data)
      setTipos(tiposRes.data)
      setPrioridades(prioridadesRes.data)
    } catch (error) {
      console.error('Erro ao carregar dados:', error)
      toast.error("Erro ao carregar dados", { description: error.response?.data?.detail || "Tente novamente." })
    } finally {
      setLoading(false)
    }
  }

  const aplicarFiltros = () => {
    let filtered = [...demandas]

    if (filtros.dataInicio) {
      filtered = filtered.filter(d => new Date(d.created_at) >= new Date(filtros.dataInicio))
    }

    if (filtros.dataFim) {
      filtered = filtered.filter(d => new Date(d.created_at) <= new Date(filtros.dataFim))
    }

    if (filtros.status) {
      filtered = filtered.filter(d => d.status === filtros.status)
    }

    if (filtros.cliente_id) {
      filtered = filtered.filter(d => d.cliente_id === filtros.cliente_id)
    }

    if (filtros.secretaria_id) {
      filtered = filtered.filter(d => d.secretaria_id === filtros.secretaria_id)
    }

    if (filtros.tipo_demanda_id) {
      filtered = filtered.filter(d => d.tipo_demanda_id === filtros.tipo_demanda_id)
    }

    if (filtros.prioridade_id) {
      filtered = filtered.filter(d => d.prioridade_id === filtros.prioridade_id)
    }

    setDemandasFiltradas(filtered)
    toast.success(`Filtros aplicados! ${filtered.length} demanda(s) encontrada(s).`)
  }

  const limparFiltros = () => {
    setFiltros({
      dataInicio: '',
      dataFim: '',
      status: '',
      cliente_id: '',
      secretaria_id: '',
      tipo_demanda_id: '',
      prioridade_id: ''
    })
    setDemandasFiltradas(demandas)
    toast.info("Filtros limpos!")
  }

  const handleExportPDF = () => {
    setGerando(true)
    toast.info("Exportação PDF", { description: "Esta funcionalidade será implementada em breve!" })
    setTimeout(() => setGerando(false), 1500)
  }

  const handleExportExcel = () => {
    setGerando(true)
    toast.info("Exportação Excel", { description: "Esta funcionalidade será implementada em breve!" })
    setTimeout(() => setGerando(false), 1500)
  }

  const calcularEstatisticas = () => {
    return {
      total: demandasFiltradas.length,
      abertas: demandasFiltradas.filter(d => d.status === 'ABERTA').length,
      em_andamento: demandasFiltradas.filter(d => d.status === 'EM_ANDAMENTO').length,
      concluidas: demandasFiltradas.filter(d => d.status === 'CONCLUIDA').length,
      canceladas: demandasFiltradas.filter(d => d.status === 'CANCELADA').length
    }
  }

  const dadosGraficoStatus = () => {
    const stats = calcularEstatisticas()
    return [
      { name: 'Abertas', value: stats.abertas, color: '#3B82F6' },
      { name: 'Em Andamento', value: stats.em_andamento, color: '#F59E0B' },
      { name: 'Concluídas', value: stats.concluidas, color: '#10B981' },
      { name: 'Canceladas', value: stats.canceladas, color: '#EF4444' }
    ]
  }

  const dadosGraficoTipo = () => {
    return tipos.map(tipo => ({
      name: tipo.nome,
      quantidade: demandasFiltradas.filter(d => d.tipo_demanda_id === tipo.id).length,
      fill: tipo.cor
    })).filter(d => d.quantidade > 0)
  }

  const getStatusBadge = (status) => {
    const statusMap = {
      'ABERTA': { variant: 'default', label: 'Aberta' },
      'EM_ANDAMENTO': { variant: 'warning', label: 'Em Andamento' },
      'CONCLUIDA': { variant: 'success', label: 'Concluída' },
      'CANCELADA': { variant: 'error', label: 'Cancelada' }
    }
    const s = statusMap[status] || statusMap['ABERTA']
    return <Badge variant={s.variant}>{s.label}</Badge>
  }

  const formatarData = (data) => {
    return new Date(data).toLocaleDateString('pt-BR')
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <Loader2 className="h-12 w-12 animate-spin text-blue-500" />
      </div>
    )
  }

  const stats = calcularEstatisticas()

  return (
    <div className="min-h-screen bg-gray-50 py-8 px-4">
      <div className="max-w-7xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <Button variant="ghost" onClick={() => navigate('/dashboard')}>
              <ArrowLeft className="h-4 w-4 mr-2" />
              Voltar
            </Button>
            <h1 className="text-3xl font-bold text-gray-900 mt-2">Relatórios</h1>
            <p className="text-gray-600">Análise e exportação de demandas</p>
          </div>
          <div className="flex gap-2">
            <Button variant="outline" onClick={handleExportPDF} disabled={gerando}>
              <FileDown className="h-4 w-4 mr-2" />
              PDF
            </Button>
            <Button variant="outline" onClick={handleExportExcel} disabled={gerando}>
              <Download className="h-4 w-4 mr-2" />
              Excel
            </Button>
          </div>
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
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              <Input
                label="Data Início"
                type="date"
                value={filtros.dataInicio}
                onChange={(e) => setFiltros({ ...filtros, dataInicio: e.target.value })}
              />
              <Input
                label="Data Fim"
                type="date"
                value={filtros.dataFim}
                onChange={(e) => setFiltros({ ...filtros, dataFim: e.target.value })}
              />
              <Select
                label="Status"
                value={filtros.status}
                onChange={(e) => setFiltros({ ...filtros, status: e.target.value })}
                options={[
                  { value: '', label: 'Todos' },
                  { value: 'ABERTA', label: 'Aberta' },
                  { value: 'EM_ANDAMENTO', label: 'Em Andamento' },
                  { value: 'CONCLUIDA', label: 'Concluída' },
                  { value: 'CANCELADA', label: 'Cancelada' }
                ]}
              />
              <Select
                label="Cliente"
                value={filtros.cliente_id}
                onChange={(e) => setFiltros({ ...filtros, cliente_id: e.target.value })}
                options={[
                  { value: '', label: 'Todos' },
                  ...clientes.map(c => ({ value: c.id, label: c.nome }))
                ]}
              />
              <Select
                label="Secretaria"
                value={filtros.secretaria_id}
                onChange={(e) => setFiltros({ ...filtros, secretaria_id: e.target.value })}
                options={[
                  { value: '', label: 'Todas' },
                  ...secretarias.map(s => ({ value: s.id, label: s.nome }))
                ]}
              />
              <Select
                label="Tipo"
                value={filtros.tipo_demanda_id}
                onChange={(e) => setFiltros({ ...filtros, tipo_demanda_id: e.target.value })}
                options={[
                  { value: '', label: 'Todos' },
                  ...tipos.map(t => ({ value: t.id, label: t.nome }))
                ]}
              />
              <Select
                label="Prioridade"
                value={filtros.prioridade_id}
                onChange={(e) => setFiltros({ ...filtros, prioridade_id: e.target.value })}
                options={[
                  { value: '', label: 'Todas' },
                  ...prioridades.map(p => ({ value: p.id, label: p.nome }))
                ]}
              />
            </div>
            <div className="flex gap-2 mt-4">
              <Button onClick={aplicarFiltros}>
                <Filter className="h-4 w-4 mr-2" />
                Aplicar Filtros
              </Button>
              <Button variant="outline" onClick={limparFiltros}>
                <RefreshCw className="h-4 w-4 mr-2" />
                Limpar
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Estatísticas */}
        <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
          <Card>
            <CardContent className="pt-6">
              <p className="text-sm text-gray-600">Total</p>
              <h3 className="text-3xl font-bold text-gray-900">{stats.total}</h3>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-6">
              <p className="text-sm text-gray-600">Abertas</p>
              <h3 className="text-3xl font-bold text-blue-600">{stats.abertas}</h3>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-6">
              <p className="text-sm text-gray-600">Em Andamento</p>
              <h3 className="text-3xl font-bold text-yellow-600">{stats.em_andamento}</h3>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-6">
              <p className="text-sm text-gray-600">Concluídas</p>
              <h3 className="text-3xl font-bold text-green-600">{stats.concluidas}</h3>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-6">
              <p className="text-sm text-gray-600">Canceladas</p>
              <h3 className="text-3xl font-bold text-red-600">{stats.canceladas}</h3>
            </CardContent>
          </Card>
        </div>

        {/* Gráficos */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card>
            <CardHeader>
              <CardTitle>Demandas por Status</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <PieChart>
                  <Pie
                    data={dadosGraficoStatus()}
                    cx="50%"
                    cy="50%"
                    labelLine={false}
                    label={({ name, value }) => `${name}: ${value}`}
                    outerRadius={80}
                    fill="#8884d8"
                    dataKey="value"
                  >
                    {dadosGraficoStatus().map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip />
                  <Legend />
                </PieChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Demandas por Tipo</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={dadosGraficoTipo()}>
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
        </div>

        {/* Tabela de Resultados */}
        <Card>
          <CardHeader>
            <CardTitle>
              Resultados ({demandasFiltradas.length} demanda{demandasFiltradas.length !== 1 && 's'})
            </CardTitle>
          </CardHeader>
          <CardContent>
            {demandasFiltradas.length === 0 ? (
              <Alert variant="info">
                <AlertDescription>Nenhuma demanda encontrada com os filtros aplicados.</AlertDescription>
              </Alert>
            ) : (
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Nome</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Data</th>
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {demandasFiltradas.slice(0, 50).map((demanda) => (
                      <tr key={demanda.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4 text-sm font-medium text-gray-900">{demanda.nome}</td>
                        <td className="px-6 py-4 text-sm">{getStatusBadge(demanda.status)}</td>
                        <td className="px-6 py-4 text-sm text-gray-500">{formatarData(demanda.created_at)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                {demandasFiltradas.length > 50 && (
                  <p className="text-sm text-gray-500 text-center mt-4">
                    Mostrando 50 de {demandasFiltradas.length} resultados. Use a exportação para ver todos.
                  </p>
                )}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

export default Relatorios

