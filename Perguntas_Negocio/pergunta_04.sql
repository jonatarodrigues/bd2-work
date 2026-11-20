DROP INDEX IF EXISTS ix_manutencoes_data_entrada ON manutencoes;
GO
CREATE NONCLUSTERED INDEX ix_manutencoes_data_entrada
    ON manutencoes (data_entrada)
    INCLUDE (cod_equipamento, custo);
GO

EXEC sp_helpindex manutencoes;
GO

DROP PROCEDURE IF EXISTS pr_candidatos_descarte;
GO
CREATE PROCEDURE pr_candidatos_descarte (@inicio date, @fim date) AS
BEGIN
    WITH custo_manutencao AS (
        SELECT  cod_equipamento,
                COUNT(*)   AS qtd_manutencoes,
                SUM(custo) AS custo_total
        FROM    manutencoes
        WHERE   data_entrada BETWEEN @inicio AND @fim
        GROUP BY cod_equipamento
    ),
    receita_locacao AS (
        SELECT  i.cod_equipamento,
                SUM(i.valor_acordado *
                    DATEDIFF(DAY,
                             CASE WHEN c.data_inicio > @inicio THEN c.data_inicio ELSE @inicio END,
                             CASE WHEN c.data_devolucao IS NULL OR c.data_devolucao > @fim THEN @fim ELSE c.data_devolucao END
                    ) / 30.0) AS receita_total
        FROM    contratos AS c
        INNER JOIN itens_contrato AS i ON i.cod_contrato = c.cod_contrato
        WHERE   c.data_inicio <= @fim
          AND   (c.data_devolucao IS NULL OR c.data_devolucao >= @inicio)
        GROUP BY i.cod_equipamento
    )
    SELECT  e.cod_equipamento,
            e.nome,
            e.modelo,
            e.numero_serie,
            m.qtd_manutencoes,
            m.custo_total                                                             AS custo_manutencao,
            ROUND(CASE WHEN r.receita_total IS NULL THEN 0 ELSE r.receita_total END, 2) AS receita_locacao,
            ROUND(m.custo_total - CASE WHEN r.receita_total IS NULL THEN 0 ELSE r.receita_total END, 2) AS prejuizo
    FROM    custo_manutencao AS m
    INNER JOIN equipamentos  AS e ON e.cod_equipamento = m.cod_equipamento
    LEFT JOIN receita_locacao AS r ON r.cod_equipamento = m.cod_equipamento
    WHERE   m.custo_total > CASE WHEN r.receita_total IS NULL THEN 0 ELSE r.receita_total END
    ORDER BY prejuizo DESC;
END
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

EXEC pr_candidatos_descarte '2026-01-01', '2026-11-20';
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
