-- =============================================
-- Author:		Vicky Lu	
-- Create date: <02/10/15>
-- Description:	<Check if the serial numbers already exsit in invtser table for the same uniq_key>
-- Modification: 02/11/15 VL changed from using tSerialnoUniq_key to SerialnoValidate
-- =============================================
CREATE PROCEDURE [dbo].[ChkDuplicateMAKEPartSNbyPART] 
	-- Add the parameters for the stored procedure here
	@ltSerialnoUniq_key AS SerialnoValidate READONLY
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

DECLARE @lUniq_key char(10) = ' '
SELECT @lUniq_key = Uniq_key FROM @ltSerialnoUniq_key

SELECT Serialno 
	FROM @ltSerialnoUniq_key
	WHERE Serialno IN 
		(SELECT Serialno 
			FROM INVTSER  
			WHERE INVTSER.UNIQ_KEY = @lUniq_key)

END