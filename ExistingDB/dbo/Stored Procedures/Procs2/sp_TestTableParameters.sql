-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 07/20/2012 
-- Description: Test passing table as parameter to SP from VFP	
-- =============================================
CREATE PROCEDURE dbo.sp_TestTableParameters
	-- Add the parameters for the stored procedure here
	@List as tMrpActUniq READONLY
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT * from MRPACT where UNIQMRPACT in (SELECT UNIQMRPACT FROM @List)
END