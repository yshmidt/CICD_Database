-- =============================================
-- Author:		Bill Blake
-- Create date: ????
-- Description:	Seaarch in poreconciliation by purchase order number
-- Modified: 12/16/14 YS added additional information for the part number, will use when searching by part number and a po number
-- 12/19/14 YS remove additional info and create a different procedure
--02/19/15 YS added code because paramit has the same invoice with the same receiver number for different invoices and different supplier
--07/17/16 VL added invno back, Penang requested to add this back	
-- =============================================
CREATE PROCEDURE [dbo].[PoReconFindByPoNum]
	-- Add the parameters for the stored procedure here
	@gcPoNum as char(15) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--12/16/14 YS added additional information for the part number, will use when searching by part number and a po number
	-- 12/19/14 YS remove additional info and create a different procedure
	-- 07/17/16 VL added Invno
	SELECT DISTINCT SupName, PoMain.PoNum, InvDate, Invno, InvAmount, PORECDTL.ReceiverNo, SInv_Uniq
	--ISNULL(I.Part_no,space(25)) as part_no,ISNULL(i.Revision,space(8)) as Revision 
	FROM Sinvoice
		  INNER JOIN  PoRecdtl 
		ON  PORECDTL.RECEIVERNO = Sinvoice.receiverno
		inner join POItems
		on  PORECDTL.UNIQLNNO = POITEMS.UNIQLNNO 
		--left outer join INVENTOR I on Poitems.UNIQ_KEY=I.UNIQ_KEY
		inner join PoMain
		on POMAIN.PONUM = POITEMS.PONUM   
		inner join SUPINFO 
		on SUPINFO.UNIQSUPNO = POMAIN.UNIQSUPNO
	WHERE PoMain.PoNum = @gcPoNum 
		AND SupInfo.UNIQSUPNO = PoMain.UNIQSUPNO
		--02/19/15 YS added code because paramit has the same invoice with the same receiver number for different invoices and different supplier
			and exists (select 1 from porecloc inner join sinvdetl on sinvdetl.LOC_UNIQ=porecloc.LOC_UNIQ 
					where  porecloc.FK_UNIQRECDTL=porecdtl.uniqrecdtl and sinvdetl.SINV_UNIQ=sinvoice.sinv_uniq) 

END