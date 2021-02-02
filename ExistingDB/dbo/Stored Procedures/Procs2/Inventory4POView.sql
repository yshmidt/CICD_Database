-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 18/19/2010
-- Description:	Query all the inventory record for a given Purchase Order
-- This view is designed for the Purchase Order module to be able to update some of the fields 
-- in the Inventor module when add/edit a PO.
-- Modification:
-- 11/07/16	VL	Added presenation currency cost fields 
-- =============================================
CREATE PROCEDURE [dbo].[Inventory4POView]
	@pcPonum char(15) =' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	SELECT Inventor.UNIQ_KEY,INVENTOR.STDCOST,INVENTOR.MATL_COST,
		INVENTOR.MinOrd,INVENTOR.ORDMULT,INVENTOR.PUR_LTIME ,
		INVENTOR.PUR_LUNIT,INVENTOR.Inv_note,ISNULL(PartType.lotdetail,cast(0 as bit)) as LotDetail,
		ISNULL(Parttype.Autodt,CAST(0 as bit)) as AutoDt,ISNULL(Parttype.FgiExpDays,CAST(0 as numeric(4,0))) as FgiExpDays,
		INVENTOR.SERIALYES,Inventor.insp_req,INVENTOR.CERT_REQ ,INVENTOR.CERT_TYPE, 
		INVENTOR.STDCOSTPR,INVENTOR.MATL_COSTPR 
		FROM Inventor LEFT OUTER JOIN PartType ON INVENTOR.PART_CLASS +INVENTOR.PART_TYPE = PARTTYPE.PART_CLASS +PARTTYPE.PART_TYPE 
		 WHERE EXISTS (SELECT 1 FROM POITEMS WHERE INVENTOR.UNIQ_KEY= Poitems.Uniq_key AND POITEMS.PONUM=@pcPonum)
		
END