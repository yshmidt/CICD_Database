-- =============================================
-- Author:		Yelena Shmidt	
-- Create date: <10/08/10>
-- Description:	<TrigOpen records fro specific UniqOpen>
-- =============================================
CREATE PROCEDURE dbo.TrigOpenView
	-- Add the parameters for the stored procedure here
	@lcUniqOpen char(10)=NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Trigopen.uniqopen, Trigopen.uniqtrig, Trigopen.cleardttm,
		Trigopen.trigdttm, Trigopen.ref, Trigopen.attachfile
	FROM trigopen WHERE UNIQOPEN=@lcUniqOpen 
	
END
