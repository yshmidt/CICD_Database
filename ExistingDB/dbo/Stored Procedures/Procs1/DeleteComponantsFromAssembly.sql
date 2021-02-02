-- =============================================
-- Author:		Sachin B
-- Create date: 11/17/2016
-- Description:	this procedure will be called from the SF module and Delete Allocated componant from assembly
-- [dbo].[DeleteComponantsFromAssembly] 'EMR5O1MTU0'  
-- =============================================

CREATE PROCEDURE [dbo].[DeleteComponantsFromAssembly] 
	-- Add the parameters for the stored procedure here
	@CompToAssemblyUk CHAR(10)
AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

	  Delete FROM SerialComponentToAssembly WHERE CompToAssemblyUk = @CompToAssemblyUk    	   
END