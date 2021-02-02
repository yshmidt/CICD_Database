-- =============================================
-- Author : SHRIPATI U
-- Create date : 07/20/2018
-- Description : GET LATEST INSERTED RECORD FROM BOM_DET TABLE
-- GetMaxItemNoByAssemblyKey '_1LR0NALBN'
-- =============================================
CREATE PROC [dbo].[GetMaxItemNoByAssemblyKey] @BOMParentKey AS char(10) = ''
AS

BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
	SELECT ISNULL (MAX(Item_no),0) as Item_no
	FROM Bom_det 
	WHERE Bom_det.BomParent = @BOMParentKey
END