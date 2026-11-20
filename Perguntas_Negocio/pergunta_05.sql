DROP INDEX IF EXISTS ix_financeiro_em_aberto ON financeiro;
GO
CREATE NONCLUSTERED INDEX ix_financeiro_em_aberto
    ON financeiro (data_pagamento, data_vencimento)
    INCLUDE (cod_contrato, valor);
GO

DROP INDEX IF EXISTS ix_contratos_cliente ON contratos;
GO
CREATE NONCLUSTERED INDEX ix_contratos_cliente
    ON contratos (cod_cliente)
    INCLUDE (data_devolucao);
GO

EXEC sp_helpindex financeiro;
EXEC sp_helpindex contratos;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

DECLARE @hoje date;
SET @hoje = '2026-11-20';

SELECT  cl.cod_cliente,
        cl.nome,
        cl.telefone,
        COUNT(*)                                     AS parcelas_vencidas,
        SUM(f.valor)                                 AS valor_devido,
        DATEDIFF(DAY, MIN(f.data_vencimento), @hoje) AS dias_parcela_mais_antiga,
        (
            SELECT COUNT(*)
            FROM   contratos      AS c2
            INNER JOIN itens_contrato AS i2 ON i2.cod_contrato = c2.cod_contrato
            WHERE  c2.cod_cliente = cl.cod_cliente
              AND  c2.data_devolucao IS NULL
        )                                            AS equipamentos_em_posse
FROM    financeiro AS f
INNER JOIN contratos  AS c  ON c.cod_contrato = f.cod_contrato
INNER JOIN clientes   AS cl ON cl.cod_cliente = c.cod_cliente
WHERE   f.data_pagamento IS NULL
  AND   f.data_vencimento < @hoje
GROUP BY cl.cod_cliente, cl.nome, cl.telefone
ORDER BY valor_devido DESC;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
