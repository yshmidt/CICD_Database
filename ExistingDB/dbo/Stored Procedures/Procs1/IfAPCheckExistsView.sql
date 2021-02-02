-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 02/20/2012 
-- Description:	Check if AP check number already exists for a given bank
-- =============================================
CREATE PROCEDURE dbo.IfAPCheckExistsView
	-- Add the parameters for the stored procedure here
	@lcBk_Uniq char(10) =' ',@lcCheckNo char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Apchkmst.APCHK_UNIQ ,apchkmst.CHECKNO FROM APCHKMST WHERE (apchkmst.CHECKNO =@lcCheckNo or apchkmst.CHECKNO=dbo.PADL(@lcCheckNo,10,'0')) and apchkmst.BK_UNIQ=@lcBk_Uniq  
END