CREATE PROCEDURE [dbo].[ApRecurView] 
	-- Add the parameters for the stored procedure here
@gcUniqRecur as Char(10)=''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
SELECT Aprecur.*, Supinfo.supname
 FROM aprecur 
    INNER JOIN supinfo 
   ON  Supinfo.uniqsupno = Aprecur.uniqsupno
WHERE ApRecur.UniqRecur = @gcUniqRecur
END