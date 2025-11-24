/**
 * Componente Alert reutilizável
 * Alertas e notificações com ícones e variantes
 */
import React from 'react'
import { cn } from '@/lib/utils.js'
import { AlertCircle, CheckCircle, Info, AlertTriangle, X } from 'lucide-react'

/**
 * Alert - Container principal
 * 
 * @param {Object} props
 * @param {string} props.variant - Variante (default, success, warning, error, info)
 * @param {boolean} props.dismissible - Se pode ser fechado
 * @param {Function} props.onDismiss - Callback ao fechar
 * @param {React.ReactNode} props.icon - Ícone customizado
 * @param {string} props.className - Classes CSS adicionais
 * 
 * @example
 * <Alert variant="success">
 *   <AlertTitle>Sucesso!</AlertTitle>
 *   <AlertDescription>Sua demanda foi criada.</AlertDescription>
 * </Alert>
 */
const Alert = React.forwardRef(
  ({ 
    className,
    variant = 'default',
    dismissible = false,
    onDismiss,
    icon,
    children,
    ...props 
  }, ref) => {
    
    const [isVisible, setIsVisible] = React.useState(true)
    
    // Ícones padrão por variante
    const icons = {
      default: Info,
      success: CheckCircle,
      warning: AlertTriangle,
      error: AlertCircle,
      info: Info,
    }
    
    const Icon = icon || icons[variant]
    
    // Variantes
    const variants = {
      default: cn(
        'bg-gray-50 border-gray-200 text-gray-900',
        '[&>svg]:text-gray-600'
      ),
      success: cn(
        'bg-green-50 border-green-200 text-green-900',
        '[&>svg]:text-green-600'
      ),
      warning: cn(
        'bg-orange-50 border-orange-200 text-orange-900',
        '[&>svg]:text-orange-600'
      ),
      error: cn(
        'bg-red-50 border-red-200 text-red-900',
        '[&>svg]:text-red-600'
      ),
      info: cn(
        'bg-blue-50 border-blue-200 text-blue-900',
        '[&>svg]:text-blue-600'
      ),
    }
    
    const handleDismiss = () => {
      setIsVisible(false)
      if (onDismiss) {
        onDismiss()
      }
    }
    
    if (!isVisible) return null
    
    return (
      <div
        ref={ref}
        role="alert"
        className={cn(
          // Layout
          'relative w-full rounded-lg border p-4',
          // Display
          'flex items-start gap-3',
          // Transições
          'transition-all duration-200',
          // Variante
          variants[variant],
          className
        )}
        {...props}
      >
        {/* Ícone */}
        {Icon && (
          <Icon className="h-5 w-5 flex-shrink-0 mt-0.5" />
        )}
        
        {/* Conteúdo */}
        <div className="flex-1 space-y-1">
          {children}
        </div>
        
        {/* Botão de fechar */}
        {dismissible && (
          <button
            onClick={handleDismiss}
            className={cn(
              'flex-shrink-0 rounded-md p-1',
              'hover:bg-black/5 active:bg-black/10',
              'transition-colors duration-200'
            )}
            aria-label="Fechar alerta"
          >
            <X className="h-4 w-4" />
          </button>
        )}
      </div>
    )
  }
)
Alert.displayName = 'Alert'

/**
 * AlertTitle - Título do Alert
 */
const AlertTitle = React.forwardRef(({ className, ...props }, ref) => (
  <h5
    ref={ref}
    className={cn(
      'font-semibold text-sm leading-none tracking-tight',
      className
    )}
    {...props}
  />
))
AlertTitle.displayName = 'AlertTitle'

/**
 * AlertDescription - Descrição do Alert
 */
const AlertDescription = React.forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      'text-sm opacity-90',
      className
    )}
    {...props}
  />
))
AlertDescription.displayName = 'AlertDescription'

export { Alert, AlertTitle, AlertDescription }

/**
 * EXEMPLOS DE USO:
 * 
 * // Alert básico
 * <Alert>
 *   <AlertTitle>Atenção</AlertTitle>
 *   <AlertDescription>
 *     Esta é uma mensagem importante.
 *   </AlertDescription>
 * </Alert>
 * 
 * // Alert de sucesso
 * <Alert variant="success">
 *   <AlertTitle>Sucesso!</AlertTitle>
 *   <AlertDescription>
 *     Sua demanda foi criada com sucesso.
 *   </AlertDescription>
 * </Alert>
 * 
 * // Alert de erro
 * <Alert variant="error">
 *   <AlertTitle>Erro</AlertTitle>
 *   <AlertDescription>
 *     Não foi possível processar sua solicitação.
 *   </AlertDescription>
 * </Alert>
 * 
 * // Alert de aviso
 * <Alert variant="warning">
 *   <AlertTitle>Atenção</AlertTitle>
 *   <AlertDescription>
 *     Você tem 5 demandas próximas do prazo.
 *   </AlertDescription>
 * </Alert>
 * 
 * // Alert com botão de fechar
 * <Alert variant="info" dismissible>
 *   <AlertTitle>Dica</AlertTitle>
 *   <AlertDescription>
 *     Você pode editar suas demandas a qualquer momento.
 *   </AlertDescription>
 * </Alert>
 * 
 * // Alert com callback ao fechar
 * <Alert 
 *   variant="success" 
 *   dismissible 
 *   onDismiss={() => console.log('Fechado!')}
 * >
 *   <AlertTitle>Concluído</AlertTitle>
 *   <AlertDescription>
 *     Operação realizada com sucesso.
 *   </AlertDescription>
 * </Alert>
 * 
 * // Alert sem ícone
 * <Alert icon={null}>
 *   <AlertDescription>
 *     Mensagem simples sem ícone.
 *   </AlertDescription>
 * </Alert>
 * 
 * // Alert com ícone customizado
 * import { Rocket } from 'lucide-react'
 * <Alert icon={Rocket}>
 *   <AlertTitle>Novidade!</AlertTitle>
 *   <AlertDescription>
 *     Nova funcionalidade disponível.
 *   </AlertDescription>
 * </Alert>
 */

