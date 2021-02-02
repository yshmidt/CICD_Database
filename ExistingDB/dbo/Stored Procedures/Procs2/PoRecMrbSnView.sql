-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <12/19/08>
-- Description:	<PorecMrbSnView imitation>
-- =============================================
CREATE PROCEDURE [dbo].[PoRecMrbSnView] 
	-- Add the parameters for the stored procedure here
	@lcDmrUnique char(10) = NULL 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Porecmrbsn.fk_dmrunique, Porecmrbsn.fk_poserunique,
	Porecmrbsn.fk_serialuniq, Porecmrbsn.porecmrbsnuniq
	FROM porecmrbsn
	WHERE  Porecmrbsn.fk_dmrunique =   @lcDmrUnique	

END