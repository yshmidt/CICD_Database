-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 09/24/2012
-- Description:	get Gl_nbrs with Note only
-- =============================================
CREATE PROCEDURE dbo.Gl_nbrs_note_view
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT GL_NBR,Gl_note FROm GL_NBRS WHERE GL_CLASS = 'Posting'
END
