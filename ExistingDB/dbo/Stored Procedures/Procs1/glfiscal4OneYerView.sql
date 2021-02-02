
-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <11/05/2009>
-- Description:	<Use this procedure to view Fiscal Periods for one Year>
-- modified 06/22/15 YS I cannot find any place this code is used. It was used in the desktop, but the code has comments.
-- will just add new sequencenumber column to the output
-- =============================================
CREATE PROCEDURE [dbo].[glfiscal4OneYerView]
@pYear as char(4) = ''
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT FiscalYr,Period,Fk_Fy_uniq,FyDtlUniq ,SequenceNumber
		FROM glfiscalYrs,glfYrsDetl where Fk_Fy_uniq=glfiscalYrs.Fy_uniq
	AND FiscalYr=@pYear ORDER BY SequenceNumber,Period
END
