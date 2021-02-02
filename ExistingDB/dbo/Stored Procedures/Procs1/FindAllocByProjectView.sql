-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <04/11/2011>
-- Description:	<Find current allocation information for a Project>
-- Takes 2 parameters;
-- @lcPrjNumber - Project number
-- @lCompleteValue 1 - if entire project value passed to this procedure; 0 - if LIKE needs to be used
-- =============================================
CREATE PROCEDURE [dbo].[FindAllocByProjectView] 
	-- Add the parameters for the stored procedure here
	@lcPrjNumber char(10)='', 
	@lCompleteValue bit=1 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    IF @lCompleteValue=1
	BEGIN	
		SELECT P.PrjNumber,C.CustName,P.PRJDESCRP ,R.Fk_PrjUnique 
			FROM Invt_Res R INNER JOIN PjctMain P ON R.Fk_PrjUnique=P.PrjUnique
				INNER JOIN CUSTOMER C ON C.CUSTNO=P.CUSTNO 
            WHERE P.PRJNUMBER  =dbo.padl(@lcPrjNumber,10,'0') 
            GROUP BY P.PrjNumber,C.CUSTNAME,P.PRJDESCRP,R.Fk_PrjUnique 
			HAVING SUM(R.QtyAlloc)>0			
		IF @@ROWCOUNT = 0
			-- will search partial match
			SET @lCompleteValue=0
			    
    END --  IF @lCompleteValue=1      
    -- check for @lCompleteValue=1 again
     IF @lCompleteValue=0
		-- 01/10/12 VL added LTRIM(RTRIM()) outside of @@lcPrjNumber
		SELECT P.PrjNumber,C.CustName,P.PRJDESCRP ,R.Fk_PrjUnique 
			FROM Invt_Res R INNER JOIN PjctMain P ON R.Fk_PrjUnique=P.PrjUnique
				INNER JOIN CUSTOMER C ON C.CUSTNO=P.CUSTNO 
            WHERE P.PRJNUMBER   LIKE '%'+LTRIM(RTRIM(@lcPrjNumber))+'%' 
            GROUP BY P.PrjNumber,C.CUSTNAME,P.PRJDESCRP ,R.Fk_PrjUnique
			HAVING SUM(R.QtyAlloc)>0			
           			
END