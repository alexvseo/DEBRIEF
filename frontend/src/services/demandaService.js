/**
 * Demanda Service
 * Serviço para comunicação com API de demandas
 */
import api from './api'

// Flag para usar mock (desenvolvimento sem backend)
const USE_MOCK = false // Backend está pronto e rodando!

/**
 * Mock de dados de demandas para desenvolvimento
 */
const MOCK_DEMANDAS = [
  {
    id: '1',
    nome: 'Design de Banner para Campanha de Vacinação',
    descricao: 'Criar banner para redes sociais da campanha de vacinação infantil. Incluir identidade visual da prefeitura e informações sobre locais e horários.',
    secretaria_id: 'sec-1',
    secretaria: { id: 'sec-1', nome: 'Secretaria de Saúde' },
    tipo_demanda_id: 'tipo-1',
    tipo_demanda: { id: 'tipo-1', nome: 'Design', cor: '#3B82F6' },
    prioridade_id: 'pri-3',
    prioridade: { id: 'pri-3', nome: 'Alta', nivel: 3, cor: '#F97316' },
    prazo_final: '2024-12-25',
    status: 'em_andamento',
    usuario_id: '2',
    cliente_id: '100',
    trello_card_id: null,
    trello_card_url: null,
    anexos: [],
    created_at: '2024-11-15T10:00:00Z',
    updated_at: '2024-11-15T10:00:00Z'
  },
  {
    id: '2',
    nome: 'Desenvolvimento de Landing Page',
    descricao: 'Landing page responsiva para divulgação de eventos culturais do município. Deve incluir calendário de eventos e galeria de fotos.',
    secretaria_id: 'sec-2',
    secretaria: { id: 'sec-2', nome: 'Secretaria de Cultura' },
    tipo_demanda_id: 'tipo-2',
    tipo_demanda: { id: 'tipo-2', nome: 'Desenvolvimento', cor: '#8B5CF6' },
    prioridade_id: 'pri-2',
    prioridade: { id: 'pri-2', nome: 'Média', nivel: 2, cor: '#F59E0B' },
    prazo_final: '2024-12-30',
    status: 'aberta',
    usuario_id: '2',
    cliente_id: '100',
    trello_card_id: null,
    trello_card_url: null,
    anexos: [],
    created_at: '2024-11-18T14:30:00Z',
    updated_at: '2024-11-18T14:30:00Z'
  },
  {
    id: '3',
    nome: 'Série de Posts para Redes Sociais',
    descricao: 'Criar 5 posts temáticos sobre programas sociais da prefeitura para Instagram e Facebook.',
    secretaria_id: 'sec-3',
    secretaria: { id: 'sec-3', nome: 'Secretaria de Assistência Social' },
    tipo_demanda_id: 'tipo-3',
    tipo_demanda: { id: 'tipo-3', nome: 'Conteúdo', cor: '#10B981' },
    prioridade_id: 'pri-1',
    prioridade: { id: 'pri-1', nome: 'Baixa', nivel: 1, cor: '#10B981' },
    prazo_final: '2024-11-20',
    status: 'concluida',
    usuario_id: '2',
    cliente_id: '100',
    trello_card_id: 'trello-123',
    trello_card_url: 'https://trello.com/c/123abc',
    anexos: [
      {
        id: 'anexo-1',
        nome_arquivo: 'post1.jpg',
        tamanho: 245000,
        tipo_mime: 'image/jpeg'
      }
    ],
    created_at: '2024-11-10T09:00:00Z',
    updated_at: '2024-11-19T16:00:00Z'
  },
  {
    id: '4',
    nome: 'Vídeo Institucional da Prefeitura',
    descricao: 'Vídeo de 2 minutos apresentando os serviços e conquistas da administração municipal.',
    secretaria_id: 'sec-4',
    secretaria: { id: 'sec-4', nome: 'Gabinete do Prefeito' },
    tipo_demanda_id: 'tipo-4',
    tipo_demanda: { id: 'tipo-4', nome: 'Vídeo', cor: '#F59E0B' },
    prioridade_id: 'pri-4',
    prioridade: { id: 'pri-4', nome: 'Urgente', nivel: 4, cor: '#EF4444' },
    prazo_final: '2024-11-22',
    status: 'cancelada',
    usuario_id: '2',
    cliente_id: '100',
    trello_card_id: null,
    trello_card_url: null,
    anexos: [],
    created_at: '2024-11-12T11:00:00Z',
    updated_at: '2024-11-18T15:00:00Z'
  }
]

// Mock de dados auxiliares
const MOCK_SECRETARIAS = [
  { id: 'sec-1', nome: 'Secretaria de Saúde', ativo: true },
  { id: 'sec-2', nome: 'Secretaria de Cultura', ativo: true },
  { id: 'sec-3', nome: 'Secretaria de Assistência Social', ativo: true },
  { id: 'sec-4', nome: 'Gabinete do Prefeito', ativo: true },
  { id: 'sec-5', nome: 'Secretaria de Educação', ativo: true },
  { id: 'sec-6', nome: 'Secretaria de Obras', ativo: true }
]

const MOCK_TIPOS_DEMANDA = [
  { id: 'tipo-1', nome: 'Design', cor: '#3B82F6', ativo: true },
  { id: 'tipo-2', nome: 'Desenvolvimento', cor: '#8B5CF6', ativo: true },
  { id: 'tipo-3', nome: 'Conteúdo', cor: '#10B981', ativo: true },
  { id: 'tipo-4', nome: 'Vídeo', cor: '#F59E0B', ativo: true }
]

const MOCK_PRIORIDADES = [
  { id: 'pri-1', nome: 'Baixa', nivel: 1, cor: '#10B981' },
  { id: 'pri-2', nome: 'Média', nivel: 2, cor: '#F59E0B' },
  { id: 'pri-3', nome: 'Alta', nivel: 3, cor: '#F97316' },
  { id: 'pri-4', nome: 'Urgente', nivel: 4, cor: '#EF4444' }
]

// Estado local para mock
let mockDemandasState = [...MOCK_DEMANDAS]

/**
 * Simular delay de rede
 */
const mockDelay = (ms = 800) => new Promise(resolve => setTimeout(resolve, ms))

/**
 * Serviço de Demandas
 */
const demandaService = {
  /**
   * Criar nova demanda
   * @param {FormData} formData - Dados do formulário com arquivos
   * @returns {Promise<Object>} Demanda criada
   */
  criar: async (formData) => {
    if (USE_MOCK) {
      await mockDelay(1000)
      
      // Extrair dados do FormData
      const dados = {
        id: `dem-${Date.now()}`,
        nome: formData.get('nome'),
        descricao: formData.get('descricao'),
        secretaria_id: formData.get('secretaria_id'),
        tipo_demanda_id: formData.get('tipo_demanda_id'),
        prioridade_id: formData.get('prioridade_id'),
        prazo_final: formData.get('prazo_final'),
        status: 'aberta',
        usuario_id: '2',
        cliente_id: '100',
        trello_card_id: null,
        trello_card_url: null,
        anexos: [],
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }

      // Adicionar relacionamentos mockados
      dados.secretaria = MOCK_SECRETARIAS.find(s => s.id === dados.secretaria_id) || { nome: 'Secretaria' }
      dados.tipo_demanda = MOCK_TIPOS_DEMANDA.find(t => t.id === dados.tipo_demanda_id) || { nome: 'Tipo' }
      dados.prioridade = MOCK_PRIORIDADES.find(p => p.id === dados.prioridade_id) || { nome: 'Prioridade' }

      // Processar arquivos (apenas simular)
      const arquivos = formData.getAll('arquivos')
      dados.anexos = arquivos
        .filter(f => f.size > 0)
        .map((file, index) => ({
          id: `anexo-${Date.now()}-${index}`,
          nome_arquivo: file.name,
          tamanho: file.size,
          tipo_mime: file.type,
          created_at: new Date().toISOString()
        }))

      mockDemandasState.unshift(dados)

      console.log('✅ Demanda criada (MOCK):', dados)
      return { data: dados }
    }

    // Produção: Enviar para API real
    try {
      const response = await api.post('/demandas', formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      })
      return response
    } catch (error) {
      console.error('Erro ao criar demanda:', error)
      throw error
    }
  },

  /**
   * Listar demandas
   * @param {Object} filtros - Filtros de busca
   * @returns {Promise<Array>} Lista de demandas
   */
  listar: async (filtros = {}) => {
    if (USE_MOCK) {
      await mockDelay(500)

      let resultado = [...mockDemandasState]

      // Aplicar filtros
      if (filtros.status) {
        resultado = resultado.filter(d => d.status === filtros.status)
      }

      if (filtros.secretaria_id) {
        resultado = resultado.filter(d => d.secretaria_id === filtros.secretaria_id)
      }

      if (filtros.tipo_demanda_id) {
        resultado = resultado.filter(d => d.tipo_demanda_id === filtros.tipo_demanda_id)
      }

      if (filtros.busca) {
        const busca = filtros.busca.toLowerCase()
        resultado = resultado.filter(d => 
          d.nome.toLowerCase().includes(busca) ||
          d.descricao.toLowerCase().includes(busca)
        )
      }

      console.log('✅ Demandas listadas (MOCK):', resultado.length, 'encontradas')
      return { data: { items: resultado, total: resultado.length } }
    }

    // Produção
    try {
      const response = await api.get('/demandas', { params: filtros })
      return response
    } catch (error) {
      console.error('Erro ao listar demandas:', error)
      throw error
    }
  },

  /**
   * Buscar demanda por ID
   * @param {string} id - ID da demanda
   * @returns {Promise<Object>} Demanda encontrada
   */
  buscarPorId: async (id) => {
    if (USE_MOCK) {
      await mockDelay(300)
      
      const demanda = mockDemandasState.find(d => d.id === id)
      
      if (!demanda) {
        throw new Error('Demanda não encontrada')
      }

      console.log('✅ Demanda encontrada (MOCK):', demanda)
      return { data: demanda }
    }

    // Produção
    try {
      const response = await api.get(`/demandas/${id}`)
      return response
    } catch (error) {
      console.error('Erro ao buscar demanda:', error)
      throw error
    }
  },

  /**
   * Atualizar demanda
   * @param {string} id - ID da demanda
   * @param {Object} dados - Dados a atualizar
   * @returns {Promise<Object>} Demanda atualizada
   */
  atualizar: async (id, dados) => {
    if (USE_MOCK) {
      await mockDelay(800)
      
      const index = mockDemandasState.findIndex(d => d.id === id)
      
      if (index === -1) {
        throw new Error('Demanda não encontrada')
      }

      mockDemandasState[index] = {
        ...mockDemandasState[index],
        ...dados,
        updated_at: new Date().toISOString()
      }

      console.log('✅ Demanda atualizada (MOCK):', mockDemandasState[index])
      return { data: mockDemandasState[index] }
    }

    // Produção
    try {
      const response = await api.put(`/demandas/${id}`, dados)
      return response
    } catch (error) {
      console.error('Erro ao atualizar demanda:', error)
      throw error
    }
  },

  /**
   * Deletar demanda
   * @param {string} id - ID da demanda
   * @returns {Promise<void>}
   */
  deletar: async (id) => {
    if (USE_MOCK) {
      await mockDelay(500)
      
      const index = mockDemandasState.findIndex(d => d.id === id)
      
      if (index === -1) {
        throw new Error('Demanda não encontrada')
      }

      // Soft delete: mudar status para cancelada
      mockDemandasState[index].status = 'cancelada'
      mockDemandasState[index].updated_at = new Date().toISOString()

      console.log('✅ Demanda cancelada (MOCK):', id)
      return { data: { success: true } }
    }

    // Produção
    try {
      const response = await api.delete(`/demandas/${id}`)
      return response
    } catch (error) {
      console.error('Erro ao deletar demanda:', error)
      throw error
    }
  },

  /**
   * Listar secretarias
   * @returns {Promise<Array>} Lista de secretarias
   */
  listarSecretarias: async () => {
    if (USE_MOCK) {
      await mockDelay(200)
      console.log('✅ Secretarias listadas (MOCK):', MOCK_SECRETARIAS.length)
      return { data: MOCK_SECRETARIAS }
    }

    try {
      const response = await api.get('/secretarias')
      return response
    } catch (error) {
      console.error('Erro ao listar secretarias:', error)
      throw error
    }
  },

  /**
   * Listar tipos de demanda
   * @returns {Promise<Array>} Lista de tipos
   */
  listarTiposDemanda: async () => {
    if (USE_MOCK) {
      await mockDelay(200)
      console.log('✅ Tipos de demanda listados (MOCK):', MOCK_TIPOS_DEMANDA.length)
      return { data: MOCK_TIPOS_DEMANDA }
    }

    try {
      const response = await api.get('/tipos-demanda')
      return response
    } catch (error) {
      console.error('Erro ao listar tipos de demanda:', error)
      throw error
    }
  },

  /**
   * Listar prioridades
   * @returns {Promise<Array>} Lista de prioridades
   */
  listarPrioridades: async () => {
    if (USE_MOCK) {
      await mockDelay(200)
      console.log('✅ Prioridades listadas (MOCK):', MOCK_PRIORIDADES.length)
      return { data: MOCK_PRIORIDADES }
    }

    try {
      const response = await api.get('/prioridades')
      return response
    } catch (error) {
      console.error('Erro ao listar prioridades:', error)
      throw error
    }
  },

  /**
   * Obter estatísticas de demandas
   * @returns {Promise<Object>} Estatísticas
   */
  obterEstatisticas: async () => {
    if (USE_MOCK) {
      await mockDelay(300)

      const stats = {
        total: mockDemandasState.length,
        abertas: mockDemandasState.filter(d => d.status === 'aberta').length,
        em_andamento: mockDemandasState.filter(d => d.status === 'em_andamento').length,
        concluidas: mockDemandasState.filter(d => d.status === 'concluida').length,
        canceladas: mockDemandasState.filter(d => d.status === 'cancelada').length,
      }

      console.log('✅ Estatísticas (MOCK):', stats)
      return { data: stats }
    }

    try {
      const response = await api.get('/demandas/estatisticas')
      return response
    } catch (error) {
      console.error('Erro ao obter estatísticas:', error)
      throw error
    }
  },

  /**
   * Resetar dados mock (útil para testes)
   */
  resetMock: () => {
    mockDemandasState = [...MOCK_DEMANDAS]
    console.log('🔄 Dados mock resetados')
  }
}

export { demandaService }
export default demandaService

