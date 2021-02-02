CREATE PROCEDURE [dbo].[FindArCredit4NSFView]
	-- Add the parameters for the stored procedure here
	@gcUniqLnNo as char(10) = ' '
	AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 09/13/12 YS changed to return 2 results 
	---1 SqlResult
	SELECT ARCREDIT.*
	from ARCREDIT
	where UNIQLNNO = @gcUniqLnNo
	-- 2 SqlResult1
	select ARCREDIT.Custno,ARCREDIT.Invno 
	from ARCREDIT INNER JOIN Acctsrec ON Arcredit.uniquear =Acctsrec.UNIQUEAR and ACCTSREC.lPrepay =1  
	INNER JOIN Aroffset on acctsrec.UNIQUEAR =AROFFSET.uniquear  
	where Arcredit.UNIQLNNO = @gcUniqLnNo
	and aroffset.AMOUNT>0 
END