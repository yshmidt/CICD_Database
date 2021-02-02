-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/04/11
-- Description:	<Gather due_dts and Packing list data for given the Sales Order line item>
-- =============================================
CREATE PROCEDURE [dbo].[spManexWebSODueDatesShipments]
	-- Add the parameters for the stored procedure here
	@pcUniqueLn as char(10)=' '
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
			
	
    -- Insert statements for procedure here
    SELECT Due_dts.due_dts,due_dts.qty,due_dts.act_shp_qt,due_dts.uniqueln FROM due_dts WHERE due_dts.uniqueln = @pcuniqueln 
	SELECT pldetail.packlistno,plmain.shipdate,pldetail.shippedqty,plmain.shipvia,plmain.invoiceno,plmain.invdate,pldetail.uniqueln,plmain.waybill    
		FROM plmain INNER JOIN plDetail on plmain.packlistno = pldetail.packlistno WHERE pldetail.uniqueln =@pcUniqueLn  
	SELECT w.WONO,w.DUE_DATE,w.BALANCE,w.MRPONHOLD,w.KITCOMPLETE,w.OPENCLOS 
		FROM SODETAIL s INNER JOIN WOENTRY w ON s.UNIQUELN=w.UNIQUELN AND s.SONO=w.SONO
		WHERE w.OPENCLOS<>'Closed' AND w.OPENCLOS<>'Cancel'AND s.UNIQUELN=@pcUniqueLn
		
END