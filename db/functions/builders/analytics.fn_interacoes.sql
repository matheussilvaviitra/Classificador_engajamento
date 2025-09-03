CREATE OR REPLACE TABLE FUNCTION analytics.fn_interacoes(
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
AS 
(WITH
  -- 1. CTE de hierarquia (sem alterações).
  hierarchy_universe AS (
    SELECT
      e.cliente,
      e.id AS environment_id, e.name AS environment_name,
      c.id AS course_id, c.name AS course_name,
      s.id AS space_id, s.name AS space_name,
      sub.id AS subject_id, sub.name AS subject_name,
      l.id AS lecture_id, l.name AS lecture_name
    FROM `replicas.environments` AS e
    LEFT JOIN `replicas.courses` AS c ON e.id = c.environment_id AND e.cliente = c.cliente
    LEFT JOIN `replicas.spaces` AS s ON c.id = s.course_id AND c.cliente = s.cliente
    LEFT JOIN `replicas.subjects` AS sub ON s.id = sub.space_id AND s.cliente = sub.cliente
    LEFT JOIN `replicas.lectures` AS l ON sub.id = l.subject_id AND l.cliente = l.cliente
    WHERE e.cliente = p_cliente
  ),
  
  
   -- 2. CTE de interações filtradas (sem alterações).
  filtered_interactions AS (
    SELECT
        cc.*
    FROM `analytics.cubo_comentarios` AS cc
    JOIN `replicas.user_environment_associations` AS uea
        ON uea.user_id = cc.user_id
        AND uea.cliente = cc.client
        AND uea.environment_id = cc.environment_id
    WHERE uea.role NOT IN ('teacher', 'tutor', 'environment_admin')
      AND cc.interaction_date BETWEEN p_start_date AND p_end_date
  ),

  -- ================================================================== --
  -- >> INÍCIO DAS ALTERAÇÕES NO PERÍODO FORTNIGHT <<
  -- ================================================================== --
  
 -- 3. CTE de interações com período (lógica de FORTNIGHT ajustada).
interactions_with_period AS (
  SELECT
    *,
    -- Calcula a data de início do período usando 'interaction_date'.
    CASE
      WHEN p_time_agg = 'WEEK' THEN DATE_TRUNC(interaction_date, WEEK)
      WHEN p_time_agg = 'MONTH' THEN DATE_TRUNC(interaction_date, MONTH)
      WHEN p_time_agg = 'YEAR' THEN DATE_TRUNC(interaction_date, YEAR)
      
      -- LÓGICA DA QUINZENA FIXA NO MÊS (INÍCIO)
      WHEN p_time_agg = 'FORTNIGHT' THEN 
        CASE
          -- Se a data for até o dia 15, o período começa no dia 1.
          WHEN EXTRACT(DAY FROM interaction_date) <= 15 THEN DATE_TRUNC(interaction_date, MONTH)
          -- Se for depois do dia 15, o período começa no dia 16.
          ELSE DATE(EXTRACT(YEAR FROM interaction_date), EXTRACT(MONTH FROM interaction_date), 16)
        END

      WHEN p_time_agg = 'QUARTER' THEN DATE_TRUNC(interaction_date, QUARTER)
      WHEN p_time_agg = 'SEMESTER' THEN
        CASE
          WHEN EXTRACT(MONTH FROM interaction_date) <= 6 THEN DATE_TRUNC(interaction_date, YEAR)
          ELSE DATE(EXTRACT(YEAR FROM interaction_date), 7, 1)
        END
      ELSE p_start_date
    END AS period_start_date,

    -- Calcula a data de fim do período, também usando 'interaction_date'.
    CASE
      WHEN p_time_agg = 'WEEK' THEN DATE_ADD(DATE_TRUNC(interaction_date, WEEK), INTERVAL 6 DAY)
      WHEN p_time_agg = 'MONTH' THEN LAST_DAY(interaction_date, MONTH)
      WHEN p_time_agg = 'YEAR' THEN LAST_DAY(DATE_TRUNC(interaction_date, YEAR), YEAR)

      -- LÓGICA DA QUINZENA FIXA NO MÊS (FIM)
      WHEN p_time_agg = 'FORTNIGHT' THEN
        CASE
          -- Se a data for até o dia 15, o período termina no dia 15.
          WHEN EXTRACT(DAY FROM interaction_date) <= 15 THEN DATE_ADD(DATE_TRUNC(interaction_date, MONTH), INTERVAL 14 DAY)
          -- Se for depois do dia 15, o período termina no último dia do mês.
          ELSE LAST_DAY(interaction_date, MONTH)
        END

      WHEN p_time_agg = 'QUARTER' THEN LAST_DAY(DATE_ADD(DATE_TRUNC(interaction_date, QUARTER), INTERVAL 2 MONTH), MONTH)
      WHEN p_time_agg = 'SEMESTER' THEN
        DATE_SUB(DATE_ADD(
          CASE
            WHEN EXTRACT(MONTH FROM interaction_date) <= 6 THEN DATE_TRUNC(interaction_date, YEAR)
            ELSE DATE(EXTRACT(YEAR FROM interaction_date), 7, 1)
          END, 
          INTERVAL 6 MONTH), 
        INTERVAL 1 DAY)
      ELSE p_end_date
    END AS period_end_date
  FROM filtered_interactions
),

-- 4. CTE para criar o "andaime" de datas (lógica de FORTNIGHT ajustada).
time_scaffold AS (
  SELECT
    period_start_date,
    -- Calcula o 'period_end_date' a partir do 'period_start_date' já gerado.
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
              SELECT month_day AS start_date FROM UNNEST(GENERATE_DATE_ARRAY(DATE_TRUNC(p_start_date, MONTH), p_end_date, INTERVAL 1 MONTH)) AS month, UNNEST([DATE(month), DATE_ADD(month, INTERVAL 15 DAY)]) AS month_day
            )
            WHERE start_date BETWEEN p_start_date AND p_end_date
          )

        WHEN 'QUARTER' THEN GENERATE_DATE_ARRAY(DATE_TRUNC(p_start_date, QUARTER), p_end_date, INTERVAL 1 QUARTER)
        WHEN 'SEMESTER' THEN
          GENERATE_DATE_ARRAY(
            CASE
              WHEN EXTRACT(MONTH FROM p_start_date) <= 6 THEN DATE_TRUNC(p_start_date, YEAR)
              ELSE DATE(EXTRACT(YEAR FROM p_start_date), 7, 1)
            END,
            p_end_date, 
            INTERVAL 6 MONTH
          )
        ELSE [p_start_date]
      END
    ) AS period_start_date
  )
),

  -- ================================================================== --
  -- >> FIM DAS ALTERAÇÕES <<
  -- ================================================================== --

  -- CTE principal (sem alterações)
  final_cte AS (
    SELECT * FROM (
        -- BLOCO 1: TOTAIS GERAIS (AGREGADO)
        SELECT
            hu.cliente AS client,
            NULL AS user_id,
            'ALL USERS' AS user_name,
            ts.period_start_date,
            ts.period_end_date,
            hu.environment_id, hu.environment_name,
            hu.course_id, hu.course_name,
            hu.space_id, hu.space_name,
            hu.subject_id, hu.subject_name,
            hu.lecture_id, hu.lecture_name,
            CASE
                WHEN GROUPING(hu.lecture_id) = 0 THEN 'LEC' WHEN GROUPING(hu.subject_id) = 0 THEN 'SUB'
                WHEN GROUPING(hu.space_id) = 0 THEN 'SPA' WHEN GROUPING(hu.course_id) = 0 THEN 'CRS'
                WHEN GROUPING(hu.environment_id) = 0 THEN 'ENV' ELSE 'GERAL'
            END AS NivelAgregacao,
            COALESCE(SUM(fi.postsAmount), 0) AS postsAmount,
            COALESCE(SUM(fi.postRepliesAmount), 0) AS postRepliesAmount,
            COALESCE(SUM(fi.helpRequestsAmount), 0) AS helpRequestsAmount,
            COALESCE(SUM(fi.helpRequestRepliesAmount), 0) AS helpRequestRepliesAmount
        FROM hierarchy_universe AS hu
        CROSS JOIN time_scaffold AS ts
        LEFT JOIN interactions_with_period AS fi
            ON hu.lecture_id = fi.lecture_id
            AND hu.subject_id = fi.subject_id
            AND hu.space_id = fi.space_id
            AND hu.course_id = fi.course_id
            AND hu.environment_id = fi.environment_id
            AND hu.cliente = fi.client
            AND ts.period_start_date = fi.period_start_date
        WHERE
            p_show_by_user = FALSE
            AND (p_cliente IS NULL OR hu.cliente = p_cliente)
            AND (p_environment_id IS NULL OR hu.environment_id = p_environment_id)
            AND (p_course_id IS NULL OR hu.course_id = p_course_id)
            AND (p_space_id IS NULL OR hu.space_id = p_space_id)
            AND (p_subject_id IS NULL OR hu.subject_id = p_subject_id)
            AND (p_lecture_id IS NULL OR hu.lecture_id = p_lecture_id)
        GROUP BY GROUPING SETS (
            (hu.cliente, hu.environment_id, hu.environment_name, ts.period_start_date, ts.period_end_date),
            (hu.cliente, hu.environment_id, hu.environment_name, hu.course_id, hu.course_name, ts.period_start_date, ts.period_end_date),
            (hu.cliente, hu.environment_id, hu.environment_name, hu.course_id, hu.course_name, hu.space_id, hu.space_name, ts.period_start_date, ts.period_end_date),
            (hu.cliente, hu.environment_id, hu.environment_name, hu.course_id, hu.course_name, hu.space_id, hu.space_name, hu.subject_id, hu.subject_name, ts.period_start_date, ts.period_end_date),
            (hu.cliente, hu.environment_id, hu.environment_name, hu.course_id, hu.course_name, hu.space_id, hu.space_name, hu.subject_id, hu.subject_name, hu.lecture_id, hu.lecture_name, ts.period_start_date, ts.period_end_date)
        )

        UNION ALL

		-- BLOCO 2: TOTAIS POR USUÁRIO
		SELECT
		    uh.cliente,
		    uh.user_id,
		    uh.user_name,
            ts.period_start_date,
            ts.period_end_date,
		    uh.environment_id, uh.environment_name,
		    uh.course_id, uh.course_name,
		    uh.space_id, uh.space_name,
		    uh.subject_id, uh.subject_name,
		    uh.lecture_id, uh.lecture_name,
		    CASE
		        WHEN GROUPING(uh.lecture_id) = 0 THEN 'LEC' WHEN GROUPING(uh.subject_id) = 0 THEN 'SUB'
		        WHEN GROUPING(uh.space_id) = 0 THEN 'SPA' WHEN GROUPING(uh.course_id) = 0 THEN 'CRS'
		        WHEN GROUPING(uh.environment_id) = 0 THEN 'ENV' ELSE 'USER'
		    END AS NivelAgregacao,
		    COALESCE(SUM(fi.postsAmount), 0) AS postsAmount,
		    COALESCE(SUM(fi.postRepliesAmount), 0) AS postRepliesAmount,
		    COALESCE(SUM(fi.helpRequestsAmount), 0) AS helpRequestsAmount,
		    COALESCE(SUM(fi.helpRequestRepliesAmount), 0) AS helpRequestRepliesAmount
		FROM (
            SELECT u.cliente, u.id AS user_id, u.name AS user_name, e.id AS environment_id, e.name AS environment_name, c.id AS course_id, c.name AS course_name, s.id AS space_id, s.name AS space_name, sub.id AS subject_id, sub.name AS subject_name, l.id AS lecture_id, l.name AS lecture_name
            FROM `replicas.users` AS u
            JOIN `replicas.user_space_associations` AS usa ON u.id = usa.user_id AND u.cliente = usa.cliente
            JOIN `replicas.spaces` AS s ON usa.space_id = s.id AND u.cliente = s.cliente
            JOIN `replicas.courses` AS c ON s.course_id = c.id AND u.cliente = c.cliente
            JOIN `replicas.environments` AS e ON c.environment_id = e.id AND u.cliente = e.cliente
            LEFT JOIN `replicas.subjects` AS sub ON s.id = sub.space_id AND u.cliente = sub.cliente
            LEFT JOIN `replicas.lectures` AS l ON sub.id = l.subject_id AND u.cliente = l.cliente
            WHERE (p_cliente IS NULL OR u.cliente = p_cliente)
        ) AS uh
        CROSS JOIN time_scaffold AS ts
		LEFT JOIN interactions_with_period AS fi
		    ON  uh.cliente = fi.client
		    AND uh.user_id = fi.user_id
		    AND COALESCE(uh.environment_id, -1) = COALESCE(fi.environment_id, -1)
		    AND COALESCE(uh.course_id, -1) = COALESCE(fi.course_id, -1)
		    AND COALESCE(uh.space_id, -1) = COALESCE(fi.space_id, -1)
		    AND COALESCE(uh.subject_id, -1) = COALESCE(fi.subject_id, -1)
		    AND COALESCE(uh.lecture_id, -1) = COALESCE(fi.lecture_id, -1)
            AND ts.period_start_date = fi.period_start_date
		WHERE
		    p_show_by_user = TRUE
		    AND (p_environment_id IS NULL OR uh.environment_id = p_environment_id)
		    AND (p_course_id IS NULL OR uh.course_id = p_course_id)
		    AND (p_space_id IS NULL OR uh.space_id = p_space_id)
		    AND (p_subject_id IS NULL OR uh.subject_id = p_subject_id)
		    AND (p_lecture_id IS NULL OR uh.lecture_id = p_lecture_id)
		GROUP BY GROUPING SETS (
		    (uh.cliente, uh.user_id, uh.user_name, uh.environment_id, uh.environment_name, ts.period_start_date, ts.period_end_date),
		    (uh.cliente, uh.user_id, uh.user_name, uh.environment_id, uh.environment_name, uh.course_id, uh.course_name, ts.period_start_date, ts.period_end_date),
		    (uh.cliente, uh.user_id, uh.user_name, uh.environment_id, uh.environment_name, uh.course_id, uh.course_name, uh.space_id, uh.space_name, ts.period_start_date, ts.period_end_date),
		    (uh.cliente, uh.user_id, uh.user_name, uh.environment_id, uh.environment_name, uh.course_id, uh.course_name, uh.space_id, uh.space_name, uh.subject_id, uh.subject_name, ts.period_start_date, ts.period_end_date),
		    (uh.cliente, uh.user_id, uh.user_name, uh.environment_id, uh.environment_name, uh.course_id, uh.course_name, uh.space_id, uh.space_name, uh.subject_id, uh.subject_name, uh.lecture_id, uh.lecture_name, ts.period_start_date, ts.period_end_date)
		)
    )
  )
SELECT *
FROM final_cte
WHERE final_cte.NivelAgregacao = p_group_agg
);