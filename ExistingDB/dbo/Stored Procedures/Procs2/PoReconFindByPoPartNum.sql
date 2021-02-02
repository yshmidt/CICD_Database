-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 12/19/2014
-- Description:	Seaarch in poreconciliation by purchase order number and part number
--02/19/15 YS added code because paramit has the same invoice with the same receiver number for different invoices and different supplier
--07/17/16 VL added invno back, Penang requested to add this back	
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- =============================================
CREATE PROCEDURE [dbo].[PoReconFindByPoPartNum]
	-- Add the parameters for the stored procedure here
	@gcPoNum as char(15) = ' ',
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
	@part_no char(35)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 07/17/16 VL added Invno
	SELECT DISTINCT SupName, PoMain.PoNum, InvDate, Invno, InvAmount, PORECDTL.ReceiverNo, SInv_Uniq,
	I.Part_no,i.Revision as Revision 
	FROM Sinvoice
		  INNER JOIN  PoRecdtl 
		ON  PORECDTL.RECEIVERNO = Sinvoice.receiverno
		inner join POItems
		on  PORECDTL.UNIQLNNO = POITEMS.UNIQLNNO 
		inner join INVENTOR I on Poitems.UNIQ_KEY=I.UNIQ_KEY
		inner join PoMain
		on POMAIN.PONUM = POITEMS.PONUM   
		inner join SUPINFO 
		on SUPINFO.UNIQSUPNO = POMAIN.UNIQSUPNO
	WHERE PoMain.PoNum = @gcPoNum 
		AND SupInfo.UNIQSUPNO = PoMain.UNIQSUPNO 
		and (@part_no=' ' or I.part_no=@part_no)
		--02/19/15 YS added code because paramit has the same invoice with the same receiver number for different invoices and different supplier
			and exists (select 1 from porecloc inner join sinvdetl on sinvdetl.LOC_UNIQ=porecloc.LOC_UNIQ 
					where  porecloc.FK_UNIQRECDTL=porecdtl.uniqrecdtl and sinvdetl.SINV_UNIQ=sinvoice.sinv_uniq)

END