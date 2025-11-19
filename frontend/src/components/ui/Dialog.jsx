/**
 * Componente Dialog/Modal reutilizável
 * Modal acessível com overlay e subcomponentes
 */
import React, { useEffect } from 'react'
import { cn } from '@/lib/utils'
import { X } from 'lucide-react'

/**
 * Dialog - Container principal do modal
 * 
 * @param {Object} props
 * @param {boolean} props.open - Se o modal está aberto
 * @param {Function} props.onOpenChange - Callback ao mudar estado
 * @param {React.ReactNode} props.children - Conteúdo do modal
 * 
 * @example
 * const [open, setOpen] = useState(false)
 * <Dialog open={open} onOpenChange={setOpen}>
 *   <DialogContent>
 *     <DialogHeader>
 *       <DialogTitle>Título</DialogTitle>
 *     </DialogHeader>
 *   </DialogContent>
 * </Dialog>
 */
const Dialog = ({ open, onOpenChange, children }) => {
  // Bloquear scroll do body quando modal aberto
  useEffect(() => {
    if (open) {
      document.body.style.overflow = 'hidden'
    } else {
      document.body.style.overflow = 'unset'
    }
    
    return () => {
      document.body.style.overflow = 'unset'
    }
  }, [open])
  
  // Fechar ao pressionar ESC
  useEffect(() => {
    const handleEscape = (e) => {
      if (e.key === 'Escape' && open) {
        onOpenChange?.(false)
      }
    }
    
    document.addEventListener('keydown', handleEscape)
    return () => document.removeEventListener('keydown', handleEscape)
  }, [open, onOpenChange])
  
  if (!open) return null
  
  return (
    <>
      {children}
    </>
  )
}

Dialog.displayName = 'Dialog'

/**
 * DialogOverlay - Overlay escuro de fundo
 */
const DialogOverlay = React.forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      // Posicionamento
      'fixed inset-0 z-50',
      // Aparência
      'bg-black/50 backdrop-blur-sm',
      // Animação
      'data-[state=open]:animate-in data-[state=closed]:animate-out',
      'data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0',
      className
    )}
    {...props}
  />
))
DialogOverlay.displayName = 'DialogOverlay'

/**
 * DialogContent - Container do conteúdo do modal
 * 
 * @param {Object} props
 * @param {Function} props.onClose - Callback ao fechar
 * @param {boolean} props.closeButton - Mostrar botão X (padrão: true)
 * @param {string} props.size - Tamanho (sm, default, lg, xl, full)
 */
const DialogContent = React.forwardRef(
  ({ 
    className,
    children,
    onClose,
    closeButton = true,
    size = 'default',
    ...props 
  }, ref) => {
    
    // Tamanhos
    const sizes = {
      sm: 'max-w-sm',
      default: 'max-w-lg',
      lg: 'max-w-2xl',
      xl: 'max-w-4xl',
      full: 'max-w-full mx-4',
    }
    
    return (
      <>
        {/* Overlay */}
        <DialogOverlay onClick={onClose} />
        
        {/* Modal */}
        <div
          className="fixed inset-0 z-50 flex items-center justify-center p-4 overflow-y-auto"
          onClick={onClose}
        >
          <div
            ref={ref}
            className={cn(
              // Layout
              'relative w-full',
              sizes[size],
              // Aparência
              'bg-white rounded-lg shadow-2xl',
              // Animação
              'animate-in fade-in-0 zoom-in-95',
              // Responsividade
              'my-auto',
              className
            )}
            onClick={(e) => e.stopPropagation()}
            role="dialog"
            aria-modal="true"
            {...props}
          >
            {children}
            
            {/* Botão de fechar */}
            {closeButton && onClose && (
              <button
                onClick={onClose}
                className={cn(
                  'absolute right-4 top-4',
                  'rounded-md p-1',
                  'text-gray-500 hover:text-gray-700',
                  'hover:bg-gray-100 active:bg-gray-200',
                  'transition-colors duration-200'
                )}
                aria-label="Fechar"
              >
                <X className="h-5 w-5" />
              </button>
            )}
          </div>
        </div>
      </>
    )
  }
)
DialogContent.displayName = 'DialogContent'

/**
 * DialogHeader - Cabeçalho do modal
 */
const DialogHeader = React.forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      'flex flex-col space-y-1.5 p-6 pb-4',
      className
    )}
    {...props}
  />
))
DialogHeader.displayName = 'DialogHeader'

/**
 * DialogTitle - Título do modal
 */
const DialogTitle = React.forwardRef(({ className, ...props }, ref) => (
  <h2
    ref={ref}
    className={cn(
      'text-2xl font-semibold leading-none tracking-tight text-gray-900',
      className
    )}
    {...props}
  />
))
DialogTitle.displayName = 'DialogTitle'

/**
 * DialogDescription - Descrição do modal
 */
const DialogDescription = React.forwardRef(({ className, ...props }, ref) => (
  <p
    ref={ref}
    className={cn(
      'text-sm text-gray-500',
      className
    )}
    {...props}
  />
))
DialogDescription.displayName = 'DialogDescription'

/**
 * DialogBody - Corpo/conteúdo principal do modal
 */
const DialogBody = React.forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      'px-6 py-4',
      className
    )}
    {...props}
  />
))
DialogBody.displayName = 'DialogBody'

/**
 * DialogFooter - Rodapé com botões de ação
 */
const DialogFooter = React.forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      'flex items-center justify-end gap-2 p-6 pt-4',
      className
    )}
    {...props}
  />
))
DialogFooter.displayName = 'DialogFooter'

export {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogBody,
  DialogFooter,
}

/**
 * EXEMPLOS DE USO:
 * 
 * // Modal básico
 * const [open, setOpen] = useState(false)
 * 
 * <Button onClick={() => setOpen(true)}>Abrir Modal</Button>
 * 
 * <Dialog open={open} onOpenChange={setOpen}>
 *   <DialogContent onClose={() => setOpen(false)}>
 *     <DialogHeader>
 *       <DialogTitle>Título do Modal</DialogTitle>
 *       <DialogDescription>
 *         Descrição do que este modal faz.
 *       </DialogDescription>
 *     </DialogHeader>
 *     <DialogBody>
 *       <p>Conteúdo do modal aqui...</p>
 *     </DialogBody>
 *     <DialogFooter>
 *       <Button variant="outline" onClick={() => setOpen(false)}>
 *         Cancelar
 *       </Button>
 *       <Button onClick={() => setOpen(false)}>
 *         Confirmar
 *       </Button>
 *     </DialogFooter>
 *   </DialogContent>
 * </Dialog>
 * 
 * // Modal de confirmação
 * <Dialog open={open} onOpenChange={setOpen}>
 *   <DialogContent onClose={() => setOpen(false)} size="sm">
 *     <DialogHeader>
 *       <DialogTitle>Confirmar exclusão</DialogTitle>
 *       <DialogDescription>
 *         Esta ação não pode ser desfeita.
 *       </DialogDescription>
 *     </DialogHeader>
 *     <DialogFooter>
 *       <Button variant="outline" onClick={() => setOpen(false)}>
 *         Cancelar
 *       </Button>
 *       <Button variant="destructive" onClick={handleDelete}>
 *         Deletar
 *       </Button>
 *     </DialogFooter>
 *   </DialogContent>
 * </Dialog>
 * 
 * // Modal com formulário
 * <Dialog open={open} onOpenChange={setOpen}>
 *   <DialogContent onClose={() => setOpen(false)} size="lg">
 *     <DialogHeader>
 *       <DialogTitle>Nova Demanda</DialogTitle>
 *     </DialogHeader>
 *     <DialogBody>
 *       <form className="space-y-4">
 *         <Input label="Nome" />
 *         <Textarea label="Descrição" />
 *       </form>
 *     </DialogBody>
 *     <DialogFooter>
 *       <Button variant="outline" onClick={() => setOpen(false)}>
 *         Cancelar
 *       </Button>
 *       <Button type="submit">
 *         Salvar
 *       </Button>
 *     </DialogFooter>
 *   </DialogContent>
 * </Dialog>
 * 
 * // Modal sem botão X
 * <Dialog open={open} onOpenChange={setOpen}>
 *   <DialogContent closeButton={false}>
 *     <DialogHeader>
 *       <DialogTitle>Processando...</DialogTitle>
 *     </DialogHeader>
 *     <DialogBody>
 *       <p>Aguarde enquanto processamos sua solicitação.</p>
 *     </DialogBody>
 *   </DialogContent>
 * </Dialog>
 * 
 * // Modal fullscreen
 * <Dialog open={open} onOpenChange={setOpen}>
 *   <DialogContent onClose={() => setOpen(false)} size="full">
 *     <DialogHeader>
 *       <DialogTitle>Visualização Completa</DialogTitle>
 *     </DialogHeader>
 *     <DialogBody>
 *       Conteúdo extenso...
 *     </DialogBody>
 *   </DialogContent>
 * </Dialog>
 */

