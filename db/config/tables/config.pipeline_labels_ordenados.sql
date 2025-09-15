-- Tabela flexível para definir os nomes das categorias de engajamento.
CREATE OR REPLACE TABLE config.pipeline_labels_ordenados (
    ranking INT64 NOT NULL,
    label STRING NOT NULL,
    descricao STRING
);

INSERT INTO config.pipeline_labels_ordenados (ranking, label, descricao) VALUES
(1, 'engajamento excelente', 'Cluster com o maior score de engajamento.'),
(2, 'engajamento consistente', 'Cluster com o segundo maior score de engajamento.'),
(3, 'desempenho crítico', 'Cluster com o terceiro maior score de engajamento.'),
(4, 'não interagem', 'Cluster com o menor score de engajamento.');