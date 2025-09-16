-- Recria a tabela de configuração para incluir o tipo de agregação de data
CREATE OR REPLACE TABLE config.pipeline_config (
    nivel_agregacao STRING NOT NULL,
    tipo_agregacao_data STRING NOT NULL,
    modelo_id STRING NOT NULL,
    tabela_fonte STRING NOT NULL,
    ativo BOOL
);

-- Populando com as combinações para WEEK e MONTH
INSERT INTO config.pipeline_config (nivel_agregacao, tipo_agregacao_data, modelo_id, tabela_fonte, ativo)
VALUES
    -- Agregações Semanais (WEEK)
    ('ENV', 'WEEK', 'analytics.modelo_engajamento_ENV_WEEK', 'analytics.fn_engajamento', TRUE),
    ('CRS', 'WEEK', 'analytics.modelo_engajamento_CRS_WEEK', 'analytics.fn_engajamento', TRUE),
    ('SPA', 'WEEK', 'analytics.modelo_engajamento_SPA_WEEK', 'analytics.fn_engajamento', TRUE),
    ('SUB', 'WEEK', 'analytics.modelo_engajamento_SUB_WEEK', 'analytics.fn_engajamento', TRUE),
    ('LEC', 'WEEK', 'analytics.modelo_engajamento_LEC_WEEK', 'analytics.fn_engajamento', TRUE),
    
    -- Agregações Mensais (MONTH)
    ('ENV', 'MONTH', 'analytics.modelo_engajamento_ENV_MONTH', 'analytics.fn_engajamento', TRUE),
    ('CRS', 'MONTH', 'analytics.modelo_engajamento_CRS_MONTH', 'analytics.fn_engajamento', TRUE),
    ('SPA', 'MONTH', 'analytics.modelo_engajamento_SPA_MONTH', 'analytics.fn_engajamento', TRUE),
    ('SUB', 'MONTH', 'analytics.modelo_engajamento_SUB_MONTH', 'analytics.fn_engajamento', TRUE),
    ('LEC', 'MONTH', 'analytics.modelo_engajamento_LEC_MONTH', 'analytics.fn_engajamento', TRUE);