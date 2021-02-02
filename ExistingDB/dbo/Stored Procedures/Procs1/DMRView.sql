CREATE PROCEDURE [dbo].[DMRView]
	-- Add the parameters for the stored procedure here
@gcDmrUnique as char(10) = ''
AS
BEGIN
-- 04/17/14 YS added dmrNote to Porecmrb table (request from Inovar, ticket 7477)
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
SELECT Porecmrb.dmr_no, Porecmrb.rma_no, Porecmrb.ret_qty,
  Porecmrb.confirmby, Porecmrb.rma_date, Porecmrb.dmrplno,
  Porecmrb.dmrunique, Porecmrb.dmr_date, Porecmrb.fk_uniqrecdtl,
  PORECMRB.LINKADD ,PORECMRB.FOB,PoRecMrb.SHIPVIA,PORECMRB.SHIPCHARGE,
  PORECMRB.WAYBILL , PORECMRB.TERMS , Porecmrb.dmrNote  
 FROM 
     porecmrb
 WHERE  Porecmrb.dmrunique = @gcDmrUnique
END 