

-----

## Como Executar o Pipeline: Os Pontos de Entrada

A execução do pipeline é dividida em dois processos distintos e independentes: o **retreinamento manual** e a **classificação automatizada**. Essa separação garante que o custoso processo de retreinamento só seja executado quando necessário, enquanto a classificação, mais leve, pode rodar de forma recorrente.

### 1\. Retreinamento Manual (Sob Demanda)

Este processo deve ser acionado manualmente sempre que for necessário atualizar a "inteligência" dos modelos de Machine Learning.

#### Procedimento Mestre: `config.sp_executar_retreinamento`

Este é o ponto de entrada para o fluxo de retreinamento. Ele funciona como um "orquestrador" que chama outros procedimentos na ordem correta, garantindo que o processo seja executado de forma coesa e completa.

  * **Para que serve?**
    O `sp_executar_retreinamento` é um procedimento mestre que atualiza completamente os modelos e seus respectivos rótulos de negócio. Ele executa duas tarefas críticas em sequência:

    1.  **`CALL config.sp_treinar_modelos()`**: Primeiro, ele invoca o procedimento que treina novamente os modelos de K-Means, usando os dados e parâmetros mais recentes definidos nas tabelas de configuração.
    2.  **`CALL config.sp_gerar_labels()`**: Imediatamente após, ele chama o procedimento que analisa os novos centroides dos modelos recém-treinados e gera os novos rótulos de engajamento, salvando-os na tabela `analytics.mapeamento_labels_engajamento`.

  * **Quando deve ser usado?**
    Este procedimento **não deve ser agendado**. Ele deve ser executado manualmente, sob demanda, nas seguintes situações:

      * Após uma mudança significativa nos dados históricos que possa alterar o comportamento dos usuários.
      * Quando os parâmetros nas tabelas `config` forem alterados (ex: mudança no período de análise ou na granularidade de tempo).
      * Periodicamente (ex: a cada trimestre ou semestre), para garantir que os modelos não fiquem desatualizados (evitar *model drift*).

  * **Como usar?**
    A execução é simples. Basta rodar o seguinte comando no BigQuery:

    ```sql
    -- Executa o fluxo completo de retreinamento e geração de labels
    CALL config.sp_executar_retreinamento();
    ```

### 2\. Classificação Automatizada (Agendada)

Este é o processo que roda de forma recorrente para classificar os usuários e atualizar a tabela final de resultados. Ele **usa os modelos que já foram treinados** pelo fluxo manual.

  * **Como automatizar a classificação?**
    A automação é feita através do recurso **Scheduled Queries** do Google BigQuery. Você deve criar uma nova consulta agendada e inserir o seguinte comando:

    ```sql
    -- Este é o comando que será executado pelo job agendado (ex: diariamente)
    CALL config.sp_classificar_cubo();
    ```

  * **O que este comando faz?**
    A cada execução, a chamada ao `config.sp_classificar_cubo` irá:

    1.  Ler os parâmetros de configuração (datas, níveis ativos, etc.).
    2.  Limpar a tabela `analytics.cubo_engajamento`.
    3.  Buscar os dados de engajamento para o período definido.
    4.  Usar os modelos de ML **existentes** para prever o cluster (`centroid_id`) de cada usuário.
    5.  Enriquecer os dados com os rótulos de negócio (ex: 'engajamento excelente') lendo da tabela `analytics.mapeamento_labels_engajamento`.
    6.  Inserir os resultados finais e atualizados na tabela `analytics.cubo_engajamento`.

Essa separação garante um pipeline eficiente, onde a parte pesada (treinamento) é feita de forma controlada, e a parte leve (classificação) pode ser automatizada com segurança e baixo custo.