CREATE OR REPLACE TABLE config.pipeline_configuracao (
    nivel_agregacao STRING OPTIONS(description="Nível de agregação, ex: ENV, CRS, SPA"),
    modelo_id STRING OPTIONS(description="Nome completo do modelo a ser gerado/usado"),
    tabela_fonte STRING OPTIONS(description="Função ou tabela que serve de fonte de dados"),
    ativo BOOL OPTIONS(description="Flag para incluir este nível na execução do pipeline")
);

-- Inserindo os dados de configuração
INSERT INTO config.pipeline_configuracao VALUES
('ENV', 'analytics.modelo_engajamento_ENV', 'analytics.fn_engajamento', TRUE),
('CRS', 'analytics.modelo_engajamento_CRS', 'analytics.fn_engajamento', TRUE),
('SPA', 'analytics.modelo_engajamento_SPA', 'analytics.fn_engajamento', TRUE),
('SUB', 'analytics.modelo_engajamento_SUB', 'analytics.fn_engajamento', TRUE),
('LEC', 'analytics.modelo_engajamento_LEC', 'analytics.fn_engajamento', TRUE);