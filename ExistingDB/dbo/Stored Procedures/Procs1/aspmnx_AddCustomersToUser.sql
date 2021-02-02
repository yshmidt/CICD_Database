-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 09/07/2011
-- Description:	Assign Customers to a User
-- =============================================
CREATE PROCEDURE [dbo].[aspmnx_AddCustomersToUser] 
	-- Add the parameters for the stored procedure here
	@UserId uniqueidentifier , 
	@Custno char(10)
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    --GroupuserId will be auto generated
	INSERT INTO aspmnx_UserCustomers (fkCustno,fkUserId) VALUES (@Custno,@UserId);
	
END
