/**
 * Página de Configuração WhatsApp
 * Gerencia número remetente e instância Evolution API
 */
import React, { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ArrowLeft,
  Save,
  TestTube,
  Loader2,
  MessageSquare,
  CheckCircle,
  XCircle,
  Phone,
  Settings,
  AlertTriangle,
  Users
} from 'lucide-react'
import {
  Button,
  Card,
  CardHeader,
  CardTitle,
  CardContent,
  Input,
  Alert,
  AlertTitle,
  AlertDescription,
  Badge
} from '@/components/ui'
import { useAuth } from '@/hooks/useAuth'
import api from '@/services/api'
import { toast } from 'sonner'

const ConfiguracaoWhatsApp = () => {
  const navigate = useNavigate()
  const { isMaster, user } = useAuth()
  
  const [loading, setLoading] = useState(false)
  const [testando, setTestando] = useState(false)
  const [verificando, setVerificando] = useState(false)
  const [statusConnection, setStatusConnection] = useState(null)
  
  // Dados fixos do sistema (Z-API já configurado)
  const [configuracaoSistema] = useState({
    numero_remetente: '5585996039026',
    instancia_wpp: 'Z-API',
    api_url: 'https://api.z-api.io',
    ativo: true
  })
  
  const [testeData, setTesteData] = useState({
    numero_teste: '',
    mensagem: '✅ Teste de notificação WhatsApp - DeBrief\n\nSeu número está configurado e você receberá notificações automáticas!'
  })
  const [testeResultado, setTesteResultado] = useState(null)
  
  // Configuração do usuário atual
  const [userConfig, setUserConfig] = useState({
    whatsapp: '',
    receber_notificacoes: true
  })
  
  // Verificar permissão
  useEffect(() => {
    if (!isMaster()) {
      navigate('/dashboard')
    }
  }, [isMaster, navigate])
  
  // Carregar dados do usuário
  useEffect(() => {
    carregarDadosUsuario()
    verificarConexao()
  }, [])
  
  const carregarDadosUsuario = async () => {
    try {
      const response = await api.get('/usuarios/me')
      if (response.data) {
        setUserConfig({
          whatsapp: response.data.whatsapp || '',
          receber_notificacoes: response.data.receber_notificacoes ?? true
        })
      }
    } catch (error) {
      console.error('Erro ao carregar dados do usuário:', error)
    }
  }
  
  const verificarConexao = async () => {
    try {
      setVerificando(true)
      // Verificar status da instância Evolution API
      const response = await api.get('/whatsapp/status')
      setStatusConnection(response.data)
    } catch (error) {
      console.error('Erro ao verificar conexão:', error)
      setStatusConnection({ connected: false, error: 'Não foi possível verificar' })
    } finally {
      setVerificando(false)
    }
  }
  
  const handleUserConfigChange = (field, value) => {
    setUserConfig(prev => ({
      ...prev,
      [field]: value
    }))
  }
  
  const formatarNumero = (numero) => {
    // Remover tudo que não é número
    const apenasNumeros = numero.replace(/\D/g, '')
    
    // Limitar a 15 dígitos (máximo WhatsApp)
    return apenasNumeros.slice(0, 15)
  }
  
  const handleNumeroChange = (field, value) => {
    const numeroFormatado = formatarNumero(value)
    if (field === 'whatsapp') {
      setUserConfig(prev => ({ ...prev, whatsapp: numeroFormatado }))
    } else if (field === 'numero_teste') {
      setTesteData(prev => ({ ...prev, numero_teste: numeroFormatado }))
    }
  }
  
  const salvarConfigUsuario = async () => {
    if (!userConfig.whatsapp) {
      toast.error('Digite um número WhatsApp')
      return
    }
    
    if (userConfig.whatsapp.length < 10) {
      toast.error('Número WhatsApp deve ter pelo menos 10 dígitos')
      return
    }
    
    try {
      setLoading(true)
      await api.put('/usuarios/me/notificacoes', userConfig)
      toast.success('Configurações atualizadas com sucesso!')
      await carregarDadosUsuario()
    } catch (error) {
      console.error('Erro ao salvar configurações:', error)
      toast.error(error.response?.data?.detail || 'Erro ao salvar configurações')
    } finally {
      setLoading(false)
    }
  }
  
  const testarNotificacao = async () => {
    if (!testeData.numero_teste) {
      toast.error('Digite um número para teste')
      return
    }
    
    if (testeData.numero_teste.length < 10) {
      toast.error('Número de teste deve ter pelo menos 10 dígitos')
      return
    }
    
    try {
      setTestando(true)
      setTesteResultado(null)
      
      // Enviar notificação de teste
      const response = await api.post('/whatsapp/testar', {
        numero: testeData.numero_teste,
        mensagem: testeData.mensagem
      })
      
      setTesteResultado({
        success: true,
        message: response.data.message || 'Mensagem enviada com sucesso!'
      })
      
      toast.success('Notificação de teste enviada com sucesso!')
    } catch (error) {
      console.error('Erro ao testar notificação:', error)
      
      setTesteResultado({
        success: false,
        message: error.response?.data?.detail || 'Erro ao enviar notificação de teste'
      })
      
      toast.error('Falha no teste de notificação')
    } finally {
      setTestando(false)
    }
  }
  
  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="h-8 w-8 animate-spin mx-auto text-primary" />
          <p className="mt-2 text-gray-600">Carregando configuração...</p>
        </div>
      </div>
    )
  }
  
  return (
    <div className="min-h-screen bg-gray-50 py-8 px-4">
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Button variant="ghost" onClick={() => navigate('/dashboard')}>
              <ArrowLeft className="h-4 w-4 mr-2" />
              Voltar
            </Button>
            <div>
              <h1 className="text-3xl font-bold text-gray-900 flex items-center gap-2">
                <MessageSquare className="h-8 w-8 text-green-600" />
                Configuração WhatsApp
              </h1>
              <p className="text-gray-600 mt-1">
                Sistema de notificações automáticas via WhatsApp
              </p>
            </div>
          </div>
        </div>
        
        {/* Status da Conexão */}
        <Alert variant={statusConnection?.connected ? "success" : verificando ? "default" : "warning"}>
          <AlertTitle className="flex items-center gap-2">
            {verificando ? (
              <>
                <Loader2 className="h-4 w-4 animate-spin" />
                Verificando Conexão...
              </>
            ) : statusConnection?.connected ? (
              <>
                <CheckCircle className="h-4 w-4" />
                WhatsApp Conectado
              </>
            ) : (
              <>
                <AlertTriangle className="h-4 w-4" />
                WhatsApp Desconectado
              </>
            )}
          </AlertTitle>
          <AlertDescription>
            {verificando ? (
              'Verificando status da conexão Z-API...'
            ) : statusConnection?.connected ? (
              `Instância "${configuracaoSistema.instancia_wpp}" está online e pronta para enviar notificações`
            ) : (
              `Não foi possível conectar à instância "${configuracaoSistema.instancia_wpp}". Verifique a conexão.`
            )}
          </AlertDescription>
        </Alert>
        
        {/* Card de Informações do Sistema */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Settings className="h-5 w-5" />
              Configuração do Sistema (Z-API)
            </CardTitle>
          </CardHeader>
          
          <CardContent className="space-y-4">
            {/* Número Remetente (Read-only) */}
            <div className="space-y-2">
              <label className="text-sm font-medium text-gray-700">
                Número WhatsApp Business Remetente
              </label>
              <div className="relative">
                <Phone className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <Input
                  type="text"
                  value={configuracaoSistema.numero_remetente}
                  disabled
                  className="pl-10 bg-gray-50"
                />
              </div>
              <p className="text-xs text-gray-500">
                Este é o número que envia as notificações automáticas
              </p>
            </div>
            
            {/* Instância (Read-only) */}
            <div className="space-y-2">
              <label className="text-sm font-medium text-gray-700">
                Nome da Instância Evolution API
              </label>
              <Input
                type="text"
                value={configuracaoSistema.instancia_wpp}
                disabled
                className="bg-gray-50"
              />
              <p className="text-xs text-gray-500">
                Instância configurada no servidor Z-API
              </p>
            </div>
            
            {/* Status */}
            <div className="flex items-center gap-3 p-3 bg-green-50 border border-green-200 rounded-lg">
              <CheckCircle className="h-5 w-5 text-green-600" />
              <div>
                <p className="text-sm font-medium text-green-900">Sistema Configurado</p>
                <p className="text-xs text-green-700">O WhatsApp está pronto para enviar notificações</p>
              </div>
            </div>
          </CardContent>
        </Card>
        
        {/* Card de Configuração do Usuário */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Users className="h-5 w-5" />
              Suas Configurações de Notificação
            </CardTitle>
          </CardHeader>
          
          <CardContent className="space-y-6">
            {/* Seu WhatsApp */}
            <div className="space-y-2">
              <label className="text-sm font-medium text-gray-700">
                Seu Número WhatsApp *
              </label>
              <div className="relative">
                <Phone className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <Input
                  type="text"
                  value={userConfig.whatsapp}
                  onChange={(e) => handleNumeroChange('whatsapp', e.target.value)}
                  placeholder="5585996039026"
                  className="pl-10"
                  maxLength={15}
                />
              </div>
              <p className="text-xs text-gray-500">
                Formato: código do país + DDD + número (apenas números)
              </p>
            </div>
            
            {/* Toggle Notificações */}
            <div className="flex items-center justify-between p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <div>
                <p className="text-sm font-medium text-blue-900">Receber Notificações</p>
                <p className="text-xs text-blue-700">Ativar/desativar notificações via WhatsApp</p>
              </div>
              <input
                type="checkbox"
                id="receber_notificacoes"
                checked={userConfig.receber_notificacoes}
                onChange={(e) => handleUserConfigChange('receber_notificacoes', e.target.checked)}
                className="w-5 h-5 text-primary border-gray-300 rounded focus:ring-primary"
              />
            </div>
            
            {/* Botão Salvar */}
            <Button
              onClick={salvarConfigUsuario}
              disabled={loading}
              className="w-full"
            >
              {loading ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Salvando...
                </>
              ) : (
                <>
                  <Save className="h-4 w-4 mr-2" />
                  Salvar Minhas Configurações
                </>
              )}
            </Button>
          </CardContent>
        </Card>
        
        {/* Card de Teste de Notificação */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TestTube className="h-5 w-5" />
              Testar Notificação WhatsApp
            </CardTitle>
          </CardHeader>
          
          <CardContent className="space-y-6">
            {!statusConnection?.connected && (
              <Alert variant="warning">
                <AlertTriangle className="h-4 w-4" />
                <AlertDescription>
                  WhatsApp desconectado. O teste pode falhar.
                </AlertDescription>
              </Alert>
            )}
            
            {/* Número para Teste */}
            <div className="space-y-2">
              <label className="text-sm font-medium text-gray-700">
                Número WhatsApp para Teste *
              </label>
              <div className="relative">
                <Phone className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <Input
                  type="text"
                  value={testeData.numero_teste}
                  onChange={(e) => handleNumeroChange('numero_teste', e.target.value)}
                  placeholder="5585996039026"
                  className="pl-10"
                  maxLength={15}
                />
              </div>
              <p className="text-xs text-gray-500">
                Digite seu número para receber uma mensagem de teste
              </p>
            </div>
            
            {/* Mensagem de Teste */}
            <div className="space-y-2">
              <label className="text-sm font-medium text-gray-700">
                Mensagem de Teste
              </label>
              <textarea
                value={testeData.mensagem}
                onChange={(e) => setTesteData(prev => ({ ...prev, mensagem: e.target.value }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary focus:border-transparent"
                rows={4}
              />
            </div>
            
            {/* Resultado do Teste */}
            {testeResultado && (
              <Alert variant={testeResultado.success ? "success" : "error"}>
                {testeResultado.success ? (
                  <CheckCircle className="h-4 w-4" />
                ) : (
                  <XCircle className="h-4 w-4" />
                )}
                <AlertDescription>{testeResultado.message}</AlertDescription>
              </Alert>
            )}
            
            {/* Botão Testar */}
            <Button
              onClick={testarNotificacao}
              disabled={testando}
              variant="outline"
              className="w-full"
            >
              {testando ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Enviando notificação de teste...
                </>
              ) : (
                <>
                  <TestTube className="h-4 w-4 mr-2" />
                  Enviar Teste
                </>
              )}
            </Button>
          </CardContent>
        </Card>
        
        {/* Informações do Sistema */}
        <Card className="bg-blue-50 border-blue-200">
          <CardContent className="py-4">
            <h3 className="font-semibold text-blue-900 mb-3">
              ℹ️ Como Funcionam as Notificações
            </h3>
            <ul className="text-sm text-blue-800 space-y-2 list-disc list-inside">
              <li><strong>Notificações Automáticas:</strong> Você receberá mensagens quando:
                <ul className="ml-6 mt-1 space-y-1 list-circle list-inside">
                  <li>Uma nova demanda for criada</li>
                  <li>Uma demanda for atualizada</li>
                  <li>O status de uma demanda mudar</li>
                  <li>Uma demanda for excluída</li>
                </ul>
              </li>
              <li><strong>Segmentação:</strong> Usuários Master recebem notificações de TODAS as demandas. Usuários comuns recebem apenas do seu cliente.</li>
              <li><strong>Configuração:</strong> Você pode desabilitar as notificações a qualquer momento desmarcando a opção acima.</li>
              <li><strong>Número Remetente:</strong> Todas as notificações virão do número {configuracaoSistema.numero_remetente}</li>
            </ul>
          </CardContent>
        </Card>
        
        {/* Card de Ajuda */}
        <Card className="bg-yellow-50 border-yellow-200">
          <CardContent className="py-4">
            <h3 className="font-semibold text-yellow-900 mb-3 flex items-center gap-2">
              <AlertTriangle className="h-5 w-5" />
              Problemas Comuns
            </h3>
            <ul className="text-sm text-yellow-800 space-y-2">
              <li><strong>Não estou recebendo notificações:</strong>
                <ul className="ml-6 mt-1 space-y-1 list-disc list-inside">
                  <li>Verifique se seu número está correto (com código do país)</li>
                  <li>Confirme que a opção "Receber Notificações" está ativada</li>
                  <li>Verifique se o WhatsApp está conectado (status acima)</li>
                  <li>Salve a mensagem do número remetente ({configuracaoSistema.numero_remetente}) nos seus contatos</li>
                </ul>
              </li>
              <li><strong>Teste falhou:</strong>
                <ul className="ml-6 mt-1 space-y-1 list-disc list-inside">
                  <li>Aguarde alguns segundos e tente novamente</li>
                  <li>Verifique se o WhatsApp Z-API está conectado</li>
                  <li>Clique em "Verificar Conexão" para atualizar o status</li>
                </ul>
              </li>
            </ul>
          </CardContent>
        </Card>
        
        {/* Botão Atualizar Status */}
        <div className="flex justify-center gap-4">
          <Button
            onClick={verificarConexao}
            disabled={verificando}
            variant="outline"
          >
            {verificando ? (
              <>
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                Verificando...
              </>
            ) : (
              <>
                <CheckCircle className="h-4 w-4 mr-2" />
                Verificar Conexão
              </>
            )}
          </Button>
        </div>
      </div>
    </div>
  )
}

export default ConfiguracaoWhatsApp

