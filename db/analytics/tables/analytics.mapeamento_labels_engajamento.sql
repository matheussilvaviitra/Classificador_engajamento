-- Cria a tabela que vai armazenar o mapeamento de ID do cluster para o label de engajamento
CREATE OR REPLACE TABLE analytics.mapeamento_labels_engajamento (
    nivel_agregacao STRING NOT NULL,
    tipo_agregacao_data STRING, -- << NOVA COLUNA ADICIONADA
    centroid_id INT64 NOT NULL,
    categoria_engajamento STRING
);