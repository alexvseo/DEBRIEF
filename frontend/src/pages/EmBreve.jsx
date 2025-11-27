/**
 * Página de Manutenção - Em Breve
 * Exibida quando o sistema está em manutenção
 */

/**
 * Página Em Breve / Manutenção
 */
const EmBreve = () => {
  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Caixa de Informação */}
        <div className="bg-white rounded-lg shadow-lg p-8 border border-gray-200 text-center">
          <h1 className="text-2xl font-bold text-gray-800 mb-4">
            Sistema em Atualização
          </h1>
          <p className="text-gray-600 leading-relaxed">
            O sistema está passando por atualizações e estará disponível em breve.
          </p>
        </div>
      </div>
    </div>
  )
}

export default EmBreve

