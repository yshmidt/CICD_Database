CREATE PROCEDURE [dbo].[chkPoitemsReceivedView] 
@Uniqlnno varchar(max) = ' '
AS

 BEGIN
 DECLARE @PoItems table (Uniqlnno char(10))
 INSERT INTO @PoItems SELECT * from dbo.fn_simpleVarcharlistToTable(@Uniqlnno,',') 

SELECT Receiverno, UniqRecdtl
	FROM Porecdtl
	WHERE Uniqlnno IN 
		(SELECT uniqlnno 
			FROM @Poitems)

END