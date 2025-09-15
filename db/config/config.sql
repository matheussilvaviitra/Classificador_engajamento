-- Cria o dataset para abrigar a lógica e os parâmetros do pipeline.
CREATE SCHEMA IF NOT EXISTS `viitra-redu.config`
OPTIONS(
  description="Dataset para armazenar tabelas de configuração e Stored Procedures dos pipelines de dados.",
  location="US" -- Adapte para a sua localização
);