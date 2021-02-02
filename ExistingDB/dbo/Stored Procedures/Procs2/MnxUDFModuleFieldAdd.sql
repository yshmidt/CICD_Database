-- =============================================
-- Author:		David Sharp
-- Create date: 1/20/2011
-- Description:	get a list of UDF Fields for the Selected Module
-- =============================================
CREATE PROCEDURE [dbo].[MnxUDFModuleFieldAdd]
	-- Add the parameters for the stored procedure here
(	@ModuleListId uniqueidentifier,
	@FIELDNAME char(10),
	@FieldType char(10),
	@FieldRequired bit,
	@FieldLength int,
	@FieldDecimal int,
	@ColumnNo int,
	@Caption varchar(50),
	@ListType char(10),
	@CalcSum bit,
	@ExcludeWhen varchar(MAX),
	@MinValue numeric(18,5),
	@MaxValue numeric(18,5),
	@DefaultValue varchar(50))
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    INSERT INTO UdfFields
		(FK_ModuleListId
		,FIELDNAME
		,FieldType
		,FieldRequired
		,FieldLength
		,FieldDecimal
		,COLUMNNO
		,CAPTION
		,ListType
		,CalcSum
		,ExcludeWhen
		,MinValue
		,MaxValue
		,DefaultValue)
	VALUES
		(@ModuleListId
		,@FIELDNAME
		,@FieldType
		,@FieldRequired
		,@FieldLength
		,@FieldDecimal
		,@COLUMNNO
		,@CAPTION
		,@ListType
		,@CalcSum
		,@ExcludeWhen
		,@MinValue
		,@MaxValue
		,@DefaultValue)
END
