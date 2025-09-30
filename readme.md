Com certeza\! Adicionei uma nova seção "Documentação Detalhada" logo no início para dar destaque ao link, como solicitado.

-----

# Projeto Classificador de Engajamento

Este repositório contém todos os scripts SQL e a estrutura necessária para implementar um pipeline de Machine Learning no Google BigQuery. O objetivo principal é classificar o engajamento de usuários com base em suas interações na plataforma, utilizando um modelo de clusterização (K-Means).

O projeto é desenhado para ser modular, parametrizável e automatizado, separando claramente as estruturas de dados das lógicas de execução.

## Documentação Detalhada

Para uma visão aprofundada da arquitetura, decisões de modelagem e próximos passos, acesse o documento completo do projeto:
[Documentação Completa do Projeto](https://docs.google.com/document/d/1lEBznqD3zt0p_o2Ipo7MNdCMtChKnpl4t7Jo0jrFm6Y/edit?usp=sharing)

## Tecnologias Principais

  * **Google BigQuery**: Utilizado como Data Warehouse, plataforma de Machine Learning (BigQuery ML) e motor de execução para todo o pipeline.
  * **SQL**: Linguagem principal para definição de tabelas, funções e procedimentos armazenados.
  * **Python**: Usado para o ambiente de desenvolvimento inicial e prototipagem em notebooks.

## Estrutura do Repositório

A organização dos arquivos e diretórios foi pensada para isolar responsabilidades e facilitar a manutenção.

```
CLASSIFICADOR/
│
├── db/
│   ├── analytics/
│   │   ├── builders/
│   │   ├── functions/
│   │   │   └── analytics.fn_cubo_engajamento.sql
│   │   └── tables/
│   │       ├── analytics.mapeamento_labels_engajamento.sql
│   │       └── analytics.cubo_engajamento.sql
│   │
│   ├── config/
│   │   ├── builders/
│   │   │   ├── config.sp_classificar_cubo.sql
│   │   │   ├── config.sp_gerar_labels.sql
│   │   │   └── config.sp_treinar_modelos.sql
│   │   ├── functions/
│   │   │   ├── config.sp_executar_treinamento.sql
│   │   │   └── consulta_main.sql
│   │   └── tables/
│   │       ├── config.pipeline_config.sql
│   │       ├── config.pipeline_labels_ordenados.sql
│   │       └── config.pipeline_parametros.sql
│   │
│   └── Ref/
│       └── (scripts sql para cálculo de variáveis)
│
├── dev/
│   └── notebooks/
│       └── BigQueryML.ipynb
│
├── DW/
│   ├── EER_DW_Proposto.png
│   └── Proximos_Passos.md
│
├── env/
├── keyfile.json
├── requirements.txt
└── readme.md
```

### Diretório `db/`

É o coração do projeto, contendo todos os scripts SQL que definem a arquitetura no BigQuery. Ele é dividido em três schemas principais: `analytics`, `config` e `Ref`.

#### `db/analytics/`

Este diretório trata das **estruturas base para a classificação**. Ele contém os objetos de banco de dados que preparam e armazenam os dados e os resultados finais.

  * `builders/`: Contém scripts "construtores", responsáveis por lógicas complexas de extração e preparação dos dados que serão classificados.
  * `functions/`: Abriga as funções SQL (UDFs) que servem como agregadores e fontes de dados para o pipeline. Ex: `analytics.fn_cubo_engajamento.sql`.
  * `tables/`: Contém os scripts DDL (`CREATE TABLE`) para as tabelas de destino, como o cubo final (`cubo_engajamento.sql`) e as tabelas de mapeamento (`mapeamento_labels_engajamento.sql`).

#### `db/config/`

Segue a mesma lógica de subdiretórios, mas com o objetivo de **automatizar e parametrizar o treinamento e a classificação**.

  * `builders/`: Contém os Stored Procedures (`sp_*.sql`) que encapsulam toda a lógica do pipeline, como treinar os modelos, gerar os labels e classificar os usuários.
  * `functions/`: Contém procedimentos "mestres" (`sp_executar_treinamento.sql`) que orquestram a chamada de outros procedimentos menores, facilitando a execução manual ou agendada.
  * `tables/`: Contém os scripts DDL para as tabelas de configuração que controlam o comportamento do pipeline (ex: `pipeline_config.sql`, `pipeline_parametros.sql`).

#### `db/Ref/`

Este diretório contém os scripts SQL de **referência e cálculo de métricas**. Seu objetivo é abrigar as consultas que devem ser executadas diretamente na base de dados do Redu para calcular e extrair as variáveis selecionadas, como níveis de interações e o uso de exercícios por cada ambiente. Estes scripts servem como base para a engenharia de features e podem ser usados tanto para a exploração de dados quanto para a criação das tabelas que alimentarão o cubo de engajamento.

### Diretório `dev/`

Este diretório serve como o **ambiente de desenvolvimento e prototipagem** do projeto. É aqui que os estudos, exploração de dados, engenharia de features e testes iniciais de modelos são realizados, geralmente em formato de notebooks (`.ipynb`). Toda a lógica validada neste ambiente é, subsequentemente, transformada nas consultas e procedimentos SQL robustos que residem no diretório `db/`.

### Diretório `DW/`

Este diretório contém a documentação e artefatos relacionados à arquitetura do Data Warehouse. Nele é possível encontrar um **esquema EER (Entidade-Relacionamento Estendido) proposto** para a modelagem dos dados, além de um documento com **sugestões e ideias para os próximos passos** e a evolução do projeto de dados.

### Outros Arquivos

  * `env/`: Diretório do ambiente virtual Python.
  * `keyfile.json`: ⚠️ **Atenção:** Arquivo de chave de serviço do Google Cloud. Este arquivo **NÃO** deve ser versionado em repositórios públicos. Certifique-se de que ele está listado no seu arquivo `.gitignore`.
  * `requirements.txt`: Lista as dependências Python usadas no ambiente de desenvolvimento (ex: `google-cloud-bigquery`, `pandas`, `jupyter`).