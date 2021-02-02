-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/28/2011
-- Description:	Drill Down  JE 
-- Modified : 
-- 12/13/16 VL: added functional and presentation currency fields and separate FC and non FC
-- =============================================
CREATE PROCEDURE [dbo].[DrillDownJE]
	-- Add the parameters for the stored procedure here
	@JEOHKEY char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
 -- 12/13/16 VL added to check if FC is installed or not, if yes, need to get the currency 
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0  
    -- Insert statements for procedure here
	SELECT TransDate as Trans_dt,JeType,GLJEHDRO.JEOHKEY, 
			GLJEDETO.DEBIT,
			GLJEDETO.Credit,
			GLJEDETO.GL_NBR ,Gl_nbrs.gl_Descr
		FROM GLJEHDRO INNER JOIN GLJEDETO ON GLJEHDRO.JEOHKEY = GLJEDETO.FKJEOH
		INNER JOIN GL_NBRS on  GLJEDETO.GL_NBR =  Gl_nbrs.gl_nbr
		WHERE JEOHKEY=@JEOHKEY
ELSE
	-- 12/13/16 VL: added functional and presentation currency fields
   -- Insert statements for procedure here
	SELECT TransDate as Trans_dt,JeType,GLJEHDRO.JEOHKEY, 
			GLJEDETO.DEBIT,
			GLJEDETO.Credit,FF.Symbol AS Functional_Currency,
			GLJEDETO.GL_NBR ,Gl_nbrs.gl_Descr,
			GLJEDETO.DEBITPR,
			GLJEDETO.CreditPR,PF.Symbol AS Presentation_Currency
		FROM GLJEHDRO 
			INNER JOIN Fcused PF ON GLJEHDRO.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON GLJEHDRO.FuncFcused_uniq = FF.Fcused_uniq	
		INNER JOIN GLJEDETO ON GLJEHDRO.JEOHKEY = GLJEDETO.FKJEOH
		INNER JOIN GL_NBRS on  GLJEDETO.GL_NBR =  Gl_nbrs.gl_nbr
		WHERE JEOHKEY=@JEOHKEY
END