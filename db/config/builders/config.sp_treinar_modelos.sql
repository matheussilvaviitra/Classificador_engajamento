CREATE OR REPLACE PROCEDURE config.sp_treinar_modelos()
BEGIN
    DECLARE niveis_a_processar ARRAY<STRUCT<nivel STRING, modelo_id STRING, tabela_fonte STRING>>;
    DECLARE data_inicio DATE;
    DECLARE data_fim DATE;
    DECLARE i INT64 DEFAULT 0;
    DECLARE tipo_agregacao STRING;
    DECLARE query_a_executar STRING;

    SET niveis_a_processar = (SELECT ARRAY_AGG(STRUCT(nivel_agregacao, modelo_id, tabela_fonte)) FROM config.pipeline_config WHERE ativo = TRUE);
    SET data_inicio = (SELECT valor_date FROM config.pipeline_parametros WHERE parametro = 'data_inicio_processamento');
    SET data_fim = (SELECT valor_date FROM config.pipeline_parametros WHERE parametro = 'data_fim_processamento');
    SET tipo_agregacao = (SELECT valor_string FROM config.pipeline_parametros WHERE parametro = 'tipo_agregacao_data');

    WHILE i < ARRAY_LENGTH(niveis_a_processar) DO
        
        -- === ALTERAÇÃO PRINCIPAL AQUI ===
        -- Agora montamos a query final, substituindo os '?' pelos valores formatados.
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
        -- Parâmetros para o FORMAT:
        niveis_a_processar[ORDINAL(i+1)].modelo_id,
        niveis_a_processar[ORDINAL(i+1)].tabela_fonte,
        data_inicio,  -- Será formatado por DATE('%t')
        data_fim,     -- Será formatado por DATE('%t')
        niveis_a_processar[ORDINAL(i+1)].nivel, -- Será formatado por '%s'
        tipo_agregacao
        );
        -- =============================================================

        -- O "Print" para debug continua o mesmo, mas agora a variável contém a query completa.
        -- RAISE USING MESSAGE = query_a_executar;

        -- A execução agora é feita sem a cláusula USING.
        -- Comente a linha 'RAISE' acima para que esta linha seja executada.
        EXECUTE IMMEDIATE query_a_executar;
        
        SET i = i + 1;
    END WHILE;
END;