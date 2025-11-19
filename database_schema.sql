-- ============================================================================
-- SCRIPT SQL COMPLETO - SISTEMA DEBRIEF
-- ============================================================================
-- Descrição: Script completo para criar o banco de dados do sistema DeBrief
-- Banco: PostgreSQL
-- Uso: Importar no DBeaver ou executar via psql
-- 
-- Instruções:
-- 1. Conectar ao banco 'dbrief' no DBeaver
-- 2. Executar este script completo
-- 3. Verificar se todas as tabelas foram criadas
-- ============================================================================

-- ============================================================================
-- CONFIGURAÇÕES INICIAIS
-- ============================================================================

-- Definir encoding UTF-8
SET client_encoding = 'UTF8';

-- ============================================================================
-- LIMPEZA (OPCIONAL - DESCOMENTE SE QUISER RECRIAR TUDO)
-- ============================================================================

-- ATENÇÃO: Descomente as linhas abaixo apenas se quiser DROPAR tudo e recriar!
-- DROP TABLE IF EXISTS anexos CASCADE;
-- DROP TABLE IF EXISTS demandas CASCADE;
-- DROP TABLE IF EXISTS configuracoes CASCADE;
-- DROP TABLE IF EXISTS secretarias CASCADE;
-- DROP TABLE IF EXISTS tipos_demanda CASCADE;
-- DROP TABLE IF EXISTS prioridades CASCADE;
-- DROP TABLE IF EXISTS users CASCADE;
-- DROP TABLE IF EXISTS clientes CASCADE;
-- DROP TYPE IF EXISTS tipousuario CASCADE;
-- DROP TYPE IF EXISTS statusdemanda CASCADE;
-- DROP TYPE IF EXISTS tipoconfiguracao CASCADE;

-- ============================================================================
-- TIPOS ENUM
-- ============================================================================

-- Tipo de Usuário
CREATE TYPE tipousuario AS ENUM ('master', 'cliente');
COMMENT ON TYPE tipousuario IS 'Tipo de usuário: master (admin) ou cliente';

-- Status de Demanda
CREATE TYPE statusdemanda AS ENUM (
    'aberta',
    'em_andamento',
    'aguardando_cliente',
    'concluida',
    'cancelada'
);
COMMENT ON TYPE statusdemanda IS 'Status possíveis de uma demanda';

-- Tipo de Configuração
CREATE TYPE tipoconfiguracao AS ENUM ('trello', 'whatsapp', 'sistema', 'email');
COMMENT ON TYPE tipoconfiguracao IS 'Tipos de configuração do sistema';

-- ============================================================================
-- TABELA: clientes
-- ============================================================================

CREATE TABLE clientes (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    nome VARCHAR(200) NOT NULL,
    whatsapp_group_id VARCHAR(100),
    trello_member_id VARCHAR(100),
    ativo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE clientes IS 'Tabela de clientes (empresas/órgãos)';
COMMENT ON COLUMN clientes.id IS 'ID único do cliente (UUID)';
COMMENT ON COLUMN clientes.nome IS 'Nome da empresa/órgão cliente';
COMMENT ON COLUMN clientes.whatsapp_group_id IS 'ID do grupo WhatsApp (formato: numero@g.us)';
COMMENT ON COLUMN clientes.trello_member_id IS 'ID do membro no Trello para atribuir cards';
COMMENT ON COLUMN clientes.ativo IS 'Status ativo/inativo do cliente';

-- Índices
CREATE INDEX idx_clientes_nome ON clientes(nome);
CREATE INDEX idx_clientes_ativo ON clientes(ativo);

-- ============================================================================
-- TABELA: users
-- ============================================================================

CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    nome_completo VARCHAR(200) NOT NULL,
    tipo tipousuario NOT NULL DEFAULT 'cliente',
    cliente_id VARCHAR(36),
    ativo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_users_cliente FOREIGN KEY (cliente_id) 
        REFERENCES clientes(id) ON DELETE SET NULL
);

COMMENT ON TABLE users IS 'Tabela de usuários do sistema';
COMMENT ON COLUMN users.id IS 'ID único do usuário (UUID)';
COMMENT ON COLUMN users.username IS 'Nome de usuário para login (único)';
COMMENT ON COLUMN users.email IS 'Email do usuário (único)';
COMMENT ON COLUMN users.password_hash IS 'Senha criptografada com bcrypt';
COMMENT ON COLUMN users.nome_completo IS 'Nome completo do usuário';
COMMENT ON COLUMN users.tipo IS 'Tipo de usuário: master (admin) ou cliente';
COMMENT ON COLUMN users.cliente_id IS 'ID do cliente (NULL para usuários master)';
COMMENT ON COLUMN users.ativo IS 'Status ativo/inativo do usuário';

-- Índices
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_tipo ON users(tipo);
CREATE INDEX idx_users_cliente_id ON users(cliente_id);
CREATE INDEX idx_users_ativo ON users(ativo);

-- ============================================================================
-- TABELA: tipos_demanda
-- ============================================================================

CREATE TABLE tipos_demanda (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    nome VARCHAR(100) NOT NULL UNIQUE,
    cor VARCHAR(7) NOT NULL DEFAULT '#3B82F6',
    ativo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE tipos_demanda IS 'Tabela de tipos de demanda (Design, Desenvolvimento, etc)';
COMMENT ON COLUMN tipos_demanda.id IS 'ID único do tipo (UUID)';
COMMENT ON COLUMN tipos_demanda.nome IS 'Nome do tipo de demanda';
COMMENT ON COLUMN tipos_demanda.cor IS 'Cor hexadecimal para UI (ex: #3B82F6)';
COMMENT ON COLUMN tipos_demanda.ativo IS 'Status ativo/inativo';

-- Índices
CREATE INDEX idx_tipos_demanda_nome ON tipos_demanda(nome);
CREATE INDEX idx_tipos_demanda_ativo ON tipos_demanda(ativo);

-- ============================================================================
-- TABELA: prioridades
-- ============================================================================

CREATE TABLE prioridades (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    nome VARCHAR(50) NOT NULL UNIQUE,
    nivel INTEGER NOT NULL,
    cor VARCHAR(7) NOT NULL DEFAULT '#10B981',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_prioridade_nivel CHECK (nivel >= 1 AND nivel <= 10)
);

COMMENT ON TABLE prioridades IS 'Tabela de prioridades (Baixa, Média, Alta, Urgente)';
COMMENT ON COLUMN prioridades.id IS 'ID único da prioridade (UUID)';
COMMENT ON COLUMN prioridades.nome IS 'Nome da prioridade';
COMMENT ON COLUMN prioridades.nivel IS 'Nível numérico (1=Baixa, 2=Média, 3=Alta, 4+=Urgente)';
COMMENT ON COLUMN prioridades.cor IS 'Cor hexadecimal para UI';

-- Índices
CREATE INDEX idx_prioridades_nome ON prioridades(nome);
CREATE INDEX idx_prioridades_nivel ON prioridades(nivel);

-- ============================================================================
-- TABELA: secretarias
-- ============================================================================

CREATE TABLE secretarias (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    nome VARCHAR(200) NOT NULL,
    cliente_id VARCHAR(36) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_secretarias_cliente FOREIGN KEY (cliente_id) 
        REFERENCES clientes(id) ON DELETE CASCADE
);

COMMENT ON TABLE secretarias IS 'Tabela de secretarias/departamentos dos clientes';
COMMENT ON COLUMN secretarias.id IS 'ID único da secretaria (UUID)';
COMMENT ON COLUMN secretarias.nome IS 'Nome da secretaria/departamento';
COMMENT ON COLUMN secretarias.cliente_id IS 'ID do cliente (FK)';
COMMENT ON COLUMN secretarias.ativo IS 'Status ativo/inativo';

-- Índices
CREATE INDEX idx_secretarias_nome ON secretarias(nome);
CREATE INDEX idx_secretarias_cliente_id ON secretarias(cliente_id);
CREATE INDEX idx_secretarias_ativo ON secretarias(ativo);

-- ============================================================================
-- TABELA: demandas
-- ============================================================================

CREATE TABLE demandas (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    nome VARCHAR(200) NOT NULL,
    descricao TEXT NOT NULL,
    status statusdemanda NOT NULL DEFAULT 'aberta',
    prazo_final DATE,
    data_conclusao TIMESTAMP WITH TIME ZONE,
    usuario_id VARCHAR(36) NOT NULL,
    cliente_id VARCHAR(36) NOT NULL,
    tipo_demanda_id VARCHAR(36) NOT NULL,
    secretaria_id VARCHAR(36),
    prioridade_id VARCHAR(36) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_demandas_usuario FOREIGN KEY (usuario_id) 
        REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_demandas_cliente FOREIGN KEY (cliente_id) 
        REFERENCES clientes(id) ON DELETE RESTRICT,
    CONSTRAINT fk_demandas_tipo_demanda FOREIGN KEY (tipo_demanda_id) 
        REFERENCES tipos_demanda(id) ON DELETE RESTRICT,
    CONSTRAINT fk_demandas_secretaria FOREIGN KEY (secretaria_id) 
        REFERENCES secretarias(id) ON DELETE SET NULL,
    CONSTRAINT fk_demandas_prioridade FOREIGN KEY (prioridade_id) 
        REFERENCES prioridades(id) ON DELETE RESTRICT
);

COMMENT ON TABLE demandas IS 'Tabela de demandas/solicitações dos clientes';
COMMENT ON COLUMN demandas.id IS 'ID único da demanda (UUID)';
COMMENT ON COLUMN demandas.nome IS 'Nome/título da demanda';
COMMENT ON COLUMN demandas.descricao IS 'Descrição detalhada da demanda';
COMMENT ON COLUMN demandas.status IS 'Status atual da demanda';
COMMENT ON COLUMN demandas.prazo_final IS 'Data limite para conclusão';
COMMENT ON COLUMN demandas.data_conclusao IS 'Data real de conclusão';
COMMENT ON COLUMN demandas.usuario_id IS 'ID do usuário que criou a demanda';
COMMENT ON COLUMN demandas.cliente_id IS 'ID do cliente';
COMMENT ON COLUMN demandas.tipo_demanda_id IS 'ID do tipo de demanda';
COMMENT ON COLUMN demandas.secretaria_id IS 'ID da secretaria responsável';
COMMENT ON COLUMN demandas.prioridade_id IS 'ID da prioridade';

-- Índices
CREATE INDEX idx_demandas_status ON demandas(status);
CREATE INDEX idx_demandas_usuario_id ON demandas(usuario_id);
CREATE INDEX idx_demandas_cliente_id ON demandas(cliente_id);
CREATE INDEX idx_demandas_tipo_demanda_id ON demandas(tipo_demanda_id);
CREATE INDEX idx_demandas_secretaria_id ON demandas(secretaria_id);
CREATE INDEX idx_demandas_prioridade_id ON demandas(prioridade_id);
CREATE INDEX idx_demandas_prazo_final ON demandas(prazo_final);

-- ============================================================================
-- TABELA: anexos
-- ============================================================================

CREATE TABLE anexos (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    demanda_id VARCHAR(36) NOT NULL,
    nome_arquivo VARCHAR(500) NOT NULL,
    caminho VARCHAR(1000) NOT NULL,
    tamanho INTEGER NOT NULL,
    tipo_mime VARCHAR(100),
    trello_attachment_id VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_anexos_demanda FOREIGN KEY (demanda_id) 
        REFERENCES demandas(id) ON DELETE CASCADE
);

COMMENT ON TABLE anexos IS 'Tabela de anexos/arquivos das demandas';
COMMENT ON COLUMN anexos.id IS 'ID único do anexo (UUID)';
COMMENT ON COLUMN anexos.demanda_id IS 'ID da demanda (FK)';
COMMENT ON COLUMN anexos.nome_arquivo IS 'Nome original do arquivo';
COMMENT ON COLUMN anexos.caminho IS 'Path no servidor ou URL';
COMMENT ON COLUMN anexos.tamanho IS 'Tamanho em bytes';
COMMENT ON COLUMN anexos.tipo_mime IS 'Tipo MIME (ex: application/pdf)';
COMMENT ON COLUMN anexos.trello_attachment_id IS 'ID do anexo no Trello (se aplicável)';

-- Índices
CREATE INDEX idx_anexos_demanda_id ON anexos(demanda_id);

-- ============================================================================
-- TABELA: configuracoes
-- ============================================================================

CREATE TABLE configuracoes (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    chave VARCHAR(100) NOT NULL UNIQUE,
    valor TEXT NOT NULL,
    tipo tipoconfiguracao NOT NULL,
    descricao VARCHAR(500),
    is_sensivel VARCHAR(10) NOT NULL DEFAULT 'false',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE configuracoes IS 'Tabela de configurações do sistema';
COMMENT ON COLUMN configuracoes.id IS 'ID único da configuração (UUID)';
COMMENT ON COLUMN configuracoes.chave IS 'Identificador único da configuração';
COMMENT ON COLUMN configuracoes.valor IS 'Valor da configuração (criptografado se sensível)';
COMMENT ON COLUMN configuracoes.tipo IS 'Categoria da configuração';
COMMENT ON COLUMN configuracoes.descricao IS 'Descrição da configuração';
COMMENT ON COLUMN configuracoes.is_sensivel IS 'Se o valor é sensível (true/false)';

-- Índices
CREATE INDEX idx_configuracoes_chave ON configuracoes(chave);
CREATE INDEX idx_configuracoes_tipo ON configuracoes(tipo);

-- ============================================================================
-- DADOS INICIAIS (SEEDS)
-- ============================================================================

-- ============================================================================
-- 1. TIPOS DE DEMANDA
-- ============================================================================

INSERT INTO tipos_demanda (id, nome, cor, ativo) VALUES
    (gen_random_uuid()::text, 'Design', '#3B82F6', true),
    (gen_random_uuid()::text, 'Desenvolvimento', '#8B5CF6', true),
    (gen_random_uuid()::text, 'Conteúdo', '#10B981', true),
    (gen_random_uuid()::text, 'Vídeo', '#F59E0B', true)
ON CONFLICT (nome) DO NOTHING;

-- ============================================================================
-- 2. PRIORIDADES
-- ============================================================================

INSERT INTO prioridades (id, nome, nivel, cor) VALUES
    (gen_random_uuid()::text, 'Baixa', 1, '#10B981'),
    (gen_random_uuid()::text, 'Média', 2, '#F59E0B'),
    (gen_random_uuid()::text, 'Alta', 3, '#F97316'),
    (gen_random_uuid()::text, 'Urgente', 4, '#EF4444')
ON CONFLICT (nome) DO NOTHING;

-- ============================================================================
-- 3. CLIENTE DE EXEMPLO
-- ============================================================================

INSERT INTO clientes (id, nome, whatsapp_group_id, trello_member_id, ativo) VALUES
    (gen_random_uuid()::text, 'Prefeitura Municipal Exemplo', '5511999999999-1234567890@g.us', 'exemplo123abc', true)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 4. SECRETARIAS (Assumindo que o cliente foi criado acima)
-- ============================================================================

-- Nota: Os IDs das secretarias dependem do ID do cliente criado acima
-- Em produção, você precisará ajustar os IDs manualmente ou usar subqueries

INSERT INTO secretarias (id, nome, cliente_id, ativo)
SELECT 
    gen_random_uuid()::text,
    nome_secretaria,
    (SELECT id FROM clientes WHERE nome = 'Prefeitura Municipal Exemplo' LIMIT 1),
    true
FROM (VALUES
    ('Secretaria de Saúde'),
    ('Secretaria de Educação'),
    ('Secretaria de Cultura'),
    ('Secretaria de Assistência Social'),
    ('Gabinete do Prefeito'),
    ('Secretaria de Obras')
) AS secretarias_nomes(nome_secretaria)
WHERE NOT EXISTS (
    SELECT 1 FROM secretarias s 
    WHERE s.nome = secretarias_nomes.nome_secretaria 
    AND s.cliente_id = (SELECT id FROM clientes WHERE nome = 'Prefeitura Municipal Exemplo' LIMIT 1)
);

-- ============================================================================
-- 5. USUÁRIOS
-- ============================================================================

-- Usuário Master (admin)
-- Senha: admin123
INSERT INTO users (id, username, email, password_hash, nome_completo, tipo, cliente_id, ativo) VALUES
    (gen_random_uuid()::text, 
     'admin', 
     'admin@debrief.com', 
     '$2b$12$..w1XluSzwwvQQ5UzY5dB.svo6MANHFKlg6QDTyHSKJKguFmrSTW2',
     'Administrador Master',
     'master',
     NULL,
     true)
ON CONFLICT (username) DO NOTHING;

-- Usuário Cliente
-- Senha: cliente123
INSERT INTO users (id, username, email, password_hash, nome_completo, tipo, cliente_id, ativo)
SELECT 
    gen_random_uuid()::text,
    'cliente',
    'cliente@prefeitura.com',
    '$2b$12$4wj9iGKCmsgq5ly5DAlFLubvyip4a6xMzqrbAfFU0oQwja7ZsNDZu',
    'João Silva',
    'cliente',
    (SELECT id FROM clientes WHERE nome = 'Prefeitura Municipal Exemplo' LIMIT 1),
    true
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'cliente');

-- ============================================================================
-- 6. DEMANDAS DE EXEMPLO
-- ============================================================================

-- Nota: As demandas dependem dos IDs criados acima
-- Em produção, você precisará ajustar os IDs manualmente

INSERT INTO demandas (
    id, nome, descricao, status, prazo_final, 
    usuario_id, cliente_id, tipo_demanda_id, secretaria_id, prioridade_id
)
SELECT 
    gen_random_uuid()::text,
    dados.nome,
    dados.descricao,
    dados.status::statusdemanda,
    dados.prazo_final,
    (SELECT id FROM users WHERE username = 'cliente' LIMIT 1),
    (SELECT id FROM clientes WHERE nome = 'Prefeitura Municipal Exemplo' LIMIT 1),
    (SELECT id FROM tipos_demanda WHERE nome = dados.tipo_nome LIMIT 1),
    (SELECT id FROM secretarias WHERE nome = dados.secretaria_nome AND cliente_id = (SELECT id FROM clientes WHERE nome = 'Prefeitura Municipal Exemplo' LIMIT 1) LIMIT 1),
    (SELECT id FROM prioridades WHERE nivel = dados.prioridade_nivel LIMIT 1)
FROM (VALUES
    ('Design de Banner para Campanha de Vacinação',
     'Criar conjunto de banners para redes sociais promovendo a campanha de vacinação contra gripe',
     'em_andamento',
     CURRENT_DATE + INTERVAL '15 days',
     'Design',
     'Secretaria de Saúde',
     3),
    ('Desenvolvimento de Landing Page para Festival Cultural',
     'Criar página responsiva para divulgar o Festival de Inverno com formulário de inscrição',
     'aberta',
     CURRENT_DATE + INTERVAL '30 days',
     'Desenvolvimento',
     'Secretaria de Cultura',
     2),
    ('Posts para Redes Sociais - Dezembro',
     'Criação de 15 posts (texto e imagem) para Instagram e Facebook',
     'aberta',
     CURRENT_DATE + INTERVAL '45 days',
     'Design',
     'Secretaria de Saúde',
     1)
) AS dados(nome, descricao, status, prazo_final, tipo_nome, secretaria_nome, prioridade_nivel)
WHERE NOT EXISTS (
    SELECT 1 FROM demandas d 
    WHERE d.nome = dados.nome
);

-- ============================================================================
-- 7. CONFIGURAÇÕES PADRÃO
-- ============================================================================

INSERT INTO configuracoes (id, chave, valor, tipo, descricao, is_sensivel) VALUES
    (gen_random_uuid()::text, 'trello_api_key', '', 'trello', 'Chave de API do Trello', 'true'),
    (gen_random_uuid()::text, 'trello_token', '', 'trello', 'Token de acesso do Trello', 'true'),
    (gen_random_uuid()::text, 'trello_board_id', '', 'trello', 'ID do Board do Trello', 'false'),
    (gen_random_uuid()::text, 'trello_list_id', '', 'trello', 'ID da Lista do Trello', 'false'),
    (gen_random_uuid()::text, 'wpp_url', '', 'whatsapp', 'URL do servidor WPPConnect', 'false'),
    (gen_random_uuid()::text, 'wpp_instance', '', 'whatsapp', 'Instância do WPPConnect', 'false'),
    (gen_random_uuid()::text, 'wpp_token', '', 'whatsapp', 'Token de acesso do WPPConnect', 'true'),
    (gen_random_uuid()::text, 'max_upload_size', '52428800', 'sistema', 'Tamanho máximo de upload em bytes (50MB)', 'false'),
    (gen_random_uuid()::text, 'allowed_extensions', 'pdf,jpg,jpeg,png', 'sistema', 'Extensões de arquivo permitidas', 'false'),
    (gen_random_uuid()::text, 'session_timeout', '1800', 'sistema', 'Timeout de sessão em segundos (30min)', 'false')
ON CONFLICT (chave) DO NOTHING;

-- ============================================================================
-- VERIFICAÇÕES FINAIS
-- ============================================================================

-- Verificar tabelas criadas
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as colunas
FROM information_schema.tables t
WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE'
    AND table_name IN ('users', 'clientes', 'secretarias', 'tipos_demanda', 'prioridades', 'demandas', 'anexos', 'configuracoes')
ORDER BY table_name;

-- Verificar dados inseridos
SELECT 'users' as tabela, COUNT(*) as registros FROM users
UNION ALL
SELECT 'clientes', COUNT(*) FROM clientes
UNION ALL
SELECT 'secretarias', COUNT(*) FROM secretarias
UNION ALL
SELECT 'tipos_demanda', COUNT(*) FROM tipos_demanda
UNION ALL
SELECT 'prioridades', COUNT(*) FROM prioridades
UNION ALL
SELECT 'demandas', COUNT(*) FROM demandas
UNION ALL
SELECT 'anexos', COUNT(*) FROM anexos
UNION ALL
SELECT 'configuracoes', COUNT(*) FROM configuracoes;

-- ============================================================================
-- FIM DO SCRIPT
-- ============================================================================

-- ✅ Script executado com sucesso!
-- 
-- 📊 Resumo:
--   - 3 tipos ENUM criados
--   - 8 tabelas criadas
--   - Dados iniciais inseridos
-- 
-- 🔐 Credenciais de Acesso:
--   👑 Master:  admin / admin123
--   👤 Cliente: cliente / cliente123
-- 
-- 🚀 Próximos Passos:
--   1. Verificar se todas as tabelas foram criadas
--   2. Verificar se os dados foram inseridos
--   3. Conectar a aplicação ao banco

