# Projeto_Fase3_FIAP_2025
Este projeto, desenvolvido como parte da Fase 3 do curso da FIAP, foca em ampliar a consistência do negócio da empresa "Melhores Compras" e analisar aspetos de sigilo e propriedade dos dados, com ênfase na Lei Geral de Proteção de Dados (LGPD).

## 👥 Integrantes do Grupo 7
    Hiago Cezar Ribeiro Fidalgo
    Isack Rafael Lagares Santos
    Nicole Lourival
    Tiphany Nemet Martins
    Vinícius Mugnes Ferreira Vitorino

## 🛠️ Tecnologias Utilizadas
    Oracle Database
    PL/SQL
    SQL
    Oracle SQL Developer (ou ferramenta similar para execução dos scripts)

## 📂 Conteúdo do Repositório / Entregáveis
### PLSQL_de_carga_de_dados:
```SQL
-- Comando para habilitar a saída no console (opcional, dependendo da ferramenta)
-- SET SERVEROUTPUT ON;

DECLARE
  -- Definição do Cursor para buscar os dados do SAC e informações relacionadas
  CURSOR c_ocorrencias_sac IS
    SELECT
      s.nr_sac,                     -- Número da ocorrência do SAC (de mc_sgv_sac)
      s.dt_abertura_sac,            -- Data de abertura do SAC (de mc_sgv_sac)
      s.hr_abertura_sac,            -- Hora de abertura do SAC (de mc_sgv_sac)
      s.tp_sac,                     -- Tipo do SAC (de mc_sgv_sac)
      p.cd_produto,                 -- Código do produto (de mc_produto)
      p.ds_produto,                 -- Nome do produto (de mc_produto)
      p.vl_unitario,                -- Valor unitário do produto (de mc_produto)
      p.vl_perc_lucro,              -- Percentual do lucro unitário do produto (de mc_produto)
      cli.nr_cliente,               -- Número do Cliente (de mc_cliente)
      cli.nm_cliente,               -- Nome do Cliente (de mc_cliente)
      est.sg_estado AS sg_estado_cliente, -- Sigla do Estado do Cliente (de mc_estado)
      est.nm_estado AS nm_estado_cliente  -- Nome do Estado do Cliente (de mc_estado)
    FROM
      mc_sgv_sac s                  -- Tabela principal do SAC
      JOIN mc_produto p ON s.cd_produto = p.cd_produto -- Junção para dados do produto
      JOIN mc_cliente cli ON s.nr_cliente = cli.nr_cliente -- Junção para dados do cliente
      -- Junções para obter o estado do cliente através do endereço
      JOIN mc_end_cli endcli ON cli.nr_cliente = endcli.nr_cliente AND endcli.st_end = 'A' -- Endereço ativo do cliente
      JOIN mc_logradouro logr ON endcli.cd_logradouro_cli = logr.cd_logradouro -- Tabela de logradouro
      JOIN mc_bairro b ON logr.cd_bairro = b.cd_bairro
      JOIN mc_cidade cid ON b.cd_cidade = cid.cd_cidade
      JOIN mc_estado est ON cid.sg_estado = est.sg_estado;

  -- Variáveis para armazenar valores calculados/transformados
  v_ds_tipo_classificacao_sac  VARCHAR2(50);
  v_vl_unitario_lucro_produto  NUMBER(10,2); -- Ajustado para corresponder à tabela de destino
  v_vl_icms_produto            NUMBER(8,2) := NULL; -- Inicializada como NULL, tipo ajustado

BEGIN
  -- Loop FOR implícito para iterar sobre cada registro do cursor
  FOR reg IN c_ocorrencias_sac LOOP

    -- Transformar o tipo de SAC (usando CASE)
    v_ds_tipo_classificacao_sac :=
      CASE reg.tp_sac
        WHEN 'S' THEN 'SUGESTÃO'
        WHEN 'D' THEN 'DÚVIDA'
        WHEN 'E' THEN 'ELOGIO'
        ELSE 'CLASSIFICAÇÃO INVÁLIDA'
      END;

    -- Calcular o valor do lucro unitário do produto
    IF reg.vl_perc_lucro IS NOT NULL AND reg.vl_unitario IS NOT NULL THEN
      v_vl_unitario_lucro_produto := (reg.vl_perc_lucro / 100) * reg.vl_unitario;
    ELSE
      v_vl_unitario_lucro_produto := NULL;
    END IF;

    -- VL_ICMS_PRODUTO (já definido como NULL na declaração)

    -- Inserir os dados processados na tabela MC_SGV_OCORRENCIA_SAC
    INSERT INTO mc_sgv_ocorrencia_sac (
      nr_ocorrencia_sac,          -- Mapeando nr_sac da origem para nr_ocorrencia_sac
      dt_abertura_sac,
      hr_abertura_sac,
      ds_tipo_classificacao_sac,
      cd_produto,
      ds_produto,
      vl_unitario_produto,
      vl_perc_lucro,              -- Coluna adicionada conforme DDL de mc_sgv_ocorrencia_sac
      vl_unitario_lucro_produto,
      sg_estado,                  -- Mapeando sg_estado_cliente para sg_estado
      nm_estado,                  -- Mapeando nm_estado_cliente para nm_estado
      nr_cliente,
      nm_cliente,
      vl_icms_produto
    ) VALUES (
      reg.nr_sac,                 -- Valor de mc_sgv_sac.nr_sac
      reg.dt_abertura_sac,
      reg.hr_abertura_sac,
      v_ds_tipo_classificacao_sac,
      reg.cd_produto,
      reg.ds_produto,
      reg.vl_unitario,
      reg.vl_perc_lucro,          -- Valor de mc_produto.vl_perc_lucro
      v_vl_unitario_lucro_produto,
      reg.sg_estado_cliente,
      reg.nm_estado_cliente,
      reg.nr_cliente,
      reg.nm_cliente,
      v_vl_icms_produto
    );

    -- Para depuração, pode-se descomentar a linha abaixo:
    -- DBMS_OUTPUT.PUT_LINE('Inserido SAC: ' || reg.nr_sac || ' para Ocorrência: ' || reg.nr_sac);

  END LOOP; -- Fim do loop do cursor

  -- Confirmar a transação
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Processamento de ocorrências do SAC concluído e transações commitadas.');

EXCEPTION
  -- Capturar qualquer erro não tratado
  WHEN OTHERS THEN
    -- Desfazer quaisquer alterações (ROLLBACK)
    ROLLBACK;
    -- Exibir mensagem de erro
    DBMS_OUTPUT.PUT_LINE('Erro durante o processamento: ' || SQLCODE || ' - ' || SQLERRM);
    -- Em produção, seria ideal logar o erro em uma tabela de log.
END; -- Fim do bloco PL/SQL
/
-- A barra acima DEVE estar em uma nova linha e sozinha para indicar ao cliente SQL
-- (como SQL*Plus ou SQL Developer) para executar o bloco PL/SQL.
-- Não adicione comentários ou outros caracteres nesta linha.

/*
-- Consulta para verificar os dados inseridos (executar separadamente após o bloco)
SELECT *
FROM mc_sgv_ocorrencia_sac
ORDER BY nr_ocorrencia_sac;
*/
```

#### Bloco anónimo PL/SQL responsável por:
- Ler dados das tabelas mc_sgv_sac, mc_produto, mc_cliente e tabelas de endereço.
- Transformar o tipo de SAC (coluna tp_sac) para uma descrição textual (Sugestão, Dúvida, Elogio).
- Calcular o valor do lucro unitário do produto.
- Inserir os dados processados na tabela mc_sgv_ocorrencia_sac.
- Inclui tratamento de exceções e controlo de transação (COMMIT/ROLLBACK).

### DQL_categoria_produto_chamados.sql:
```SQL
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
```
Consulta SQL (DQL) que exibe todas as categorias de produtos e a contagem total de chamados SAC associados a cada categoria.

Os resultados são ordenados pelo maior número de chamados e, em seguida, pelo código da categoria.

#### Consulta_categorias_e_quantidade_de_chamados_associados:
- Consulta SQL (DQL) para verificar os dados inseridos na tabela mc_sgv_ocorrencia_sac após a execução do bloco PL/SQL.
- Seleciona todas as colunas da tabela mc_sgv_ocorrencia_sac e ordena pelo nr_ocorrencia_sac.

### Documentos de Evidência:

#### 1_2_evidências_PL_SQL.docx:
- Contém capturas de ecrã demonstrando a conexão com o SGBD Oracle, as tabelas criadas e a execução bem-sucedida do bloco PL/SQL de carga de dados, exibindo os dados inseridos na tabela mc_sgv_ocorrencia_sac.

#### 1_3_evidências_Consulta_categorias_e_quantidade_de_chamados_associados.docx:
- Apresenta evidências da execução da consulta de verificação dos dados na tabela mc_sgv_ocorrencia_sac.

#### 1_4_evidências_teste_DQL_categoria_produto_chamados.docx:
- Demonstra a execução bem-sucedida da consulta DQL que lista as categorias e a quantidade de chamados associados.

### Análise LGPD e Proteção de Dados (1_5_Template_Fase3_Grupo7.docx e 1_5_Template_Fase3_Grupo7.pdf):

#### Documento que aborda:
- O papel da TI em relação à LGPD, tanto nas tarefas internas da TI quanto na plataforma de eCommerce da "Melhores Compras".
- Recomendações práticas de proteção aos dados (ex: criptografia, controlo de acesso).
- Estratégias de anonimização de dados de clientes, com justificativas.
- Inclui referências e um glossário de termos relevantes.

#### Verificação das Evidências:
- Os ficheiros .docx contêm capturas de ecrã que demonstram a execução e os resultados obtidos.
