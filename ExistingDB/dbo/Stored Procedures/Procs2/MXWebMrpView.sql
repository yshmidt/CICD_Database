-- =============================================
-- Author:Shivshankar P		
-- Create date: 27/09/17
-- Description:	Get information for MrpView
-- EXEC MXWebMrpView 'NP0VAON4DK', 1, 150, ''
-- Shivshankar P 03/03/2020: Apply sorting on Projected Inventory grid
-- =============================================
CREATE PROCEDURE [dbo].[MXWebMrpView] 
	-- Add the parameters for the stored procedure here
	@gcUniq_Key as char(10) = ' ',
	@StartRecord int=1,
	@EndRecord int=10,
	@sortExpression VARCHAR(MAX) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @sqlQuery NVARCHAR(MAX),@rowCount NVARCHAR(MAX)

    -- Insert statements for procedure here
	SELECT Mrpsch2.*, dbo.fRemoveLeadingZeros(Pjctmain.prjnumber) AS prjnumber,totalCount = COUNT(Pjctmain.prjnumber) OVER()
	INTO #MrpView
	FROM mrpsch2 
    LEFT OUTER JOIN pjctmain ON  Mrpsch2.prjunique = Pjctmain.prjunique
    WHERE  Mrpsch2.uniq_key = @gcUniq_Key 
    ORDER BY prjnumber
     --OFFSET (@StartRecord -1) ROWS  
     --FETCH NEXT @EndRecord ROWS ONLY; 
	 
	BEGIN 
	-- Shivshankar P 03/03/2020: Apply sorting on Projected Inventory grid
	SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #MrpView','',@sortExpression,'','UNIQ_KEY',@startRecord,@endRecord))       
		EXEC sp_executesql @rowCount  		

	SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #MrpView','',@sortExpression,N'REQDATE','',@startRecord,@endRecord))  
		EXEC sp_executesql @sqlQuery
	END  
END