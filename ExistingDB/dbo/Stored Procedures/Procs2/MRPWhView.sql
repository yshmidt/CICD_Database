-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <06/04/2012 >
-- Description:	<MRPWHVIEW>
-- =============================================
CREATE PROCEDURE dbo.MRPWhView
	-- Add the parameters for the stored procedure here
	@lcUniq_key char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Warehouse, Location, PartMfgr, Mfgr_Pt_No, Qty_Oh, 
		CASE WHEN Netable=1 THEN 'YES' ELSE 'NO ' END AS Netable 
	FROM MrpWh INNER JOIN Warehous ON MrpWh.Uniqwh =Warehous.UNIQWH  
	WHERE Uniq_Key = @lcUniq_key  
	
END