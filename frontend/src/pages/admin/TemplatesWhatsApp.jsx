/**
 * Página de Gerenciamento de Templates WhatsApp
 * Editor de templates com preview em tempo real
 */
import React, { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ArrowLeft,
  Save,
  Plus,
  Edit,
  Trash2,
  Eye,
  MessageSquare,
  Loader2,
  CheckCircle,
  XCircle,
  AlertTriangle,
  Copy,
  FileText,
  Sparkles
} from 'lucide-react'
import {
  Button,
  Card,
  CardHeader,
  CardTitle,
  CardContent,
  Input,
  Alert,
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
import { toast } from 'sonner'

const TemplatesWhatsApp = () => {
  const navigate = useNavigate()
  const { isMaster } = useAuth()
  
  const [loading, setLoading] = useState(true)
  const [templates, setTemplates] = useState([])
  const [variaveisDisponiveis, setVariaveisDisponiveis] = useState({})
  const [modalAberto, setModalAberto] = useState(false)
  const [templateSelecionado, setTemplateTemplateSelect] = useState(null)
  const [salvando, setSalvando] = useState(false)
  const [previewAtivo, setPreviewAtivo] = useState(false)
  const [previewResultado, setPreviewResultado] = useState(null)
  
  const [formData, setFormData] = useState({
    nome: '',
    tipo_evento: 'demanda_criada',
    mensagem: '',
    ativo: true
  })
  
  const tiposEvento = [
    { value: 'demanda_criada', label: 'Demanda Criada' },
    { value: 'demanda_atualizada', label: 'Demanda Atualizada' },
    { value: 'demanda_concluida', label: 'Demanda Concluída' },
    { value: 'demanda_cancelada', label: 'Demanda Cancelada' }
  ]
  
  // Verificar permissão
  useEffect(() => {
    if (!isMaster()) {
      navigate('/dashboard')
    }
  }, [isMaster, navigate])
  
  // Carregar templates e variáveis
  useEffect(() => {
    carregarDados()
  }, [])
  
  const carregarDados = async () => {
    try {
      setLoading(true)
      await Promise.all([
        carregarTemplates(),
        carregarVariaveis()
      ])
    } finally {
      setLoading(false)
    }
  }
  
  const carregarTemplates = async () => {
    try {
      const response = await api.get('/whatsapp/templates')
      setTemplates(response.data || [])
    } catch (error) {
      console.error('Erro ao carregar templates:', error)
      toast.error('Erro ao carregar templates')
    }
  }
  
  const carregarVariaveis = async () => {
    try {
      const response = await api.get('/whatsapp/templates/variaveis/disponiveis')
      setVariaveisDisponiveis(response.data?.variaveis || {})
    } catch (error) {
      console.error('Erro ao carregar variáveis:', error)
    }
  }
  
  const abrirModal = (template = null) => {
    if (template) {
      setTemplateTemplateSelect(template)
      setFormData({
        nome: template.nome,
        tipo_evento: template.tipo_evento,
        mensagem: template.mensagem,
        ativo: template.ativo
      })
    } else {
      setTemplateTemplateSelect(null)
      setFormData({
        nome: '',
        tipo_evento: 'demanda_criada',
        mensagem: '',
        ativo: true
      })
    }
    setModalAberto(true)
    setPreviewAtivo(false)
    setPreviewResultado(null)
  }
  
  const fecharModal = () => {
    setModalAberto(false)
    setTemplateTemplateSelect(null)
    setFormData({
      nome: '',
      tipo_evento: 'demanda_criada',
      mensagem: '',
      ativo: true
    })
    setPreviewAtivo(false)
    setPreviewResultado(null)
  }
  
  const handleChange = (field, value) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }))
    
    // Atualizar preview em tempo real
    if (field === 'mensagem' && previewAtivo) {
      gerarPreview(value)
    }
  }
  
  const inserirVariavel = (variavel) => {
    const placeholder = `{${variavel}}`
    const textarea = document.getElementById('mensagem-template')
    const start = textarea.selectionStart
    const end = textarea.selectionEnd
    const text = formData.mensagem
    const before = text.substring(0, start)
    const after = text.substring(end)
    
    setFormData(prev => ({
      ...prev,
      mensagem: before + placeholder + after
    }))
    
    // Reposicionar cursor
    setTimeout(() => {
      textarea.focus()
      textarea.setSelectionRange(start + placeholder.length, start + placeholder.length)
    }, 0)
  }
  
  const gerarPreview = async (mensagem = formData.mensagem) => {
    if (!mensagem.trim()) {
      setPreviewResultado(null)
      return
    }
    
    try {
      const response = await api.post('/whatsapp/templates/preview', {
        mensagem,
        dados_exemplo: null // Usa dados de exemplo padrão
      })
      
      setPreviewResultado(response.data)
    } catch (error) {
      console.error('Erro ao gerar preview:', error)
      setPreviewResultado(null)
    }
  }
  
  const togglePreview = () => {
    const novoEstado = !previewAtivo
    setPreviewAtivo(novoEstado)
    
    if (novoEstado) {
      gerarPreview()
    } else {
      setPreviewResultado(null)
    }
  }
  
  const validarFormulario = () => {
    if (!formData.nome.trim()) {
      toast.error('Nome do template é obrigatório')
      return false
    }
    
    if (formData.nome.length < 3) {
      toast.error('Nome deve ter pelo menos 3 caracteres')
      return false
    }
    
    if (!formData.mensagem.trim()) {
      toast.error('Mensagem do template é obrigatória')
      return false
    }
    
    if (formData.mensagem.length < 10) {
      toast.error('Mensagem deve ter pelo menos 10 caracteres')
      return false
    }
    
    return true
  }
  
  const salvarTemplate = async () => {
    if (!validarFormulario()) return
    
    try {
      setSalvando(true)
      
      if (templateSelecionado) {
        // Atualizar existente
        await api.put(`/whatsapp/templates/${templateSelecionado.id}`, formData)
        toast.success('Template atualizado com sucesso!')
      } else {
        // Criar novo
        await api.post('/whatsapp/templates', formData)
        toast.success('Template criado com sucesso!')
      }
      
      await carregarTemplates()
      fecharModal()
    } catch (error) {
      console.error('Erro ao salvar template:', error)
      toast.error(error.response?.data?.detail || 'Erro ao salvar template')
    } finally {
      setSalvando(false)
    }
  }
  
  const deletarTemplate = async (template) => {
    if (!window.confirm(`Tem certeza que deseja deletar o template "${template.nome}"?`)) {
      return
    }
    
    try {
      await api.delete(`/whatsapp/templates/${template.id}`)
      toast.success('Template deletado com sucesso!')
      await carregarTemplates()
    } catch (error) {
      console.error('Erro ao deletar template:', error)
      toast.error('Erro ao deletar template')
    }
  }
  
  const copiarTemplate = (mensagem) => {
    navigator.clipboard.writeText(mensagem)
    toast.success('Mensagem copiada!')
  }
  
  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="h-8 w-8 animate-spin mx-auto text-primary" />
          <p className="mt-2 text-gray-600">Carregando templates...</p>
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
            <Button variant="ghost" onClick={() => navigate('/admin/configuracao-whatsapp')}>
              <ArrowLeft className="h-4 w-4 mr-2" />
              Voltar
            </Button>
            <div>
              <h1 className="text-3xl font-bold text-gray-900 flex items-center gap-2">
                <FileText className="h-8 w-8 text-purple-600" />
                Templates de Mensagens
              </h1>
              <p className="text-gray-600 mt-1">
                Crie e edite templates personalizados com variáveis dinâmicas
              </p>
            </div>
          </div>
          
          <Button onClick={() => abrirModal()}>
            <Plus className="h-4 w-4 mr-2" />
            Novo Template
          </Button>
        </div>
        
        {/* Lista de Templates */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {templates.length === 0 ? (
            <Card className="col-span-2">
              <CardContent className="py-12 text-center">
                <MessageSquare className="h-12 w-12 mx-auto text-gray-400 mb-4" />
                <h3 className="text-lg font-semibold text-gray-900 mb-2">
                  Nenhum template cadastrado
                </h3>
                <p className="text-gray-600 mb-4">
                  Crie seu primeiro template de mensagem WhatsApp
                </p>
                <Button onClick={() => abrirModal()}>
                  <Plus className="h-4 w-4 mr-2" />
                  Criar Primeiro Template
                </Button>
              </CardContent>
            </Card>
          ) : (
            templates.map(template => (
              <Card key={template.id} className="hover:shadow-md transition-shadow">
                <CardHeader>
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <CardTitle className="flex items-center gap-2">
                        {template.nome}
                        <Badge variant={template.ativo ? "success" : "secondary"}>
                          {template.ativo ? 'Ativo' : 'Inativo'}
                        </Badge>
                      </CardTitle>
                      <p className="text-sm text-gray-600 mt-1">
                        {tiposEvento.find(t => t.value === template.tipo_evento)?.label}
                      </p>
                    </div>
                  </div>
                </CardHeader>
                
                <CardContent>
                  <div className="space-y-4">
                    {/* Preview da Mensagem */}
                    <div className="bg-gray-50 rounded-lg p-3 border border-gray-200">
                      <pre className="text-sm text-gray-700 whitespace-pre-wrap font-sans">
                        {template.mensagem.length > 150 
                          ? template.mensagem.substring(0, 150) + '...'
                          : template.mensagem
                        }
                      </pre>
                    </div>
                    
                    {/* Ações */}
                    <div className="flex gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => abrirModal(template)}
                        className="flex-1"
                      >
                        <Edit className="h-4 w-4 mr-1" />
                        Editar
                      </Button>
                      
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => copiarTemplate(template.mensagem)}
                      >
                        <Copy className="h-4 w-4" />
                      </Button>
                      
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => deletarTemplate(template)}
                        className="text-red-600 hover:text-red-700 hover:bg-red-50"
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))
          )}
        </div>
        
        {/* Modal de Criar/Editar */}
        <Dialog open={modalAberto} onOpenChange={fecharModal}>
          <DialogContent className="max-w-5xl max-h-[90vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>
                {templateSelecionado ? 'Editar Template' : 'Novo Template'}
              </DialogTitle>
            </DialogHeader>
            
            <DialogBody>
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Coluna Esquerda - Editor */}
                <div className="space-y-4">
                  <div>
                    <label className="text-sm font-medium text-gray-700 mb-1 block">
                      Nome do Template *
                    </label>
                    <Input
                      value={formData.nome}
                      onChange={(e) => handleChange('nome', e.target.value)}
                      placeholder="Ex: Nova Demanda"
                    />
                  </div>
                  
                  <div>
                    <label className="text-sm font-medium text-gray-700 mb-1 block">
                      Tipo de Evento *
                    </label>
                    <select
                      value={formData.tipo_evento}
                      onChange={(e) => handleChange('tipo_evento', e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary focus:border-transparent"
                    >
                      {tiposEvento.map(tipo => (
                        <option key={tipo.value} value={tipo.value}>
                          {tipo.label}
                        </option>
                      ))}
                    </select>
                  </div>
                  
                  <div>
                    <label className="text-sm font-medium text-gray-700 mb-1 block">
                      Mensagem do Template *
                    </label>
                    <textarea
                      id="mensagem-template"
                      value={formData.mensagem}
                      onChange={(e) => handleChange('mensagem', e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary focus:border-transparent font-mono text-sm"
                      rows={12}
                      placeholder="Digite a mensagem do template..."
                    />
                    <p className="text-xs text-gray-500 mt-1">
                      Use {'{variavel}'} para inserir dados dinâmicos
                    </p>
                  </div>
                  
                  <div className="flex items-center gap-3">
                    <input
                      type="checkbox"
                      id="template-ativo"
                      checked={formData.ativo}
                      onChange={(e) => handleChange('ativo', e.target.checked)}
                      className="w-4 h-4 text-primary border-gray-300 rounded focus:ring-primary"
                    />
                    <label htmlFor="template-ativo" className="text-sm font-medium text-gray-700">
                      Template ativo
                    </label>
                  </div>
                </div>
                
                {/* Coluna Direita - Variáveis e Preview */}
                <div className="space-y-4">
                  {/* Variáveis Disponíveis */}
                  <Card>
                    <CardHeader>
                      <CardTitle className="text-sm flex items-center gap-2">
                        <Sparkles className="h-4 w-4" />
                        Variáveis Disponíveis
                      </CardTitle>
                    </CardHeader>
                    <CardContent>
                      <div className="grid grid-cols-2 gap-2 max-h-60 overflow-y-auto">
                        {Object.entries(variaveisDisponiveis).map(([chave, descricao]) => (
                          <button
                            key={chave}
                            onClick={() => inserirVariavel(chave)}
                            className="text-left px-2 py-1.5 text-xs bg-blue-50 hover:bg-blue-100 border border-blue-200 rounded transition-colors"
                            title={descricao}
                          >
                            <code className="text-blue-700">{`{${chave}}`}</code>
                          </button>
                        ))}
                      </div>
                    </CardContent>
                  </Card>
                  
                  {/* Preview */}
                  <Card>
                    <CardHeader>
                      <div className="flex items-center justify-between">
                        <CardTitle className="text-sm flex items-center gap-2">
                          <Eye className="h-4 w-4" />
                          Preview
                        </CardTitle>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={togglePreview}
                        >
                          {previewAtivo ? 'Ocultar' : 'Mostrar'} Preview
                        </Button>
                      </div>
                    </CardHeader>
                    <CardContent>
                      {previewAtivo && previewResultado ? (
                        <div className="space-y-3">
                          {/* Mensagem Renderizada */}
                          <div className="bg-green-50 border border-green-200 rounded-lg p-3">
                            <p className="text-xs text-green-700 font-medium mb-2">
                              Mensagem Final:
                            </p>
                            <pre className="text-sm text-gray-800 whitespace-pre-wrap font-sans">
                              {previewResultado.mensagem_renderizada}
                            </pre>
                          </div>
                          
                          {/* Variáveis Não Substituídas */}
                          {previewResultado.variaveis_nao_substituidas.length > 0 && (
                            <Alert variant="warning">
                              <AlertTriangle className="h-4 w-4" />
                              <AlertDescription>
                                <strong>Variáveis não encontradas:</strong>
                                {' '}
                                {previewResultado.variaveis_nao_substituidas.join(', ')}
                              </AlertDescription>
                            </Alert>
                          )}
                        </div>
                      ) : (
                        <p className="text-sm text-gray-500 text-center py-4">
                          Clique em "Mostrar Preview" para visualizar
                        </p>
                      )}
                    </CardContent>
                  </Card>
                </div>
              </div>
            </DialogBody>
            
            <DialogFooter>
              <Button variant="ghost" onClick={fecharModal}>
                Cancelar
              </Button>
              <Button onClick={salvarTemplate} disabled={salvando}>
                {salvando ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    Salvando...
                  </>
                ) : (
                  <>
                    <Save className="h-4 w-4 mr-2" />
                    {templateSelecionado ? 'Atualizar' : 'Criar'} Template
                  </>
                )}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>
    </div>
  )
}

export default TemplatesWhatsApp

