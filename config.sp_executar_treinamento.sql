CREATE OR REPLACE PROCEDURE config.sp_executar_retreinamento()
OPTIONS(description="Executa o retreinamento dos modelos e a subsequente geração de labels. Use sob demanda.")
BEGIN
    -- Passo 1: Recria os modelos com os dados mais recentes.
    CALL config.sp_treinar_modelos();
    -- Passo 2: Recalcula e salva os labels para os novos centroides.
    CALL config.sp_gerar_labels();
END;