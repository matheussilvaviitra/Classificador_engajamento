
-----

### Os Construtores (`builders`): A Lógica da Automação

Os scripts no diretório `config/builders/` são os motores do pipeline. Diferente das funções (`fn_...`) que apenas retornam dados, os procedimentos (`sp_...`) **executam ações**: treinam modelos, limpam tabelas e inserem dados. Eles são projetados para serem chamados por "jobs", seja manualmente por um analista ou de forma automática por um agendador.

A automação é dividida em dois fluxos de trabalho principais: um para o retreinamento (manual, sob demanda) e outro para a classificação (automatizado, recorrente).

-----

### Fluxo de Trabalho 1: Retreinamento Manual (Sob Demanda)

Este fluxo é executado apenas quando há necessidade de atualizar a inteligência dos modelos, seja por mudanças nos dados históricos ou na própria arquitetura do modelo. Ele consiste em dois procedimentos que devem ser executados em sequência.

#### `config.sp_treinar_modelos`

  * **Objetivo:** Treinar ou retreinar todos os modelos de clusterização (K-Means) para cada nível de agregação que estiver ativo.
  * **Como Funciona:**
    1.  Lê a tabela `config.pipeline_config` para descobrir quais níveis de agregação estão com `ativo = TRUE`.
    2.  Lê a tabela `config.pipeline_parametros` para obter as datas de início/fim e o tipo de agregação temporal (ex: 'MONTH').
    3.  Entra em um loop, processando um nível de agregação por vez.
    4.  Para cada nível, monta dinamicamente uma query `CREATE OR REPLACE MODEL`, inserindo os nomes do modelo e da função fonte, além dos parâmetros de data e agregação.
    5.  Executa a query, fazendo com que o BigQuery ML treine e salve o modelo especificado (ex: `analytics.modelo_engajamento_CRS`).
  * **Parâmetros de Configuração Utilizados:**
      * `config.pipeline_config`: Para saber quais modelos treinar.
      * `data_inicio_processamento`, `data_fim_processamento`: Para definir a janela de dados de treinamento.
      * `tipo_agregacao_data`: Para garantir que o modelo seja treinado com a mesma granularidade temporal da classificação.

#### `config.sp_gerar_labels`

  * **Objetivo:** "Traduzir" os centroides matemáticos gerados pelos modelos em rótulos de negócio compreensíveis (ex: 'engajamento excelente'). Este procedimento **deve sempre ser executado após `sp_treinar_modelos`**, pois os centroides mudam a cada novo treinamento.
  * **Como Funciona:**
    1.  Lê a tabela `config.pipeline_config` para saber para quais modelos deve gerar labels.
    2.  Limpa (`TRUNCATE`) a tabela de destino `analytics.mapeamento_labels_engajamento`.
    3.  Entra em um loop para cada nível ativo.
    4.  Usa as funções `ML.CENTROIDS` e `ML.FEATURE_INFO` para extrair os dados dos centroides do modelo recém-treinado.
    5.  Calcula um "score de engajamento" para cada centroide com base nas métricas de interações e rendimento.
    6.  Ordena os centroides por este score e, fazendo `JOIN` com a tabela `config.pipeline_labels_ordenados`, atribui o rótulo de negócio correspondente (ranking 1 recebe o melhor rótulo, etc.).
    7.  Insere o mapeamento final (`nivel_agregacao`, `centroid_id`, `categoria_engajamento`) na tabela `analytics.mapeamento_labels_engajamento`.
  * **Parâmetros de Configuração Utilizados:**
      * `config.pipeline_config`: Para identificar os modelos a serem analisados.
      * `config.pipeline_labels_ordenados`: Para buscar os nomes dos rótulos.
      * `tabela_mapeamento_labels`: Para saber onde salvar os resultados.

-----

### Fluxo de Trabalho 2: Classificação Automatizada (Agendada)

Este é o fluxo principal do dia a dia, projetado para ser executado de forma recorrente (ex: diariamente) pelo agendador do BigQuery (Scheduled Queries).

#### `config.sp_classificar_cubo`

  * **Objetivo:** Usar os modelos já treinados para classificar os usuários e popular a tabela final `analytics.cubo_engajamento` com os dados mais recentes.
  * **Como Funciona:**
    1.  Lê todos os parâmetros necessários das tabelas `config.pipeline_config` e `config.pipeline_parametros`.
    2.  Limpa (`TRUNCATE`) a tabela de destino `analytics.cubo_engajamento` para garantir que ela contenha apenas a "foto" da última classificação.
    3.  Entra em um loop para cada nível de agregação ativo.
    4.  Para cada nível, chama a função `ML.PREDICT`, passando o modelo correspondente (ex: `analytics.modelo_engajamento_CRS`) e os dados de engajamento do período solicitado.
    5.  Faz um `JOIN` do resultado da predição (que contém o `centroid_id`) com a tabela `analytics.mapeamento_labels_engajamento` para obter a `categoria_engajamento` (o rótulo de negócio).
    6.  Calcula colunas adicionais (como `conclusion_percent`) e insere o conjunto de dados completo e classificado na tabela `analytics.cubo_engajamento`.
  * **Parâmetros de Configuração Utilizados:** Todos. Esta procedure é a que mais depende do "painel de controle" para funcionar corretamente.

### Como Executar (Jobs)

A execução do pipeline é feita através de chamadas a procedimentos "mestres" ou diretamente aos procedimentos de trabalho.

  * **Para o Retreinamento Manual:**
    Deve ser chamado um procedimento mestre (ex: `config.sp_manual_executar_retreinamento`) que executa `sp_treinar_modelos` e `sp_gerar_labels` na ordem correta.

    ```sql
    -- Este job é executado manualmente quando for necessário atualizar os modelos.
    CALL config.sp_manual_executar_retreinamento();
    ```

  * **Para a Classificação Agendada:**
    O "job" é uma **Consulta Agendada (Scheduled Query)** no BigQuery que chama diretamente o procedimento de classificação.

    ```sql
    -- Este comando deve ser inserido no agendador do BigQuery para rodar diariamente.
    -- Ele executa a classificação usando os modelos e labels que já existem.
    CALL config.sp_classificar_cubo();
    ```