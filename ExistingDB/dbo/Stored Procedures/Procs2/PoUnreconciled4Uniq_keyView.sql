-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 06/08/10
-- Description:	Find if there are any un-reconciled receipts for a specified uniq_key
-- 07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')
-- 05/28/15 YS remove ReceivingStatus
-- =============================================
CREATE PROCEDURE [dbo].[PoUnreconciled4Uniq_keyView] 
	-- Add the parameters for the stored procedure here
	@lcUniq_key char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	-- 07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')
	-- 05/28/15 YS remove ReceivingStatus
	SELECT Poitems.Ponum,Porecdtl.Receiverno,Porecdtl.UniqLnno,Porecloc.Loc_uniq
		FROM Poitems,Porecdtl,Porecloc
		WHERE Poitems.Uniq_key=@lcUniq_key 
		AND Porecdtl.UniqLnno=Poitems.Uniqlnno
		AND Porecdtl.Receiverno	=Porecloc.Receiverno
		--and (PORECDTL.ReceivingStatus='Complete' or PORECDTL.ReceivingStatus=' ') 
		AND Sinv_uniq=SPACE(10)
		AND PoRecLoc.AccptQty > 0 
		
END