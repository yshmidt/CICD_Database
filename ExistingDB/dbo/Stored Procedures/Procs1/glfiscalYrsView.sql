
-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <09/29/2009>
-- Description:	<Use this procedure as a view for the glfiscalYrs>
-- 06/22/15 YS added sequncenumber column to allow entering any data in the FY column and allow the user to find prior and next year
-- =============================================
CREATE PROCEDURE [dbo].[glfiscalYrsView]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 06/22/15 YS added sequncenumber column to allow entering any data in the FY column and allow the user to find prior and next year
	SELECT FiscalYr,(SELECT COUNT(*) FROM glfYrsDetl where Fk_Fy_uniq=glfiscalYrs.Fy_uniq) as Periods,
	dBeginDate,dEndDate,lClosed,lCurrent,FyNote,Fy_uniq,SequenceNumber
	FROM glfiscalYrs ORDER BY FiscalYr,dBeginDate
END
