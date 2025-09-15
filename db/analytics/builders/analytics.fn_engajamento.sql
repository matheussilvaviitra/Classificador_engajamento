CREATE OR REPLACE TABLE FUNCTION analytics.fn_engajamento(
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
    p_time_agg STRING -- << ADIÇÃO 1: Recebe o novo parâmetro
)
AS (
    SELECT
        -- Chaves da hierarquia
        COALESCE(eng.client, rend.cliente) AS cliente,
        COALESCE(eng.user_id, rend.user_id) AS user_id,
        COALESCE(eng.user_name, rend.user_name) AS user_name,

        -- << ADIÇÃO 2: Exibe os novos campos de período >>
        COALESCE(eng.period_start_date, rend.period_start_date) AS period_start_date,
        COALESCE(eng.period_end_date, rend.period_end_date) AS period_end_date,

        COALESCE(eng.environment_id, rend.environment_id) AS environment_id,
        COALESCE(eng.environment_name, rend.environment_name) AS environment_name,
        COALESCE(eng.course_id, rend.course_id) AS course_id,
        COALESCE(eng.course_name, rend.course_name) AS course_name,
        COALESCE(eng.space_id, rend.space_id) AS space_id,
        COALESCE(eng.space_name, rend.space_name) AS space_name,
        COALESCE(eng.subject_id, rend.subject_id) AS subject_id,
        COALESCE(eng.subject_name, rend.subject_name) AS subject_name,
        COALESCE(eng.lecture_id, rend.lecture_id) AS lecture_id,
        COALESCE(eng.lecture_name, rend.lecture_name) AS lecture_name,
        eng.NivelAgregacao,

        -- Métricas de Interações
        eng.postsAmount,
        eng.postRepliesAmount,
        eng.helpRequestsAmount,
        eng.helpRequestRepliesAmount,

        -- Métricas de Rendimento
        COALESCE(rend.assigned_exercises, 0) AS assigned_exercises,
        COALESCE(rend.submitted_exercises, 0) AS submitted_exercises,
        rend.performance_rate

    FROM
        -- << ADIÇÃO 3: Passa o novo parâmetro p_time_agg para as funções >>
        analytics.fn_interacoes(p_start_date, p_end_date, p_show_by_user, p_cliente, p_environment_id, p_course_id, p_space_id, p_subject_id, p_lecture_id, p_group_agg, p_time_agg) AS eng
    LEFT JOIN
        analytics.fn_rendimento(p_start_date, p_end_date, p_show_by_user, p_cliente, p_environment_id, p_course_id, p_space_id, p_subject_id, p_lecture_id, p_group_agg, p_time_agg) AS rend
    ON
        COALESCE(eng.client, '') = COALESCE(rend.cliente, '')
        AND COALESCE(eng.user_id, -1) = COALESCE(rend.user_id, -1)
        AND COALESCE(eng.environment_id, -1) = COALESCE(rend.environment_id, -1)
        AND COALESCE(eng.course_id, -1) = COALESCE(rend.course_id, -1)
        AND COALESCE(eng.space_id, -1) = COALESCE(rend.space_id, -1)
        AND COALESCE(eng.subject_id, -1) = COALESCE(rend.subject_id, -1)
        AND COALESCE(eng.lecture_id, -1) = COALESCE(rend.lecture_id, -1)
        -- << ADIÇÃO 4: Garante que o JOIN seja feito também pelo período de tempo >>
        AND COALESCE(eng.period_start_date, '1900-01-01') = COALESCE(rend.period_start_date, '1900-01-01')
    ORDER BY
        user_name, period_start_date, postsAmount DESC, performance_rate DESC
);