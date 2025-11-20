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
  MultiSelect,
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
  ResponsiveContainer,
  LineChart,
  Line
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
    secretaria_ids: [],  // Múltipla escolha
    tipo_demanda_ids: [],  // Múltipla escolha
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

    // Filtro múltiplo de secretarias
    if (filtros.secretaria_ids && filtros.secretaria_ids.length > 0) {
      filtered = filtered.filter(d => filtros.secretaria_ids.includes(d.secretaria_id))
    }

    // Filtro múltiplo de tipos de demanda
    if (filtros.tipo_demanda_ids && filtros.tipo_demanda_ids.length > 0) {
      filtered = filtered.filter(d => filtros.tipo_demanda_ids.includes(d.tipo_demanda_id))
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
      secretaria_ids: [],
      tipo_demanda_ids: [],
      prioridade_id: ''
    })
    setDemandasFiltradas(demandas)
    toast.info("Filtros limpos!")
  }

  const handleExportPDF = async () => {
    try {
      setGerando(true)
      toast.info("Gerando PDF...", { description: "Aguarde enquanto o relatório é gerado." })
      
      // Construir query params
      const params = new URLSearchParams()
      if (filtros.dataInicio) params.append('data_inicio', filtros.dataInicio)
      if (filtros.dataFim) params.append('data_fim', filtros.dataFim)
      if (filtros.status) params.append('status', filtros.status)
      if (filtros.cliente_id) params.append('cliente_id', filtros.cliente_id)
      if (filtros.secretaria_ids && filtros.secretaria_ids.length > 0) {
        filtros.secretaria_ids.forEach(id => params.append('secretaria_id', id))
      }
      if (filtros.tipo_demanda_ids && filtros.tipo_demanda_ids.length > 0) {
        filtros.tipo_demanda_ids.forEach(id => params.append('tipo_demanda_id', id))
      }
      
      // Fazer requisição e baixar arquivo
      const response = await api.get(`/relatorios/pdf?${params.toString()}`, {
        responseType: 'blob'
      })
      
      // Criar link para download
      const url = window.URL.createObjectURL(new Blob([response.data]))
      const link = document.createElement('a')
      link.href = url
      link.setAttribute('download', `relatorio_demandas_${new Date().toISOString().split('T')[0]}.pdf`)
      document.body.appendChild(link)
      link.click()
      link.remove()
      window.URL.revokeObjectURL(url)
      
      toast.success("PDF gerado com sucesso!")
    } catch (error) {
      console.error('Erro ao gerar PDF:', error)
      toast.error("Erro ao gerar PDF", { description: error.response?.data?.detail || "Tente novamente." })
    } finally {
      setGerando(false)
    }
  }

  const handleExportExcel = async () => {
    try {
      setGerando(true)
      toast.info("Gerando Excel...", { description: "Aguarde enquanto o relatório é gerado." })
      
      // Construir query params
      const params = new URLSearchParams()
      if (filtros.dataInicio) params.append('data_inicio', filtros.dataInicio)
      if (filtros.dataFim) params.append('data_fim', filtros.dataFim)
      if (filtros.status) params.append('status', filtros.status)
      if (filtros.cliente_id) params.append('cliente_id', filtros.cliente_id)
      if (filtros.secretaria_ids && filtros.secretaria_ids.length > 0) {
        filtros.secretaria_ids.forEach(id => params.append('secretaria_id', id))
      }
      if (filtros.tipo_demanda_ids && filtros.tipo_demanda_ids.length > 0) {
        filtros.tipo_demanda_ids.forEach(id => params.append('tipo_demanda_id', id))
      }
      
      // Fazer requisição e baixar arquivo
      const response = await api.get(`/relatorios/excel?${params.toString()}`, {
        responseType: 'blob'
      })
      
      // Criar link para download
      const url = window.URL.createObjectURL(new Blob([response.data]))
      const link = document.createElement('a')
      link.href = url
      link.setAttribute('download', `relatorio_demandas_${new Date().toISOString().split('T')[0]}.xlsx`)
      document.body.appendChild(link)
      link.click()
      link.remove()
      window.URL.revokeObjectURL(url)
      
      toast.success("Excel gerado com sucesso!")
    } catch (error) {
      console.error('Erro ao gerar Excel:', error)
      toast.error("Erro ao gerar Excel", { description: error.response?.data?.detail || "Tente novamente." })
    } finally {
      setGerando(false)
    }
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

  // Gráfico de evolução mensal (últimos 12 meses)
  const dadosEvolucaoMensal = () => {
    const meses = []
    const hoje = new Date()
    
    for (let i = 11; i >= 0; i--) {
      const data = new Date(hoje.getFullYear(), hoje.getMonth() - i, 1)
      const mesAno = data.toLocaleDateString('pt-BR', { month: 'short', year: 'numeric' })
      
      const inicioMes = new Date(data.getFullYear(), data.getMonth(), 1)
      const fimMes = new Date(data.getFullYear(), data.getMonth() + 1, 0)
      
      const count = demandasFiltradas.filter(d => {
        const dataCriacao = new Date(d.created_at)
        return dataCriacao >= inicioMes && dataCriacao <= fimMes
      }).length
      
      meses.push({
        mes: mesAno,
        quantidade: count
      })
    }
    
    return meses
  }

  // Calcular média de dias até conclusão
  const calcularMediaDiasConclusao = () => {
    const concluidas = demandasFiltradas.filter(d => 
      d.status === 'CONCLUIDA' && d.data_conclusao && d.created_at
    )
    
    if (concluidas.length === 0) return 0
    
    const totalDias = concluidas.reduce((acc, d) => {
      const inicio = new Date(d.created_at)
      const fim = new Date(d.data_conclusao)
      const dias = Math.ceil((fim - inicio) / (1000 * 60 * 60 * 24))
      return acc + dias
    }, 0)
    
    return Math.round(totalDias / concluidas.length)
  }

  // Calcular totais resumidos
  const calcularTotaisResumidos = () => {
    return {
      porTipo: tipos.map(tipo => ({
        tipo: tipo.nome,
        total: demandasFiltradas.filter(d => d.tipo_demanda_id === tipo.id).length
      })).filter(t => t.total > 0),
      porSecretaria: secretarias.map(secretaria => ({
        secretaria: secretaria.nome,
        total: demandasFiltradas.filter(d => d.secretaria_id === secretaria.id).length
      })).filter(s => s.total > 0),
      porStatus: {
        ABERTA: demandasFiltradas.filter(d => d.status === 'ABERTA').length,
        EM_ANDAMENTO: demandasFiltradas.filter(d => d.status === 'EM_ANDAMENTO').length,
        CONCLUIDA: demandasFiltradas.filter(d => d.status === 'CONCLUIDA').length,
        CANCELADA: demandasFiltradas.filter(d => d.status === 'CANCELADA').length
      },
      mediaDias: calcularMediaDiasConclusao()
    }
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
              <MultiSelect
                label="Secretaria"
                value={filtros.secretaria_ids || []}
                onChange={(values) => setFiltros({ ...filtros, secretaria_ids: values })}
                options={secretarias.map(s => ({ value: s.id, label: s.nome }))}
                placeholder="Selecione secretarias..."
              />
              <MultiSelect
                label="Tipo de Demanda"
                value={filtros.tipo_demanda_ids || []}
                onChange={(values) => setFiltros({ ...filtros, tipo_demanda_ids: values })}
                options={tipos.map(t => ({ value: t.id, label: t.nome }))}
                placeholder="Selecione tipos..."
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

        {/* Tabela Resumida */}
        <Card>
          <CardHeader>
            <CardTitle>Tabela Resumida</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              {/* Total por Tipo */}
              <div>
                <h3 className="text-sm font-semibold text-gray-700 mb-3">Total por Tipo de Demanda</h3>
                <div className="space-y-2">
                  {calcularTotaisResumidos().porTipo.length > 0 ? (
                    calcularTotaisResumidos().porTipo.map((item, idx) => (
                      <div key={idx} className="flex justify-between items-center py-2 border-b">
                        <span className="text-sm text-gray-600">{item.tipo}</span>
                        <Badge variant="secondary">{item.total}</Badge>
                      </div>
                    ))
                  ) : (
                    <p className="text-sm text-gray-500">Nenhum dado disponível</p>
                  )}
                </div>
              </div>

              {/* Total por Secretaria */}
              <div>
                <h3 className="text-sm font-semibold text-gray-700 mb-3">Total por Secretaria</h3>
                <div className="space-y-2">
                  {calcularTotaisResumidos().porSecretaria.length > 0 ? (
                    calcularTotaisResumidos().porSecretaria.map((item, idx) => (
                      <div key={idx} className="flex justify-between items-center py-2 border-b">
                        <span className="text-sm text-gray-600">{item.secretaria}</span>
                        <Badge variant="secondary">{item.total}</Badge>
                      </div>
                    ))
                  ) : (
                    <p className="text-sm text-gray-500">Nenhum dado disponível</p>
                  )}
                </div>
              </div>

              {/* Total por Status */}
              <div>
                <h3 className="text-sm font-semibold text-gray-700 mb-3">Total por Status</h3>
                <div className="space-y-2">
                  {Object.entries(calcularTotaisResumidos().porStatus).map(([status, total]) => (
                    <div key={status} className="flex justify-between items-center py-2 border-b">
                      <span className="text-sm text-gray-600">{status.replace('_', ' ')}</span>
                      <Badge variant="secondary">{total}</Badge>
                    </div>
                  ))}
                </div>
              </div>

              {/* Média de Dias */}
              <div>
                <h3 className="text-sm font-semibold text-gray-700 mb-3">Média de Dias até Conclusão</h3>
                <div className="py-2">
                  <div className="text-3xl font-bold text-blue-600">
                    {calcularTotaisResumidos().mediaDias}
                  </div>
                  <p className="text-sm text-gray-500 mt-1">dias</p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Gráficos */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card>
            <CardHeader>
              <CardTitle>Distribuição por Tipo</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <PieChart>
                  <Pie
                    data={dadosGraficoTipo()}
                    cx="50%"
                    cy="50%"
                    labelLine={false}
                    label={({ name, value }) => `${name}: ${value}`}
                    outerRadius={80}
                    fill="#8884d8"
                    dataKey="quantidade"
                  >
                    {dadosGraficoTipo().map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.fill || '#8884d8'} />
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
              <CardTitle>Evolução Mensal</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={dadosEvolucaoMensal()}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="mes" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="quantidade" fill="#3B82F6" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </div>

        {/* Gráfico de Linhas - Tendência */}
        <Card>
          <CardHeader>
            <CardTitle>Tendência de Abertura de Demandas</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={dadosEvolucaoMensal()}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="mes" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line 
                  type="monotone" 
                  dataKey="quantidade" 
                  stroke="#3B82F6" 
                  strokeWidth={2}
                  name="Demandas Abertas"
                />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

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

