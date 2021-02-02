-- =============================================
-- Author:		Yelena Shmidt	
-- Create date: <10/08/10>
-- Description:	<Use to update TrigSent>
-- =============================================
CREATE PROCEDURE dbo.TrigSentView
	-- Add the parameters for the stored procedure here
	@lcUniqtrsent char(10)=NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Trigsent.uniqtrsent, Trigsent.uniqopen, Trigsent.uniqemail,
		Trigsent.dttimesent
	FROM trigsent WHERE UniqTrSent=@lcUniqtrsent 
END
