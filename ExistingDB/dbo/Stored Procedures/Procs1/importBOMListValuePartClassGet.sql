-- =============================================
-- Author:		David Sharp
-- Create date: 5/14/2012
-- Description:	get import list values
-- =============================================
CREATE PROCEDURE [dbo].[importBOMListValuePartClassGet] 
	@partClass varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	---- Get Part Types
	SELECT part_type AS partType, part_class AS partClass FROM PARTTYPE WHERE part_class=@partClass

END