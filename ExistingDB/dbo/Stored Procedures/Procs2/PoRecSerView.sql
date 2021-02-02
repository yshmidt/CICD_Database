-- =============================================
-- Author:		Yelena Shmidt	
-- Create date: <10/28/2010>
-- Description:	<PoRecSerView for PO receiving module>
-- Modified: 05/15/14 YS added sourcedev column to ='D' when updated from desktop
-- =============================================
CREATE PROCEDURE [dbo].[PoRecSerView]
	-- Add the parameters for the stored procedure here
	@lcReceiverno char(10)=' '  
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Porecser.poserunique, Porecser.loc_uniq, Porecser.lot_uniq,
  Porecser.serialno, Porecser.receiverno, Porecser.serialrej,PORECSER.FK_SERIALUNIQ,
  PorecSer.sourcedev 
 FROM porecser
 WHERE  Porecser.receiverno = @lcReceiverno
END