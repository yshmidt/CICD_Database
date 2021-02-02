
--@userid uniqueidentifier = null

-- =============================================
-- Author:		David Sharp
-- Create date: 12/14/2012
-- Description:	get unreconciled receipts
-- 07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')
-- 05/28/15 YS remove ReceivingStatus
-- 02/03/17 YS structure changes  Fix for now.
-- =============================================
CREATE PROCEDURE [dbo].[QkViewUnreconciledReciepts] 
@userid uniqueidentifier = null
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 05/28/15 YS remove ReceivingStatus
	-- 02/03/17 YS structure changes  Fix for now.
	SELECT		dbo.POMAIN.PONUM, dbo.POMAIN.PODATE, dbo.POMAIN.POSTATUS, dbo.SUPINFO.SUPNAME, dbo.POITEMS.ORD_QTY, 
                      dbo.PORECDTL.RECVDATE, dbo.PORECDTL.AcceptedQty, dbo.PORECDTL.FailedQty, dbo.POITEMS.POITTYPE, 
                      dbo.INVENTOR.PART_NO, dbo.INVENTOR.DESCRIPT, dbo.POITEMS.COSTEACH, 
                      dbo.PORECDTL.AcceptedQty * dbo.POITEMS.COSTEACH AS ExtCost, dbo.PORECLOC.SDET_UNIQ
		FROM	dbo.PORECDTL INNER JOIN
					  dbo.PORECLOC ON dbo.PORECDTL.UNIQRECDTL = dbo.PORECLOC.FK_UNIQRECDTL INNER JOIN
					  dbo.POITEMS ON dbo.PORECDTL.UNIQLNNO = dbo.POITEMS.UNIQLNNO INNER JOIN
					  dbo.POMAIN ON dbo.POITEMS.PONUM = dbo.POMAIN.PONUM INNER JOIN
					  dbo.SUPINFO ON dbo.POMAIN.UNIQSUPNO = dbo.SUPINFO.UNIQSUPNO LEFT OUTER JOIN
					  dbo.INVENTOR ON dbo.POITEMS.UNIQ_KEY = dbo.INVENTOR.UNIQ_KEY
		WHERE   (dbo.PORECLOC.SDET_UNIQ = ' ') AND (dbo.POMAIN.POSTATUS <> 'Cancel')
		--and (PORECDTL.ReceivingStatus='Complete' or PORECDTL.ReceivingStatus=' ') 
END