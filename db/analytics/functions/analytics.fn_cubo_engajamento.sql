CREATE OR REPLACE TABLE FUNCTION analytics.fn_cubo_engajamento(
    p_cliente STRING,
    p_nivel_agregacao STRING,
    p_tipo_agregacao_data STRING, -- <-- Parâmetro ajustado para 'p' minúsculo
    p_environment_id INT64,
    p_course_id INT64,
    p_space_id INT64,
    p_subject_id INT64,
    p_lecture_id INT64,
    p_data_inicio DATE,
    p_data_fim DATE
)
AS (
  SELECT
     cliente
    ,user_id
    ,environment_id
    ,course_id
    ,space_id
    ,subject_id
    ,lecture_id
    ,NivelAgregacao
    ,TipoAgregacaoData
    ,user_name
    ,environment_name
    ,course_name
    ,space_name
    ,subject_name
    ,lecture_name
    ,data_inicio
    ,data_fim
    ,postsAmount
    ,postRepliesAmount
    ,helpRequestsAmount
    ,helpRequestRepliesAmount
    ,assigned_exercises
    ,submitted_exercises
    ,conclusion_percent
    ,categoria_engajamento
    ,data_classificacao
  FROM
    `analytics.cubo_engajamento`
  WHERE
    -- Filtros fixos que sempre se aplicam
    cliente = p_cliente
    AND NivelAgregacao = p_nivel_agregacao
    AND TipoAgregacaoData = p_tipo_agregacao_data -- <-- Variável ajustada aqui também

    -- Filtros de escopo hierárquico opcionais
    AND (p_environment_id IS NULL OR environment_id = p_environment_id)
    AND (p_course_id IS NULL OR course_id = p_course_id)
    AND (p_space_id IS NULL OR space_id = p_space_id)
    AND (p_subject_id IS NULL OR subject_id = p_subject_id)
    AND (p_lecture_id IS NULL OR lecture_id = p_lecture_id)

    -- Filtros de período opcionais
    AND (p_data_inicio IS NULL OR data_inicio >= p_data_inicio)
    AND (p_data_fim IS NULL OR data_fim <= p_data_fim)
);