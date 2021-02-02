-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 09/06/2011
-- Description:	Remove Supplier from a User
-- =============================================
CREATE PROCEDURE [dbo].[aspmnx_RemoveSupplierFromUser] 
	-- Add the parameters for the stored procedure here
	@UserSuppId uniqueidentifier
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
   
	DELETE FROM aspmnx_UserSuppliers WHERE UserSuppId=@UserSuppId;
	
END
