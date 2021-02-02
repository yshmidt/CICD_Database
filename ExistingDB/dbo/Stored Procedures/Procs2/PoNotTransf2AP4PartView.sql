-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <05/27/10>
-- Description:	<Procedure will get all unreconciled and reconciled, but not transferred to AP for the specific uniq_key>
-- 07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')
-- 10/09/14 YS removed Invtmfhd table and replaced with 2 new tables
--- 05/28/15 YS remove ReceivingStatus
-- 07/01/19 YS need to use OR in (Porecloc.AccptQty<>0 and Porecloc.RejQty<>0) not and
-- =============================================
CREATE PROCEDURE [dbo].[PoNotTransf2AP4PartView]
	-- Add the parameters for the stored procedure here
	@lcUniq_key char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 07/23/14 YS make sure only complete receivers are selected
	-- 10/09/14 YS removed Invtmfhd table and replaced with 2 new tables. Only one table needed in this case
	SELECT DISTINCT Sinv_uniq
		from Porecrelgl,Porecloc,Porecdtl,InvtMPNLink L
	 WHERE Porecloc.Loc_uniq=Porecrelgl.Loc_uniq 
	 AND Porecdtl.UniqMfgrHd=L.UniqMfgrHd 
	 AND Porecdtl.UniqRecdtl=Porecloc.Fk_uniqrecdtl
	 AND Sinv_uniq=' '	
	 -- 07/01/19 YS need to use OR in (Porecloc.AccptQty<>0 and Porecloc.RejQty<>0) not and
	 AND (Porecloc.AccptQty<>0 or Porecloc.RejQty<>0)
	 AND L.Uniq_key=@lcUniq_key
	 UNION
	 SELECT DISTINCT Porecloc.Sinv_uniq
		from Porecrelgl,Porecloc,Porecdtl,InvtMPNLink L,SINVOICE  
	 WHERE Porecloc.Loc_uniq=Porecrelgl.Loc_uniq 
	 AND Porecdtl.UniqMfgrHd=L.UniqMfgrHd 
	 AND Porecdtl.UniqRecdtl=Porecloc.Fk_uniqrecdtl
	 AND Porecloc.Sinv_uniq<>' '	
	 AND PORECLOC.SINV_UNIQ =SINVOICE.SINV_UNIQ 
	 AND Sinvoice.is_rel_ap=0
	 -- 07/01/19 YS need to use OR in (Porecloc.AccptQty<>0 and Porecloc.RejQty<>0) not and
	 AND (Porecloc.AccptQty<>0 or Porecloc.RejQty<>0)
	 AND L.Uniq_key=@lcUniq_key
	
END