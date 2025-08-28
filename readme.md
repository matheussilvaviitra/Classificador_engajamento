# Banco de Dados : InteliBase

## Orientação do Banco de Dados - Data Warehouse

Justificativa: a utilização de dados estruturados para a criação dos datasets de treinamento, validção e testes se mostra mais efetivo visto que nãot rataremos de Big Data, a maioria dos dados a serem classificados são númericos, sendo assim a utilização de dados estruturados provenientes do banco de dados da Redu (MySQL). ALém disso, a integração do VertexAI com o BigQuery se mostrou eficiente e proveitosa, desse modo, optamos pela utilização do data warehouse com tabelas-fato bem definidas, onde na criação dos datasets unimo-as. alÉM DISSO, TEMOS COMO OBJETIVO EXIBIR OS DADOS CLASSIFICADOS EM UMA PLATAFORMA DE bi, SENOD A CLASSIFICAÇÃO UMA PARTE ESSENCIAL PORÉM PRECISAMOS TAMBÉM ENTENDER O CONTEXTO EM QUE ELA VAI SER EXPOSTA. ALEM DISSO TEMOS INTERESSE NA CLASSIFICAÇÃO EM LOTE VISTO QUE OS RECURSOS DO VERTEXai NÃO PODEM ESCALAR RÁPIDO.


Antes de tudo é importante entendermos que perguntas queremos responder, nesse sentido, em reunião coma  acessoria, apuramos as seguintes perguntas, como as principais que os tutores tem interesse em seres respondidas

[INSERIR PERGUNTAS]


isso levou a elaboração e modelagem das seguintes tabelas-fato:


[INSERIR TABELAS-FATO]



as tabelas-fato estarão acompanhadas das seguintes dimensões (tabelas) de análise:


[INSERIR TABELAS-DIMENSÃO]

