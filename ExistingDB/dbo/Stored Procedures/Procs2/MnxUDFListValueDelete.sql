-- =============================================
-- Author:		David Sharp
-- Create date: 1/20/2011
-- Description:	delete a list item value to a UDF
-- =============================================
CREATE PROCEDURE dbo.MnxUDFListValueDelete
	-- Add the parameters for the stored procedure here
	@UniqueListId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    DELETE FROM UDFListValues
	WHERE UniqueListID = @UniqueListId
END
