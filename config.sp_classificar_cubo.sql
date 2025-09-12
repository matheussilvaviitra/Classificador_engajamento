CREATE OR REPLACE PROCEDURE config.sp_classificar_cubo()
BEGIN
    DECLARE niveis_a_processar ARRAY<STRUCT<nivel STRING, modelo_id STRING, tabela_fonte STRING>>;
    DECLARE tabela_destino_final STRING;
    DECLARE tabela_labels STRING;
    DECLARE data_inicio DATE;
    DECLARE data_fim DATE;
    DECLARE i INT64 DEFAULT 0;

    SET niveis_a_processar = (SELECT ARRAY_AGG(STRUCT(nivel_agregacao, modelo_id, tabela_fonte)) FROM config.pipeline_config WHERE ativo = TRUE);
    SET tabela_destino_final = (SELECT valor_string FROM config.pipeline_parametros WHERE parametro = 'tabela_destino_classificacao');
    SET tabela_labels = (SELECT valor_string FROM config.pipeline_parametros WHERE parametro = 'tabela_mapeamento_labels');
    SET data_inicio = (SELECT valor_date FROM config.pipeline_parametros WHERE parametro = 'data_inicio_processamento');
    SET data_fim = (SELECT valor_date FROM config.pipeline_parametros WHERE parametro = 'data_fim_processamento');

    EXECUTE IMMEDIATE FORMAT("TRUNCATE TABLE `%s`", tabela_destino_final);

    WHILE i < ARRAY_LENGTH(niveis_a_processar) DO
        EXECUTE IMMEDIATE FORMAT("""
        INSERT INTO `%s` (
            cliente, user_id, environment_id, course_id, space_id, subject_id, lecture_id,
            NivelAgregacao, user_name, environment_name, course_name, space_name, subject_name,
            lecture_name, data_inicio, data_fim, postsAmount, postRepliesAmount,
            helpRequestsAmount, helpRequestRepliesAmount, assigned_exercises, submitted_exercises,
            conclusion_percent, categoria_engajamento, data_classificacao
        )
        SELECT
            source_data.* EXCEPT(centroid_id),
            SAFE_DIVIDE(source_data.submitted_exercises, source_data.assigned_exercises) AS conclusion_percent,
            labels.categoria_engajamento,
            CURRENT_DATE() AS data_classificacao
        FROM (
            SELECT *
            FROM ML.PREDICT(
                MODEL `%s`,
                (
                    SELECT eng.*
                    FROM %s(?, ?, TRUE, 'redu-digital', NULL, NULL, NULL, NULL, NULL, ?, 'QUARTER') AS eng
                    INNER JOIN replicas.user_environment_associations AS filtro ON eng.cliente = filtro.cliente AND eng.user_id = filtro.user_id
                    WHERE filtro.role NOT IN ('teacher', 'tutor', 'environment_admin')
                )
            )
        ) AS source_data
        JOIN `%s` AS labels 
            ON source_data.centroid_id = labels.centroid_id
            AND labels.nivel_agregacao = ?;
        """,
        tabela_destino_final,
        niveis_a_processar[ORDINAL(i+1)].modelo_id,
        niveis_a_processar[ORDINAL(i+1)].tabela_fonte,
        tabela_labels
        )
        USING data_inicio, data_fim, niveis_a_processar[ORDINAL(i+1)].nivel, niveis_a_processar[ORDINAL(i+1)].nivel;
        SET i = i + 1;
    END WHILE;
END;