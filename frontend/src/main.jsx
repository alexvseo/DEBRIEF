import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { Toaster } from 'sonner'
import { AuthProvider } from '@/contexts/AuthContext'
import App from './App.jsx'
import './index.css'
import './styles/animations.css'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <BrowserRouter>
      <AuthProvider>
        <App />
        <Toaster 
          position="top-right"
          richColors
          closeButton
          duration={4000}
        />
      </AuthProvider>
    </BrowserRouter>
  </StrictMode>,
)
