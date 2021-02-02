-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <04/11/2011>
-- Description:	<Find current allocation information for a Part Number>
-- Takes 2 parameters;
-- @lcPartNo - Part Number
-- @lCompleteValue 1 - if entire part number value passed to the procedure; 0 - if LIKE needs to be used
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- =============================================
CREATE PROCEDURE [dbo].[FindAllocByPartNoView] 
	-- Add the parameters for the stored procedure here
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
	@lcpartno char(35)='', 
	@lCompleteValue bit=1 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    IF @lCompleteValue=1
		BEGIN
		SELECT I.Part_no, I.Revision, I.Descript, R.Uniq_Key
            FROM Invt_Res R INNER JOIN Inventor I ON R.UNIQ_KEY =I.UNIQ_KEY 
            WHERE I.PART_NO=@lcPartNo
            GROUP BY I.Part_no, I.Revision, I.Descript,R.Uniq_Key 
            having SUM(QtyAlloc)>0	
			IF @@ROWCOUNT = 0
				-- will search partial match
			SET @lCompleteValue=0
	END	-- @lCompleteValue=1				
     -- check for @lCompleteValue=1 again
    IF @lCompleteValue=0
		-- 01/10/12 VL added LTRIM(RTRIM()) outside of @lcPartNo
		SELECT I.Part_no, I.Revision, I.Descript, R.Uniq_Key
            FROM Invt_Res R INNER JOIN Inventor I ON R.UNIQ_KEY =I.UNIQ_KEY 
            WHERE I.PART_NO LIKE '%'+LTRIM(RTRIM(@lcPartNo))+'%'
            GROUP BY I.Part_no, I.Revision, I.Descript,R.Uniq_Key 
            having SUM(QtyAlloc)>0	
        
            	
END