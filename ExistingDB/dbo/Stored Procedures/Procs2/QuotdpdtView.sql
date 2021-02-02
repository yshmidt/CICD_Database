CREATE PROC [dbo].[QuotdpdtView] @gUniq_key AS char(10) = ''
AS
SELECT *
	FROM Quotdpdt
	WHERE Uniq_key = @gUniq_key
