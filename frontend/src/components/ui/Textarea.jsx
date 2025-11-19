/**
 * Componente Textarea reutilizável
 * Área de texto multilinha com estilos consistentes, validação e contador
 */
import React from 'react'
import { cn } from '@/lib/utils.js'
import { AlertCircle } from 'lucide-react'

/**
 * Textarea flexível com validação visual e contador de caracteres
 * 
 * @param {Object} props
 * @param {string} props.label - Label do textarea
 * @param {string} props.error - Mensagem de erro
 * @param {string} props.helperText - Texto de ajuda
 * @param {boolean} props.required - Se é obrigatório
 * @param {boolean} props.disabled - Se está desabilitado
 * @param {number} props.maxLength - Tamanho máximo (mostra contador)
 * @param {number} props.rows - Número de linhas (padrão: 4)
 * @param {boolean} props.resize - Se permite redimensionar (padrão: true)
 * @param {string} props.className - Classes CSS adicionais
 * 
 * @example
 * <Textarea
 *   label="Descrição"
 *   placeholder="Descreva sua demanda..."
 *   maxLength={2000}
 *   required
 * />
 */
const Textarea = React.forwardRef(
  ({ 
    className,
    label,
    error,
    helperText,
    required = false,
    disabled = false,
    maxLength,
    rows = 4,
    resize = true,
    id,
    value = '',
    ...props 
  }, ref) => {
    
    // Gerar ID único se não fornecido
    const textareaId = id || `textarea-${Math.random().toString(36).substr(2, 9)}`
    
    // Calcular caracteres restantes
    const currentLength = value?.toString().length || 0
    const remainingChars = maxLength ? maxLength - currentLength : null
    const isNearLimit = maxLength && currentLength > maxLength * 0.9
    
    return (
      <div className="w-full">
        {/* Label */}
        {label && (
          <label 
            htmlFor={textareaId}
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
        
        {/* Textarea */}
        <textarea
          id={textareaId}
          rows={rows}
          className={cn(
            // Base
            'flex w-full rounded-lg border bg-white text-sm',
            // Padding
            'px-3 py-2',
            // Placeholder
            'placeholder:text-gray-400',
            // Focus
            'focus:outline-none focus:ring-2 focus:ring-offset-0',
            error 
              ? 'border-error focus:ring-error focus:border-error' 
              : 'border-gray-300 focus:ring-primary focus:border-primary',
            // Disabled
            'disabled:cursor-not-allowed disabled:bg-gray-50 disabled:text-gray-500 disabled:border-gray-200',
            // Resize
            resize ? 'resize-y' : 'resize-none',
            // Transições
            'transition-all duration-200',
            // Classes customizadas
            className
          )}
          ref={ref}
          disabled={disabled}
          maxLength={maxLength}
          value={value}
          aria-invalid={error ? 'true' : 'false'}
          aria-describedby={error ? `${textareaId}-error` : helperText ? `${textareaId}-helper` : undefined}
          {...props}
        />
        
        {/* Contador de caracteres e mensagens */}
        <div className="mt-1.5 flex items-center justify-between">
          {/* Mensagem de erro ou helper text */}
          <div className="flex-1">
            {error && (
              <p 
                id={`${textareaId}-error`}
                className="text-sm text-error flex items-center gap-1"
                role="alert"
              >
                <AlertCircle className="h-3.5 w-3.5 flex-shrink-0" />
                <span>{error}</span>
              </p>
            )}
            
            {helperText && !error && (
              <p 
                id={`${textareaId}-helper`}
                className="text-xs text-gray-500"
              >
                {helperText}
              </p>
            )}
          </div>
          
          {/* Contador de caracteres */}
          {maxLength && (
            <p className={cn(
              'text-xs font-medium ml-2',
              isNearLimit && 'text-orange-600',
              currentLength >= maxLength && 'text-error',
              !isNearLimit && currentLength < maxLength && 'text-gray-500'
            )}>
              {currentLength} / {maxLength}
            </p>
          )}
        </div>
      </div>
    )
  }
)

Textarea.displayName = 'Textarea'

export default Textarea

/**
 * EXEMPLOS DE USO:
 * 
 * // Textarea básico
 * <Textarea placeholder="Digite algo..." />
 * 
 * // Textarea com label
 * <Textarea 
 *   label="Descrição"
 *   placeholder="Descreva sua demanda..."
 * />
 * 
 * // Textarea com limite de caracteres
 * <Textarea 
 *   label="Descrição"
 *   maxLength={2000}
 *   helperText="Quanto mais detalhes, melhor"
 * />
 * 
 * // Textarea com erro (React Hook Form)
 * <Textarea 
 *   label="Observações"
 *   error={errors.observacoes?.message}
 *   {...register('observacoes')}
 * />
 * 
 * // Textarea com tamanho customizado
 * <Textarea 
 *   label="Comentário"
 *   rows={6}
 *   resize={false}
 * />
 * 
 * // Textarea desabilitado
 * <Textarea 
 *   label="Campo bloqueado"
 *   value="Texto fixo"
 *   disabled
 * />
 * 
 * // Textarea obrigatório
 * <Textarea 
 *   label="Descrição da demanda"
 *   required
 *   maxLength={2000}
 * />
 */

