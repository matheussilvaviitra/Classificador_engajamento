
-----

### As Tabelas de Configuração: O Painel de Controle do Pipeline

As tabelas no schema `config` são o cérebro e o painel de controle de todo o pipeline de automação. A principal importância delas é **desacoplar a lógica de execução (código SQL) das regras de negócio e parâmetros operacionais**.

Isso significa que um analista ou gestor do projeto pode alterar o comportamento de todo o fluxo de treinamento e classificação — como as datas de processamento, os níveis de agregação a serem considerados, ou até os nomes das categorias de engajamento — **sem precisar editar uma única linha de código SQL dos procedimentos armazenados**. Basta alterar os valores nestas tabelas.

-----

#### Tabela: `config.pipeline_config`

Esta tabela funciona como uma chave geral, definindo **quais** hierarquias e modelos devem ser processados pelo pipeline. Cada linha representa um nível de agregação a ser considerado.

  * **Importância para a Automação:** Permite ligar ou desligar o processamento de níveis inteiros de forma simples. Se um nível se torna irrelevante ou computacionalmente caro, basta desativá-lo. Os procedimentos (`sp_treinar_modelos`, `sp_classificar_cubo`, etc.) leem dinamicamente esta tabela para saber qual trabalho devem executar.
  * **Parâmetros e Impactos:**
      * **Mudar o parâmetro `ativo`:** Este é o controle mais direto.
          * **Exemplo:** Suponha que a análise no nível de `LEC` (aula) está muito granular e consumindo muitos recursos. Pode-se desativá-la temporariamente.
          * **Comando:**
            ```sql
            UPDATE config.pipeline_config SET ativo = FALSE WHERE nivel_agregacao = 'LEC';
            ```
          * **Impacto:** Na próxima execução, o pipeline irá pular o treinamento do modelo `modelo_engajamento_LEC` e a classificação para este nível, tornando a execução mais rápida e barata. A tabela `cubo_engajamento` não receberá novas linhas com `NivelAgregacao = 'LEC'`.

-----

#### Tabela: `config.pipeline_parametros`

Esta tabela armazena os parâmetros globais que afetam **toda** a execução do pipeline.

  * **Importância para a Automação:** Permite ajustar o escopo de dados e a granularidade temporal de todas as análises de forma centralizada. É o local para configurar o "quando" e o "como" em termos de tempo.
  * **Parâmetros e Impactos:**
      * **Mudar o intervalo de datas (`data_inicio_processamento`, `data_fim_processamento`):**
          * **Exemplo:** Você precisa reprocessar os dados do primeiro semestre de 2021 para um estudo específico.
          * **Comando:**
            ```sql
            UPDATE config.pipeline_parametros SET valor_date = '2021-01-01' WHERE parametro = 'data_inicio_processamento';
            UPDATE config.pipeline_parametros SET valor_date = '2021-06-30' WHERE parametro = 'data_fim_processamento';
            ```
          * **Impacto:** A próxima execução do pipeline (tanto de treinamento quanto de classificação) usará este novo intervalo de datas para consultar os dados nas funções base (`fn_interacoes`, `fn_rendimento`), focando a análise apenas neste período.
      * **Mudar a lógica de agregação de data (`tipo_agregacao_data`):**
          * **Exemplo:** A análise trimestral ('QUARTER') não é granular o suficiente. Você quer analisar o engajamento mensalmente ('MONTH').
          * **Comando:**
            ```sql
            UPDATE config.pipeline_parametros SET valor_string = 'MONTH' WHERE parametro = 'tipo_agregacao_data';
            ```
          * **Impacto:** O pipeline passará este novo valor para as funções construtoras. A agregação de dados mudará de trimestral para mensal, e a tabela final `cubo_engajamento` passará a ter linhas que representam o engajamento de cada mês, permitindo uma visão mais detalhada da evolução do engajamento ao longo do tempo.

-----

#### Tabela: `config.pipeline_labels_ordenados`

Esta tabela é fundamental para a flexibilidade do negócio, pois desacopla a saída numérica do modelo de Machine Learning (ex: cluster 1, 2, 3, 4) da terminologia de negócio (os rótulos de engajamento).

  * **Importância para a Automação:** Permite que a equipe de negócio ajuste a nomenclatura das categorias de engajamento sem qualquer intervenção da equipe de dados. O procedimento `sp_gerar_labels` lê esta tabela para atribuir os rótulos corretos com base no ranking de score dos clusters.
  * **Parâmetros e Impactos:**
      * **Mudar os rótulos de engajamento (`label`):**
          * **Exemplo:** A equipe pedagógica decide que "desempenho crítico" é um termo muito forte e prefere usar "ponto de atenção".
          * **Comando:**
            ```sql
            UPDATE config.pipeline_labels_ordenados SET label = 'ponto de atenção' WHERE ranking = 3;
            ```
          * **Impacto:** Após a execução do `sp_manual_executar_retreinamento` (que chama o `sp_gerar_labels`), a tabela de mapeamento será atualizada. Consequentemente, todas as futuras classificações no `cubo_engajamento` usarão o novo rótulo "ponto de atenção" para o terceiro cluster, tornando o resultado mais alinhado à linguagem do negócio.
      * **Adaptar para mais clusters:**
          * **Exemplo:** O modelo foi retreinado para usar 5 clusters em vez de 4.
          * **Comando:**
            ```sql
            INSERT INTO config.pipeline_labels_ordenados (ranking, label, descricao) VALUES (5, 'observação', 'Cluster com o menor score de engajamento.');
            ```
          * **Impacto:** O pipeline se adapta automaticamente. O `sp_gerar_labels` irá ranquear os 5 centroides e usar a tabela para atribuir os 5 rótulos correspondentes, evitando erros e garantindo que todos os clusters sejam corretamente nomeados.