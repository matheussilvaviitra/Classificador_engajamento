-- Parâmetros que controlam as execuções. Note que renomeamos as datas para um uso mais genérico.
CREATE OR REPLACE TABLE config.pipeline_parametros (
    parametro STRING NOT NULL,
    valor_date DATE,
    valor_string STRING,
    descricao STRING
);

INSERT INTO config.pipeline_parametros (parametro, valor_date, valor_string, descricao) VALUES
('data_inicio_processamento', DATE('2020-01-01'), NULL, 'Data de início para buscar dados para CLASSIFICAÇÃO.'),
('data_fim_processamento', DATE('2021-12-31'), NULL, 'Data de fim para buscar dados para CLASSIFICAÇÃO.'),
('tabela_destino_classificacao', NULL, 'viitra-redu.analytics.cubo_engajamento', 'Tabela final que armazena o cubo.'),
('tabela_mapeamento_labels', NULL, 'viitra-redu.analytics.mapeamento_labels_engajamento', 'Tabela que armazena os labels gerados para cada cluster.');