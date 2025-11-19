/**
 * Componente Select reutilizável
 * Dropdown nativo estilizado com validação
 */
import React from 'react'
import { cn } from '@/lib/utils'
import { AlertCircle, ChevronDown } from 'lucide-react'

/**
 * Select estilizado com validação visual
 * 
 * @param {Object} props
 * @param {string} props.label - Label do select
 * @param {string} props.error - Mensagem de erro
 * @param {string} props.helperText - Texto de ajuda
 * @param {boolean} props.required - Se é obrigatório
 * @param {boolean} props.disabled - Se está desabilitado
 * @param {string} props.placeholder - Texto do placeholder (primeira opção)
 * @param {Array} props.options - Array de opções [{value, label}]
 * @param {string} props.className - Classes CSS adicionais
 * 
 * @example
 * <Select
 *   label="Prioridade"
 *   options={[
 *     { value: '1', label: 'Baixa' },
 *     { value: '2', label: 'Média' }
 *   ]}
 *   required
 * />
 */
const Select = React.forwardRef(
  ({ 
    className,
    label,
    error,
    helperText,
    required = false,
    disabled = false,
    placeholder = 'Selecione...',
    options = [],
    id,
    children,
    ...props 
  }, ref) => {
    
    // Gerar ID único se não fornecido
    const selectId = id || `select-${Math.random().toString(36).substr(2, 9)}`
    
    return (
      <div className="w-full">
        {/* Label */}
        {label && (
          <label 
            htmlFor={selectId}
            className={cn(
              'block text-sm font-medium mb-1.5',
              error ? 'text-error' : 'text-gray-700',
              disabled && 'text-gray-400'
            )}
          >
            {label}
            {required && (
              <span className="text-error ml-1" title="Campo obrigatório">*</span>
            )}
          </label>
        )}
        
        {/* Container do Select (para ícone customizado) */}
        <div className="relative">
          {/* Select */}
          <select
            id={selectId}
            className={cn(
              // Base
              'flex w-full rounded-lg border bg-white text-sm',
              // Padding (espaço para ícone)
              'px-3 py-2 pr-10',
              // Aparência
              'appearance-none cursor-pointer',
              // Focus
              'focus:outline-none focus:ring-2 focus:ring-offset-0',
              error 
                ? 'border-error focus:ring-error focus:border-error' 
                : 'border-gray-300 focus:ring-primary focus:border-primary',
              // Disabled
              'disabled:cursor-not-allowed disabled:bg-gray-50 disabled:text-gray-500 disabled:border-gray-200',
              // Transições
              'transition-all duration-200',
              // Classes customizadas
              className
            )}
            ref={ref}
            disabled={disabled}
            aria-invalid={error ? 'true' : 'false'}
            aria-describedby={error ? `${selectId}-error` : helperText ? `${selectId}-helper` : undefined}
            {...props}
          >
            {/* Placeholder como primeira opção */}
            {placeholder && (
              <option value="" disabled>
                {placeholder}
              </option>
            )}
            
            {/* Opções do array */}
            {options.map((option, index) => (
              <option key={index} value={option.value}>
                {option.label}
              </option>
            ))}
            
            {/* Children (opções customizadas) */}
            {children}
          </select>
          
          {/* Ícone de seta customizado */}
          <div className={cn(
            'absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none',
            error ? 'text-error' : 'text-gray-400'
          )}>
            <ChevronDown className="h-4 w-4" />
          </div>
        </div>
        
        {/* Mensagem de erro */}
        {error && (
          <p 
            id={`${selectId}-error`}
            className="mt-1.5 text-sm text-error flex items-center gap-1"
            role="alert"
          >
            <AlertCircle className="h-3.5 w-3.5 flex-shrink-0" />
            <span>{error}</span>
          </p>
        )}
        
        {/* Texto de ajuda */}
        {helperText && !error && (
          <p 
            id={`${selectId}-helper`}
            className="mt-1.5 text-xs text-gray-500"
          >
            {helperText}
          </p>
        )}
      </div>
    )
  }
)

Select.displayName = 'Select'

export default Select

/**
 * EXEMPLOS DE USO:
 * 
 * // Select básico com options array
 * <Select
 *   label="Prioridade"
 *   options={[
 *     { value: '1', label: 'Baixa' },
 *     { value: '2', label: 'Média' },
 *     { value: '3', label: 'Alta' },
 *     { value: '4', label: 'Urgente' }
 *   ]}
 * />
 * 
 * // Select com placeholder customizado
 * <Select
 *   label="Tipo de Demanda"
 *   placeholder="Escolha o tipo..."
 *   options={tipos}
 * />
 * 
 * // Select com children (opções customizadas)
 * <Select label="Status">
 *   <option value="">Selecione...</option>
 *   <option value="aberta">Aberta</option>
 *   <option value="em_andamento">Em Andamento</option>
 *   <option value="concluida">Concluída</option>
 * </Select>
 * 
 * // Select obrigatório
 * <Select
 *   label="Secretaria"
 *   options={secretarias}
 *   required
 * />
 * 
 * // Select com erro (React Hook Form)
 * <Select
 *   label="Cliente"
 *   options={clientes}
 *   error={errors.cliente_id?.message}
 *   {...register('cliente_id')}
 * />
 * 
 * // Select com helper text
 * <Select
 *   label="Categoria"
 *   options={categorias}
 *   helperText="Escolha a categoria mais adequada"
 * />
 * 
 * // Select desabilitado
 * <Select
 *   label="Campo bloqueado"
 *   options={opcoes}
 *   disabled
 * />
 * 
 * // Select com valor padrão
 * <Select
 *   label="Status"
 *   options={statusOptions}
 *   defaultValue="aberta"
 * />
 * 
 * // Select controlado
 * const [value, setValue] = useState('')
 * <Select
 *   label="Seleção"
 *   options={opcoes}
 *   value={value}
 *   onChange={(e) => setValue(e.target.value)}
 * />
 */

