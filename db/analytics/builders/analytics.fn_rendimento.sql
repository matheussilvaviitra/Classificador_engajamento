CREATE OR REPLACE TABLE FUNCTION analytics.fn_rendimento(
    p_start_date DATE,
    p_end_date DATE,
    p_show_by_user BOOL,
    p_cliente STRING,
    p_environment_id INT64,
    p_course_id INT64,
    p_space_id INT64,
    p_subject_id INT64,
    p_lecture_id INT64,
    p_group_agg STRING,
    p_time_agg STRING
)
AS (
WITH
  -- 1. CTE para obter a primeira entrega de cada exercício por usuário
  deduplicated_results AS (
    SELECT
      cliente,
      user_id,
      exercise_id,
      id,
      created_at
    FROM `replicas.results`
    WHERE
      DATE(created_at) BETWEEN p_start_date AND p_end_date
    QUALIFY ROW_NUMBER() OVER(PARTITION BY cliente, user_id, exercise_id ORDER BY created_at ASC) = 1
  ),

  -- ================================================================== --
  -- >> INÍCIO DAS ALTERAÇÕES NO PERÍODO FORTNIGHT <<
  -- ================================================================== --

  time_scaffold AS (
    SELECT
      period_start_date,
      CASE
        WHEN p_time_agg = 'WEEK' THEN DATE_ADD(period_start_date, INTERVAL 6 DAY)
        WHEN p_time_agg = 'MONTH' THEN LAST_DAY(period_start_date, MONTH)
        WHEN p_time_agg = 'YEAR' THEN LAST_DAY(period_start_date, YEAR)
        
        -- LÓGICA DA QUINZENA FIXA NO MÊS (FIM)
        WHEN p_time_agg = 'FORTNIGHT' THEN
          CASE
            -- Se o período começa no dia 1, ele termina no dia 15.
            WHEN EXTRACT(DAY FROM period_start_date) = 1 THEN DATE_ADD(period_start_date, INTERVAL 14 DAY)
            -- Se começa no dia 16, termina no último dia do mês.
            ELSE LAST_DAY(period_start_date, MONTH)
          END

        WHEN p_time_agg = 'QUARTER' THEN LAST_DAY(DATE_ADD(period_start_date, INTERVAL 2 MONTH), MONTH)
        WHEN p_time_agg = 'SEMESTER' THEN DATE_SUB(DATE_ADD(period_start_date, INTERVAL 6 MONTH), INTERVAL 1 DAY)
        ELSE p_end_date
      END AS period_end_date
    FROM (
      SELECT DISTINCT period_start_date
      FROM UNNEST(
        CASE p_time_agg
          WHEN 'WEEK' THEN GENERATE_DATE_ARRAY(DATE_TRUNC(p_start_date, WEEK), p_end_date, INTERVAL 1 WEEK)
          WHEN 'MONTH' THEN GENERATE_DATE_ARRAY(DATE_TRUNC(p_start_date, MONTH), p_end_date, INTERVAL 1 MONTH)
          WHEN 'YEAR' THEN GENERATE_DATE_ARRAY(DATE_TRUNC(p_start_date, YEAR), p_end_date, INTERVAL 1 YEAR)
          
          -- LÓGICA DA QUINZENA FIXA NO MÊS (GERAÇÃO)
          WHEN 'FORTNIGHT' THEN 
            (
              SELECT ARRAY_AGG(start_date)
              FROM (
                -- Gera o dia 1 e o dia 16 de cada mês no intervalo...
                SELECT month_day AS start_date FROM UNNEST(GENERATE_DATE_ARRAY(DATE_TRUNC(p_start_date, MONTH), p_end_date, INTERVAL 1 MONTH)) AS month, UNNEST([DATE(month), DATE_ADD(month, INTERVAL 15 DAY)]) AS month_day
              )
              -- ...e garante que apenas as datas dentro do período solicitado sejam consideradas.
              WHERE start_date BETWEEN p_start_date AND p_end_date
            )

          WHEN 'QUARTER' THEN GENERATE_DATE_ARRAY(DATE_TRUNC(p_start_date, QUARTER), p_end_date, INTERVAL 1 QUARTER)
          WHEN 'SEMESTER' THEN
            GENERATE_DATE_ARRAY(
              CASE WHEN EXTRACT(MONTH FROM p_start_date) <= 6 THEN DATE_TRUNC(p_start_date, YEAR) ELSE DATE(EXTRACT(YEAR FROM p_start_date), 7, 1) END,
              p_end_date, 
              INTERVAL 6 MONTH
            )
          ELSE [p_start_date]
        END
      ) AS period_start_date
    )
  ),

  results_with_period AS (
    SELECT
      dr.cliente,
      dr.user_id,
      dr.exercise_id,
      dr.id,
      CASE
        WHEN p_time_agg = 'WEEK' THEN DATE_TRUNC(DATE(dr.created_at), WEEK)
        WHEN p_time_agg = 'MONTH' THEN DATE_TRUNC(DATE(dr.created_at), MONTH)
        WHEN p_time_agg = 'YEAR' THEN DATE_TRUNC(DATE(dr.created_at), YEAR)
        
        -- LÓGICA DA QUINZENA FIXA NO MÊS (INÍCIO)
        WHEN p_time_agg = 'FORTNIGHT' THEN
          CASE
            -- Se a data for até o dia 15, o período começa no dia 1.
            WHEN EXTRACT(DAY FROM DATE(dr.created_at)) <= 15 THEN DATE_TRUNC(DATE(dr.created_at), MONTH)
            -- Se for depois do dia 15, o período começa no dia 16.
            ELSE DATE(EXTRACT(YEAR FROM DATE(dr.created_at)), EXTRACT(MONTH FROM DATE(dr.created_at)), 16)
          END

        WHEN p_time_agg = 'QUARTER' THEN DATE_TRUNC(DATE(dr.created_at), QUARTER)
        WHEN p_time_agg = 'SEMESTER' THEN
          CASE
            WHEN EXTRACT(MONTH FROM DATE(dr.created_at)) <= 6 THEN DATE_TRUNC(DATE(dr.created_at), YEAR)
            ELSE DATE(EXTRACT(YEAR FROM DATE(dr.created_at)), 7, 1)
          END
        ELSE p_start_date
      END AS period_start_date
    FROM deduplicated_results AS dr
  ),

  -- ================================================================== --
  -- >> FIM DAS ALTERAÇÕES <<
  -- ================================================================== --

  -- 4. CTE que cria o universo de todas as tarefas atribuídas a todos os usuários
  assignments_universe AS (
    SELECT
      l.cliente,
      e.id AS environment_id, e.name AS environment_name,
      c.id AS course_id, c.name AS course_name,
      s.id AS space_id, s.name AS space_name,
      sub.id AS subject_id, sub.name AS subject_name,
      l.id AS lecture_id, l.name AS lecture_name,
      l.lectureable_id AS exercise_id,
      u.id AS user_id,
      u.name AS user_name
    FROM `replicas.lectures` AS l
    JOIN `replicas.subjects` AS sub ON l.subject_id = sub.id AND l.cliente = sub.cliente
    JOIN `replicas.spaces` AS s ON sub.space_id = s.id AND l.cliente = s.cliente
    JOIN `replicas.courses` AS c ON s.course_id = c.id AND l.cliente = s.cliente
    JOIN `replicas.environments` AS e ON c.environment_id = e.id AND l.cliente = e.cliente
    JOIN `replicas.user_space_associations` AS usa ON s.id = usa.space_id AND l.cliente = usa.cliente
    JOIN `replicas.users` AS u ON usa.user_id = u.id AND l.cliente = u.cliente
    WHERE l.lectureable_type = 'Exercise'
  ),

  final_cte AS (
    SELECT * FROM (

        -- BLOCO 1: RENDIMENTO GERAL (AGREGADO) - MODIFICADO COM SCAFFOLD
        SELECT
          au.cliente,
          NULL AS user_id,
          'ALL USERS' AS user_name,
          ts.period_start_date,
          ts.period_end_date,
          au.environment_id, au.environment_name,
          au.course_id, au.course_name,
          au.space_id, au.space_name,
          au.subject_id, au.subject_name,
          au.lecture_id, au.lecture_name,
          CASE
            WHEN GROUPING(au.lecture_id) = 0 THEN 'LEC' WHEN GROUPING(au.subject_id) = 0 THEN 'SUB'
            WHEN GROUPING(au.space_id) = 0 THEN 'SPA' WHEN GROUPING(au.course_id) = 0 THEN 'CRS'
            WHEN GROUPING(au.environment_id) = 0 THEN 'ENV' ELSE 'GERAL'
          END AS NivelAgregacao,
          COUNT(DISTINCT FORMAT('%t', (au.user_id, au.exercise_id))) AS assigned_exercises,
          COUNT(DISTINCT rwp.id) AS submitted_exercises,
          COALESCE(SAFE_DIVIDE(COUNT(DISTINCT rwp.id), COUNT(DISTINCT FORMAT('%t', (au.user_id, au.exercise_id)))), 0) AS performance_rate
        FROM assignments_universe AS au
        CROSS JOIN time_scaffold AS ts
        LEFT JOIN results_with_period AS rwp 
          ON au.exercise_id = rwp.exercise_id 
          AND au.user_id = rwp.user_id 
          AND au.cliente = rwp.cliente
          AND ts.period_start_date = rwp.period_start_date
        WHERE
          p_show_by_user = FALSE
          AND (p_cliente IS NULL OR au.cliente = p_cliente)
          AND (p_environment_id IS NULL OR au.environment_id = p_environment_id)
          AND (p_course_id IS NULL OR au.course_id = p_course_id)
          AND (p_space_id IS NULL OR au.space_id = p_space_id)
          AND (p_subject_id IS NULL OR au.subject_id = p_subject_id)
          AND (p_lecture_id IS NULL OR au.lecture_id = p_lecture_id)
        GROUP BY GROUPING SETS (
          (au.cliente, au.environment_id, au.environment_name, ts.period_start_date, ts.period_end_date),
          (au.cliente, au.environment_id, au.environment_name, au.course_id, au.course_name, ts.period_start_date, ts.period_end_date),
          (au.cliente, au.environment_id, au.environment_name, au.course_id, au.course_name, au.space_id, au.space_name, ts.period_start_date, ts.period_end_date),
          (au.cliente, au.environment_id, au.environment_name, au.course_id, au.course_name, au.space_id, au.space_name, au.subject_id, au.subject_name, ts.period_start_date, ts.period_end_date),
          (au.cliente, au.environment_id, au.environment_name, au.course_id, au.course_name, au.space_id, au.space_name, au.subject_id, au.subject_name, au.lecture_id, au.lecture_name, ts.period_start_date, ts.period_end_date)
        )

        UNION ALL

        -- BLOCO 2: RENDIMENTO POR USUÁRIO - MODIFICADO COM SCAFFOLD
        SELECT
          au.cliente,
          au.user_id, au.user_name,
          ts.period_start_date,
          ts.period_end_date,
          au.environment_id, au.environment_name,
          au.course_id, au.course_name,
          au.space_id, au.space_name,
          au.subject_id, au.subject_name,
          au.lecture_id, au.lecture_name,
          CASE
            WHEN GROUPING(au.lecture_id) = 0 THEN 'LEC' WHEN GROUPING(au.subject_id) = 0 THEN 'SUB'
            WHEN GROUPING(au.space_id) = 0 THEN 'SPA' WHEN GROUPING(au.course_id) = 0 THEN 'CRS'
            WHEN GROUPING(au.environment_id) = 0 THEN 'ENV' ELSE 'USER'
          END AS NivelAgregacao,
          COUNT(DISTINCT au.exercise_id) AS assigned_exercises,
          COUNT(DISTINCT rwp.id) AS submitted_exercises,
          COALESCE(SAFE_DIVIDE(COUNT(DISTINCT rwp.id), COUNT(DISTINCT au.exercise_id)), 0) AS performance_rate
        FROM assignments_universe AS au
        CROSS JOIN time_scaffold AS ts
        LEFT JOIN results_with_period AS rwp 
          ON au.exercise_id = rwp.exercise_id 
          AND au.user_id = rwp.user_id 
          AND au.cliente = rwp.cliente
          AND ts.period_start_date = rwp.period_start_date
        WHERE
          p_show_by_user = TRUE
          AND (p_cliente IS NULL OR au.cliente = p_cliente)
          AND (p_environment_id IS NULL OR au.environment_id = p_environment_id)
          AND (p_course_id IS NULL OR au.course_id = p_course_id)
          AND (p_space_id IS NULL OR au.space_id = p_space_id)
          AND (p_subject_id IS NULL OR au.subject_id = p_subject_id)
          AND (p_lecture_id IS NULL OR au.lecture_id = p_lecture_id)
        GROUP BY GROUPING SETS (
          (au.cliente, au.user_id, au.user_name, au.environment_id, au.environment_name, ts.period_start_date, ts.period_end_date),
          (au.cliente, au.user_id, au.user_name, au.environment_id, au.environment_name, au.course_id, au.course_name, ts.period_start_date, ts.period_end_date),
          (au.cliente, au.user_id, au.user_name, au.environment_id, au.environment_name, au.course_id, au.course_name, au.space_id, au.space_name, ts.period_start_date, ts.period_end_date),
          (au.cliente, au.user_id, au.user_name, au.environment_id, au.environment_name, au.course_id, au.course_name, au.space_id, au.space_name, au.subject_id, au.subject_name, ts.period_start_date, ts.period_end_date),
          (au.cliente, au.user_id, au.user_name, au.environment_id, au.environment_name, au.course_id, au.course_name, au.space_id, au.space_name, au.subject_id, au.subject_name, au.lecture_id, au.lecture_name, ts.period_start_date, ts.period_end_date)
        )
    )
  )

SELECT *
FROM final_cte
WHERE final_cte.NivelAgregacao = p_group_agg
ORDER BY performance_rate DESC
);