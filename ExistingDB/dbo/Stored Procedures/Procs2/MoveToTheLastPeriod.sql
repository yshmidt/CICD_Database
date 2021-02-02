-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 06/29/16 
-- Description:	For INTERNAL USE ONLY or if instrcuted by MANEX
-- Don't try it at home
-- this procedure will make current the last period of the current year
-- =============================================
CREATE PROCEDURE MoveToTheLastPeriod
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @fy char(4)

	select @fy=glsys.CUR_FY from glsys 
	update glsys set cur_period=12,cur_end_dt=FY_END_DT
	update GLFYRSDETL set lClosed=1 , lCURRENT=0 where lCurrent=1 
	update GLFYRSDETL set lCurrent=1 where Period=12 and exists (select 1 from GLFISCALYRS F where f.FY_UNIQ=GLFYRSDETL.FK_FY_UNIQ and f.FISCALYR=@fy)

END