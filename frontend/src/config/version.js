/**
 * Versão do Sistema DeBrief
 * Atualizar este arquivo a cada modificação no sistema
 */

export const APP_VERSION = '1.1.0'
export const APP_NAME = 'DeBrief'
export const APP_BUILD_DATE = new Date().toISOString().split('T')[0] // YYYY-MM-DD

// Histórico de versões (opcional, para referência)
export const VERSION_HISTORY = [
  {
    version: '1.1.0',
    date: '2025-01-15',
    changes: [
      'Correção na exclusão de demandas',
      'Adicionadas colunas Cliente e Usuário no Dashboard',
      'Variável {url_sistema} agora aponta para DeBrief ao invés do Trello',
      'Sistema de versionamento implementado'
    ]
  },
  {
    version: '1.0.0',
    date: '2025-01-01',
    changes: [
      'Versão inicial do sistema'
    ]
  }
]

export default {
  APP_VERSION,
  APP_NAME,
  APP_BUILD_DATE,
  VERSION_HISTORY
}

