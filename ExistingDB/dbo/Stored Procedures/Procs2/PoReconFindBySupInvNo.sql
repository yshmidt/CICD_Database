﻿CREATE PROCEDURE [dbo].[PoReconFindBySupInvNo]
	-- Add the parameters for the stored procedure here
	--02/19/15 YS added code because paramit has the same invoice with the same receiver number for different invoices and different supplier
	--07/17/16 VL added invno back, Penang requested to add this back	
	@gcSupInvNo as char(20) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 07/17/16 VL added Invno
	SELECT DISTINCT SupName, PoMain.PoNum, InvDate, Invno, InvAmount, Sinvoice.ReceiverNo, SInv_Uniq 
	FROM Sinvoice
		INNER JOIN  PoRecdtl 
			ON  PORECDTL.RECEIVERNO = Sinvoice.receiverno
		inner join POItems
			on  PORECDTL.UNIQLNNO = POITEMS.UNIQLNNO 
		inner join PoMain
			on POMAIN.PONUM = POITEMS.PONUM   
		inner join SUPINFO 
			on SUPINFO.UNIQSUPNO = POMAIN.UNIQSUPNO
			--02/19/15 YS added code because paramit has the same invoice with the same receiver number for different invoices and different supplier
			and exists (select 1 from porecloc inner join sinvdetl on sinvdetl.LOC_UNIQ=porecloc.LOC_UNIQ 
					where  porecloc.FK_UNIQRECDTL=porecdtl.uniqrecdtl and sinvdetl.SINV_UNIQ=sinvoice.sinv_uniq)
	WHERE Sinvoice.InvNo  = @gcSupInvNo 
			

END