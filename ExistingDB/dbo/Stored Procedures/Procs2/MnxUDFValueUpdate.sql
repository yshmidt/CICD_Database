-- =============================================
-- Author:		David Sharp
-- Create date: 1/20/2011
-- Description:	update a value for a UDF
-- =============================================
CREATE PROCEDURE [dbo].[MnxUDFValueUpdate]
	-- Add the parameters for the stored procedure here
(	@uniqueId uniqueidentifier,
	@FieldListId uniqueidentifier,
	@ModuleListId uniqueidentifier,
	@RecordId uniqueidentifier,
	@NumericValue numeric,
	@StringValue varchar(MAX),
	@LogicValue bit,
	@DateValue datetime,
	@RowId uniqueidentifier)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    UPDATE UDFValues
	SET	fk_fieldListId = @FieldListId,
		FK_ModuleListId = @ModuleListId,
		fk_RecordId = @RecordId,
		FieldNValue = @NumericValue,
		FieldCValue = @StringValue,
		FieldLValue = @LogicValue,
		FieldDvalue = @DateValue,
		RowId = @RowId
	WHERE UniqueID = @UniqueId
END
