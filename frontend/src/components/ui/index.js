/**
 * Exportações centralizadas dos componentes UI
 * Facilita os imports em outros arquivos
 * 
 * @example
 * import { Button, Input, Card, Badge, Alert } from '@/components/ui'
 */

// Componentes base
export { default as Button } from './Button'
export { default as Input } from './Input'
export { default as Textarea } from './Textarea'
export { default as Select } from './Select'
export { MultiSelect } from './MultiSelect'
export { default as Badge } from './Badge'

// Card e subcomponentes
export { 
  Card, 
  CardHeader, 
  CardTitle, 
  CardDescription, 
  CardContent, 
  CardFooter 
} from './Card'

// Alert e subcomponentes
export {
  Alert,
  AlertTitle,
  AlertDescription
} from './Alert'

// Dialog/Modal e subcomponentes
export {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogBody,
  DialogFooter
} from './Dialog'

/**
 * COMO USAR:
 * 
 * // Import individual
 * import Button from '@/components/ui/Button'
 * 
 * // Import múltiplo (recomendado)
 * import { Button, Input, Badge, Alert } from '@/components/ui'
 * 
 * // Import de subcomponentes
 * import { 
 *   Card, 
 *   CardHeader, 
 *   CardTitle, 
 *   Alert,
 *   AlertTitle,
 *   Dialog,
 *   DialogContent
 * } from '@/components/ui'
 * 
 * // Import completo
 * import {
 *   Button,
 *   Input,
 *   Textarea,
 *   Select,
 *   Badge,
 *   Card,
 *   Alert,
 *   Dialog
 * } from '@/components/ui'
 */

