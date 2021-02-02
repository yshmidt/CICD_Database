-- =============================================
-- Author:	??	
-- Create date: ??
-- Description:	this procedure will be used for get SFT Lock position
-- Sachin B: 08/17/2016: change datatype of @cUserID from char(8) to uniqueidentifier
-- =============================================

CREATE PROCEDURE [dbo].[sp_LockShopFlag] 
@cUserID uniqueidentifier,
@cUpdScreen char(20)--, @Return bit = 0 OUTPUT
AS
BEGIN

-- 05/06/14 VL remove @Return bit = 0 OUTPUT, make it as variable, also will return who placed the lock info to show on form
DECLARE @lIs_Lock bit, @Return bit = 0

SELECT @lIs_Lock = InUpdate 
	FROM ShopFSet

BEGIN
IF @lIs_Lock = 1
	BEGIN	
	
	-- Is locked already, return 0
	SET @Return = 0;
	
	END
ELSE
	BEGIN
	
	-- Not lock yet, can place lock and return 1
	UPDATE SHOPFSET
		SET INUPDATE = 1,
			UPDATEBY = @cUserID,
			UPDATETIME = GETDATE(),
			UPDSCREEN = @cUpdScreen;
			
	SET @Return = 1;
	
	END
END

-- Return the result of the function
SELECT @Return AS InUpdate, UpdateBy as UpdateBy, updateTime as UpdateTime, UpdScreen  as UpdatedScreen
	FROM Shopfset


END