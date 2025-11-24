# Frontend Dockerfile - DeBrief React App

# Etapa 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Copiar package files
COPY package*.json ./

# Instalar dependências
RUN npm ci --silent

# Copiar código fonte
COPY . .

# Build args para variáveis de ambiente
ARG VITE_API_URL=/api
ENV VITE_API_URL=$VITE_API_URL

# Build da aplicação para produção
RUN npm run build

# Etapa 2: Servir com nginx
FROM nginx:alpine

# Copiar build para nginx
COPY --from=builder /app/dist /usr/share/nginx/html

# Copiar configuração customizada do nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expor porta
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:80/ || exit 1

# Iniciar nginx
CMD ["nginx", "-g", "daemon off;"]

