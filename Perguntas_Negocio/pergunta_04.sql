DROP INDEX IF EXISTS ix_contratos_data_inicio ON contratos;
GO
CREATE NONCLUSTERED INDEX ix_contratos_data_inicio
    ON contratos (data_inicio)
    INCLUDE (data_fim_prevista);
GO

EXEC sp_helpindex contratos;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

DECLARE @inicio_ano date, @fim_ano date;
SET @inicio_ano = '2026-01-01';
SET @fim_ano    = '2026-12-31';

WITH receita_por_equipamento AS (
    SELECT  i.cod_equipamento,
            SUM(i.valor_acordado * DATEDIFF(MONTH, c.data_inicio, c.data_fim_prevista)) AS receita,
            COUNT(*)                                                                  AS qtd_contratos
    FROM    contratos       AS c
    INNER JOIN itens_contrato AS i ON i.cod_contrato = c.cod_contrato
    WHERE   c.data_inicio BETWEEN @inicio_ano AND @fim_ano
    GROUP BY i.cod_equipamento
)
SELECT  e.nome                                                       AS tipo_equipamento,
        e.modelo,
        e.numero_serie,
        r.qtd_contratos,
        r.receita,
        RANK() OVER (PARTITION BY e.nome ORDER BY r.receita DESC)    AS posicao_no_tipo,
        ROUND(100.0 * r.receita / SUM(r.receita) OVER (), 2)         AS perc_receita_total
FROM    receita_por_equipamento AS r
INNER JOIN equipamentos         AS e ON e.cod_equipamento = r.cod_equipamento
ORDER BY r.receita DESC;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
