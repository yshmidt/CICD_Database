-- =============================================
-- Author:	??	
-- Create date: ??
-- Description:	this procedure will be unlock the ShopFlag
-- Sachin B: 08/17/2016: While unlock set updateTime by GetDate() and updatedby empty Guid
--- 09/20/17 YS By adding @cUserID it distrupts work of the work order module in the desk top. I don't see the user id is used anywhere here
-- I will assign default value for now
-- =============================================

CREATE PROCEDURE [dbo].[sp_UnLockShopFlag]
@cUserID uniqueidentifier = NULL
AS
BEGIN
-- Sachin B: 08/17/2016: While unlock set updateTime by GetDate() and updatedby empty Guid
	UPDATE SHOPFSET
		SET INUPDATE = 0,
			UPDATEBY = '00000000-0000-0000-0000-000000000000',
			UPDATETIME = GETDATE(),
			UPDSCREEN = ''
END