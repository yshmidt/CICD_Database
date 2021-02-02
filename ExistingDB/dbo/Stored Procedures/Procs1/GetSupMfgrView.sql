-- =============================================
-- Author:Satish B
-- Create date: 07/05/2017
-- Description:	Get part saved mfgr in Line Card module
-- exec GetSupMfgrView '_1D50WFSWT','',1,100,0
-- =============================================
CREATE PROCEDURE [dbo].[GetSupMfgrView] 
	-- Add the parameters for the stored procedure here
	@uniqSupno char(10) ='',
	@partMfgr char(8)=null,
	@startRecord int =1,
    @endRecord int =10, 
	@outTotalNumberOfRecord int OUTPUT
AS
BEGIN
	 SET NOCOUNT ON	 
	 SELECT COUNT(1) AS RowCnt -- Get total counts 
	 INTO #tempSupMfgrView
	 FROM SUPMFGR supmfgr
		  INNER JOIN SUPPORT support ON support.TEXT2=supmfgr.PARTMFGR
	 WHERE Partmfgr = LEFT(Support.Text2,8)
		AND support.Fieldname ='PARTMFGR'
		AND supmfgr.UniqSupno = @uniqSupno
		AND ((@partMfgr IS NULL OR @partMfgr='') OR (PartMfgr =@partMfgr))
		
	 SELECT --0 AS IsChecked
		  supmfgr.UNQSUPMFGR
		 ,supmfgr.UNIQSUPNO
		 ,supmfgr.PartMfgr
		 ,support.Text AS PartMfgrDescript
	 FROM SUPMFGR supmfgr
		  INNER JOIN SUPPORT support ON support.TEXT2=supmfgr.PARTMFGR
	 WHERE Partmfgr = LEFT(Support.Text2,8)
		AND support.Fieldname ='PARTMFGR'
		AND supmfgr.UniqSupno = @uniqSupno
		AND ((@partMfgr IS NULL OR @partMfgr='') OR (PartMfgr =@partMfgr))
     ORDER BY supmfgr.PartMfgr 
	 OFFSET(@startRecord-1) ROWS
	 FETCH NEXT @EndRecord ROWS ONLY;

	 SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempSupMfgrView) -- Set total count to Out parameter 
END