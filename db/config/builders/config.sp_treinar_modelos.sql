CREATE OR REPLACE PROCEDURE config.sp_treinar_modelos()
BEGIN
    -- Declarações de variáveis, incluindo a que representa a combinação a ser processada
    DECLARE combinacoes_a_processar ARRAY<STRUCT<nivel STRING, tipo_agregacao STRING, modelo_id STRING, tabela_fonte STRING>>;
    DECLARE data_inicio DATE;
    DECLARE data_fim DATE;
    DECLARE i INT64 DEFAULT 0;
    DECLARE item_atual STRUCT<nivel STRING, tipo_agregacao STRING, modelo_id STRING, tabela_fonte STRING>;
    DECLARE query_a_executar STRING;

    -- Carrega a lista de tarefas da tabela de configuração principal
    SET combinacoes_a_processar = (SELECT ARRAY_AGG(STRUCT(nivel_agregacao, tipo_agregacao_data, modelo_id, tabela_fonte)) FROM config.pipeline_config WHERE ativo = TRUE);
    SET data_inicio = (SELECT valor_date FROM config.pipeline_parametros WHERE parametro = 'data_inicio_processamento');
    SET data_fim = (SELECT valor_date FROM config.pipeline_parametros WHERE parametro = 'data_fim_processamento');
    
    -- Loop principal que itera sobre cada combinação ativa (ex: CRS-WEEK, CRS-MONTH, etc.)
    WHILE i < ARRAY_LENGTH(combinacoes_a_processar) DO
        
        SET item_atual = combinacoes_a_processar[ORDINAL(i+1)];

        -- Monta a string da query dinamicamente, inserindo todos os valores
        SET query_a_executar = FORMAT("""
            CREATE OR REPLACE MODEL `%s`
            OPTIONS(
                model_type='kmeans', 
                num_clusters=4, 
                standardize_features=true,
                kmeans_init_method = 'KMEANS++'
            ) AS
            WITH
            source_data AS (
                SELECT
                    eng.postsAmount,
                    eng.postRepliesAmount,
                    eng.helpRequestsAmount,
                    eng.helpRequestRepliesAmount,
                    eng.assigned_exercises,
                    eng.submitted_exercises
                FROM
                    -- << ALTERAÇÃO AQUI: Os parâmetros vêm do loop atual >>
                    %s(DATE('%t'), DATE('%t'), TRUE, 'redu-digital', NULL, NULL, NULL, NULL, NULL, '%s', '%s') AS eng
                INNER JOIN
                    replicas.user_environment_associations AS filtro ON eng.cliente = filtro.cliente AND eng.user_id = filtro.user_id
                WHERE
                    filtro.role NOT IN ('teacher', 'tutor', 'environment_admin')
            )
            SELECT
                LOG(postsAmount + 1) AS postsAmount,
                LOG(postRepliesAmount + 1) AS postRepliesAmount,
                LOG(helpRequestsAmount + 1) AS helpRequestsAmount,
                LOG(helpRequestRepliesAmount + 1) AS helpRequestRepliesAmount,
                LOG(assigned_exercises + 1) AS assigned_exercises,
                LOG(submitted_exercises + 1) AS submitted_exercises
            FROM
                source_data;
        """, 
        -- Lista de argumentos para o FORMAT, na ordem correta
        item_atual.modelo_id,        -- 1º %s: Nome do modelo (ex: ..._CRS_WEEK)
        item_atual.tabela_fonte,     -- 2º %s: Nome da função fonte
        data_inicio,                 -- 1º %t: Data de início
        data_fim,                    -- 2º %t: Data de fim
        item_atual.nivel,            -- 3º %s: Nível de agregação (ex: 'CRS')
        item_atual.tipo_agregacao    -- 4º %s: Tipo de agregação de data (ex: 'WEEK')
        );

        -- Para depurar, descomente a linha RAISE e comente a EXECUTE IMMEDIATE
        -- RAISE USING MESSAGE = query_a_executar;

        -- Executa a query que foi montada
        EXECUTE IMMEDIATE query_a_executar;
        
        SET i = i + 1;
    END WHILE;
END;