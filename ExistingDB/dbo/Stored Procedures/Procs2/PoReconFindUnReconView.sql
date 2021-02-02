-- =============================================
-- Author:		Bill Blake
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- 07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')
-- 05/28/15 YS remove ReceivingStatus
-- 01/15/19 YS new "manex" will save recvdate as item received for the PL could be at different time. 
--- will use dockDate from receiverheader.
-- =============================================
CREATE PROCEDURE [dbo].[PoReconFindUnReconView]

	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')
	-- Make sure only complete receiver selected
	-- 05/28/15 YS remove ReceivingStatus
	-- 01/15/19 YS use new structure to gather inofo
	SELECT distinct SupName, PoMain.UniqSupNo,PoMain.PoNum, PoDate, PoTotal,receiverHeader.recPklNo as PoRecPkNo,receiverHeader.ReceiverNo, 
	receiverHeader.DockDate as RecvDate
		from PORECLOC inner join PoRecDtl ON porecloc.Fk_UniqRecDtl=PORECDTL.UNIQRECDTL
		INNER JOIN receiverDetail on PORECDTL.receiverdetId=receiverDetail.receiverDetId 
		inner join receiverHeader on receiverHeader.receiverHdrId=receiverDetail.receiverHdrId
		INNER JOIN  PoMain ON receiverHeader.ponum=pomain.ponum
		inner join SUPINFO ON pomain.UNIQSUPNO=SUPINFO.UNIQSUPNO
		WHERE SINV_UNIQ = ''
		and PoRecLoc.AccptQty <> 0
END