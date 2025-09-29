

### Visão Geral: Uma Arquitetura de Pipeline em Três Camadas

Essas três funções (`fn_interacoes`, `fn_rendimento` e `fn_engajamento`) trabalham juntas para formar um pipeline de dados que cria uma visão 360° do aluno, unindo duas dimensões críticas:

1.  **Interação Social (`fn_interacoes`):** Mede o quão ativo e participativo o aluno é na plataforma.
2.  **Desempenho Acadêmico (`fn_rendimento`):** Mede a performance do aluno em relação às tarefas e exercícios.
3.  **Engajamento Unificado (`fn_engajamento`):** Combina as duas dimensões acima para criar um dataset rico e completo, que serve de base para a classificação.

---

### As Peças Fundamentais: `fn_interacoes` e `fn_rendimento`

Estas duas funções são os "construtores" da base de dados. Elas compartilham uma arquitetura muito similar, projetada para ser flexível e eficiente.

#### Arquitetura Comum e Conceitos-Chave

Ambas as funções são construídas sobre os mesmos pilares:

* **Hierarquia do Sistema:** As consultas constroem um universo de dados que respeita a hierarquia da plataforma: `Ambiente (ENV) -> Curso (CRS) -> Disciplina (SPA) -> Módulo (SUB) -> Aula/Mídia (LEC)`. Elas fazem isso através de `JOIN`s sucessivos nas tabelas `replicas.environments`, `courses`, `spaces`, `subjects` e `lectures`.
* **Agregação de Nível (`p_group_agg`):** O parâmetro `p_group_agg` permite que a função retorne dados já agregados no nível hierárquico desejado (ex: 'SUB' para disciplina, 'CRS' para curso). Isso é feito de forma extremamente eficiente usando **`GROUP BY GROUPING SETS`**, uma técnica avançada de SQL que calcula todas as agregações necessárias em uma única passagem pelos dados, evitando múltiplas consultas.
* **Agregação de Tempo (`p_time_agg`):** O parâmetro `p_time_agg` controla a granularidade temporal dos dados (WEEK, MONTH, QUARTER, etc.). O ponto mais interessante aqui é a implementação do **"Time Scaffold" (Andaime de Tempo)**.

    * **Ponto de Destaque (Time Scaffold):** Em vez de simplesmente agrupar os dados pela data, a função primeiro cria uma tabela temporária com *todos os períodos de tempo possíveis* no intervalo solicitado (`time_scaffold`). Depois, ela junta os dados de atividade (interações ou rendimento) a essa estrutura. Isso garante que **não haverá lacunas na série temporal**. Se um aluno não teve atividade em um determinado mês, haverá uma linha para aquele mês com valores zerados, o que é fundamental para análises de séries temporais e visualizações corretas.
    * **Lógica de Quinzena (`FORTNIGHT`):** A implementação da agregação quinzenal é um ótimo exemplo de flexibilidade. A lógica foi customizada para seguir uma regra de negócio específica (períodos fixos de 1-15 e 16-fim do mês), algo que as funções padrão do SQL não oferecem.

#### `analytics.fn_interacoes` - O Termômetro Social

* **Objetivo:** Medir a pulsação social do aluno na plataforma.
* **Fonte Principal:** A tabela `analytics.cubo_comentarios`.
* **Métricas Geradas:** `postsAmount`, `postRepliesAmount`, `helpRequestsAmount`, `helpRequestRepliesAmount`.
* **Lógica:** Ela conta os diferentes tipos de interações (posts, respostas, etc.) e os agrega de acordo com a hierarquia do sistema e o período de tempo definidos nos parâmetros.

#### `analytics.fn_rendimento` - O Medidor Acadêmico

* **Objetivo:** Medir o desempenho acadêmico e a conclusão de tarefas.
* **Fonte Principal:** A tabela `replicas.results`, que contém as entregas de exercícios.
* **Métricas Geradas:** `assigned_exercises` (exercícios atribuídos), `submitted_exercises` (exercícios entregues) e `performance_rate` (taxa de aproveitamento).
* **Lógica Interessante:**
    * **Deduplicação com `QUALIFY`:** A função primeiro remove entregas duplicadas para o mesmo exercício, considerando apenas a primeira submissão (`QUALIFY ROW_NUMBER() ... = 1`). Essa é uma forma moderna e eficiente de fazer deduplicação no BigQuery.
    * **Universo de Tarefas:** Ela cria um "universo" de todas as tarefas que deveriam ser feitas por todos os alunos (`assignments_universe`) e depois junta com os resultados das entregas para calcular a taxa de performance.

---

### A União das Forças: `analytics.fn_engajamento`

Esta é a função que **une** as duas anteriores, respondendo à sua pergunta central.

* **Objetivo Principal:** Atuar como a camada final de agregação, criando uma **visão 360° do engajamento** ao combinar as métricas sociais e acadêmicas em um único dataset.
* **Como Ela Une as Funções:**
    1.  **Chamada em Cascata:** A `fn_engajamento` chama `fn_interacoes` e `fn_rendimento`, passando para elas os **mesmos parâmetros** que recebeu (`p_start_date`, `p_time_agg`, etc.).
    2.  **`LEFT JOIN` Estratégico:** Ela une os resultados das duas funções usando um `LEFT JOIN`. O `fn_interacoes` é a base (tabela da esquerda), o que significa que o pipeline prioriza a atividade social, e anexa os dados de rendimento quando eles existem para o mesmo contexto.
    3.  **Chave de Junção Composta:** A união é o ponto mais crucial. A cláusula `ON` do `JOIN` garante que os dados sejam combinados corretamente, alinhando **todas as chaves da hierarquia** (`user_id`, `environment_id`, `course_id`, etc.) e, mais importante, a **chave de período de tempo (`period_start_date`)**. Isso assegura que as interações de um aluno em uma disciplina, durante uma semana específica, sejam combinadas com o rendimento dele naquela mesma disciplina e semana.
    4.  **Robustez com `COALESCE`:** O uso de `COALESCE` em todas as chaves da junção torna a união mais robusta, tratando corretamente possíveis valores nulos e evitando a perda de dados.

Em resumo, a `fn_engajamento` orquestra as duas funções construtoras para entregar um dataset final, coeso e pronto para ser usado pelo pipeline de Machine Learning para treinar e classificar os modelos.