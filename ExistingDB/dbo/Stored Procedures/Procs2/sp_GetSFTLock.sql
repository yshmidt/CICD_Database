-- =============================================
-- Author:	Sachin B	
-- Create date: 08/17/2016 
-- Description:	this procedure will be used for get SFT Lock position
-- =============================================

CREATE PROCEDURE [dbo].[sp_GetSFTLock] 
AS
BEGIN
SELECT INUPDATE as 'InUpdate' ,UPDATEBY as 'UpdateBy',UPDATETIME as 'UpdateTime',UPDSCREEN 'UpdatedScreen'
	FROM Shopfset
END

