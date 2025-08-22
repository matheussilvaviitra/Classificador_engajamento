CREATE OR REPLACE TABLE `viitra-redu.analytics.cubo_engajamento`
(
  cliente STRING,
  user_id INT64,
  environment_id INT64,
  course_id INT64,
  space_id INT64,
  subject_id INT64,
  lecture_id INT64,
  NivelAgregacao STRING,
  user_name STRING,
  environment_name STRING,
  course_name STRING,
  space_name STRING,
  subject_name STRING,
  lecture_name STRING,
  data_inicio DATE,
  data_fim DATE,
  postsAmount INT64,
  postRepliesAmount INT64,
  helpRequestsAmount INT64,
  helpRequestRepliesAmount INT64,
  performance_rate FLOAT64,
  categoria_engajamento STRING,
  data_classificacao DATE
)
OPTIONS(
  description="Tabela com dados de engajamento dos estudantes, classificados por algoritmo de clusterização."
);