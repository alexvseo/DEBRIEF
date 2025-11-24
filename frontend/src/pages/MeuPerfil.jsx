/**
 * Página de Perfil do Usuário
 * Visualização e edição de dados pessoais
 */
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, User, Mail, Building, Shield, Edit2, Save, X } from 'lucide-react'
import { 
  Button, 
  Card, 
  CardHeader, 
  CardTitle, 
  CardContent,
  Badge,
  Input,
  Alert,
  AlertTitle,
  AlertDescription
} from '@/components/ui'
import { useAuth } from '@/hooks/useAuth'

const MeuPerfil = () => {
  const navigate = useNavigate()
  const { user, logout } = useAuth()
  const [isEditing, setIsEditing] = useState(false)
  const [formData, setFormData] = useState({
    nome_completo: user?.nome_completo || '',
    email: user?.email || '',
    username: user?.username || ''
  })
  const [showSuccess, setShowSuccess] = useState(false)

  const handleSave = () => {
    // TODO: Implementar chamada à API para atualizar perfil
    console.log('Salvando perfil:', formData)
    setIsEditing(false)
    setShowSuccess(true)
    setTimeout(() => setShowSuccess(false), 3000)
  }

  const handleCancel = () => {
    setFormData({
      nome_completo: user?.nome_completo || '',
      email: user?.email || '',
      username: user?.username || ''
    })
    setIsEditing(false)
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8 px-4">
      <div className="max-w-4xl mx-auto space-y-6">
        
        {/* Header */}
        <div className="flex items-center justify-between">
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
                👤 Meu Perfil
              </h1>
              <p className="text-gray-600 mt-1">
                Gerencie suas informações pessoais
              </p>
            </div>
          </div>

          {!isEditing ? (
            <Button onClick={() => setIsEditing(true)}>
              <Edit2 className="h-4 w-4" />
              Editar Perfil
            </Button>
          ) : (
            <div className="flex gap-2">
              <Button variant="outline" onClick={handleCancel}>
                <X className="h-4 w-4" />
                Cancelar
              </Button>
              <Button onClick={handleSave}>
                <Save className="h-4 w-4" />
                Salvar
              </Button>
            </div>
          )}
        </div>

        {/* Mensagem de Sucesso */}
        {showSuccess && (
          <Alert variant="success">
            <AlertTitle>✅ Perfil Atualizado!</AlertTitle>
            <AlertDescription>
              Suas informações foram atualizadas com sucesso.
            </AlertDescription>
          </Alert>
        )}

        {/* Avatar e Badge */}
        <Card>
          <CardContent className="pt-8">
            <div className="flex items-center gap-6">
              <div className="h-24 w-24 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white text-4xl font-bold">
                {user?.nome_completo?.charAt(0).toUpperCase()}
              </div>
              <div className="flex-1">
                <h2 className="text-2xl font-bold text-gray-900">{user?.nome_completo}</h2>
                <p className="text-gray-600 mt-1">{user?.email}</p>
                <div className="flex gap-2 mt-3">
                  <Badge variant={user?.tipo === 'master' ? 'default' : 'secondary'}>
                    {user?.tipo === 'master' ? '👑 Master' : '👤 Cliente'}
                  </Badge>
                  <Badge variant={user?.ativo ? 'success' : 'error'}>
                    {user?.ativo ? '✓ Ativo' : '✗ Inativo'}
                  </Badge>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Informações Pessoais */}
        <Card>
          <CardHeader>
            <CardTitle>
              <User className="h-5 w-5 inline mr-2" />
              Informações Pessoais
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Nome Completo
                </label>
                {isEditing ? (
                  <Input
                    value={formData.nome_completo}
                    onChange={(e) => setFormData({...formData, nome_completo: e.target.value})}
                    placeholder="Seu nome completo"
                  />
                ) : (
                  <p className="text-gray-900 py-2">{user?.nome_completo}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Email
                </label>
                {isEditing ? (
                  <Input
                    type="email"
                    value={formData.email}
                    onChange={(e) => setFormData({...formData, email: e.target.value})}
                    placeholder="seu@email.com"
                    leftIcon={Mail}
                  />
                ) : (
                  <p className="text-gray-900 py-2 flex items-center gap-2">
                    <Mail className="h-4 w-4 text-gray-500" />
                    {user?.email}
                  </p>
                )}
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Username
                </label>
                {isEditing ? (
                  <Input
                    value={formData.username}
                    onChange={(e) => setFormData({...formData, username: e.target.value})}
                    placeholder="seu_username"
                  />
                ) : (
                  <p className="text-gray-900 py-2">@{user?.username}</p>
                )}
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Informações da Conta */}
        <Card>
          <CardHeader>
            <CardTitle>
              <Shield className="h-5 w-5 inline mr-2" />
              Informações da Conta
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <span className="block text-sm font-semibold text-gray-700 mb-2">Tipo de Usuário</span>
                <Badge variant={user?.tipo === 'master' ? 'default' : 'secondary'} size="lg">
                  {user?.tipo === 'master' ? '👑 Master (Administrador)' : '👤 Cliente'}
                </Badge>
              </div>

              <div>
                <span className="block text-sm font-semibold text-gray-700 mb-2">Status da Conta</span>
                <Badge variant={user?.ativo ? 'success' : 'error'} size="lg">
                  {user?.ativo ? '✓ Conta Ativa' : '✗ Conta Inativa'}
                </Badge>
              </div>

              {user?.cliente_id && (
                <div>
                  <span className="block text-sm font-semibold text-gray-700 mb-2">
                    <Building className="h-4 w-4 inline mr-1" />
                    Cliente ID
                  </span>
                  <p className="text-gray-900 py-2 font-mono text-sm">{user.cliente_id}</p>
                </div>
              )}

              <div>
                <span className="block text-sm font-semibold text-gray-700 mb-2">ID do Usuário</span>
                <p className="text-gray-900 py-2 font-mono text-sm">{user?.id}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Ações da Conta */}
        <Card>
          <CardHeader>
            <CardTitle>Ações da Conta</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              <Button variant="outline" className="w-full justify-start">
                🔒 Alterar Senha
              </Button>
              <Button variant="outline" className="w-full justify-start">
                🔔 Configurar Notificações
              </Button>
              <Button variant="outline" className="w-full justify-start text-red-600 hover:text-red-700 hover:border-red-600">
                🚪 Sair da Conta
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Informações do Sistema Mock */}
        <Alert variant="info">
          <AlertTitle>ℹ️ Sistema de Desenvolvimento</AlertTitle>
          <AlertDescription>
            Você está usando o sistema em modo de desenvolvimento com autenticação mock. 
            Algumas funcionalidades de edição serão ativadas quando o backend estiver conectado.
          </AlertDescription>
        </Alert>

      </div>
    </div>
  )
}

export default MeuPerfil

