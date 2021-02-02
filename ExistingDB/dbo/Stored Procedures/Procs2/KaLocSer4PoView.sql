-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <12/06/2010>
-- Description:	<Shortages for items on the given PO >
-- =============================================
CREATE PROCEDURE [dbo].[KaLocSer4PoView]
	-- Add the parameters for the stored procedure here
	@pcPonum char(15)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT KALOCSER.IS_OVERISSUED,KALOCSER.SERIALNO,KALOCSER.SERIALUNIQ, 
		Kalocser.UNIQKALOCATE,KALOCSER.UNIQKALOCSER,KALOCSER.Wono
		FROm KALOCSER,KALOCATE
		WHERE KALOCSER.UNIQKALOCATE =KALOCATE.UNIQKALOCATE 
		AND EXISTS (SELECT 1 FROm KAMAIN,Poitems WHERE Kamain.KaSeqNum=Kalocate.KaSeqnum AND KAMAIN.UNIQ_KEY =POITEMS.UNIQ_KEY and POITEMS.PONUM=@pcPonum)  
		
		
	
	
	
END