-- =============================================
-- Author:		Rajendra K	
-- Create date: <07/26/2017>
-- Description:Get GetWKey
-- exec GetWKey 'nrknrknrkn','_01F0NBJHR','nrknrknrkk'
-- =============================================
CREATE PROCEDURE [dbo].[GetWKey]
(	
 @UniqKey char(10)='', 
 @WKey char(10)='', 
 @UniqWH char(1)=''		
)
AS
BEGIN
   SET NOCOUNT ON
	-- Declare and set UniqMfgrHd from WKey
	DECLARE @UniqMfgrHd CHAR(10) = (SELECT UNIQMFGRHD FROM InvtMfgr WHERE W_KEY = @WKey)
	
	-- Declare table variable for W_Key
	DECLARE @WkeyTemp TABLE(
				W_Key CHAR(10) NOT NULL
				)
	
	-- Check record exist in Invtmfgr table for parameter @UniqMfgrHd and @UniqWH ,If record not exists add new record in InvtMfgr table
	IF NOT EXISTS (SELECT 1 FROM InvtMfgr WHERE UNIQWH = @UniqWH AND UNIQMFGRHD = @UniqMfgrHd)
	BEGIN
	-- Add new record in InvtMfgr table
	INSERT INTO InvtMfgr(W_Key,Uniq_Key,Uniqmfgrhd,Uniqwh)
	 OUTPUT inserted.W_Key INTO @WkeyTemp -- Get W_Key from inserted record
	 SELECT dbo.fn_GenerateUniqueNumber(),@UniqKey,@UniqMfgrHd,@UniqWH 
	
	-- Set WKey
	 SET @WKey = (SELECT W_Key FROM @WkeyTemp)
	END

	SELECT @WKey AS WKey
END