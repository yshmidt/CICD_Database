-- =============================================
-- Author:		David Sharp
-- Create date: 1/20/2011
-- Description:	add a list item value to a UDF
-- =============================================
CREATE PROCEDURE [dbo].[MnxUDFListValueAdd]
	-- Add the parameters for the stored procedure here
	@FieldListId uniqueidentifier,
	@ListItemValue varchar(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    INSERT INTO UDFListValues
		(FK_FieldListID,ListItemValue)
	VALUES
		(@FieldListId, @ListItemValue)
END
