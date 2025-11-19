/** @type {import('tailwindcss').Config} */
export default {
  // Modo dark baseado em classe
  darkMode: ["class"],
  
  // Arquivos que o Tailwind vai escanear
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  
  theme: {
    extend: {
      // Cores customizadas do projeto
      colors: {
        // Cores principais
        primary: {
          DEFAULT: '#3B82F6',
          light: '#60A5FA',
          dark: '#2563EB',
        },
        secondary: {
          DEFAULT: '#8B5CF6',
          light: '#A78BFA',
          dark: '#7C3AED',
        },
        accent: {
          DEFAULT: '#10B981',
          light: '#34D399',
          dark: '#059669',
        },
        
        // Cores de status
        success: '#10B981',
        warning: '#F59E0B',
        error: '#EF4444',
        info: '#3B82F6',
        
        // Prioridades
        priority: {
          low: '#10B981',
          medium: '#F59E0B',
          high: '#F97316',
          urgent: '#EF4444',
        },
        
        // Background e texto
        background: '#FFFFFF',
        foreground: '#111827',
      },
      
      // Animações customizadas
      keyframes: {
        "fade-in": {
          "0%": { opacity: "0" },
          "100%": { opacity: "1" },
        },
        "slide-in": {
          "0%": { transform: "translateX(-100%)" },
          "100%": { transform: "translateX(0)" },
        },
      },
      animation: {
        "fade-in": "fade-in 0.3s ease-in-out",
        "slide-in": "slide-in 0.3s ease-in-out",
      },
    },
  },
  
  plugins: [],
}

