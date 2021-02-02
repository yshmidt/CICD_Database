-- =============================================
-- Author:		Vicky Lu	
-- Create date: <02/10/15>
-- Description:	<Check if the serial numbers already exsit in invtser table>
-- =============================================
CREATE PROCEDURE [dbo].[ChkDuplicateMAKEPartSN] 
	-- Add the parameters for the stored procedure here
	@ltSerialno AS tSerialno READONLY
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

SELECT Serialno 
	FROM @ltSerialno
	WHERE Serialno IN 
		(SELECT Serialno 
			FROM INVTSER, Inventor 
			WHERE INVTSER.UNIQ_KEY = INVENTOR.UNIQ_KEY 
			AND INVENTOR.PART_SOURC = 'MAKE')

END