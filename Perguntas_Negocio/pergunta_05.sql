DROP INDEX IF EXISTS ix_equipamentos_fabricante ON equipamentos;
GO
CREATE NONCLUSTERED INDEX ix_equipamentos_fabricante
    ON equipamentos (fabricante)
    INCLUDE (status);
GO

EXEC sp_helpindex equipamentos;
GO

DROP FUNCTION IF EXISTS fn_percentual;
GO
CREATE FUNCTION fn_percentual (@parte int, @total int) RETURNS numeric(5,2) AS
BEGIN
    DECLARE @percentual numeric(5,2)
    SELECT @percentual = 100.0 * @parte / @total
    RETURN @percentual
END
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

SELECT  fabricante,
        COUNT(*)                                                   AS total_equipamentos,
        SUM(CASE WHEN status = 'locado'     THEN 1 ELSE 0 END)     AS locados,
        SUM(CASE WHEN status = 'manutenção' THEN 1 ELSE 0 END)     AS em_manutencao,
        SUM(CASE WHEN status = 'disponível' THEN 1 ELSE 0 END)     AS disponiveis,
        dbo.fn_percentual(SUM(CASE WHEN status = 'locado' THEN 1 ELSE 0 END), COUNT(*)) AS taxa_ocupacao,
        (SELECT dbo.fn_percentual(SUM(CASE WHEN e2.status = 'locado' THEN 1 ELSE 0 END), COUNT(*))
         FROM equipamentos AS e2)                                  AS taxa_ocupacao_frota,
        dbo.fn_percentual(COUNT(*), SUM(COUNT(*)) OVER ())         AS participacao_na_frota
FROM    equipamentos
GROUP BY fabricante
ORDER BY taxa_ocupacao DESC, total_equipamentos DESC;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
