CREATE PROC [dbo].[ScrapRelView] @gUniq_key AS char(10) = ''
AS

BEGIN
SELECT *
	FROM 
	ScrapRel
	WHERE Uniq_key = @gUniq_key
	ORDER BY Wono

END