-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <01/10/2011>
-- Description:	porejlotview
-- Modified: 05/15/14 YS added sourcedev column = 'D' when updated from desktop
-- =============================================
CREATE PROCEDURE [dbo].[porejlotview]
	-- Add the parameters for the stored procedure here
	@lcreceiverno char(10)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT DISTINCT Poreclot.lotcode, Poreclot.expdate, Poreclot.reference,
		Poreclot.lotqty, Poreclot.rejlotqty, Poreclot.lot_uniq,
		Poreclot.receiverno, Poreclot.loc_uniq,
		Poreclot.rejlotqty-0 AS oldrejlotqty,
		Poreclot.lotqty-Poreclot.lotqty AS retlotqty, Poreclot.sourceDev,  CAST(1 as bit) AS lFilter
	FROM poreclot
	WHERE  Poreclot.receiverno =  @lcreceiverno

END