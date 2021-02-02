-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <12/06/2010>
-- Description:	<Shortages for items on the given PO >
-- =============================================
CREATE PROCEDURE [dbo].[KaMain4PoView]
	-- Add the parameters for the stored procedure here
	@pcPonum char(15)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT DISTINCT KAMAIN.UNIQ_KEY,KAMAIN.ACT_QTY ,KAMAIN.IGNOREKIT,KAMAIN.KASEQNUM,
		KAMAIN.LINESHORT,KAMAIN.SHORTQTY,KAMAIN.QTY,Kamain.shortqty-Kamain.shortqty AS qtyissue,
		Kamain.shortqty AS shortbalance,KAMAIN.INITIALS,KAMAIN.DEPT_ID,KAMAIN.WONO
	FROM KAMAIN,WOENTRY,POITEMS
	WHERE KAMAIN.WONO=WOENTRY.WONO
	and WOENTRY.OPENCLOS <>'Closed'
	AND Woentry.OPENCLOS <>'Cancel'
	ANd POITEMS.UNIQ_KEY =KAMAIN.UNIQ_KEY 
	and KAMAIN.IGNOREKIT =0
	and KAMAIN.SHORTQTY >0.00 
	and POITEMS.PONUM=@pcPonum
		        
END