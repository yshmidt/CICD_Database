-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 09/07/2011
-- Description:	Assign Supplier to a User
-- =============================================
CREATE PROCEDURE [dbo].[aspmnx_AddSuppliersToUser] 
	-- Add the parameters for the stored procedure here
	@UserId uniqueidentifier , 
	@UniqSupno char(10)
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    --GroupuserId will be auto generated
	INSERT INTO aspmnx_UserSuppliers (fkUniqSupno,fkUserId) VALUES (@UniqSupno,@UserId);
	
END
