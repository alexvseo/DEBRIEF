import { useState, useRef, useEffect } from 'react'
import { X, ChevronDown, Check } from 'lucide-react'

/**
 * Componente MultiSelect para seleção múltipla
 * 
 * @param {Object} props
 * @param {string} props.label - Label do campo
 * @param {Array} props.options - Array de opções {value, label}
 * @param {Array} props.value - Array de valores selecionados
 * @param {Function} props.onChange - Callback quando muda (recebe array de valores)
 * @param {string} props.placeholder - Placeholder
 * @param {boolean} props.disabled - Se está desabilitado
 */
export const MultiSelect = ({ 
  label, 
  options = [], 
  value = [], 
  onChange, 
  placeholder = 'Selecione...',
  disabled = false 
}) => {
  const [isOpen, setIsOpen] = useState(false)
  const containerRef = useRef(null)

  // Fechar ao clicar fora
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (containerRef.current && !containerRef.current.contains(event.target)) {
        setIsOpen(false)
      }
    }

    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside)
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [isOpen])

  const toggleOption = (optionValue) => {
    if (disabled) return
    
    const newValue = value.includes(optionValue)
      ? value.filter(v => v !== optionValue)
      : [...value, optionValue]
    
    onChange(newValue)
  }

  const removeOption = (optionValue, e) => {
    e.stopPropagation()
    onChange(value.filter(v => v !== optionValue))
  }

  const selectedOptions = options.filter(opt => value.includes(opt.value))
  const displayText = selectedOptions.length > 0
    ? `${selectedOptions.length} selecionado(s)`
    : placeholder

  return (
    <div className="w-full" ref={containerRef}>
      {label && (
        <label className="block text-sm font-medium text-gray-700 mb-1">
          {label}
        </label>
      )}
      <div className="relative">
        <button
          type="button"
          onClick={() => !disabled && setIsOpen(!isOpen)}
          disabled={disabled}
          className={`
            w-full px-3 py-2 text-left bg-white border border-gray-300 rounded-md
            shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500
            disabled:bg-gray-100 disabled:cursor-not-allowed
            flex items-center justify-between
            ${isOpen ? 'ring-2 ring-blue-500 border-blue-500' : ''}
          `}
        >
          <span className={`block truncate ${selectedOptions.length === 0 ? 'text-gray-500' : 'text-gray-900'}`}>
            {displayText}
          </span>
          <ChevronDown className={`h-4 w-4 text-gray-400 transition-transform ${isOpen ? 'transform rotate-180' : ''}`} />
        </button>

        {isOpen && (
          <div className="absolute z-50 w-full mt-1 bg-white border border-gray-300 rounded-md shadow-lg max-h-60 overflow-auto">
            {options.length === 0 ? (
              <div className="px-3 py-2 text-sm text-gray-500">Nenhuma opção disponível</div>
            ) : (
              options.map((option) => {
                const isSelected = value.includes(option.value)
                return (
                  <div
                    key={option.value}
                    onClick={() => toggleOption(option.value)}
                    className={`
                      px-3 py-2 cursor-pointer hover:bg-blue-50 flex items-center justify-between
                      ${isSelected ? 'bg-blue-50' : ''}
                    `}
                  >
                    <span className="text-sm text-gray-900">{option.label}</span>
                    {isSelected && <Check className="h-4 w-4 text-blue-600" />}
                  </div>
                )
              })
            )}
          </div>
        )}
      </div>

      {/* Tags dos selecionados */}
      {selectedOptions.length > 0 && (
        <div className="flex flex-wrap gap-2 mt-2">
          {selectedOptions.map((option) => (
            <span
              key={option.value}
              className="inline-flex items-center gap-1 px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded-md"
            >
              {option.label}
              <button
                type="button"
                onClick={(e) => removeOption(option.value, e)}
                className="hover:bg-blue-200 rounded-full p-0.5"
              >
                <X className="h-3 w-3" />
              </button>
            </span>
          ))}
        </div>
      )}
    </div>
  )
}

