-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <04/11/2011>
-- Description:	<Find current allocation information for a work order>
-- Takes 2 parameters;
-- @lcWono - work order number
-- @lCompleteValue 1 - if entire work order value is passed; 0 - if LIKE needs to be used
-- =============================================
CREATE PROCEDURE [dbo].[FindAllocByWOView] 
	-- Add the parameters for the stored procedure here
	@lcWono char(10)='', 
	@lCompleteValue bit=1 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    IF @lCompleteValue=1
	BEGIN	
		SELECT R.WoNo,C.CustName
         FROM Invt_Res R INNER JOIN WoEntry W ON R.Wono=W.Wono
            INNER JOIN CUSTOMER C ON W.CUSTNO=C.custno
            WHERE r.WONO=dbo.padl(@lcWono,10,'0')
            GROUP BY R.Wono,C.CustName
            having SUM(QtyAlloc)>0
        IF @@ROWCOUNT = 0
			-- will search partial match
			SET @lCompleteValue=0
			    
    END --  IF @lCompleteValue=1      
    -- check for @lCompleteValue=1 again
     IF @lCompleteValue=0
			-- 01/10/12 VL added LTRIM(RTRIM()) outside of @lcWono
            SELECT R.WoNo,C.CustName
				FROM Invt_Res R INNER JOIN WoEntry W ON R.Wono=W.Wono
            INNER JOIN CUSTOMER C ON W.CUSTNO=C.custno
            WHERE r.WONO LIKE '%'+LTRIM(RTRIM(@lcWono))+'%'
            GROUP BY R.Wono,C.CustName
            having SUM(QtyAlloc)>0
            
            
END