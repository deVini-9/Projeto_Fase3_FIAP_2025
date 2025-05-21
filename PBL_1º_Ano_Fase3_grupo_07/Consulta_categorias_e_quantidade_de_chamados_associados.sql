-- Seleciona todos os registos da tabela de ocorrências do SAC,
-- ordenados pelo número da ocorrência, para análise e verificação.
SELECT
    NR_OCORRENCIA_SAC,
    DT_ABERTURA_SAC,
    HR_ABERTURA_SAC,
    DS_TIPO_CLASSIFICACAO_SAC,
    CD_PRODUTO,
    DS_PRODUTO,
    VL_UNITARIO_PRODUTO,
    VL_PERC_LUCRO,
    VL_UNITARIO_LUCRO_PRODUTO,
    SG_ESTADO,
    NM_ESTADO,
    NR_CLIENTE,
    NM_CLIENTE,
    VL_ICMS_PRODUTO
FROM
    MC_SGV_OCORRENCIA_SAC
ORDER BY
    NR_OCORRENCIA_SAC;
