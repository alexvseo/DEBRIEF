/**
 * Página de Nova Demanda
 * Formulário para criar nova demanda
 */
import { useNavigate } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import { Button, Card, CardHeader, CardTitle, CardContent } from '@/components/ui'
import DemandaForm from '@/components/forms/DemandaForm'
import { useAuth } from '@/hooks/useAuth'

const NovaDemanda = () => {
  const navigate = useNavigate()
  const { user } = useAuth()

  const handleSuccess = (demanda) => {
    console.log('Demanda criada:', demanda)
    // Redirecionar para a lista de demandas
    navigate('/minhas-demandas')
  }

  const handleCancel = () => {
    navigate('/dashboard')
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8 px-4">
      <div className="max-w-4xl mx-auto space-y-6">
        
        {/* Header */}
        <div className="flex items-center gap-4">
          <Button 
            variant="outline" 
            size="sm"
            onClick={() => navigate('/dashboard')}
          >
            <ArrowLeft className="h-4 w-4" />
            Voltar
          </Button>
          
          <div>
            <h1 className="text-3xl font-bold text-gray-900">
              📝 Nova Demanda
            </h1>
            <p className="text-gray-600 mt-1">
              Preencha o formulário abaixo para criar uma nova demanda
            </p>
          </div>
        </div>

        {/* Informações do Usuário */}
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3 text-sm text-gray-600">
              <span className="font-semibold">Solicitante:</span>
              <span>{user?.nome_completo}</span>
              <span className="text-gray-400">•</span>
              <span>{user?.email}</span>
            </div>
          </CardContent>
        </Card>

        {/* Formulário de Demanda */}
        <DemandaForm 
          onSuccess={handleSuccess}
          onCancel={handleCancel}
        />

      </div>
    </div>
  )
}

export default NovaDemanda

