SELECT
	r.name,
	SUM(r.qtd_interacoes) AS qtd_interacoes,
	SUM(r.qtd_exercicios_atribuidos) AS qtd_exercicios_atribuidos,
	SUM(r.qtd_exercicios_entregues) AS qtd_exercicios_entregues
FROM
	(
		-- 1. Query para contagem de interações
		SELECT
			e.name,
			COUNT(s.id) AS qtd_interacoes,
			0 AS qtd_exercicios_atribuidos,
			0 AS qtd_exercicios_entregues
		FROM
			environments e
		LEFT JOIN
			user_environment_associations uea ON uea.environment_id = e.id
		LEFT JOIN
			statuses s ON uea.user_id = s.user_id
		WHERE
			s.type IN ('Answer', 'Activity', 'Help')
			AND s.created_at BETWEEN '2025-08-01' AND '2025-08-31'
		GROUP BY
			e.name

		UNION ALL

		-- 2. Query para contagem de exercícios atribuídos
		SELECT
			e2.name,
			0 AS qtd_interacoes,
			COUNT(l.id) AS qtd_exercicios_atribuidos,
			0 AS qtd_exercicios_entregues
		FROM
			environments e2
		LEFT JOIN
			courses c ON c.environment_id = e2.id
		LEFT JOIN
			spaces s2 ON s2.course_id = c.id
		LEFT JOIN
			subjects sub ON sub.space_id = s2.id
		LEFT JOIN
			lectures l ON l.subject_id = sub.id
		WHERE
			l.lectureable_type = 'Exercise' -- Filtra apenas exercícios
		GROUP BY
			e2.name

		UNION ALL

		-- 3. Query para contagem de exercícios entregues
		SELECT
			e3.name,
			0 AS qtd_interacoes,
			0 AS qtd_exercicios_atribuidos,
			COUNT(r.id) AS qtd_exercicios_entregues
		FROM
			environments e3
		LEFT JOIN
			courses c ON c.environment_id = e3.id
		LEFT JOIN
			spaces s2 ON s2.course_id = c.id
		LEFT JOIN
			subjects sub ON sub.space_id = s2.id
		LEFT JOIN
			lectures l ON l.subject_id = sub.id
		LEFT JOIN
			exercises ex ON ex.id = l.lectureable_id
		LEFT JOIN
			results r ON r.exercise_id = ex.id
		WHERE
			r.state = 'finalized'
		GROUP BY
			e3.name
	) AS r
-- WHERE name like '%UFPE%'
GROUP BY
	r.name
ORDER BY
	qtd_interacoes DESC, qtd_exercicios_entregues DESC;