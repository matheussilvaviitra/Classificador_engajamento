# Documentação da Função: fn_cubo_engajamento

## 1. Resumo

A função `fn_cubo_engajamento` é uma interface flexível para consultar dados hierárquicos de engajamento no Google BigQuery. Ela permite ao usuário selecionar a **granularidade** dos dados (ex: por curso, disciplina), aplicar **filtros de escopo hierárquico** (ex: para um ambiente ou curso específico) e restringir a consulta a um **período de tempo** determinado.

O principal objetivo é simplificar a análise de dados, permitindo que uma única função atenda a múltiplas necessidades de consulta, desde visões macro (todos os cursos de um ambiente) até micro (dados de uma única aula em uma data específica).

## 2. Sintaxe da Função

A função deve ser criada no mesmo *dataset* da tabela `cubo_engajamento` para melhor organização.

```sql
CREATE OR REPLACE TABLE FUNCTION analytics.fn_consultar_cubo_engajamento(
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
      -- Colunas da tabela cubo_engajamento
      *
  FROM
    `analytics.cubo_engajamento`
  WHERE
    -- Filtros fixos que sempre se aplicam
    cliente = p_cliente
    AND NivelAgregacao = p_nivel_agregacao

    -- Filtros de escopo hierárquico opcionais
    AND (p_environment_id IS NULL OR environment_id = p_environment_id)
    AND (p_course_id IS NULL OR course_id = p_course_id)
    AND (p_space_id IS NULL OR space_id = p_space_id)
    AND (p_subject_id IS NULL OR subject_id = p_subject_id)
    AND (p_lecture_id IS NULL OR lecture_id = p_lecture_id)

    -- Filtros de período opcionais (baseados na data_classificacao)
    AND (p_data_inicio IS NULL OR data_classificacao >= p_data_inicio)
    AND (p_data_fim IS NULL OR data_classificacao <= p_data_fim)
);
```

## 3. Parâmetros

| Nome do Parâmetro | Tipo de Dado | Obrigatório | Descrição |
| :--- | :--- | :--- | :--- |
| `p_cliente` | `STRING` | Sim | Identificador do cliente. |
| `p_nivel_agregacao` | `STRING` | Sim | Define a granularidade dos dados ('ENV', 'CRS', 'SPA', 'SUB', 'LEC'). |
| `p_environment_id`| `INT64` | Não | Filtra por um ID de ambiente específico. Passe `NULL` para ignorar. |
| `p_course_id` | `INT64` | Não | Filtra por um ID de curso específico. Passe `NULL` para ignorar. |
| `p_space_id` | `INT64` | Não | Filtra por um ID de comunidade (space) específico. Passe `NULL` para ignorar. |
| `p_subject_id` | `INT64` | Não | Filtra por um ID de disciplina específico. Passe `NULL` para ignorar. |
| `p_lecture_id` | `INT64` | Não | Filtra por um ID de aula específico. Passe `NULL` para ignorar. |
| `p_data_inicio` | `DATE` | Não | Data de início do filtro (inclusiva). Filtra `data_classificacao >= p_data_inicio`. Passe `NULL` para ignorar. |
| `p_data_fim` | `DATE` | Não | Data de fim do filtro (inclusiva). Filtra `data_classificacao <= p_data_fim`. Passe `NULL` para ignorar. |


## 4. Como Usar: Exemplos Práticos

A seguir, veja cenários práticos que demonstram a flexibilidade da função.

### Cenário 1: Obter os dados de TODOS os cursos de um ambiente

* **Objetivo**: Analisar o desempenho de todos os cursos (`CRS`) dentro de um ambiente específico (`environment_id = 1`), sem restrição de data.

```sql
SELECT
  course_id,
  course_name,
  performance_rate,
  categoria_engajamento
FROM
  analytics.fn_cubo_engajamento(
    'redu-digital', -- p_cliente
    'CRS',          -- Granularidade
    1,              -- Escopo (environment_id)
    NULL,           -- Escopo (ignorar course_id)
    NULL, NULL, NULL,
    NULL,           -- Sem data de início
    NULL            -- Sem data de fim
  );
```

### Cenário 2: Obter os dados de TODAS as disciplinas de um curso no último trimestre

* **Objetivo**: Listar todas as disciplinas (`SUB`) de um curso (`course_id = 45`) classificadas no terceiro trimestre de 2025.
* **Lógica**: A granularidade é `'SUB'`, o escopo é o curso 45, e definimos `p_data_inicio` e `p_data_fim`.

```sql
SELECT
  subject_id,
  subject_name,
  user_name,
  postsAmount,
  data_classificacao
FROM
  analytics.fn_cubo_engajamento(
    'redu-digital',                 -- p_cliente
    'SUB',                          -- Granularidade
    10,                             -- Escopo (environment_id)
    45,                             -- Escopo (course_id)
    NULL, NULL, NULL,
    DATE('2025-07-01'),             -- Data de início do filtro
    DATE('2025-09-30')              -- Data de fim do filtro
  );
```

### Cenário 3: Obter os dados de uma única aula a partir de uma data

* **Objetivo**: Investigar os dados de uma aula (`LEC`) específica, mas apenas as classificações feitas desde o início de agosto de 2025.
* **Lógica**: Definimos a granularidade `'LEC'`, fornecemos todos os IDs de escopo e apenas a `p_data_inicio`.

```sql
SELECT
  user_name,
  lecture_name,
  performance_rate,
  categoria_engajamento,
  data_classificacao
FROM
  analytics.fn_consultar_cubo_engajamento(
    'redu-digital',         -- p_cliente
    'SPA',                  -- Granularidade
    73, NULL, NULL, NULL, NULL,   -- Escopo hierárquico completo
    NULL,     -- Data de início do filtro
    NULL      -- Sem data de fim (pega tudo até o presente)
  );
```

## 5. Considerações Adicionais

* **Performance**: Para garantir o bom desempenho, é altamente recomendado que a tabela `analytics.cubo_engajamento` seja **particionada** pela coluna `data_classificacao` e **clusterizada** pelas colunas usadas nos filtros, como `cliente`, `NivelAgregacao` e os diversos `_id`.
* **Permissões**: O usuário ou conta de serviço que executa a consulta precisa ter permissões para chamar funções no *dataset* `analytics`.