CREATE OR REPLACE TABLE FUNCTION analytics.fn_engajamento(
    p_cliente STRING,
    p_nivel_agregacao STRING,
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
      cliente,
      user_id,
      environment_id,
      course_id,
      space_id,
      subject_id,
      lecture_id,
      NivelAgregacao,
      user_name,
      environment_name,
      course_name,
      space_name,
      subject_name,
      lecture_name,
      data_inicio,
      data_fim,
      postsAmount,
      postRepliesAmount,
      helpRequestsAmount,
      helpRequestRepliesAmount,
      performance_rate,
      categoria_engajamento,
      data_classificacao
  FROM
    `analytics.cubo_engajamento`
  WHERE
    -- Filtros base sempre obrigatórios
    cliente = p_cliente
    AND NivelAgregacao = p_nivel_agregacao
    AND environment_id = p_environment_id

    -- Filtros de escopo opcionais e independentes
    AND (p_course_id IS NULL OR course_id = p_course_id)
    AND (p_space_id IS NULL OR space_id = p_space_id)
    AND (p_subject_id IS NULL OR subject_id = p_subject_id)
    AND (p_lecture_id IS NULL OR lecture_id = p_lecture_id)

    -- Filtros de período opcionais
    AND (p_data_inicio IS NULL OR data_classificacao >= p_data_inicio)
    AND (p_data_fim IS NULL OR data_classificacao <= p_data_fim)
);