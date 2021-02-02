create procedure [dbo].[TerritoryView]
AS SELECT left(text,15) as Territory  FROM support WHERE fieldname = 'TERRITORY' ORDER BY Number 
