-- =============================================
-- Author:		David Sharp
-- Create date: 11/22/2011
-- Description:	gets the list of Search Categories
-- =============================================
CREATE PROCEDURE [dbo].[MnxSearchGetCategoryView] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT	DISTINCT c.sCategoryId, c.sCatResourceId, c.sCatResourceValue, c.listOrder
		FROM    dbo.MnxSearchCategory AS c INNER JOIN
					dbo.MnxSearchType AS t ON c.sCategoryId = t.fksCategoryId 
					INNER JOIN dbo.MnxSearchType2Procedure tp ON t.sTypeId=tp.fkTypeId 
					INNER JOIN dbo.MnxSearchProcedureList p ON tp.fkProcedureId = p.procedureId
		WHERE p.isActive=1
END
