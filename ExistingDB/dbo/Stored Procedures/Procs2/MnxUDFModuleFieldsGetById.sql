-- =============================================
-- Author:		David Sharp
-- Create date: 1/20/2011
-- Description:	get a list of UDF Fields for the Selected Module
-- =============================================
CREATE PROCEDURE [dbo].[MnxUDFModuleFieldsGetById]
	-- Add the parameters for the stored procedure here
	@ModuleListId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT FieldListId, FieldName,FieldRequired, Caption
	FROM UdfFields
	WHERE FK_ModuleListId = @ModuleListId
END
