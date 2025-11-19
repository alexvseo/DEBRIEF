/**
 * Componente Card e subcomponentes
 * Container flexível para agrupar conteúdo relacionado
 */
import React from 'react'
import { cn } from '@/lib/utils'

/**
 * Card - Container principal
 * 
 * @param {Object} props
 * @param {string} props.className - Classes CSS adicionais
 * @param {React.ReactNode} props.children - Conteúdo do card
 * 
 * @example
 * <Card>
 *   <CardHeader>
 *     <CardTitle>Título</CardTitle>
 *   </CardHeader>
 *   <CardContent>
 *     Conteúdo aqui
 *   </CardContent>
 * </Card>
 */
const Card = React.forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      // Layout e espaçamento
      'rounded-lg',
      // Cores e bordas
      'border border-gray-200 bg-white',
      // Sombra
      'shadow-card',
      // Transições
      'transition-shadow duration-200',
      // Hover
      'hover:shadow-lg',
      // Classes customizadas
      className
    )}
    {...props}
  />
))
Card.displayName = 'Card'

/**
 * CardHeader - Cabeçalho do Card
 * Geralmente contém CardTitle e CardDescription
 * 
 * @example
 * <CardHeader>
 *   <CardTitle>Minhas Demandas</CardTitle>
 *   <CardDescription>Gerencie suas solicitações</CardDescription>
 * </CardHeader>
 */
const CardHeader = React.forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      'flex flex-col space-y-1.5 p-6',
      className
    )}
    {...props}
  />
))
CardHeader.displayName = 'CardHeader'

/**
 * CardTitle - Título do Card
 * 
 * @example
 * <CardTitle>Título Principal</CardTitle>
 */
const CardTitle = React.forwardRef(({ className, children, ...props }, ref) => (
  <h3
    ref={ref}
    className={cn(
      'text-2xl font-semibold leading-none tracking-tight text-gray-900',
      className
    )}
    {...props}
  >
    {children}
  </h3>
))
CardTitle.displayName = 'CardTitle'

/**
 * CardDescription - Descrição/subtítulo do Card
 * 
 * @example
 * <CardDescription>Acompanhe suas solicitações</CardDescription>
 */
const CardDescription = React.forwardRef(({ className, ...props }, ref) => (
  <p
    ref={ref}
    className={cn(
      'text-sm text-gray-500',
      className
    )}
    {...props}
  />
))
CardDescription.displayName = 'CardDescription'

/**
 * CardContent - Conteúdo principal do Card
 * 
 * @example
 * <CardContent>
 *   <p>Conteúdo do card...</p>
 * </CardContent>
 */
const CardContent = React.forwardRef(({ className, ...props }, ref) => (
  <div 
    ref={ref} 
    className={cn('p-6 pt-0', className)} 
    {...props} 
  />
))
CardContent.displayName = 'CardContent'

/**
 * CardFooter - Rodapé do Card
 * Geralmente contém botões de ação
 * 
 * @example
 * <CardFooter>
 *   <Button>Salvar</Button>
 *   <Button variant="outline">Cancelar</Button>
 * </CardFooter>
 */
const CardFooter = React.forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      'flex items-center p-6 pt-0',
      className
    )}
    {...props}
  />
))
CardFooter.displayName = 'CardFooter'

// Exportar todos os componentes
export { Card, CardHeader, CardFooter, CardTitle, CardDescription, CardContent }

/**
 * EXEMPLOS DE USO:
 * 
 * // Card básico
 * <Card>
 *   <CardHeader>
 *     <CardTitle>Título</CardTitle>
 *   </CardHeader>
 *   <CardContent>
 *     Conteúdo
 *   </CardContent>
 * </Card>
 * 
 * // Card completo
 * <Card>
 *   <CardHeader>
 *     <CardTitle>Minhas Demandas</CardTitle>
 *     <CardDescription>
 *       Acompanhe suas solicitações e gerencie prazos
 *     </CardDescription>
 *   </CardHeader>
 *   <CardContent>
 *     <p>Lista de demandas aqui...</p>
 *   </CardContent>
 *   <CardFooter>
 *     <Button>Nova Demanda</Button>
 *   </CardFooter>
 * </Card>
 * 
 * // Card com grid de estatísticas
 * <div className="grid grid-cols-3 gap-4">
 *   <Card>
 *     <CardHeader>
 *       <CardTitle>150</CardTitle>
 *       <CardDescription>Total de Demandas</CardDescription>
 *     </CardHeader>
 *   </Card>
 *   <Card>
 *     <CardHeader>
 *       <CardTitle>45</CardTitle>
 *       <CardDescription>Em Andamento</CardDescription>
 *     </CardHeader>
 *   </Card>
 *   <Card>
 *     <CardHeader>
 *       <CardTitle>105</CardTitle>
 *       <CardDescription>Concluídas</CardDescription>
 *     </CardHeader>
 *   </Card>
 * </div>
 * 
 * // Card com classe customizada
 * <Card className="bg-blue-50 border-blue-200">
 *   <CardHeader>
 *     <CardTitle>Destaque</CardTitle>
 *   </CardHeader>
 *   <CardContent>
 *     Card com estilo customizado
 *   </CardContent>
 * </Card>
 * 
 * // Card com múltiplos botões no footer
 * <Card>
 *   <CardHeader>
 *     <CardTitle>Confirmar ação</CardTitle>
 *   </CardHeader>
 *   <CardContent>
 *     Tem certeza que deseja continuar?
 *   </CardContent>
 *   <CardFooter className="gap-2">
 *     <Button variant="default">Confirmar</Button>
 *     <Button variant="outline">Cancelar</Button>
 *   </CardFooter>
 * </Card>
 */

