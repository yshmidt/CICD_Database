-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE dbo.usp_validateserialnbrs
	-- Add the parameters for the stored procedure here
	(
	@SerialnoTable SerialnoValidate Readonly 
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	

    -- Insert statements for procedure here
    SELECT * FROM @SerialnoTable
	SELECT INVTSER.SERIALUNIQ,INVTSER.Serialno 
		from INVTSER WHERE UNIQ_KEY+SERIALNO IN (SELECT UNIQ_KEY+SERIALNO FROm @SerialnoTable) 
	

END