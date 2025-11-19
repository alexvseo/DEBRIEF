/**
 * Componente Button reutilizável
 * Baseado no padrão shadcn/ui com múltiplas variantes e tamanhos
 */
import React from 'react'
import { cn } from '@/lib/utils'

/**
 * Botão flexível com suporte a variantes, tamanhos e estados
 * 
 * @param {Object} props
 * @param {string} props.variant - Variante do botão (default, secondary, outline, ghost, destructive, success)
 * @param {string} props.size - Tamanho do botão (default, sm, lg, icon)
 * @param {boolean} props.disabled - Se o botão está desabilitado
 * @param {string} props.className - Classes CSS adicionais
 * @param {React.ReactNode} props.children - Conteúdo do botão
 * @param {Function} props.onClick - Handler de clique
 * 
 * @example
 * <Button variant="default" size="lg" onClick={handleClick}>
 *   Criar Demanda
 * </Button>
 * 
 * @example
 * <Button variant="outline" size="sm" disabled>
 *   Cancelar
 * </Button>
 */
const Button = React.forwardRef(
  ({ 
    className, 
    variant = 'default', 
    size = 'default', 
    disabled = false,
    type = 'button',
    children, 
    ...props 
  }, ref) => {
    
    // Classes base do botão (aplicadas a todas as variantes)
    const baseClasses = cn(
      // Layout e tipografia
      'inline-flex items-center justify-center gap-2',
      'font-medium text-sm',
      'rounded-lg',
      'whitespace-nowrap',
      // Transições suaves
      'transition-all duration-200',
      // Focus visível para acessibilidade
      'focus-visible:outline-none',
      'focus-visible:ring-2 focus-visible:ring-offset-2',
      // Estados desabilitados
      'disabled:pointer-events-none disabled:opacity-50 disabled:cursor-not-allowed',
      // Prevenção de seleção de texto
      'select-none'
    )
    
    // Variantes de estilo
    const variants = {
      default: cn(
        'bg-primary text-white shadow-sm',
        'hover:bg-primary-dark hover:shadow-md',
        'active:scale-95',
        'focus-visible:ring-primary'
      ),
      secondary: cn(
        'bg-secondary text-white shadow-sm',
        'hover:bg-secondary-dark hover:shadow-md',
        'active:scale-95',
        'focus-visible:ring-secondary'
      ),
      outline: cn(
        'border-2 border-gray-300 bg-white text-gray-700',
        'hover:bg-gray-50 hover:border-gray-400',
        'active:scale-95',
        'focus-visible:ring-gray-300'
      ),
      ghost: cn(
        'bg-transparent text-gray-700',
        'hover:bg-gray-100 hover:text-gray-900',
        'active:scale-95',
        'focus-visible:ring-gray-300'
      ),
      destructive: cn(
        'bg-error text-white shadow-sm',
        'hover:bg-red-600 hover:shadow-md',
        'active:scale-95',
        'focus-visible:ring-error'
      ),
      success: cn(
        'bg-success text-white shadow-sm',
        'hover:bg-green-600 hover:shadow-md',
        'active:scale-95',
        'focus-visible:ring-success'
      ),
      link: cn(
        'text-primary underline-offset-4',
        'hover:underline hover:text-primary-dark',
        'focus-visible:ring-primary'
      ),
    }
    
    // Tamanhos
    const sizes = {
      default: 'h-10 px-4 py-2',
      sm: 'h-8 px-3 py-1.5 text-xs',
      lg: 'h-12 px-6 py-3 text-base',
      icon: 'h-10 w-10 p-0',
    }
    
    return (
      <button
        className={cn(
          baseClasses,
          variants[variant],
          sizes[size],
          className
        )}
        ref={ref}
        disabled={disabled}
        type={type}
        {...props}
      >
        {children}
      </button>
    )
  }
)

Button.displayName = 'Button'

export default Button

/**
 * EXEMPLOS DE USO:
 * 
 * // Botão primário padrão
 * <Button>Salvar</Button>
 * 
 * // Botão secundário grande
 * <Button variant="secondary" size="lg">Continuar</Button>
 * 
 * // Botão outline pequeno
 * <Button variant="outline" size="sm">Cancelar</Button>
 * 
 * // Botão ghost (sem fundo)
 * <Button variant="ghost">Fechar</Button>
 * 
 * // Botão destrutivo (ações perigosas)
 * <Button variant="destructive">Deletar</Button>
 * 
 * // Botão de sucesso
 * <Button variant="success">Confirmar</Button>
 * 
 * // Botão com ícone
 * <Button size="icon">
 *   <X className="h-4 w-4" />
 * </Button>
 * 
 * // Botão desabilitado
 * <Button disabled>Procesando...</Button>
 * 
 * // Botão com handler
 * <Button onClick={() => console.log('Clicou!')}>
 *   Clique aqui
 * </Button>
 * 
 * // Botão submit em formulário
 * <Button type="submit">Enviar</Button>
 */

