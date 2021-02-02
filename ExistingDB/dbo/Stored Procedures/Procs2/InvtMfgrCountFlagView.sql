CREATE proc [dbo].[InvtMfgrCountFlagView]
@lcW_key char(10)= null
as
SELECT CountFlag 
	FROM InvtMfgr 
	WHERE W_Key = @lcW_Key 
	AND Is_Deleted <> 1 and countflag<>SPACE(1)
	