-- =============================================
-- Author:		Yelena Shmidt	
-- Create date: <10/08/10>
-- Description:	<Collect e-mail address for a specific trigger>
-- =============================================
CREATE PROCEDURE dbo.EmailAddress4triggerView
	-- Add the parameters for the stored procedure here
	@lcUniqTrig char(10)=NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Email.Email AS ToAdr, ISNULL(Msg,' ') as Msg, Email.UniqEMail 
		FROM EMail, TrigDetl LEFT OUTER JOIN TrigMessages 
		ON TrigDetl.Uniq_Msg = TrigMessages.Uniq_Msg 
		WHERE TrigDetl.UniqTrig = @lcUniqTrig 
		AND Email.UniqEMail = TrigDetl.UniqEMail 	
END
