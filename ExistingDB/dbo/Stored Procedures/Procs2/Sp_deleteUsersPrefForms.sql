
-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <05/09/11>
-- Description:	<Integrate with new age project>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_deleteUsersPrefForms]
	-- Add the parameters for the stored procedure here
	@iUniqueUPFA INT = NULL
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    BEGIN TRANSACTION
	DELETE FROM UsersPrefForms
      WHERE UniqueUPFA=@iUniqueUPFA 
    COMMIT  
END      

