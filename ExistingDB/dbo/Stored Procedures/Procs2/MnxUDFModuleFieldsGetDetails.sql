-- =============================================
-- Author:		David Sharp
-- Create date: 1/20/2011
-- Description:	get a list of UDF Fields for the Selected Module
-- =============================================
CREATE PROCEDURE [dbo].[MnxUDFModuleFieldsGetDetails]
	-- Add the parameters for the stored procedure here
	@FieldListId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT FieldName,FieldType,FieldRequired,FieldLength, FieldDecimal, ColumnNo, Caption, ListType, CalcSum, ExcludeWhen, MinValue, MaxValue, DefaultValue
	FROM UdfFields
	WHERE FieldListId = @FieldListId
END
