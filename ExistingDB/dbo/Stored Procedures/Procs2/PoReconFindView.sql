CREATE PROCEDURE [dbo].[PoReconFindView]
	-- Add the parameters for the stored procedure here
	--02/19/15 YS added code because paramit has the same invoice with the same receiver number for different invoices and different supplier
	--07/17/16 VL added invno back, Penang requested to add this back	
	-- 07/12/18 YS supname field name encreased 30 to 50
	@gnType as char(10) = ' ', @gcSupName as char(50) = ' ', @gcUniqSupNo as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
IF (@gnType = '1')
BEGIN
		-- Not Transferred AP
		-- 07/17/16 VL added Invno
		SELECT DISTINCT @gcSupName AS SupName, PoMain.PoNum, Invno, InvDate, InvAmount, PORECDTL.RECEIVERNO, SInv_Uniq
			FROM Sinvoice
			    INNER JOIN  PoRecdtl 
				ON  PORECDTL.RECEIVERNO = Sinvoice.receiverno
				inner join POItems
				on  PORECDTL.UNIQLNNO = POITEMS.UNIQLNNO 
				inner join PoMain
				on POMAIN.PONUM = POITEMS.PONUM   
			WHERE PoMain.UniqSUpno = @gcUniqSUpNo
				AND Is_Rel_Ap = 0
				--02/19/15 YS added code because paramit has the same invoice with the same receiver number for different invoices and different supplier
			and exists (select 1 from porecloc inner join sinvdetl on sinvdetl.LOC_UNIQ=porecloc.LOC_UNIQ 
					where  porecloc.FK_UNIQRECDTL=porecdtl.uniqrecdtl and sinvdetl.SINV_UNIQ=sinvoice.sinv_uniq)
			ORDER BY PoMain.PoNum	

END
ELSE
	IF (@gnType = '2')
		-- Transferred to AP
		-- 07/17/16 VL added Invno
		SELECT DISTINCT @gcSupName AS SupName, PoMain.PoNum, Invno, InvDate, InvAmount,PORECDTL.RECEIVERNO , SInv_Uniq
			FROM Sinvoice
			    INNER JOIN  PoRecdtl 
				ON  PORECDTL.RECEIVERNO = Sinvoice.receiverno
				inner join POItems
				on  PORECDTL.UNIQLNNO = POITEMS.UNIQLNNO 
				inner join PoMain
				on POMAIN.PONUM = POITEMS.PONUM   
			WHERE PoMain.UniqSUpno = @gcUniqSUpNo
				AND Is_Rel_Ap = 1
				--02/19/15 YS added code because paramit has the same invoice with the same receiver number for different invoices and different supplier
			and exists (select 1 from porecloc inner join sinvdetl on sinvdetl.LOC_UNIQ=porecloc.LOC_UNIQ 
					where  porecloc.FK_UNIQRECDTL=porecdtl.uniqrecdtl and sinvdetl.SINV_UNIQ=sinvoice.sinv_uniq)
			ORDER BY PoMain.PoNum	
	
	
	ELSE 
		-- All
		-- 07/17/16 VL added Invno
		SELECT DISTINCT @gcSupName AS SupName, PoMain.PoNum, Invno, InvDate, InvAmount, PORECDTL.RECEIVERNO, SInv_Uniq
			FROM Sinvoice
			    INNER JOIN  PoRecdtl 
				ON  PORECDTL.RECEIVERNO = Sinvoice.receiverno
				inner join POItems
				on  PORECDTL.UNIQLNNO = POITEMS.UNIQLNNO 
				inner join PoMain
				on POMAIN.PONUM = POITEMS.PONUM   
			WHERE PoMain.UniqSUpno = @gcUniqSUpNo
			--02/19/15 YS added code because paramit has the same invoice with the same receiver number for different invoices and different supplier
			and exists (select 1 from porecloc inner join sinvdetl on sinvdetl.LOC_UNIQ=porecloc.LOC_UNIQ 
					where  porecloc.FK_UNIQRECDTL=porecdtl.uniqrecdtl and sinvdetl.SINV_UNIQ=sinvoice.sinv_uniq)
			ORDER BY PoMain.PoNum	
	
END