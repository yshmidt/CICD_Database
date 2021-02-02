
-- =============================================
-- Author:		Yelena 
-- Create date: 02/28/2014
-- Description:	This procedure is for test only.
--- I am using it to test different ways to call procedure and different ways to return a value
-- =============================================
CREATE PROCEDURE [dbo].[sp_TestOnly]
	-- Add the parameters for the stored procedure here
	@nInput int =0,@nOutput int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @nReturn int = 0
    -- Insert statements for procedure here
	select @nReturn =@nInput,@nOutput =@nInput  
	RETURN @nReturn
END
