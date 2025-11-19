import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ArrowLeft,
  Plus,
  Edit,
  AlertTriangle,
  RefreshCw,
  Loader2,
  Palette
} from 'lucide-react'
import {
  Button,
  Card,
  CardHeader,
  CardTitle,
  CardContent,
  Badge,
  Input,
  Alert,
  AlertDescription,
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogBody,
  DialogFooter,
  Select,
  Textarea
} from '@/components/ui'
import { useAuth } from '@/hooks/useAuth'
import api from '@/services/api'
import { toast } from 'sonner'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import { zodResolver } from '@hookform/resolvers/zod'
import { HexColorPicker } from 'react-colorful'

// Esquema de validação para criar/editar prioridade
const prioridadeSchema = z.object({
  nome: z.string().min(3, "Nome deve ter no mínimo 3 caracteres"),
  nivel: z.coerce.number().int().min(1, "Nível mínimo é 1").max(10, "Nível máximo é 10"),
  cor: z.string().regex(/^#[0-9A-Fa-f]{6}$/, "Cor deve estar no formato #RRGGBB"),
})

const GerenciarPrioridades = () => {
  const navigate = useNavigate()
  const { isMaster } = useAuth()
  const [prioridades, setPrioridades] = useState([])
  const [loading, setLoading] = useState(true)
  const [openModal, setOpenModal] = useState(false)
  const [editingPrioridade, setEditingPrioridade] = useState(null)
  const [successMessage, setSuccessMessage] = useState('')
  const [showColorPicker, setShowColorPicker] = useState(false)

  const { register, handleSubmit, reset, setValue, watch, formState: { errors, isSubmitting } } = useForm({
    resolver: zodResolver(prioridadeSchema),
    defaultValues: {
      nome: '',
      nivel: 1,
      cor: '#10B981',
    }
  })

  const watchedCor = watch('cor')

  useEffect(() => {
    if (!isMaster()) {
      navigate('/dashboard')
      toast.error("Acesso negado", { description: "Apenas usuários master podem gerenciar prioridades." })
    } else {
      carregarPrioridades()
    }
  }, [isMaster, navigate])

  const carregarPrioridades = async () => {
    setLoading(true)
    try {
      const response = await api.get('/api/prioridades/')
      // Ordenar por nível
      const sorted = response.data.sort((a, b) => a.nivel - b.nivel)
      setPrioridades(sorted)
    } catch (error) {
      console.error('Erro ao carregar prioridades:', error)
      toast.error("Erro ao carregar prioridades", { description: error.response?.data?.detail || "Tente novamente." })
    } finally {
      setLoading(false)
    }
  }

  const handleOpenModal = (prioridade = null) => {
    setEditingPrioridade(prioridade)
    if (prioridade) {
      reset({
        nome: prioridade.nome,
        nivel: prioridade.nivel,
        cor: prioridade.cor,
      })
    } else {
      reset({
        nome: '',
        nivel: prioridades.length + 1, // Próximo nível disponível
        cor: '#10B981',
      })
    }
    setOpenModal(true)
    setShowColorPicker(false)
  }

  const handleCloseModal = () => {
    setOpenModal(false)
    setEditingPrioridade(null)
    reset()
    setShowColorPicker(false)
  }

  const onSubmit = async (data) => {
    try {
      if (editingPrioridade) {
        // Atualizar prioridade
        await api.put(`/api/prioridades/${editingPrioridade.id}`, data)
        toast.success("Prioridade atualizada com sucesso!")
        setSuccessMessage("Prioridade atualizada com sucesso!")
      } else {
        // Criar prioridade
        await api.post('/api/prioridades/', data)
        toast.success("Prioridade criada com sucesso!")
        setSuccessMessage("Prioridade criada com sucesso!")
      }
      handleCloseModal()
      carregarPrioridades()
      setTimeout(() => setSuccessMessage(''), 3000)
    } catch (error) {
      console.error('Erro ao salvar prioridade:', error)
      const errorMsg = error.response?.data?.detail || "Verifique os dados e tente novamente."
      toast.error("Erro ao salvar prioridade", { description: errorMsg })
    }
  }

  const handleSeedDefault = async () => {
    try {
      await api.post('/api/prioridades/seed')
      toast.success("Prioridades padrões criadas com sucesso!")
      setSuccessMessage("Prioridades padrões criadas com sucesso!")
      carregarPrioridades()
      setTimeout(() => setSuccessMessage(''), 3000)
    } catch (error) {
      console.error('Erro ao criar prioridades padrões:', error)
      toast.error("Erro ao criar prioridades padrões", { description: error.response?.data?.detail || "Tente novamente." })
    }
  }

  const getNivelIcon = (nivel) => {
    if (nivel >= 4) return "🔴"
    if (nivel === 3) return "🟠"
    if (nivel === 2) return "🟡"
    return "🟢"
  }

  const getNivelLabel = (nivel) => {
    if (nivel >= 4) return "Urgente"
    if (nivel === 3) return "Alta"
    if (nivel === 2) return "Média"
    return "Baixa"
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8 px-4">
      <div className="max-w-7xl mx-auto space-y-6">
        <div className="flex items-center justify-between">
          <Button variant="ghost" onClick={() => navigate('/configuracoes')}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Voltar para Configurações
          </Button>
          <h1 className="text-3xl font-bold text-gray-900">Gerenciar Prioridades</h1>
        </div>

        {successMessage && (
          <Alert variant="success">
            <AlertDescription>{successMessage}</AlertDescription>
          </Alert>
        )}

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0">
            <CardTitle className="text-2xl flex items-center gap-2">
              <Palette className="h-6 w-6" />
              Lista de Prioridades
            </CardTitle>
            <div className="flex gap-2">
              {prioridades.length === 0 && (
                <Button variant="outline" onClick={handleSeedDefault}>
                  <RefreshCw className="h-4 w-4 mr-2" />
                  Criar Padrões
                </Button>
              )}
              <Button onClick={() => handleOpenModal()}>
                <Plus className="h-4 w-4 mr-2" />
                Nova Prioridade
              </Button>
            </div>
          </CardHeader>
          <CardContent>
            <Alert variant="info" className="mb-4">
              <AlertDescription>
                <strong>ℹ️ Dica:</strong> Prioridades são usadas para classificar a urgência das demandas. 
                O nível indica a ordem (1 = Baixa, 2 = Média, 3 = Alta, 4+ = Urgente).
              </AlertDescription>
            </Alert>

            {loading ? (
              <div className="flex justify-center items-center h-40">
                <Loader2 className="h-8 w-8 animate-spin text-blue-500" />
              </div>
            ) : prioridades.length === 0 ? (
              <div className="text-center py-12">
                <AlertTriangle className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <p className="text-gray-600 mb-4">Nenhuma prioridade cadastrada ainda.</p>
                <Button onClick={handleSeedDefault} variant="outline">
                  <RefreshCw className="h-4 w-4 mr-2" />
                  Criar Prioridades Padrões
                </Button>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Nível
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Nome
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Cor
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Preview
                      </th>
                      <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Ações
                      </th>
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {prioridades.map((prioridade) => (
                      <tr key={prioridade.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="flex items-center gap-2">
                            <span className="text-2xl">{getNivelIcon(prioridade.nivel)}</span>
                            <span className="font-semibold text-gray-900">{prioridade.nivel}</span>
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm font-medium text-gray-900">{prioridade.nome}</div>
                          <div className="text-xs text-gray-500">{getNivelLabel(prioridade.nivel)}</div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <code className="text-xs bg-gray-100 px-2 py-1 rounded">{prioridade.cor}</code>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="flex items-center gap-2">
                            <div
                              className="w-8 h-8 rounded border-2 border-gray-200"
                              style={{ backgroundColor: prioridade.cor }}
                            />
                            <Badge
                              variant="default"
                              style={{
                                backgroundColor: prioridade.cor,
                                color: '#ffffff'
                              }}
                            >
                              {prioridade.nome}
                            </Badge>
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => handleOpenModal(prioridade)}
                          >
                            <Edit className="h-4 w-4" />
                          </Button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Modal de Criar/Editar Prioridade */}
        <Dialog open={openModal} onOpenChange={handleCloseModal}>
          <DialogContent className="sm:max-w-[500px]">
            <DialogHeader>
              <DialogTitle>{editingPrioridade ? 'Editar Prioridade' : 'Nova Prioridade'}</DialogTitle>
            </DialogHeader>
            <DialogBody>
              <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                <Input
                  label="Nome da Prioridade"
                  {...register('nome')}
                  error={errors.nome?.message}
                  placeholder="Ex: Muito Alta, Crítica, etc."
                />

                <Input
                  label="Nível"
                  type="number"
                  {...register('nivel')}
                  error={errors.nivel?.message}
                  helperText="Quanto maior o nível, maior a urgência (1-10)"
                  min="1"
                  max="10"
                />

                <div className="space-y-2">
                  <label className="block text-sm font-medium text-gray-700">
                    Cor <span className="text-red-500">*</span>
                  </label>
                  
                  <div className="flex gap-3 items-start">
                    <div className="flex-1">
                      <Input
                        {...register('cor')}
                        error={errors.cor?.message}
                        placeholder="#10B981"
                      />
                    </div>
                    
                    <div className="relative">
                      <div
                        className="w-12 h-10 rounded border-2 border-gray-300 cursor-pointer hover:border-blue-500 transition-colors"
                        style={{ backgroundColor: watchedCor || '#10B981' }}
                        onClick={() => setShowColorPicker(!showColorPicker)}
                        title="Clique para escolher uma cor"
                      />
                      
                      {showColorPicker && (
                        <div className="absolute top-12 right-0 z-50 bg-white p-3 rounded-lg shadow-xl border">
                          <div className="mb-2 flex justify-between items-center">
                            <span className="text-xs font-medium text-gray-700">Escolher Cor</span>
                            <button
                              type="button"
                              onClick={() => setShowColorPicker(false)}
                              className="text-gray-400 hover:text-gray-600"
                            >
                              ✕
                            </button>
                          </div>
                          <HexColorPicker
                            color={watchedCor || '#10B981'}
                            onChange={(color) => setValue('cor', color)}
                          />
                          <div className="mt-2 text-xs text-center text-gray-500">
                            {watchedCor || '#10B981'}
                          </div>
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Preview da Badge */}
                  <div className="mt-3 p-3 bg-gray-50 rounded-lg">
                    <p className="text-xs text-gray-600 mb-2">Preview:</p>
                    <div className="flex items-center gap-2">
                      <span className="text-2xl">{getNivelIcon(watch('nivel') || 1)}</span>
                      <Badge
                        variant="default"
                        style={{
                          backgroundColor: watchedCor || '#10B981',
                          color: '#ffffff'
                        }}
                      >
                        {watch('nome') || 'Prioridade'}
                      </Badge>
                    </div>
                  </div>
                </div>

                <DialogFooter>
                  <Button variant="outline" onClick={handleCloseModal} type="button">
                    Cancelar
                  </Button>
                  <Button type="submit" disabled={isSubmitting}>
                    {isSubmitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                    {editingPrioridade ? 'Salvar Alterações' : 'Criar Prioridade'}
                  </Button>
                </DialogFooter>
              </form>
            </DialogBody>
          </DialogContent>
        </Dialog>
      </div>
    </div>
  )
}

export default GerenciarPrioridades

