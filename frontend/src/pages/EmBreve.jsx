/**
 * Página de Manutenção - Em Breve
 * Exibida quando o sistema está em manutenção
 */
import { Wrench, Clock, AlertCircle, ArrowRight } from 'lucide-react'
import { Link } from 'react-router-dom'
import { Button } from '@/components/ui'

/**
 * Página Em Breve / Manutenção
 */
const EmBreve = () => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-purple-50 to-pink-50 flex items-center justify-center p-4">
      <div className="w-full max-w-2xl space-y-8 text-center">
        
        {/* Logo e Título */}
        <div className="space-y-4">
          <div className="flex justify-center">
            <div className="relative">
              <div className="absolute inset-0 bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 rounded-full blur-2xl opacity-20 animate-pulse"></div>
              <div className="relative bg-white rounded-full p-6 shadow-xl">
                <Wrench className="h-16 w-16 text-blue-600" />
              </div>
            </div>
          </div>
          
          <h1 className="text-5xl md:text-6xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600">
            🎯 DeBrief
          </h1>
          
          <h2 className="text-3xl md:text-4xl font-bold text-gray-800">
            Sistema em Manutenção
          </h2>
        </div>

        {/* Card de Informação */}
        <div className="bg-white rounded-2xl shadow-xl p-8 space-y-6 border border-gray-100">
          
          {/* Ícone de Manutenção */}
          <div className="flex justify-center">
            <div className="bg-orange-100 rounded-full p-4">
              <AlertCircle className="h-12 w-12 text-orange-600" />
            </div>
          </div>

          {/* Mensagem Principal */}
          <div className="space-y-4">
            <p className="text-xl md:text-2xl text-gray-700 font-semibold">
              Estamos realizando atualizações importantes no sistema
            </p>
            
            <p className="text-gray-600 text-lg leading-relaxed">
              O DeBrief está temporariamente indisponível para melhorias e atualizações. 
              Estamos trabalhando para oferecer uma experiência ainda melhor.
            </p>
          </div>

          {/* Informações Adicionais */}
          <div className="grid md:grid-cols-2 gap-4 pt-6 border-t border-gray-200">
            <div className="flex items-start gap-3 p-4 bg-blue-50 rounded-lg">
              <Clock className="h-6 w-6 text-blue-600 flex-shrink-0 mt-1" />
              <div className="text-left">
                <p className="font-semibold text-gray-800">Tempo Estimado</p>
                <p className="text-sm text-gray-600">Em breve estaremos de volta</p>
              </div>
            </div>
            
            <div className="flex items-start gap-3 p-4 bg-purple-50 rounded-lg">
              <Wrench className="h-6 w-6 text-purple-600 flex-shrink-0 mt-1" />
              <div className="text-left">
                <p className="font-semibold text-gray-800">O que está acontecendo?</p>
                <p className="text-sm text-gray-600">Atualizações e melhorias no sistema</p>
              </div>
            </div>
          </div>

          {/* Botão de Acesso (Opcional - para administradores) */}
          <div className="pt-6">
            <Link to="/login">
              <Button 
                size="lg" 
                className="w-full md:w-auto px-8"
                variant="outline"
              >
                <span>Acesso Administrativo</span>
                <ArrowRight className="h-4 w-4 ml-2" />
              </Button>
            </Link>
            <p className="text-xs text-gray-500 mt-3">
              * Apenas para administradores do sistema
            </p>
          </div>
        </div>

        {/* Rodapé */}
        <div className="text-center text-sm text-gray-500 space-y-2">
          <p>© 2025 DeBrief. Todos os direitos reservados.</p>
          <p className="flex items-center justify-center gap-2">
            <span>Versão</span>
            <span className="font-semibold text-gray-700 bg-gray-200 px-2 py-0.5 rounded">
              v1.1.0
            </span>
          </p>
        </div>

      </div>
    </div>
  )
}

export default EmBreve

