CREATE PROC [dbo].[QuotdeptView] @gUniq_key AS char(10) = ''
AS
SELECT *
	FROM Quotdept
	WHERE Uniq_key = @gUniq_key