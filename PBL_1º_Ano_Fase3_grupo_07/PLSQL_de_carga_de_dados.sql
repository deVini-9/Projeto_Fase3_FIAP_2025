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
