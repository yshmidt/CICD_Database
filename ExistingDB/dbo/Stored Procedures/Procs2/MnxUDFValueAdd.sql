-- =============================================
-- Author:		David Sharp
-- Create date: 1/20/2011
-- Description:	add a value for a UDF
-- =============================================
CREATE PROCEDURE [dbo].[MnxUDFValueAdd]
	-- Add the parameters for the stored procedure here
(	@FieldListId uniqueidentifier,
	@ModuleListId uniqueidentifier,
	@RecordId char(10),
	@ValueType varchar(10),
	@Value varchar(MAX),
	@uniqueId uniqueidentifier,
	@RowId uniqueidentifier)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @NumericValue int = null
	DECLARE @StringValue varchar(MAX) = null
	DECLARE @LogicValue bit = null
	DECLARE @DateValue datetime = null
	
	IF @ValueType = 'String' SET @StringValue = @Value
	IF @ValueType = 'Date' SET @DateValue = CAST(@Value AS datetime)
	IF @ValueType = 'Logic' SET @LogicValue = CAST(@Value AS bit)
	IF @ValueType = 'Numeric' SET @NumericValue = CAST(@Value AS decimal(18,5))

    -- Insert statements for procedure here
    INSERT INTO UDFValues
		(UniqueID
		,fk_fieldListId
		,FK_ModuleListId
		,fk_RecordId
		,FieldNValue
		,FieldCValue
		,FieldLValue
		,FieldDvalue
		,RowId)
	VALUES
		(@uniqueId
		,@FieldListId
		,@ModuleListId
		,@RecordId
		,@NumericValue
		,@StringValue
		,@LogicValue
		,@DateValue
		,@RowId)
END
