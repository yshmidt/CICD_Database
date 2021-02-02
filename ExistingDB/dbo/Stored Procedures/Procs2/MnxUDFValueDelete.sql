-- =============================================
-- Author:		David Sharp
-- Create date: 1/20/2011
-- Description:	delete a value for a UDF
-- =============================================
CREATE PROCEDURE [dbo].[MnxUDFValueDelete]
	-- Add the parameters for the stored procedure here
	@uniqueId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    DELETE FROM UDFValues
	WHERE UniqueID = @UniqueId
END
