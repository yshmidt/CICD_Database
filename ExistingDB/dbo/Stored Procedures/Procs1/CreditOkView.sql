create procedure [dbo].[CreditOkView]
AS SELECT left(text,15) AS CreditOk  FROM support WHERE fieldname = 'CREDITOK' ORDER BY Number 
