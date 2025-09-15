

---

## O Diretório `db/`: O Coração do Pipeline

Este diretório contém todos os objetos de banco de dados (tabelas, funções, procedimentos) que compõem o pipeline no Google BigQuery. A estrutura é dividida em dois schemas principais, que representam uma separação clara de responsabilidades: `analytics` e `config`.

A maneira mais fácil de entender a diferença é pensar neles da seguinte forma:
* **`analytics`** responde à pergunta: "**O que** são os dados?"
* **`config`** responde à pergunta: "**Como** o processo funciona?"

### Schema `analytics`: O 'Quê' (Os Dados e Resultados)

Este schema contém os **ativos de dados** do projeto. Ele define a estrutura dos dados de entrada, das tabelas de resultado e das funções que servem como fontes de dados. É a camada que armazena e serve os dados brutos e processados.

* #### `tables/`
    Aqui estão os scripts DDL (`CREATE TABLE`) que definem a estrutura das tabelas de destino e de suporte à análise.
    * **`cubo_engajamento.sql`**: A tabela final, o principal entregável do projeto. É aqui que os resultados da classificação são armazenados para serem consumidos por dashboards ou outras análises.
    * **`mapeamento_labels_engajamento.sql`**: Uma tabela de suporte crucial que armazena a correspondência entre o `centroid_id` (ID do cluster) gerado pelo modelo e o label de negócio (ex: 'engajamento excelente').

* #### `functions/`
    Contém as Funções Definidas pelo Usuário (UDFs) que atuam como fontes de dados reutilizáveis e parametrizáveis. Elas encapsulam a lógica de negócio para buscar e pré-processar os dados.
    * **`fn_cubo_engajamento.sql`**: É a função principal que, ao receber parâmetros como datas e níveis de agregação, retorna o dataset completo e preparado que servirá de entrada para o treinamento e classificação dos modelos.

* #### `builders/`
    (Se aplicável) Scripts mais complexos e fundamentais, geralmente executados com menos frequência, que constroem as visões materializadas ou tabelas base que são consumidas pelas funções no diretório `functions/`.

### Schema `config`: O 'Como' (A Lógica e o Controle)

Se o `analytics` define os dados, o schema `config` define **como o pipeline opera**. Ele contém toda a lógica de orquestração, os procedimentos que executam as tarefas e as tabelas de parâmetros que controlam dinamicamente o comportamento de todo o processo.

* #### `tables/`
    Contém os scripts DDL para as tabelas que **controlam o pipeline**, permitindo que ele seja flexível sem a necessidade de alterar o código.
    * **`pipeline_config.sql`**: Define os níveis de agregação (ENV, CRS, SPA, etc.) a serem processados e se estão ativos ou não.
    * **`pipeline_parametros.sql`**: Armazena parâmetros globais como datas de início/fim e o tipo de agregação temporal (`MONTH`, `QUARTER`).
    * **`pipeline_labels_ordenados.sql`**: Permite a customização dos nomes das categorias de engajamento, tornando a regra de negócio editável.

* #### `builders/`
    Aqui residem os "motores" do pipeline: os **Stored Procedures** (procedimentos armazenados) que executam as ações.
    * **`sp_treinar_modelos.sql`**: Contém a lógica para treinar (ou retreinar) os modelos de K-Means para cada nível de agregação ativo.
    * **`sp_gerar_labels.sql`**: Executa a lógica para analisar os centroides do modelo treinado, calcular um score e atribuir os labels de negócio (lidos da tabela `pipeline_labels_ordenados`).
    * **`sp_classificar_cubo.sql`**: Usa os modelos treinados para classificar os usuários e inserir o resultado final na tabela `analytics.cubo_engajamento`.

* #### `functions/`
    Embora na pasta `functions`, estes são na verdade **procedimentos mestres** que orquestram a execução de outros procedimentos. São os pontos de entrada para rodar o pipeline.
    * **`sp_executar_treinamento.sql`**: Um procedimento que chama `sp_treinar_modelos` e `sp_gerar_labels` em sequência, para ser usado na execução manual do retreinamento.
    * **`consulta_main.sql`**: Provavelmente o ponto de entrada principal, que pode ser usado para disparar todo o fluxo de forma agendada.

### Resumo das Diferenças

| Característica | `analytics` | `config` |
| :--- | :--- | :--- |
| **Propósito Principal** | Armazenar e definir os dados | Orquestrar e controlar o processo |
| **Tipo de Objeto** | Tabelas de Dados, Funções (UDFs) | Tabelas de Parâmetros, Procedimentos (SPs) |
| **Responsabilidade** | O "Quê" (Dados, Resultados) | O "Como" (Lógica, Execução) |
| **Exemplo Chave** | `cubo_engajamento.sql` (tabela final) | `sp_classificar_cubo.sql` (procedimento de ação) |
| **Frequência de Mudança** | Baixa (estrutura estável) | Média (lógica do pipeline pode evoluir) |