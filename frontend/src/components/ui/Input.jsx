/**
 * Componente Input reutilizável
 * Input HTML com estilos consistentes, label, mensagens de erro e ícones
 */
import React from 'react'
import { cn } from '@/lib/utils'
import { AlertCircle } from 'lucide-react'

/**
 * Input de texto flexível com validação visual
 * 
 * @param {Object} props
 * @param {string} props.type - Tipo do input (text, email, password, number, date, etc.)
 * @param {string} props.label - Label do input
 * @param {string} props.error - Mensagem de erro (exibe em vermelho)
 * @param {string} props.helperText - Texto de ajuda abaixo do input
 * @param {boolean} props.required - Se o campo é obrigatório
 * @param {boolean} props.disabled - Se o input está desabilitado
 * @param {React.ReactNode} props.icon - Ícone à esquerda do input
 * @param {React.ReactNode} props.rightIcon - Ícone à direita do input
 * @param {string} props.className - Classes CSS adicionais
 * @param {string} props.placeholder - Placeholder do input
 * 
 * @example
 * <Input
 *   label="Nome completo"
 *   placeholder="Digite seu nome"
 *   required
 * />
 * 
 * @example
 * <Input
 *   label="Email"
 *   type="email"
 *   error={errors.email?.message}
 * />
 */
const Input = React.forwardRef(
  ({ 
    className,
    type = 'text',
    label,
    error,
    helperText,
    required = false,
    disabled = false,
    icon,
    rightIcon,
    id,
    ...props 
  }, ref) => {
    
    // Gerar ID único se não fornecido
    const inputId = id || `input-${Math.random().toString(36).substr(2, 9)}`
    
    return (
      <div className="w-full">
        {/* Label */}
        {label && (
          <label 
            htmlFor={inputId}
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
        
        {/* Container do Input (para suportar ícones) */}
        <div className="relative">
          {/* Ícone esquerdo */}
          {icon && (
            <div className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
              {icon}
            </div>
          )}
          
          {/* Input */}
          <input
            id={inputId}
            type={type}
            className={cn(
              // Base
              'flex w-full rounded-lg border bg-white text-sm',
              // Padding
              'px-3 py-2',
              icon && 'pl-10', // Espaço para ícone esquerdo
              rightIcon && 'pr-10', // Espaço para ícone direito
              error && 'pr-10', // Espaço para ícone de erro
              // Placeholder
              'placeholder:text-gray-400',
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
            aria-describedby={error ? `${inputId}-error` : helperText ? `${inputId}-helper` : undefined}
            {...props}
          />
          
          {/* Ícone direito ou ícone de erro */}
          {(rightIcon || error) && (
            <div className={cn(
              'absolute right-3 top-1/2 -translate-y-1/2',
              error ? 'text-error' : 'text-gray-400'
            )}>
              {error ? <AlertCircle className="h-4 w-4" /> : rightIcon}
            </div>
          )}
        </div>
        
        {/* Mensagem de erro */}
        {error && (
          <p 
            id={`${inputId}-error`}
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
            id={`${inputId}-helper`}
            className="mt-1.5 text-xs text-gray-500"
          >
            {helperText}
          </p>
        )}
      </div>
    )
  }
)

Input.displayName = 'Input'

export default Input

/**
 * EXEMPLOS DE USO:
 * 
 * // Input básico
 * <Input placeholder="Digite algo..." />
 * 
 * // Input com label
 * <Input 
 *   label="Nome completo"
 *   placeholder="João Silva"
 * />
 * 
 * // Input obrigatório
 * <Input 
 *   label="Email"
 *   type="email"
 *   required
 * />
 * 
 * // Input com erro (React Hook Form)
 * <Input 
 *   label="Senha"
 *   type="password"
 *   error={errors.password?.message}
 *   {...register('password')}
 * />
 * 
 * // Input com ícone
 * import { Mail } from 'lucide-react'
 * <Input 
 *   label="Email"
 *   type="email"
 *   icon={<Mail className="h-4 w-4" />}
 * />
 * 
 * // Input com texto de ajuda
 * <Input 
 *   label="Username"
 *   helperText="Apenas letras minúsculas e números"
 * />
 * 
 * // Input desabilitado
 * <Input 
 *   label="Campo bloqueado"
 *   value="Valor fixo"
 *   disabled
 * />
 * 
 * // Input de data
 * <Input 
 *   label="Data de nascimento"
 *   type="date"
 * />
 * 
 * // Input numérico
 * <Input 
 *   label="Idade"
 *   type="number"
 *   min="0"
 *   max="150"
 * />
 */

