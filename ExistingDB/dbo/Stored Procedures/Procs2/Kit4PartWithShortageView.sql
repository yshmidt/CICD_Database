-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <03/22/2010>
-- Description:	<Get information from Kamain for a specific part with open shortage>
---07/24/18 YS added allocatedqty
-- =============================================
CREATE PROCEDURE [dbo].[Kit4PartWithShortageView] 
	-- Add the parameters for the stored procedure here
	@lcUniq_key as char(10)=' ' 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Kamain.Uniq_key, Kamain.Wono, Kaseqnum 
	FROM Woentry, Kamain 
	WHERE Woentry.Wono = Kamain.Wono 
	AND Kamain.Uniq_key = @lcUniq_key
	AND Woentry.KitStatus='KIT PROCSS' 
	---07/24/18 YS added allocatedqty
	AND ((ShortQty>=0 AND Act_qty+allocatedQty>0) OR (ShortQty<0 AND Act_qty+allocatedQty+ShortQty>0))
	
END