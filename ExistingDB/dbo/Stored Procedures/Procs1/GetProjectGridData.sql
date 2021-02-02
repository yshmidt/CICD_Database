-- =============================================
-- Author: Satish B
-- Create date: <08/01/2017>
-- Description:	<Get Receiving Status main grid data>
-- Modified : 10/13/2017 Satish B : Comment unused parameters
-- Exec GetProjectGridData '_3A60T8BLC',0
-- =============================================
CREATE PROCEDURE [dbo].[GetProjectGridData] 
	-- Add the parameters for the stored procedure here
	@uniqKey nvarchar(15) = null ,
	--10/13/2017 Satish B : Comment unused parameters
	--@startRecord int =1,
 --   @endRecord int =10,
	@outTotalNumberOfRecord int OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	SELECT COUNT(1) AS RowCnt -- Get total counts 
	INTO #tempPjDetail 
	FROM PJCTMAIN pjctmain
		 INNER JOIN INVT_RES invtRes ON invtRes.FK_PRJUNIQUE = pjctmain.PRJUNIQUE	
	WHERE invtRes.UNIQ_KEY=@uniqKey 
	GROUP BY pjctmain.PRJNUMBER,invtRes.FK_PRJUNIQUE
	HAVING SUM(invtRes.QTYALLOC)>0

	SELECT CAST(dbo.fremoveLeadingZeros(pjctmain.PRJNUMBER) AS VARCHAR(MAX)) AS PrjNumber
		  ,SUM(invtRes.QTYALLOC) AS Quantity
		  ,invtRes.FK_PRJUNIQUE
	FROM PJCTMAIN pjctmain
		 INNER JOIN INVT_RES invtRes ON invtRes.FK_PRJUNIQUE = pjctmain.PRJUNIQUE	
	WHERE invtRes.UNIQ_KEY=@uniqKey 
	GROUP BY pjctmain.PRJNUMBER,invtRes.FK_PRJUNIQUE
	HAVING SUM(invtRes.QTYALLOC)>0

	SET @outTotalNumberOfRecord = (SELECT COUNT(1) FROM #tempPjDetail) -- Set total count to Out parameter 
END