

-----

# Documentação da Função: fn\_cubo\_engajamento

## 1\. Resumo

A função `fn_cubo_engajamento` serve como uma interface de consulta parametrizável para a tabela `analytics.cubo_engajamento`. Ela foi projetada para simplificar o acesso aos dados de classificação de engajamento, permitindo que os usuários filtrem os resultados de forma dinâmica por múltiplos critérios, incluindo:

  * **Nível de Hierarquia:** Define a granularidade dos dados (ex: por Curso, Disciplina).
  * **Escopo Hierárquico:** Filtra os dados para um ou mais níveis específicos da hierarquia (ex: para um Ambiente ou Turma específica).
  * **Intervalo de Datas:** Restringe a consulta a um período de tempo específico com base nas datas de início e fim dos dados agregados.

O objetivo principal é oferecer um ponto de acesso único e flexível à tabela de resultados, evitando a necessidade de escrever consultas complexas repetidamente.

## 2\. Sintaxe da Função

```sql
CREATE OR REPLACE TABLE FUNCTION analytics.fn_cubo_engajamento(
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
| `p_nivel_agregacao` | `STRING` | Sim | Define a granularidade dos dados. Valores válidos: 'ENV', 'CRS', 'SPA', 'SUB', 'LEC'. |
| `p_environment_id`| `INT64` | Não | Filtra por um ID de ambiente específico. Passe `NULL` para ignorar. |
| `p_course_id` | `INT64` | Não | Filtra por um ID de curso específico. Passe `NULL` para ignorar. |
| `p_space_id` | `INT64` | Não | Filtra por um ID de turma (space) específico. Passe `NULL` para ignorar. |
| `p_subject_id` | `INT64` | Não | Filtra por um ID de disciplina específico. Passe `NULL` para ignorar. |
| `p_lecture_id` | `INT64` | Não | Filtra por um ID de aula específico. Passe `NULL` para ignorar. |
| `p_data_inicio` | `DATE` | Não | Data de início do período de agregação (inclusiva). Filtra `data_inicio >= p_data_inicio`. |
| `p_data_fim` | `DATE` | Não | Data de fim do período de agregação (inclusiva). Filtra `data_fim <= p_data_fim`. |

## 4\. Campos Retornados

A função retorna todas as colunas da tabela `analytics.cubo_engajamento`. Abaixo está a lista completa de campos disponíveis para seleção.

| Campo | Tipo de Dado | Descrição |
| :--- | :--- | :--- |
| `cliente` | `STRING` | Identificador do cliente. |
| `user_id` | `INT64` | ID do usuário. |
| `environment_id` | `INT64` | ID do ambiente. |
| `course_id` | `INT64` | ID do curso. |
| `space_id` | `INT64` | ID da turma (space). |
| `subject_id` | `INT64` | ID da disciplina. |
| `lecture_id` | `INT64` | ID da aula. |
| `NivelAgregacao` | `STRING` | Nível de agregação dos dados na linha (ENV, CRS, etc.). |
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

### Cenário 1: Obter dados de TODOS os cursos de um ambiente

  * **Objetivo**: Analisar o desempenho de todos os cursos (`CRS`) dentro de um ambiente específico (`environment_id = 73`), sem restrição de data.

<!-- end list -->

```sql
SELECT
  course_id,
  course_name,
  categoria_engajamento,
  conclusion_percent
FROM
  analytics.fn_cubo_engajamento(
    'redu-digital', -- p_cliente
    'CRS',          -- p_nivel_agregacao
    73,             -- p_environment_id
    NULL,           -- p_course_id (ignorado)
    NULL, NULL, NULL,
    NULL,           -- p_data_inicio (ignorado)
    NULL            -- p_data_fim (ignorado)
  );
```

### Cenário 2: Obter dados de TODAS as disciplinas de uma turma no segundo semestre de 2025

  * **Objetivo**: Listar todas as disciplinas (`SUB`) de uma turma específica (`space_id = 120`) com dados agregados no período de Julho a Dezembro de 2025.
  * **Lógica**: A granularidade é `'SUB'`, o escopo é a turma 120, e definimos `p_data_inicio` e `p_data_fim`.

<!-- end list -->

```sql
SELECT
  subject_id,
  subject_name,
  user_name,
  postsAmount,
  submitted_exercises
FROM
  analytics.fn_cubo_engajamento(
    'redu-digital',           -- p_cliente
    'SUB',                    -- p_nivel_agregacao
    NULL,                     -- p_environment_id (ignorado)
    NULL,                     -- p_course_id (ignorado)
    120,                      -- p_space_id
    NULL, NULL,
    DATE('2025-07-01'),       -- p_data_inicio
    DATE('2025-12-31')        -- p_data_fim
  );
```

### Cenário 3: Obter os dados de uma única aula a partir de uma data

  * **Objetivo**: Investigar os dados de uma aula (`LEC`) específica, mas apenas para períodos que começam a partir de 1º de Setembro de 2025.
  * **Lógica**: Definimos a granularidade `'LEC'`, fornecemos todos os IDs de escopo para afunilar até a aula, e apenas a `p_data_inicio`.

<!-- end list -->

```sql
SELECT
  user_name,
  lecture_name,
  conclusion_percent,
  categoria_engajamento,
  data_inicio
FROM
  analytics.fn_cubo_engajamento(
    'redu-digital',         -- p_cliente
    'LEC',                  -- p_nivel_agregacao
    73,                     -- p_environment_id
    101,                    -- p_course_id
    120,                    -- p_space_id
    250,                    -- p_subject_id
    3001,                   -- p_lecture_id
    DATE('2025-09-01'),     -- p_data_inicio
    NULL                    -- p_data_fim (ignorado)
  );
```

## 6\. Considerações Adicionais

  * **Performance**: Para garantir o bom desempenho, é altamente recomendado que a tabela `analytics.cubo_engajamento` seja **particionada** pela coluna `data_inicio` ou `data_classificacao` e **clusterizada** pelas colunas usadas nos filtros, como `cliente`, `NivelAgregacao` e os diversos `_id`.
  * **Permissões**: O usuário ou conta de serviço que executa a consulta precisa ter permissões de `bigquery.routines.get` e `bigquery.tables.getData` no dataset `analytics`.