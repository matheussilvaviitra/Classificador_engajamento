
-----

# Documentação da Função: fn\_cubo\_engajamento

## 1\. Resumo

A função `fn_cubo_engajamento` serve como uma interface de consulta parametrizável para a tabela `analytics.cubo_engajamento`. Ela foi projetada para simplificar o acesso aos dados de classificação de engajamento, permitindo que os usuários filtrem os resultados de forma dinâmica por múltiplos critérios, incluindo:

  * **Nível de Hierarquia:** Define a granularidade dos dados (ex: por Curso, Disciplina).
  * **Tipo de Agregação de Data:** Define a granularidade temporal dos dados (ex: `WEEK`, `MONTH`).
  * **Escopo Hierárquico:** Filtra os dados para um ou mais níveis específicos da hierarquia (ex: para um Ambiente ou Turma específica).
  * **Intervalo de Datas:** Restringe a consulta a um período de tempo específico com base nas datas de início e fim dos dados agregados.

O objetivo principal é oferecer um ponto de acesso único e flexível à tabela de resultados, evitando a necessidade de escrever consultas complexas repetidamente.

## 2\. Sintaxe da Função

```sql
CREATE OR REPLACE TABLE FUNCTION analytics.fn_cubo_engajamento(
    p_cliente STRING,
    p_nivel_agregacao STRING,
    p_tipo_agregacao_data STRING,
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
      TipoAgregacaoData,
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
      assigned_exercises,
      submitted_exercises,
      conclusion_percent,
      categoria_engajamento,
      data_classificacao
  FROM
    `analytics.cubo_engajamento`
  WHERE
    -- Filtros obrigatórios
    cliente = p_cliente
    AND NivelAgregacao = p_nivel_agregacao
    AND TipoAgregacaoData = p_tipo_agregacao_data

    -- Filtros de escopo hierárquico (opcionais)
    AND (p_environment_id IS NULL OR environment_id = p_environment_id)
    AND (p_course_id IS NULL OR course_id = p_course_id)
    AND (p_space_id IS NULL OR space_id = p_space_id)
    AND (p_subject_id IS NULL OR subject_id = p_subject_id)
    AND (p_lecture_id IS NULL OR lecture_id = p_lecture_id)

    -- Filtros de período (opcionais)
    AND (p_data_inicio IS NULL OR data_inicio >= p_data_inicio)
    AND (p_data_fim IS NULL OR data_fim <= p_data_fim)
);
```

## 3\. Parâmetros

| Nome do Parâmetro | Tipo de Dado | Obrigatório | Descrição |
| :--- | :--- | :--- | :--- |
| `p_cliente` | `STRING` | Sim | Identificador do cliente. Ex: 'redu-digital'. |
| `p_nivel_agregacao` | `STRING` | Sim | Define a granularidade hierárquica. Valores: 'ENV', 'CRS', 'SPA', 'SUB', 'LEC'. |
| `p_tipo_agregacao_data` | `STRING` | Sim | Define a granularidade temporal. Valores: 'WEEK', 'MONTH', 'QUARTER', etc. |
| `p_environment_id`| `INT64` | Não | Filtra por um ID de ambiente específico. Passe `NULL` para ignorar. |
| `p_course_id` | `INT64` | Não | Filtra por um ID de curso específico. Passe `NULL` para ignorar. |
| `p_space_id` | `INT64` | Não | Filtra por um ID de turma (space) específico. Passe `NULL` para ignorar. |
| `p_subject_id` | `INT64` | Não | Filtra por um ID de disciplina específico. Passe `NULL` para ignorar. |
| `p_lecture_id` | `INT64` | Não | Filtra por um ID de aula específico. Passe `NULL` para ignorar. |
| `p_data_inicio` | `DATE` | Não | Data de início do período de agregação (inclusiva). Filtra `data_inicio >= p_data_inicio`. |
| `p_data_fim` | `DATE` | Não | Data de fim do período de agregação (inclusiva). Filtra `data_fim <= p_data_fim`. |

## 4\. Campos Retornados

| Campo | Tipo de Dado | Descrição |
| :--- | :--- | :--- |
| `cliente` | `STRING` | Identificador do cliente. |
| `user_id` | `INT64` | ID do usuário. |
| `environment_id` | `INT64` | ID do ambiente. |
| `course_id` | `INT64` | ID do curso. |
| `space_id` | `INT64` | ID da turma (space). |
| `subject_id` | `INT64` | ID da disciplina. |
| `lecture_id` | `INT64` | ID da aula. |
| `NivelAgregacao` | `STRING` | Nível de agregação hierárquica dos dados (ENV, CRS, etc.). |
| `TipoAgregacaoData` | `STRING` | Nível de agregação temporal dos dados (WEEK, MONTH, etc.). |
| `user_name` | `STRING` | Nome do usuário. |
| `environment_name`| `STRING` | Nome do ambiente. |
| `course_name` | `STRING` | Nome do curso. |
| `space_name` | `STRING` | Nome da turma (space). |
| `subject_name` | `STRING` | Nome da disciplina. |
| `lecture_name` | `STRING` | Nome da aula. |
| `data_inicio` | `DATE` | Data de início do período de agregação dos dados. |
| `data_fim` | `DATE` | Data de fim do período de agregação dos dados. |
| `postsAmount` | `INT64` | Quantidade de posts criados. |
| `postRepliesAmount`| `INT64` | Quantidade de respostas a posts. |
| `helpRequestsAmount`| `INT64` | Quantidade de pedidos de ajuda. |
| `helpRequestRepliesAmount`| `INT64` | Quantidade de respostas a pedidos de ajuda. |
| `assigned_exercises`| `INT64` | Quantidade de exercícios atribuídos. |
| `submitted_exercises`| `INT64` | Quantidade de exercícios entregues. |
| `conclusion_percent`| `FLOAT64` | Percentual de conclusão de exercícios. |
| `categoria_engajamento`| `STRING` | Label de classificação (ex: 'engajamento excelente'). |
| `data_classificacao`| `DATE` | Data em que o pipeline de classificação foi executado. |

## 5\. Como Usar: Exemplos Práticos

### Cenário 1: Comparar engajamento mensal vs. semanal para um curso

  * **Objetivo**: Analisar o desempenho de um curso (`CRS`, `course_id = 101`), comparando os dados agregados por mês e por semana, sem restrição de data.

<!-- end list -->

```sql
-- Consulta para dados MENSAIS
SELECT course_name, data_inicio, categoria_engajamento, conclusion_percent
FROM analytics.fn_cubo_engajamento(
    'redu-digital', -- p_cliente
    'CRS',          -- p_nivel_agregacao
    'MONTH',        -- p_tipo_agregacao_data
    NULL, 101, NULL, NULL, NULL,
    NULL, NULL
);

-- Consulta para dados SEMANAIS
SELECT course_name, data_inicio, categoria_engajamento, conclusion_percent
FROM analytics.fn_cubo_engajamento(
    'redu-digital', -- p_cliente
    'CRS',          -- p_nivel_agregacao
    'WEEK',         -- p_tipo_agregacao_data
    NULL, 101, NULL, NULL, NULL,
    NULL, NULL
);
```

### Cenário 2: Obter dados mensais de todas as disciplinas de uma turma no segundo semestre de 2025

  * **Objetivo**: Listar os dados mensais (`MONTH`) de todas as disciplinas (`SUB`) de uma turma específica (`space_id = 120`) com dados agregados no período de Julho a Dezembro de 2025.

<!-- end list -->

```sql
SELECT
  subject_id,
  subject_name,
  user_name,
  postsAmount
FROM
  analytics.fn_cubo_engajamento(
    'redu-digital',           -- p_cliente
    'SUB',                    -- p_nivel_agregacao
    'MONTH',                  -- p_tipo_agregacao_data
    NULL, NULL, 120, NULL, NULL,
    DATE('2025-07-01'),       -- p_data_inicio
    DATE('2025-12-31')        -- p_data_fim
  );
```

## 6\. Considerações Adicionais

  * **Performance**: Para garantir o bom desempenho, é altamente recomendado que a tabela `analytics.cubo_engajamento` seja **particionada** pela coluna `data_inicio` ou `data_classificacao` e **clusterizada** pelas colunas usadas nos filtros, como `cliente`, `NivelAgregacao`, `TipoAgregacaoData` e os diversos `_id`.
  * **Permissões**: O usuário ou conta de serviço que executa a consulta precisa ter permissões de `bigquery.routines.get` e `bigquery.tables.getData` no dataset `analytics`.