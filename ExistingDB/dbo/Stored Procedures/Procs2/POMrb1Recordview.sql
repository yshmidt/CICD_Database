-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <01/10/2011>
-- Description:	<POMrb1Recordview>
-- =============================================
CREATE PROCEDURE [dbo].[POMrb1Recordview]
	-- Add the parameters for the stored procedure here
	@lcuniqrecdtl char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	-- 04/17/14 YS added dmrNote to Porecmrb table (request from Inovar, ticket 7477)
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Porecmrb.dmr_no, Porecmrb.rma_no, Porecmrb.rma_date,
		Porecmrb.confirmby, Porecmrb.ret_qty, Porecmrb.dmrplno, Porecmrb.transno,
		Porecmrb.linkadd, Porecmrb.initial, Porecmrb.shipvia,
		Porecmrb.shipcharge, Porecmrb.fob, Porecmrb.terms, Porecmrb.waybill,
		Porecmrb.freightamt, Porecmrb.rej_date, Porecmrb.dmrunique,
		Porecmrb.fk_uniqrecdtl, Porecmrb.printdmr, Porecmrb.dmr_date,poRecMrb.dmrNote
	FROM porecmrb
	WHERE  Porecmrb.fk_uniqrecdtl = ( @lcuniqrecdtl )

END