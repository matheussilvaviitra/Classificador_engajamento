CREATE OR REPLACE PROCEDURE config.sp_gerar_labels()
BEGIN
    -- Todas as declarações de variáveis agora estão juntas no início do bloco.
    DECLARE combinacoes_a_processar ARRAY<STRUCT<nivel STRING, tipo_agregacao STRING, modelo_id STRING>>;
    DECLARE tabela_destino_mapeamento STRING;
    DECLARE i INT64 DEFAULT 0;
    -- << CORREÇÃO: A variável 'item_atual' foi movida para cá >>
    DECLARE item_atual STRUCT<nivel STRING, tipo_agregacao STRING, modelo_id STRING>;

    SET combinacoes_a_processar = (SELECT ARRAY_AGG(STRUCT(nivel_agregacao, tipo_agregacao_data, modelo_id)) FROM config.pipeline_config WHERE ativo = TRUE);
    SET tabela_destino_mapeamento = (SELECT valor_string FROM config.pipeline_parametros WHERE parametro = 'tabela_mapeamento_labels');
    
    EXECUTE IMMEDIATE FORMAT("TRUNCATE TABLE `%s`", tabela_destino_mapeamento);

    WHILE i < ARRAY_LENGTH(combinacoes_a_processar) DO
        -- A declaração foi removida daqui. A variável agora é apenas utilizada.
        SET item_atual = combinacoes_a_processar[ORDINAL(i+1)];

        EXECUTE IMMEDIATE FORMAT("""
        INSERT INTO `%s` (nivel_agregacao, tipo_agregacao_data, centroid_id, categoria_engajamento)
        WITH
        centroids_std AS (SELECT centroid_id, feature, numerical_value FROM ML.CENTROIDS(MODEL `%s`)),
        feature_info AS (SELECT input AS feature, mean, stddev FROM ML.FEATURE_INFO(MODEL `%s`)),
        centroids_log_scale AS (SELECT centroid_id, feature, (c.numerical_value * f.stddev) + f.mean AS log_scale_value FROM centroids_std c JOIN feature_info f USING(feature)),
        centroids_original_scale AS (SELECT centroid_id, EXP(MAX(IF(feature = 'postsAmount', log_scale_value, 0))) - 1 AS postsAmount, EXP(MAX(IF(feature = 'postRepliesAmount', log_scale_value, 0))) - 1 AS postRepliesAmount, EXP(MAX(IF(feature = 'helpRequestsAmount', log_scale_value, 0))) - 1 AS helpRequestsAmount, EXP(MAX(IF(feature = 'helpRequestRepliesAmount', log_scale_value, 0))) - 1 AS helpRequestRepliesAmount, EXP(MAX(IF(feature = 'submitted_exercises', log_scale_value, 0))) - 1 AS submitted_exercises FROM centroids_log_scale GROUP BY centroid_id),
        scored_centroids AS (SELECT centroid_id, (postsAmount + postRepliesAmount + helpRequestsAmount + helpRequestRepliesAmount + (submitted_exercises * 1.5)) AS engagement_score FROM centroids_original_scale),
        ranked_centroids AS (SELECT centroid_id, ROW_NUMBER() OVER(ORDER BY engagement_score DESC) as ranking FROM scored_centroids)
        SELECT '%s' as nivel_agregacao, '%s' as tipo_agregacao_data, r.centroid_id, l.label AS categoria_engajamento
        FROM ranked_centroids AS r JOIN `config.pipeline_labels_ordenados` AS l ON r.ranking = l.ranking;
        """, 
        tabela_destino_mapeamento, 
        item_atual.modelo_id, 
        item_atual.modelo_id, 
        item_atual.nivel,
        item_atual.tipo_agregacao
        );
        SET i = i + 1;
    END WHILE;
END;