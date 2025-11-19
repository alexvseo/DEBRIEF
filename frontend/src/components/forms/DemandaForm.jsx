import React, { useState, useEffect } from 'react'
import { useForm, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'
import { toast } from 'sonner'
import { Calendar, Upload, X, FileText, Image as ImageIcon, Loader2, AlertCircle } from 'lucide-react'
import { format } from 'date-fns'
import { ptBR } from 'date-fns/locale'

// Componentes UI
import Button from '@/components/ui/button'
import Input from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Alert, AlertDescription } from '@/components/ui/alert'

// Services
import { demandaService } from '@/services/demandaService'

// Hooks
import { useAuth } from '@/hooks/useAuth'

/**
 * Schema de validação Zod
 * Define todas as regras de validação do formulário de demanda
 */
const demandaSchema = z.object({
  secretaria_id: z.string()
    .min(1, 'Selecione uma secretaria')
    .uuid('ID de secretaria inválido'),
  
  nome: z.string()
    .min(5, 'Nome deve ter pelo menos 5 caracteres')
    .max(200, 'Nome deve ter no máximo 200 caracteres')
    .trim(),
  
  tipo_demanda_id: z.string()
    .min(1, 'Selecione um tipo de demanda')
    .uuid('ID de tipo inválido'),
  
  prioridade_id: z.string()
    .min(1, 'Selecione uma prioridade')
    .uuid('ID de prioridade inválido'),
  
  descricao: z.string()
    .min(10, 'Descrição deve ter pelo menos 10 caracteres')
    .max(2000, 'Descrição deve ter no máximo 2000 caracteres')
    .trim(),
  
  prazo_final: z.string()
    .min(1, 'Selecione uma data')
    .refine(
      (date) => {
        const selectedDate = new Date(date)
        const today = new Date()
        today.setHours(0, 0, 0, 0)
        return selectedDate >= today
      },
      'Prazo deve ser hoje ou uma data futura'
    ),
})

/**
 * Componente de formulário para criar/editar demanda
 * 
 * @param {Object} demanda - Dados da demanda (para edição) ou null (para criação)
 * @param {Function} onSuccess - Callback executado após sucesso
 * @param {Function} onCancel - Callback para cancelar operação
 */
const DemandaForm = ({ demanda = null, onSuccess, onCancel }) => {
  const { user } = useAuth()
  
  // Estados
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [files, setFiles] = useState([])
  const [filePreviews, setFilePreviews] = useState([])
  const [isDragging, setIsDragging] = useState(false)
  
  // Estados para carregar dados dos dropdowns
  const [secretarias, setSecretarias] = useState([])
  const [tiposDemanda, setTiposDemanda] = useState([])
  const [prioridades, setPrioridades] = useState([])
  const [isLoadingData, setIsLoadingData] = useState(true)
  
  // Configurar React Hook Form com Zod
  const {
    register,
    handleSubmit,
    formState: { errors },
    setValue,
    watch,
    control,
    reset,
  } = useForm({
    resolver: zodResolver(demandaSchema),
    defaultValues: demanda ? {
      secretaria_id: demanda.secretaria_id || '',
      nome: demanda.nome || '',
      tipo_demanda_id: demanda.tipo_demanda_id || '',
      prioridade_id: demanda.prioridade_id || '',
      descricao: demanda.descricao || '',
      prazo_final: demanda.prazo_final || '',
    } : {
      secretaria_id: '',
      nome: '',
      tipo_demanda_id: '',
      prioridade_id: '',
      descricao: '',
      prazo_final: '',
    },
  })
  
  /**
   * Carregar dados dos dropdowns ao montar componente
   */
  useEffect(() => {
    const loadFormData = async () => {
      try {
        setIsLoadingData(true)
        
        // Carregar dados em paralelo
        const [secretariasData, tiposData, prioridadesData] = await Promise.all([
          demandaService.getSecretarias(),
          demandaService.getTipos(),
          demandaService.getPrioridades(),
        ])
        
        setSecretarias(secretariasData)
        setTiposDemanda(tiposData)
        setPrioridades(prioridadesData)
        
      } catch (error) {
        console.error('Erro ao carregar dados do formulário:', error)
        toast.error('Erro ao carregar dados. Recarregue a página.')
      } finally {
        setIsLoadingData(false)
      }
    }
    
    loadFormData()
  }, [])
  
  /**
   * Validar tipo e tamanho do arquivo
   */
  const validateFile = (file) => {
    const maxSize = 52428800 // 50MB
    const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png', 'image/jpg']
    const allowedExtensions = ['.pdf', '.jpg', '.jpeg', '.png']
    
    // Validar tamanho
    if (file.size > maxSize) {
      toast.error(`${file.name} é muito grande (máx 50MB)`)
      return false
    }
    
    // Validar tipo MIME
    if (!allowedTypes.includes(file.type)) {
      // Validar também por extensão como fallback
      const extension = '.' + file.name.split('.').pop().toLowerCase()
      if (!allowedExtensions.includes(extension)) {
        toast.error(`${file.name} tem tipo não permitido. Use PDF, JPG ou PNG`)
        return false
      }
    }
    
    return true
  }
  
  /**
   * Criar preview de imagem
   */
  const createPreview = (file) => {
    if (file.type.startsWith('image/')) {
      const reader = new FileReader()
      reader.onloadend = () => {
        setFilePreviews(prev => [...prev, {
          name: file.name,
          url: reader.result,
          type: 'image'
        }])
      }
      reader.readAsDataURL(file)
    } else {
      setFilePreviews(prev => [...prev, {
        name: file.name,
        url: null,
        type: 'pdf'
      }])
    }
  }
  
  /**
   * Handler de upload de arquivos
   * Valida tamanho e tipo antes de adicionar
   */
  const handleFileChange = (e) => {
    const selectedFiles = Array.from(e.target.files)
    processFiles(selectedFiles)
  }
  
  /**
   * Processar arquivos selecionados
   */
  const processFiles = (selectedFiles) => {
    // Validar cada arquivo
    const validFiles = selectedFiles.filter(file => validateFile(file))
    
    // Verificar limite de 5 arquivos
    const totalFiles = files.length + validFiles.length
    if (totalFiles > 5) {
      toast.error(`Máximo de 5 arquivos permitido. Você tentou adicionar ${validFiles.length} arquivo(s), mas só há espaço para ${5 - files.length}`)
      return
    }
    
    // Verificar duplicatas
    const newFiles = validFiles.filter(newFile => {
      const isDuplicate = files.some(existingFile => 
        existingFile.name === newFile.name && 
        existingFile.size === newFile.size
      )
      if (isDuplicate) {
        toast.warning(`${newFile.name} já foi adicionado`)
      }
      return !isDuplicate
    })
    
    if (newFiles.length > 0) {
      setFiles(prev => [...prev, ...newFiles])
      newFiles.forEach(file => createPreview(file))
      toast.success(`${newFiles.length} arquivo(s) adicionado(s)`)
    }
  }
  
  /**
   * Remover arquivo da lista
   */
  const removeFile = (index) => {
    setFiles(prev => prev.filter((_, i) => i !== index))
    setFilePreviews(prev => prev.filter((_, i) => i !== index))
    toast.info('Arquivo removido')
  }
  
  /**
   * Handlers para Drag and Drop
   */
  const handleDragEnter = (e) => {
    e.preventDefault()
    e.stopPropagation()
    setIsDragging(true)
  }
  
  const handleDragLeave = (e) => {
    e.preventDefault()
    e.stopPropagation()
    setIsDragging(false)
  }
  
  const handleDragOver = (e) => {
    e.preventDefault()
    e.stopPropagation()
  }
  
  const handleDrop = (e) => {
    e.preventDefault()
    e.stopPropagation()
    setIsDragging(false)
    
    const droppedFiles = Array.from(e.dataTransfer.files)
    processFiles(droppedFiles)
  }
  
  /**
   * Formatar tamanho do arquivo
   */
  const formatFileSize = (bytes) => {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
  }
  
  /**
   * Submeter formulário
   */
  const onSubmit = async (data) => {
    try {
      setIsSubmitting(true)
      
      // Criar FormData para enviar arquivos
      const formData = new FormData()
      
      // Adicionar dados do formulário
      formData.append('secretaria_id', data.secretaria_id)
      formData.append('nome', data.nome)
      formData.append('tipo_demanda_id', data.tipo_demanda_id)
      formData.append('prioridade_id', data.prioridade_id)
      formData.append('descricao', data.descricao)
      formData.append('prazo_final', data.prazo_final)
      
      // Adicionar ID do usuário
      if (user?.id) {
        formData.append('usuario_id', user.id)
      }
      
      // Adicionar arquivos
      files.forEach((file, index) => {
        formData.append('files', file)
      })
      
      // Enviar para API
      let result
      if (demanda) {
        // Editar demanda existente
        result = await demandaService.update(demanda.id, formData)
        toast.success('✅ Demanda atualizada com sucesso!')
      } else {
        // Criar nova demanda
        result = await demandaService.create(formData)
        toast.success('✅ Demanda criada com sucesso! Card criado no Trello e notificação enviada no WhatsApp.')
      }
      
      // Limpar formulário se for criação
      if (!demanda) {
        reset()
        setFiles([])
        setFilePreviews([])
      }
      
      // Callback de sucesso
      if (onSuccess) {
        onSuccess(result)
      }
      
    } catch (error) {
      console.error('Erro ao salvar demanda:', error)
      
      // Tratamento de erros específicos
      if (error.response?.status === 400) {
        toast.error('Dados inválidos. Verifique os campos e tente novamente.')
      } else if (error.response?.status === 401) {
        toast.error('Sessão expirada. Faça login novamente.')
      } else if (error.response?.status === 413) {
        toast.error('Arquivos muito grandes. Reduza o tamanho e tente novamente.')
      } else {
        toast.error(
          error.response?.data?.detail || 
          'Erro ao salvar demanda. Tente novamente.'
        )
      }
    } finally {
      setIsSubmitting(false)
    }
  }
  
  // Observar valor da descrição para contador
  const descricaoValue = watch('descricao') || ''
  
  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="text-2xl">
            {demanda ? '✏️ Editar Demanda' : '📝 Nova Demanda'}
          </CardTitle>
          <CardDescription>
            {demanda 
              ? 'Atualize as informações da sua demanda' 
              : 'Preencha os campos abaixo para criar uma nova demanda'
            }
          </CardDescription>
        </CardHeader>
        
        <CardContent className="space-y-6">
          
          {/* Loading state */}
          {isLoadingData && (
            <Alert>
              <Loader2 className="h-4 w-4 animate-spin" />
              <AlertDescription>
                Carregando dados do formulário...
              </AlertDescription>
            </Alert>
          )}
          
          {/* Grid de 2 colunas em telas grandes */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            
            {/* Secretaria */}
            <div>
              <label htmlFor="secretaria_id" className="block text-sm font-medium text-gray-700 mb-1">
                Secretaria <span className="text-red-500">*</span>
              </label>
              <select
                id="secretaria_id"
                {...register('secretaria_id')}
                disabled={isLoadingData}
                className={`w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed ${
                  errors.secretaria_id ? 'border-red-500' : 'border-gray-300'
                }`}
              >
                <option value="">Selecione uma secretaria...</option>
                {secretarias.map(sec => (
                  <option key={sec.id} value={sec.id}>
                    {sec.nome}
                  </option>
                ))}
              </select>
              {errors.secretaria_id && (
                <p className="mt-1 text-sm text-red-500 flex items-center">
                  <AlertCircle className="h-3 w-3 mr-1" />
                  {errors.secretaria_id.message}
                </p>
              )}
            </div>
            
            {/* Tipo de Demanda */}
            <div>
              <label htmlFor="tipo_demanda_id" className="block text-sm font-medium text-gray-700 mb-1">
                Tipo de Demanda <span className="text-red-500">*</span>
              </label>
              <select
                id="tipo_demanda_id"
                {...register('tipo_demanda_id')}
                disabled={isLoadingData}
                className={`w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed ${
                  errors.tipo_demanda_id ? 'border-red-500' : 'border-gray-300'
                }`}
              >
                <option value="">Selecione um tipo...</option>
                {tiposDemanda.map(tipo => (
                  <option key={tipo.id} value={tipo.id}>
                    {tipo.nome}
                  </option>
                ))}
              </select>
              {errors.tipo_demanda_id && (
                <p className="mt-1 text-sm text-red-500 flex items-center">
                  <AlertCircle className="h-3 w-3 mr-1" />
                  {errors.tipo_demanda_id.message}
                </p>
              )}
            </div>
            
            {/* Prioridade */}
            <div>
              <label htmlFor="prioridade_id" className="block text-sm font-medium text-gray-700 mb-1">
                Prioridade <span className="text-red-500">*</span>
              </label>
              <select
                id="prioridade_id"
                {...register('prioridade_id')}
                disabled={isLoadingData}
                className={`w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed ${
                  errors.prioridade_id ? 'border-red-500' : 'border-gray-300'
                }`}
              >
                <option value="">Selecione uma prioridade...</option>
                {prioridades.map(prioridade => (
                  <option key={prioridade.id} value={prioridade.id}>
                    {prioridade.nome}
                  </option>
                ))}
              </select>
              {errors.prioridade_id && (
                <p className="mt-1 text-sm text-red-500 flex items-center">
                  <AlertCircle className="h-3 w-3 mr-1" />
                  {errors.prioridade_id.message}
                </p>
              )}
            </div>
            
            {/* Prazo Final */}
            <div>
              <label htmlFor="prazo_final" className="block text-sm font-medium text-gray-700 mb-1">
                Prazo Final <span className="text-red-500">*</span>
              </label>
              <input
                id="prazo_final"
                type="date"
                {...register('prazo_final')}
                min={format(new Date(), 'yyyy-MM-dd')}
                className={`w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent ${
                  errors.prazo_final ? 'border-red-500' : 'border-gray-300'
                }`}
              />
              {errors.prazo_final && (
                <p className="mt-1 text-sm text-red-500 flex items-center">
                  <AlertCircle className="h-3 w-3 mr-1" />
                  {errors.prazo_final.message}
                </p>
              )}
            </div>
          </div>
          
          {/* Nome da Demanda (largura total) */}
          <div>
            <label htmlFor="nome" className="block text-sm font-medium text-gray-700 mb-1">
              Nome da Demanda <span className="text-red-500">*</span>
            </label>
            <input
              id="nome"
              type="text"
              {...register('nome')}
              placeholder="Ex: Criação de arte para campanha de vacinação"
              className={`w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent ${
                errors.nome ? 'border-red-500' : 'border-gray-300'
              }`}
            />
            {errors.nome && (
              <p className="mt-1 text-sm text-red-500 flex items-center">
                <AlertCircle className="h-3 w-3 mr-1" />
                {errors.nome.message}
              </p>
            )}
            <p className="text-xs text-gray-500 mt-1">
              {watch('nome')?.length || 0} / 200 caracteres
            </p>
          </div>
          
          {/* Descrição (largura total) */}
          <div>
            <label htmlFor="descricao" className="block text-sm font-medium text-gray-700 mb-1">
              Descrição Detalhada <span className="text-red-500">*</span>
            </label>
            <textarea
              id="descricao"
              {...register('descricao')}
              placeholder="Descreva detalhadamente sua demanda: objetivo, público-alvo, referências, informações importantes..."
              rows={6}
              className={`w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-y ${
                errors.descricao ? 'border-red-500' : 'border-gray-300'
              }`}
            />
            {errors.descricao && (
              <p className="mt-1 text-sm text-red-500 flex items-center">
                <AlertCircle className="h-3 w-3 mr-1" />
                {errors.descricao.message}
              </p>
            )}
            <div className="flex justify-between items-center mt-1">
              <p className="text-xs text-gray-500">
                Quanto mais detalhes, melhor será o resultado
              </p>
              <p className={`text-xs font-medium ${
                descricaoValue.length > 1900 ? 'text-orange-500' : 'text-gray-500'
              }`}>
                {descricaoValue.length} / 2000
              </p>
            </div>
          </div>
          
          {/* Upload de Arquivos */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Anexos (Opcional)
            </label>
            <p className="text-xs text-gray-500 mb-3">
              Adicione arquivos de referência, briefings, imagens, etc. Máximo 5 arquivos de 50MB cada.
            </p>
            
            {/* Input file oculto */}
            <input
              type="file"
              id="file-upload"
              multiple
              accept=".pdf,.jpg,.jpeg,.png"
              onChange={handleFileChange}
              className="hidden"
              disabled={files.length >= 5}
            />
            
            {/* Área de Drop customizada */}
            <div
              onDragEnter={handleDragEnter}
              onDragLeave={handleDragLeave}
              onDragOver={handleDragOver}
              onDrop={handleDrop}
              className={`relative border-2 border-dashed rounded-lg transition-all ${
                isDragging 
                  ? 'border-blue-500 bg-blue-50' 
                  : files.length >= 5
                  ? 'border-gray-200 bg-gray-50 opacity-50 cursor-not-allowed'
                  : 'border-gray-300 hover:border-blue-400 hover:bg-gray-50 cursor-pointer'
              }`}
            >
              <label
                htmlFor="file-upload"
                className={`flex items-center justify-center w-full p-8 ${
                  files.length >= 5 ? 'cursor-not-allowed' : 'cursor-pointer'
                }`}
              >
                <div className="text-center">
                  <Upload className={`mx-auto h-12 w-12 mb-3 ${
                    isDragging ? 'text-blue-500' : 'text-gray-400'
                  }`} />
                  <p className="text-sm text-gray-600 font-medium mb-1">
                    {files.length >= 5 
                      ? 'Limite de 5 arquivos atingido' 
                      : isDragging
                      ? 'Solte os arquivos aqui'
                      : 'Clique para selecionar ou arraste arquivos'
                    }
                  </p>
                  <p className="text-xs text-gray-500">
                    PDF, JPG, PNG • Máx 50MB cada
                  </p>
                </div>
              </label>
            </div>
            
            {/* Lista de arquivos selecionados com preview */}
            {files.length > 0 && (
              <div className="mt-4 space-y-3">
                <p className="text-sm font-medium text-gray-700">
                  Arquivos selecionados ({files.length}/5):
                </p>
                
                {files.map((file, index) => (
                  <div
                    key={index}
                    className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg border border-gray-200 hover:border-gray-300 transition-colors"
                  >
                    {/* Preview ou ícone */}
                    <div className="flex-shrink-0">
                      {filePreviews[index]?.type === 'image' ? (
                        <img
                          src={filePreviews[index].url}
                          alt={file.name}
                          className="h-12 w-12 object-cover rounded border border-gray-200"
                        />
                      ) : (
                        <div className="h-12 w-12 bg-red-100 rounded flex items-center justify-center">
                          <FileText className="h-6 w-6 text-red-600" />
                        </div>
                      )}
                    </div>
                    
                    {/* Info do arquivo */}
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-gray-900 truncate">
                        {file.name}
                      </p>
                      <p className="text-xs text-gray-500">
                        {formatFileSize(file.size)} • {file.type.split('/')[1].toUpperCase()}
                      </p>
                    </div>
                    
                    {/* Botão remover */}
                    <button
                      type="button"
                      onClick={() => removeFile(index)}
                      className="flex-shrink-0 p-2 text-red-500 hover:text-red-700 hover:bg-red-50 rounded-lg transition-colors"
                      title="Remover arquivo"
                    >
                      <X className="h-4 w-4" />
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
          
        </CardContent>
      </Card>
      
      {/* Botões de ação */}
      <div className="flex flex-col sm:flex-row justify-end gap-3">
        {onCancel && (
          <Button
            type="button"
            variant="outline"
            onClick={onCancel}
            disabled={isSubmitting}
            className="w-full sm:w-auto"
          >
            Cancelar
          </Button>
        )}
        
        <Button
          type="submit"
          disabled={isSubmitting || isLoadingData}
          className="w-full sm:w-auto min-w-[200px]"
        >
          {isSubmitting ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Salvando...
            </>
          ) : (
            <>
              {demanda ? '✏️ Atualizar Demanda' : '📝 Criar Demanda'}
            </>
          )}
        </Button>
      </div>
      
      {/* Informações adicionais */}
      <Alert className="bg-blue-50 border-blue-200">
        <AlertCircle className="h-4 w-4 text-blue-600" />
        <AlertDescription className="text-blue-800 text-sm">
          <strong>Importante:</strong> Ao criar a demanda, um card será automaticamente criado no Trello 
          e uma notificação será enviada no WhatsApp do seu grupo.
        </AlertDescription>
      </Alert>
    </form>
  )
}

DemandaForm.displayName = 'DemandaForm'

export default DemandaForm

