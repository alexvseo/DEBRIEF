/**
 * Página de Editar Demanda
 * Formulário para editar demanda existente
 */
import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import { Button, Card, CardContent, Alert, AlertTitle, AlertDescription } from '@/components/ui'
import DemandaForm from '@/components/forms/DemandaForm'
import { useAuth } from '@/hooks/useAuth'
import { demandaService } from '@/services/demandaService'
import { toast } from 'sonner'

const EditarDemanda = () => {
  const { id } = useParams()
  const navigate = useNavigate()
  const { user } = useAuth()
  const [demanda, setDemanda] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    carregarDemanda()
  }, [id])

  const carregarDemanda = async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await demandaService.buscarPorId(id)
      const demandaData = response.data
      
      // Verificar se pode editar
      if (demandaData.status !== 'aberta') {
        setError('Apenas demandas abertas podem ser editadas')
        return
      }

      // Verificar permissão
      if (!user.is_master && demandaData.usuario_id !== user.id) {
        setError('Você não tem permissão para editar esta demanda')
        return
      }

      setDemanda(demandaData)
    } catch (error) {
      console.error('Erro ao carregar demanda:', error)
      setError('Erro ao carregar demanda. Tente novamente.')
      toast.error('Erro ao carregar demanda')
    } finally {
      setLoading(false)
    }
  }

  const handleSuccess = (demandaAtualizada) => {
    console.log('Demanda atualizada:', demandaAtualizada)
    toast.success('Demanda atualizada com sucesso!')
    // Redirecionar para os detalhes da demanda
    navigate(`/demanda/${id}`)
  }

  const handleCancel = () => {
    navigate(`/demanda/${id}`)
  }

  // Loading state
  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 py-8 px-4 flex items-center justify-center">
        <div className="text-center space-y-4">
          <div className="animate-spin rounded-full h-16 w-16 border-b-4 border-primary mx-auto"></div>
          <p className="text-gray-600 text-lg">Carregando demanda...</p>
        </div>
      </div>
    )
  }

  // Error state
  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 py-8 px-4">
        <div className="max-w-4xl mx-auto space-y-6">
          <div className="flex items-center gap-4">
            <Button 
              variant="outline" 
              size="sm"
              onClick={() => navigate('/minhas-demandas')}
            >
              <ArrowLeft className="h-4 w-4" />
              Voltar
            </Button>
            
            <div>
              <h1 className="text-3xl font-bold text-gray-900">
                ✏️ Editar Demanda
              </h1>
            </div>
          </div>

          <Alert variant="error">
            <AlertTitle>Não é possível editar esta demanda</AlertTitle>
            <AlertDescription>{error}</AlertDescription>
          </Alert>

          <div className="flex gap-4">
            <Button onClick={() => navigate('/minhas-demandas')}>
              Voltar para Minhas Demandas
            </Button>
            {demanda && (
              <Button variant="outline" onClick={() => navigate(`/demanda/${id}`)}>
                Ver Detalhes da Demanda
              </Button>
            )}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8 px-4">
      <div className="max-w-4xl mx-auto space-y-6">
        
        {/* Header */}
        <div className="flex items-center gap-4">
          <Button 
            variant="outline" 
            size="sm"
            onClick={() => navigate(`/demanda/${id}`)}
          >
            <ArrowLeft className="h-4 w-4" />
            Voltar
          </Button>
          
          <div>
            <h1 className="text-3xl font-bold text-gray-900">
              ✏️ Editar Demanda
            </h1>
            <p className="text-gray-600 mt-1">
              Atualize as informações da demanda
            </p>
          </div>
        </div>

        {/* Informações da Demanda Atual */}
        <Card>
          <CardContent className="pt-6">
            <div className="space-y-2">
              <div className="flex items-center gap-3 text-sm">
                <span className="font-semibold text-gray-700">Demanda:</span>
                <span className="text-gray-900">{demanda?.nome}</span>
              </div>
              <div className="flex items-center gap-3 text-sm">
                <span className="font-semibold text-gray-700">Solicitante:</span>
                <span className="text-gray-900">{user?.nome_completo}</span>
                <span className="text-gray-400">•</span>
                <span className="text-gray-600">{user?.email}</span>
              </div>
              <div className="flex items-center gap-3 text-sm">
                <span className="font-semibold text-gray-700">Criada em:</span>
                <span className="text-gray-900">
                  {new Date(demanda?.created_at).toLocaleString('pt-BR')}
                </span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Aviso */}
        <Alert dismissible>
          <AlertTitle>💡 Dica</AlertTitle>
          <AlertDescription>
            Após salvar, a demanda será atualizada e um card no Trello será atualizado automaticamente.
          </AlertDescription>
        </Alert>

        {/* Formulário de Edição */}
        <DemandaForm 
          demanda={demanda}
          onSuccess={handleSuccess}
          onCancel={handleCancel}
        />

      </div>
    </div>
  )
}

export default EditarDemanda

