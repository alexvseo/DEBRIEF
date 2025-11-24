/**
 * Utilitários para manipulação de classes CSS
 * Usado pelos componentes UI para combinar classes do Tailwind
 */
import { clsx } from "clsx"
import { twMerge } from "tailwind-merge"

/**
 * Combina classes CSS com Tailwind, resolvendo conflitos
 * 
 * Usa clsx para concatenar classes condicionalmente
 * Usa twMerge para resolver conflitos do Tailwind
 * 
 * @param {...any} inputs - Classes CSS a serem combinadas
 * @returns {string} - String com classes combinadas
 * 
 * @example
 * cn("px-4 py-2", "px-6") // => "px-6 py-2" (px-6 sobrescreve px-4)
 * cn("text-red-500", condition && "text-blue-500") // => condicional
 */
export function cn(...inputs) {
  return twMerge(clsx(inputs))
}

