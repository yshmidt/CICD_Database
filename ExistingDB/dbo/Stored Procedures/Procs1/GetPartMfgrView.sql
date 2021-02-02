-- =============================================
-- Author:Satish B		
-- Create date: 07/04/2017
-- Description:	This Stored Procedure used to get all part mfgr
-- exec GetPartMfgrView '','_1D50WFSWT',1,1000,0
-- =============================================
CREATE PROCEDURE [dbo].[GetPartMfgrView]
 -- Add the parameters for the stored procedure here
	@partMfgr char(8)='',
	@uniqSupno char(10) ='',
	@startRecord int =1,
    @endRecord int =10, 
	@outTotalNumberOfRecord int OUTPUT
AS
BEGIN
	 SET NOCOUNT ON	 
	 SELECT COUNT(support.Text2) AS RowCnt -- Get total counts 
	 INTO #tempPartMfgrView
	 FROM SUPPORT support
		  LEFT JOIN SUPMFGR supMfgr ON supMfgr.PARTMFGR=support.TEXT2 AND (supMfgr.UniqSupno = @uniqSupno)
	 WHERE support.Fieldname = 'PARTMFGR' 
	    AND ((@partMfgr IS NULL OR @partMfgr='') OR (support.TEXT2 =@partMfgr))
	
	 SELECT-- 0 AS IsChecked
		 support.Text2 AS PartMfgr
		,support.Text as PartMfgrDescript
		,supMfgr.UNIQSUPNO 
		,supMfgr.UNQSUPMFGR
		,CASE WHEN supMfgr.PARTMFGR IS NULL THEN 0 ELSE 1 END AS IsSort
	 FROM SUPPORT support
		 LEFT JOIN SUPMFGR supMfgr ON supMfgr.PARTMFGR=support.TEXT2 AND (supMfgr.UniqSupno = @uniqSupno)
	 WHERE support.Fieldname = 'PARTMFGR' 
		 AND ((@partMfgr IS NULL OR @partMfgr='') OR (support.TEXT2 =@partMfgr))
	 ORDER BY IsSort DESC
	 OFFSET(@startRecord-1) ROWS
	 FETCH NEXT @EndRecord ROWS ONLY;

	 SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempPartMfgrView) -- Set total count to Out parameter 
END