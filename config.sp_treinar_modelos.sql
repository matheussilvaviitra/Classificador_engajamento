CREATE OR REPLACE PROCEDURE config.sp_treinar_modelos()
BEGIN
    DECLARE niveis_a_processar ARRAY<STRUCT<nivel STRING, modelo_id STRING, tabela_fonte STRING>>;
    DECLARE data_inicio DATE;
    DECLARE data_fim DATE;
    DECLARE i INT64 DEFAULT 0;

    -- Usa as datas da tabela de parâmetros para o período de treinamento
    SET niveis_a_processar = (SELECT ARRAY_AGG(STRUCT(nivel_agregacao, modelo_id, tabela_fonte)) FROM config.pipeline_config WHERE ativo = TRUE);
    SET data_inicio = (SELECT valor_date FROM config.pipeline_parametros WHERE parametro = 'data_inicio_processamento');
    SET data_fim = (SELECT valor_date FROM config.pipeline_parametros WHERE parametro = 'data_fim_processamento');

    WHILE i < ARRAY_LENGTH(niveis_a_processar) DO
        EXECUTE IMMEDIATE FORMAT("""
            CREATE OR REPLACE MODEL `%s`
            OPTIONS(model_type='kmeans', num_clusters=4, standardize_features=true) AS
            SELECT
                LOG(SAFE_ADD(postsAmount, 1)) AS postsAmount,
                LOG(SAFE_ADD(postRepliesAmount, 1)) AS postRepliesAmount,
                LOG(SAFE_ADD(helpRequestsAmount, 1)) AS helpRequestsAmount,
                LOG(SAFE_ADD(helpRequestRepliesAmount, 1)) AS helpRequestRepliesAmount,
                LOG(SAFE_ADD(submitted_exercises, 1)) AS submitted_exercises
            FROM
                %s(?, ?, TRUE, 'redu-digital', NULL, NULL, NULL, NULL, NULL, ?, 'QUARTER') AS eng
            INNER JOIN
                replicas.user_environment_associations AS filtro ON eng.cliente = filtro.cliente AND eng.user_id = filtro.user_id
            WHERE
                filtro.role NOT IN ('teacher', 'tutor', 'environment_admin');
        """, 
        niveis_a_processar[ORDINAL(i+1)].modelo_id,
        niveis_a_processar[ORDINAL(i+1)].tabela_fonte
        )
        USING data_inicio, data_fim, niveis_a_processar[ORDINAL(i+1)].nivel;
        SET i = i + 1;
    END WHILE;
END;