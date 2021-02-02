-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <01/10/2011>
-- Description:	<Pur_varView>
-- Modification:
-- 11/16/16 VL added CosteachPR, StdcostPR and VariancePR
-- 01/05/17 VL Added PRFcused_uniq and FuncFcused_uniq
-- =============================================
CREATE PROCEDURE [dbo].[Pur_varView]
	-- Add the parameters for the stored procedure here
	@lcSdet_uniq char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Pur_var.var_key, Pur_var.fk_UniqApHead,
   Pur_var.acpt_qty, Pur_var.costeach, Pur_var.stdcost, Pur_var.variance,
  Pur_var.gl_nbr, Pur_var.gl_nbr_var, 
  Pur_var.is_rel_gl, Pur_var.sdet_uniq, Pur_var.trans_dt, 
  Pur_var.trans_date, 
  Pur_var.costeachPR, Pur_var.stdcostPR, Pur_var.variancePR, PRFcused_uniq, FuncFcused_uniq
 FROM pur_var
 WHERE  Pur_var.sdet_uniq = ( @lcSdet_uniq )
END