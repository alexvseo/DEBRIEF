/**
 * Componente Footer
 * Rodapé do sistema com informações de versão
 */
import { APP_VERSION, APP_NAME } from '@/config/version'

const Footer = () => {
  const currentYear = new Date().getFullYear()

  return (
    <footer className="bg-gray-50 border-t border-gray-200 mt-auto">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
        <div className="flex flex-col sm:flex-row justify-between items-center text-sm text-gray-600 space-y-2 sm:space-y-0">
          <div className="flex items-center space-x-4">
            <span>© {currentYear} {APP_NAME}. Todos os direitos reservados.</span>
          </div>
          <div className="flex items-center space-x-2">
            <span className="text-gray-500">Versão</span>
            <span className="font-semibold text-gray-700 bg-gray-200 px-2 py-1 rounded">
              v{APP_VERSION}
            </span>
          </div>
        </div>
      </div>
    </footer>
  )
}

export default Footer

