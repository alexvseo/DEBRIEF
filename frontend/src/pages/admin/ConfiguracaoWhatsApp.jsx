/**
 * Página de Configuração WhatsApp
 * Gerencia número remetente e instância WPP Connect
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
  AlertTriangle
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
  const { isMaster } = useAuth()
  
  const [loading, setLoading] = useState(true)
  const [salvando, setSalvando] = useState(false)
  const [testando, setTestando] = useState(false)
  const [configuracaoAtiva, setConfiguracaoAtiva] = useState(null)
  const [formData, setFormData] = useState({
    numero_remetente: '',
    instancia_wpp: '',
    ativo: true
  })
  const [testeData, setTesteData] = useState({
    numero_teste: '',
    mensagem: '✅ Teste de conexão WhatsApp - DeBrief Sistema'
  })
  const [testeResultado, setTesteResultado] = useState(null)
  
  // Verificar permissão
  useEffect(() => {
    if (!isMaster()) {
      navigate('/dashboard')
    }
  }, [isMaster, navigate])
  
  // Carregar configuração ativa
  useEffect(() => {
    carregarConfiguracao()
  }, [])
  
  const carregarConfiguracao = async () => {
    try {
      setLoading(true)
      const response = await api.get('/whatsapp/configuracoes/ativa')
      
      if (response.data) {
        setConfiguracaoAtiva(response.data)
        setFormData({
          numero_remetente: response.data.numero_remetente || '',
          instancia_wpp: response.data.instancia_wpp || '',
          ativo: response.data.ativo
        })
      }
    } catch (error) {
      // Se não encontrar configuração ativa, não é erro
      if (error.response?.status !== 404) {
        console.error('Erro ao carregar configuração:', error)
        toast.error('Erro ao carregar configuração WhatsApp')
      }
    } finally {
      setLoading(false)
    }
  }
  
  const handleChange = (field, value) => {
    setFormData(prev => ({
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
    if (field === 'numero_remetente') {
      setFormData(prev => ({ ...prev, numero_remetente: numeroFormatado }))
    } else {
      setTesteData(prev => ({ ...prev, numero_teste: numeroFormatado }))
    }
  }
  
  const validarFormulario = () => {
    if (!formData.numero_remetente) {
      toast.error('Número remetente é obrigatório')
      return false
    }
    
    if (formData.numero_remetente.length < 10) {
      toast.error('Número remetente deve ter pelo menos 10 dígitos')
      return false
    }
    
    if (!formData.instancia_wpp) {
      toast.error('Instância WPP Connect é obrigatória')
      return false
    }
    
    return true
  }
  
  const salvarConfiguracao = async () => {
    if (!validarFormulario()) return
    
    try {
      setSalvando(true)
      
      if (configuracaoAtiva) {
        // Atualizar existente
        await api.put(`/whatsapp/configuracoes/${configuracaoAtiva.id}`, formData)
        toast.success('Configuração atualizada com sucesso!')
      } else {
        // Criar nova
        const response = await api.post('/whatsapp/configuracoes', formData)
        setConfiguracaoAtiva(response.data)
        toast.success('Configuração criada com sucesso!')
      }
      
      await carregarConfiguracao()
    } catch (error) {
      console.error('Erro ao salvar configuração:', error)
      toast.error(error.response?.data?.detail || 'Erro ao salvar configuração')
    } finally {
      setSalvando(false)
    }
  }
  
  const testarConexao = async () => {
    if (!testeData.numero_teste) {
      toast.error('Digite um número para teste')
      return
    }
    
    if (testeData.numero_teste.length < 10) {
      toast.error('Número de teste deve ter pelo menos 10 dígitos')
      return
    }
    
    if (!configuracaoAtiva) {
      toast.error('Salve a configuração antes de testar')
      return
    }
    
    try {
      setTestando(true)
      setTesteResultado(null)
      
      const response = await api.post('/whatsapp/configuracoes/testar', testeData)
      
      setTesteResultado({
        success: true,
        message: response.data.message
      })
      
      toast.success('Mensagem de teste enviada com sucesso!')
    } catch (error) {
      console.error('Erro ao testar conexão:', error)
      
      setTesteResultado({
        success: false,
        message: error.response?.data?.detail || 'Erro ao enviar mensagem de teste'
      })
      
      toast.error('Falha no teste de conexão')
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
            <Button variant="ghost" onClick={() => navigate('/configuracoes')}>
              <ArrowLeft className="h-4 w-4 mr-2" />
              Voltar
            </Button>
            <div>
              <h1 className="text-3xl font-bold text-gray-900 flex items-center gap-2">
                <MessageSquare className="h-8 w-8 text-green-600" />
                Configuração WhatsApp
              </h1>
              <p className="text-gray-600 mt-1">
                Configure o número remetente para notificações individuais
              </p>
            </div>
          </div>
        </div>
        
        {/* Status da Configuração */}
        {configuracaoAtiva && (
          <Alert variant={configuracaoAtiva.ativo ? "success" : "warning"}>
            <AlertTitle className="flex items-center gap-2">
              {configuracaoAtiva.ativo ? (
                <>
                  <CheckCircle className="h-4 w-4" />
                  Configuração Ativa
                </>
              ) : (
                <>
                  <AlertTriangle className="h-4 w-4" />
                  Configuração Inativa
                </>
              )}
            </AlertTitle>
            <AlertDescription>
              Número remetente: {configuracaoAtiva.numero_remetente}
            </AlertDescription>
          </Alert>
        )}
        
        {/* Card de Configuração */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Settings className="h-5 w-5" />
              Configuração do Número Remetente
            </CardTitle>
          </CardHeader>
          
          <CardContent className="space-y-6">
            {/* Número Remetente */}
            <div className="space-y-2">
              <label className="text-sm font-medium text-gray-700">
                Número WhatsApp Business Remetente *
              </label>
              <div className="relative">
                <Phone className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <Input
                  type="text"
                  value={formData.numero_remetente}
                  onChange={(e) => handleNumeroChange('numero_remetente', e.target.value)}
                  placeholder="5511999999999"
                  className="pl-10"
                  maxLength={15}
                />
              </div>
              <p className="text-xs text-gray-500">
                Formato: código do país + DDD + número (apenas números)
              </p>
            </div>
            
            {/* Instância WPP Connect */}
            <div className="space-y-2">
              <label className="text-sm font-medium text-gray-700">
                Nome da Instância WPP Connect *
              </label>
              <Input
                type="text"
                value={formData.instancia_wpp}
                onChange={(e) => handleChange('instancia_wpp', e.target.value)}
                placeholder="debrief-instance"
              />
              <p className="text-xs text-gray-500">
                Nome da instância configurada no WPPConnect Server
              </p>
            </div>
            
            {/* Status Ativo */}
            <div className="flex items-center gap-3">
              <input
                type="checkbox"
                id="ativo"
                checked={formData.ativo}
                onChange={(e) => handleChange('ativo', e.target.checked)}
                className="w-4 h-4 text-primary border-gray-300 rounded focus:ring-primary"
              />
              <label htmlFor="ativo" className="text-sm font-medium text-gray-700">
                Configuração ativa
              </label>
            </div>
            
            {/* Botão Salvar */}
            <Button
              onClick={salvarConfiguracao}
              disabled={salvando}
              className="w-full"
            >
              {salvando ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Salvando...
                </>
              ) : (
                <>
                  <Save className="h-4 w-4 mr-2" />
                  {configuracaoAtiva ? 'Atualizar Configuração' : 'Salvar Configuração'}
                </>
              )}
            </Button>
          </CardContent>
        </Card>
        
        {/* Card de Teste de Conexão */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TestTube className="h-5 w-5" />
              Testar Conexão WhatsApp
            </CardTitle>
          </CardHeader>
          
          <CardContent className="space-y-6">
            {!configuracaoAtiva && (
              <Alert variant="warning">
                <AlertTriangle className="h-4 w-4" />
                <AlertDescription>
                  Salve a configuração antes de realizar o teste
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
                  placeholder="5511999999999"
                  className="pl-10"
                  maxLength={15}
                  disabled={!configuracaoAtiva}
                />
              </div>
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
                rows={3}
                disabled={!configuracaoAtiva}
              />
            </div>
            
            {/* Resultado do Teste */}
            {testeResultado && (
              <Alert variant={testeResultado.success ? "success" : "error"} dismissible>
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
              onClick={testarConexao}
              disabled={testando || !configuracaoAtiva}
              variant="outline"
              className="w-full"
            >
              {testando ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Enviando mensagem de teste...
                </>
              ) : (
                <>
                  <TestTube className="h-4 w-4 mr-2" />
                  Testar Conexão
                </>
              )}
            </Button>
          </CardContent>
        </Card>
        
        {/* Informações Adicionais */}
        <Card className="bg-blue-50 border-blue-200">
          <CardContent className="py-4">
            <h3 className="font-semibold text-blue-900 mb-2">
              ℹ️ Informações Importantes
            </h3>
            <ul className="text-sm text-blue-800 space-y-1 list-disc list-inside">
              <li>Apenas uma configuração pode estar ativa por vez</li>
              <li>O número remetente deve ser um WhatsApp Business válido</li>
              <li>A instância WPPConnect deve estar configurada e ativa</li>
              <li>Use o teste de conexão para validar a configuração</li>
              <li>Após salvar, configure os templates de mensagens</li>
            </ul>
          </CardContent>
        </Card>
        
        {/* Botão para Templates */}
        <div className="flex justify-center">
          <Button
            onClick={() => navigate('/admin/templates-whatsapp')}
            variant="outline"
            size="lg"
          >
            <MessageSquare className="h-5 w-5 mr-2" />
            Gerenciar Templates de Mensagens
          </Button>
        </div>
      </div>
    </div>
  )
}

export default ConfiguracaoWhatsApp

