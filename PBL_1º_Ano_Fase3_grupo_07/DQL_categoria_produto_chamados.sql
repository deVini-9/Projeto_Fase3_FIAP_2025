-- Consulta para exibir todas as categorias de produtos
-- e a contagem total de chamados SAC associados a cada uma,
-- ordenando pelo maior número de chamados e, em seguida, pelo código da categoria.

SELECT
    CP.CD_CATEGORIA,
    CP.TP_CATEGORIA,
    CP.DS_CATEGORIA,
    CP.DT_INICIO,
    CP.DT_TERMINO,
    CP.ST_CATEGORIA,
    COUNT(SAC.NR_SAC) AS TOTAL_CHAMADOS -- Contagem de chamados SAC para cada categoria
FROM
    MC_CATEGORIA_PROD CP -- Alias para a tabela de categorias de produto
LEFT JOIN
    MC_PRODUTO P ON CP.CD_CATEGORIA = P.CD_CATEGORIA -- Junção com a tabela de produtos
LEFT JOIN
    MC_SGV_SAC SAC ON P.CD_PRODUTO = SAC.CD_PRODUTO -- Junção com a tabela de SAC
GROUP BY
    CP.CD_CATEGORIA,
    CP.TP_CATEGORIA,
    CP.DS_CATEGORIA,
    CP.DT_INICIO,
    CP.DT_TERMINO,
    CP.ST_CATEGORIA -- Agrupamento por todas as colunas não agregadas da categoria
ORDER BY
    TOTAL_CHAMADOS DESC, -- Ordena pelo total de chamados em ordem decrescente
    CP.CD_CATEGORIA DESC;  -- Em caso de empate no total de chamados, ordena pelo código da categoria em ordem decrescente
