-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- 07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')
-- 05/28/15 YS remove ReceivingStatus
-- 01/15/19 YS use new structure to gather info
-- =============================================
CREATE PROCEDURE [dbo].[PoReconFindUnReconView3]
	-- Add the parameters for the stored procedure here
	@gcSupPkNo as char(15) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')
	-- Make sure only complete receiver is selected
	--SELECT DISTINCT PoMain.PoNum, PoDate, PoTotal, PoRecPkNo, UniqSupno ,PoRecDtl.ReceiverNo, RecvDate
	--	FROM PoMain, PoItems, PoRecDtl,Porecloc 
	--	WHERE PoItems.PoNum = PoMain.Ponum 
	--		AND PoRecDtl.UniqLnNo = PoItems.UniqLnNo 
	--		-- 05/28/15 YS remove ReceivingStatus
	--		--AND (PORECDTL.ReceivingStatus='Complete' or PORECDTL.ReceivingStatus =' ')
	--		AND PoRecLoc.Fk_UniqRecDtl= PoRecDtl.UniqRecDtl
	--		AND PoRecLoc.SInv_Uniq = ' '
	--		AND PoRecLoc.AccptQty <> 0 
	--		AND Porecdtl.Porecpkno = @gcSupPkNo 
	--	ORDER BY PoMain.PoNum
	-- 01/15/19 YS use new structure to gather info
	SELECT distinct SupName, PoMain.UniqSupNo,PoMain.PoNum, PoDate, PoTotal,receiverHeader.recPklNo as PoRecPkNo,receiverHeader.ReceiverNo, 
	receiverHeader.DockDate as RecvDate
		from PORECLOC inner join PoRecDtl ON porecloc.Fk_UniqRecDtl=PORECDTL.UNIQRECDTL
		INNER JOIN receiverDetail on PORECDTL.receiverdetId=receiverDetail.receiverDetId 
		inner join receiverHeader on receiverHeader.receiverHdrId=receiverDetail.receiverHdrId
		INNER JOIN  PoMain ON receiverHeader.ponum=pomain.ponum
		inner join SUPINFO ON pomain.UNIQSUPNO=SUPINFO.UNIQSUPNO
		WHERE SINV_UNIQ = ''
		and PoRecLoc.AccptQty <> 0
		AND receiverHeader.recPklNo = @gcSupPkNo 
		ORDER BY POMAIN.ponum
END