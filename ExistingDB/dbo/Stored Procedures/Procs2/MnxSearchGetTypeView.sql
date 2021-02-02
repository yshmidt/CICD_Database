-- =============================================
-- Author:		David Sharp
-- Create date: 11/22/2011
-- Description:	gets the list of Search Types
-- =============================================
CREATE PROCEDURE [dbo].[MnxSearchGetTypeView] 
	-- Add the parameters for the stored procedure here
	@categoryId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT DISTINCT sTypeId, sTypeResourceId,sTypeResourceValue, listOrder
		FROM [MnxSearchType] t INNER JOIN dbo.MnxSearchType2Procedure tp ON t.sTypeId=tp.fkTypeId
			INNER JOIN dbo.MnxSearchProcedureList p ON tp.fkProcedureID=p.procedureId
		WHERE fksCategoryId = @categoryId AND p.isActive=1
END
