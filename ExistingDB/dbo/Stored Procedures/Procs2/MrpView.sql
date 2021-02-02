
-- =============================================
-- Author:		
-- Create date: 
-- Description:	Get information for MrpView
-- 08/23/17 Shivshankar added @StartRecord int=0,	@EndRecord int=10000 
--08/25/17 YS modified @EndRecord to default to null, then check if null update with the xount ( for desktop and when need to retun all the records)
-- =============================================
CREATE PROCEDURE [dbo].[MrpView] 
	-- Add the parameters for the stored procedure here
	@gcUniq_Key as char(10) = ' ',
	@StartRecord int=0,
	--08/25/17 YS modified @EndRecord to default to null, then check if null update with the xount ( for desktop and when need to retun all the records)
	--@EndRecord int=10000    --Used for Desktop with default rows for web each time passing 150 (@EndRecord=150) server paging
	@EndRecord int=NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--08/25/17 YS modified @EndRecord to default to null, then check if null update with the xount ( for desktop and when need to retun all the records)
	if (@EndRecord is null)
		select @EndRecord=count(*) from mrpsch2

    -- Insert statements for procedure here
	SELECT Mrpsch2.*, dbo.fRemoveLeadingZeros(Pjctmain.prjnumber) AS prjnumber,totalCount = COUNT(Pjctmain.prjnumber) OVER()
	FROM 
    mrpsch2 
    LEFT OUTER JOIN pjctmain 
	ON  Mrpsch2.prjunique = Pjctmain.prjunique
     WHERE  Mrpsch2.uniq_key = @gcUniq_Key 
     ORDER BY prjnumber
     OFFSET (@StartRecord) ROWS  
     FETCH NEXT @EndRecord ROWS ONLY;   


END