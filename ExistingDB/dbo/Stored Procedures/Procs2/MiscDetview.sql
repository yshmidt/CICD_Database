
CREATE PROC [dbo].[MiscDetview] (@lcMisckey char(10) =' ')
AS
SELECT *
	FROM Miscdet
	WHERE Misckey = @lcMisckey







