-- =============================================
-- Author:		PoRejSerView
-- Create date: <01/10/2011>
-- Description:	<PoRejSerView>
-- Modified: 05/15/14 YS added sourcedev column to ='D' when updated from desktop
-- =============================================
CREATE PROCEDURE [dbo].[PoRejSerView]
	-- Add the parameters for the stored procedure here
	@lcreceiverno char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Porecser.poserunique, Porecser.loc_uniq, Porecser.lot_uniq,
		Porecser.serialno, Porecser.receiverno, Porecser.serialrej,PorecSer.sourcedev,
		CAST(0 as bit) AS serialret, CAST(1 as bit) AS lFilter
	FROM porecser
	WHERE  Porecser.receiverno = ( @lcreceiverno )
END