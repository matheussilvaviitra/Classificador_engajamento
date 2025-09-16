CREATE OR REPLACE PROCEDURE config.sp_classificar_cubo()
BEGIN
    DECLARE combinacoes_a_processar ARRAY<STRUCT<nivel STRING, tipo_agregacao STRING, modelo_id STRING, tabela_fonte STRING>>;
    DECLARE tabela_destino_final STRING;
    DECLARE tabela_labels STRING;
    DECLARE data_inicio DATE;
    DECLARE data_fim DATE;
    DECLARE i INT64 DEFAULT 0;
    DECLARE item_atual STRUCT<nivel STRING, tipo_agregacao STRING, modelo_id STRING, tabela_fonte STRING>;

    SET combinacoes_a_processar = (SELECT ARRAY_AGG(STRUCT(nivel_agregacao, tipo_agregacao_data, modelo_id, tabela_fonte)) FROM config.pipeline_config WHERE ativo = TRUE);
    SET tabela_destino_final = (SELECT valor_string FROM config.pipeline_parametros WHERE parametro = 'tabela_destino_classificacao');
    SET tabela_labels = (SELECT valor_string FROM config.pipeline_parametros WHERE parametro = 'tabela_mapeamento_labels');
    SET data_inicio = (SELECT valor_date FROM config.pipeline_parametros WHERE parametro = 'data_inicio_processamento');
    SET data_fim = (SELECT valor_date FROM config.pipeline_parametros WHERE parametro = 'data_fim_processamento');

    EXECUTE IMMEDIATE FORMAT("TRUNCATE TABLE `%s`", tabela_destino_final);

    WHILE i < ARRAY_LENGTH(combinacoes_a_processar) DO
        SET item_atual = combinacoes_a_processar[ORDINAL(i+1)];

        EXECUTE IMMEDIATE FORMAT("""
        INSERT INTO `%s` ( -- Placeholder 1
            cliente, user_id, environment_id, course_id, space_id, subject_id, lecture_id,
            NivelAgregacao, TipoAgregacaoData,
            user_name, environment_name, course_name, space_name, subject_name,
            lecture_name, data_inicio, data_fim, postsAmount, postRepliesAmount,
            helpRequestsAmount, helpRequestRepliesAmount, assigned_exercises, submitted_exercises,
            conclusion_percent, categoria_engajamento, data_classificacao
        )
        SELECT
            source_data.cliente, source_data.user_id, source_data.environment_id, source_data.course_id, 
            source_data.space_id, source_data.subject_id, source_data.lecture_id,
            '%s' AS NivelAgregacao, -- Placeholder 2
            '%s' AS TipoAgregacaoData, -- Placeholder 3
            source_data.user_name, source_data.environment_name, source_data.course_name, source_data.space_name,
            source_data.subject_name, source_data.lecture_name,
            source_data.period_start_date AS data_inicio,
            source_data.period_end_date AS data_fim,
            source_data.postsAmount, source_data.postRepliesAmount, source_data.helpRequestsAmount,
            source_data.helpRequestRepliesAmount, source_data.assigned_exercises, source_data.submitted_exercises,
            SAFE_DIVIDE(source_data.submitted_exercises, source_data.assigned_exercises) AS conclusion_percent,
            labels.categoria_engajamento,
            CURRENT_DATE() AS data_classificacao
        FROM (
            SELECT *
            FROM ML.PREDICT(
                MODEL `%s`, -- Placeholder 4
                (
                    SELECT eng.*
                    FROM %s(?, ?, TRUE, 'redu-digital', NULL, NULL, NULL, NULL, NULL, ?, ?) AS eng -- Placeholder 5
                    INNER JOIN replicas.user_environment_associations AS filtro ON eng.cliente = filtro.cliente AND eng.user_id = filtro.user_id
                    WHERE filtro.role NOT IN ('teacher', 'tutor', 'environment_admin')
                )
            )
        ) AS source_data
        JOIN `%s` AS labels -- Placeholder 6
            ON source_data.centroid_id = labels.centroid_id
            AND labels.nivel_agregacao = ?
            AND labels.tipo_agregacao_data = ?;
        """,
        -- << CORREÇÃO: Ordem e contagem de argumentos para FORMAT revisada >>
        tabela_destino_final,                -- Argumento para Placeholder 1
        item_atual.nivel,                    -- Argumento para Placeholder 2
        item_atual.tipo_agregacao,           -- Argumento para Placeholder 3
        item_atual.modelo_id,                -- Argumento para Placeholder 4
        item_atual.tabela_fonte,             -- Argumento para Placeholder 5
        tabela_labels                        -- Argumento para Placeholder 6
        )
        USING 
            data_inicio, 
            data_fim, 
            item_atual.nivel, 
            item_atual.tipo_agregacao, 
            item_atual.nivel,
            item_atual.tipo_agregacao;
        
        SET i = i + 1;
    END WHILE;
END;