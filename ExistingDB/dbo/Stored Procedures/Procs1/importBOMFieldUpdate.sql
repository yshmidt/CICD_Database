-- =============================================
-- Author:		David Sharp
-- Create date: 4/18/2012
-- Description:	add import detail
-- =============================================
CREATE PROCEDURE [dbo].[importBOMFieldUpdate]
	-- Add the parameters for the stored procedure here
	@detailId uniqueidentifier,@value varchar(max),@validation varchar(20)='02row'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    
	UPDATE [dbo].[importBOMFields]
		SET [adjusted]= @value,
			[validation] = @validation
		WHERE detailId = @detailId
END