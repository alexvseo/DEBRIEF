/**
 * Componente Badge reutilizável
 * Etiquetas/tags coloridas para status, categorias, etc.
 */
import React from 'react'
import { cn } from '@/lib/utils.js'

/**
 * Badge para exibir status, tags, categorias
 * 
 * @param {Object} props
 * @param {string} props.variant - Variante do badge (default, secondary, success, warning, error, outline)
 * @param {string} props.size - Tamanho (sm, default, lg)
 * @param {React.ReactNode} props.children - Conteúdo do badge
 * @param {string} props.className - Classes CSS adicionais
 * 
 * @example
 * <Badge variant="success">Concluída</Badge>
 * <Badge variant="warning">Pendente</Badge>
 */
const Badge = React.forwardRef(
  ({ 
    className, 
    variant = 'default',
    size = 'default',
    children,
    ...props 
  }, ref) => {
    
    // Classes base
    const baseClasses = cn(
      // Layout
      'inline-flex items-center gap-1',
      'rounded-full',
      'font-medium',
      'whitespace-nowrap',
      // Transições
      'transition-colors duration-200',
      // Seleção de texto
      'select-none'
    )
    
    // Variantes
    const variants = {
      default: cn(
        'bg-primary text-white',
        'hover:bg-primary-dark'
      ),
      secondary: cn(
        'bg-secondary text-white',
        'hover:bg-secondary-dark'
      ),
      success: cn(
        'bg-success text-white',
        'hover:bg-green-600'
      ),
      warning: cn(
        'bg-warning text-white',
        'hover:bg-orange-600'
      ),
      error: cn(
        'bg-error text-white',
        'hover:bg-red-600'
      ),
      info: cn(
        'bg-info text-white',
        'hover:bg-blue-600'
      ),
      outline: cn(
        'border-2 border-gray-300 bg-white text-gray-700',
        'hover:bg-gray-50'
      ),
      ghost: cn(
        'bg-gray-100 text-gray-700',
        'hover:bg-gray-200'
      ),
    }
    
    // Tamanhos
    const sizes = {
      sm: 'px-2 py-0.5 text-xs',
      default: 'px-2.5 py-1 text-xs',
      lg: 'px-3 py-1.5 text-sm',
    }
    
    return (
      <span
        className={cn(
          baseClasses,
          variants[variant],
          sizes[size],
          className
        )}
        ref={ref}
        {...props}
      >
        {children}
      </span>
    )
  }
)

Badge.displayName = 'Badge'

export default Badge

/**
 * EXEMPLOS DE USO:
 * 
 * // Status de demandas
 * <Badge variant="success">Concluída</Badge>
 * <Badge variant="warning">Pendente</Badge>
 * <Badge variant="error">Atrasada</Badge>
 * <Badge variant="info">Em andamento</Badge>
 * 
 * // Prioridades
 * <Badge variant="success">🟢 Baixa</Badge>
 * <Badge variant="warning">🟡 Média</Badge>
 * <Badge variant="error">🔴 Alta</Badge>
 * 
 * // Com ícones
 * import { Clock, Check } from 'lucide-react'
 * <Badge variant="warning">
 *   <Clock className="h-3 w-3" />
 *   Aguardando
 * </Badge>
 * 
 * // Tamanhos
 * <Badge size="sm">Pequeno</Badge>
 * <Badge size="default">Padrão</Badge>
 * <Badge size="lg">Grande</Badge>
 * 
 * // Customizado
 * <Badge className="bg-purple-500">Custom</Badge>
 * 
 * // Em tabelas
 * <td>
 *   <Badge variant="success">Ativo</Badge>
 * </td>
 * 
 * // Múltiplos badges
 * <div className="flex gap-2">
 *   <Badge variant="default">React</Badge>
 *   <Badge variant="secondary">TypeScript</Badge>
 *   <Badge variant="success">Tailwind</Badge>
 * </div>
 */

