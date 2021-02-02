CREATE PROC [dbo].[AssyDocView] @gUniq_key AS char(10) = ''
AS
SELECT *
	FROM AssyDoc
	WHERE Uniq_key = @gUniq_key
