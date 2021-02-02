-- =============================================
-- Author:		Yelena Shmidt	
-- Create date: 12/19/14 
-- Description:	find unreconciled receipt by ponum and part number
-- 05/28/15 YS remove ReceivingStatus
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 01/15/19 YS structure changed for new "manex"
-- =============================================
CREATE  PROCEDURE [dbo].[PoReconFindUnReconbyPOPart]
	-- Add the parameters for the stored procedure here
	@lcPoNum as char(15) = ' ' ,
	@Part_no char(35)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')
	-- make sure only complete receiver is selected
	-- 05/28/15 YS remove ReceivingStatus
	--SELECT DISTINCT PoMain.PoNum, PoDate, PoTotal, PoRecPkNo, UniqSupno ,PoRecDtl.ReceiverNo, RecvDate,
	--	inventor.part_no,Inventor.Revision
	--	FROM PoMain INNER JOIN PoItems ON POitems.ponum=pomain.ponum
	--	inner join PoRecDtl on POrecdtl.uniqlnno=poitems.uniqlnno 
	--	inner join porecloc ON POrecloc.FK_UNIQRECDTL=porecdtl.UNIQRECDTL
	--	inner join inventor on poitems.uniq_key=inventor.uniq_key 
	--	WHERE 
	--	--(PORECDTL.ReceivingStatus='Complete' or PORECDTL.ReceivingStatus=' ')
	--		--AND 
	--		PoRecLoc.SInv_Uniq = ' '
	--		AND PoRecLoc.AccptQty <> 0 
	--		AND PoMain.PONUM = @lcPoNum 
	--		and (@part_no=' ' OR Inventor.part_no=@part_no)



-- 01/15/19 YS use new structure to gather info
	SELECT distinct SupName, PoMain.UniqSupNo,PoMain.PoNum, PoDate, PoTotal,receiverHeader.recPklNo as PoRecPkNo,receiverHeader.ReceiverNo, 
	receiverHeader.DockDate as RecvDate,inventor.part_no,Inventor.Revision
		from PORECLOC inner join PoRecDtl ON porecloc.Fk_UniqRecDtl=PORECDTL.UNIQRECDTL
		INNER JOIN receiverDetail on PORECDTL.receiverdetId=receiverDetail.receiverDetId 
		INNER JOIN Inventor on receiverDetail.Uniq_key=inventor.uniq_key
		inner join receiverHeader on receiverHeader.receiverHdrId=receiverDetail.receiverHdrId
		INNER JOIN  PoMain ON receiverHeader.ponum=pomain.ponum
		inner join SUPINFO ON pomain.UNIQSUPNO=SUPINFO.UNIQSUPNO
		WHERE SINV_UNIQ = ''
		and PoRecLoc.AccptQty <> 0
		AND PoMain.PONUM = @lcPoNum 
		and (@part_no=' ' OR Inventor.part_no=@part_no)
		ORDER BY POMAIN.ponum
	
END