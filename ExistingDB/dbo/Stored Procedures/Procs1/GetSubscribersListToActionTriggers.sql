-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 12/19/2017
-- Description:	Get list of subscribers by trigger Action name
-- =============================================
CREATE PROCEDURE GetSubscribersListToActionTriggers 
--declare 
	@trigName varchar(50)
AS
BEGIN
select u.Email, m.triggerName,t.* from wmTriggersActionSubsc t 
inner join MnxTriggersAction m on t.fkActTriggerId=m.actTriggerId
inner join aspnet_Membership u on t.fkUserId=u.userid 
where fkActTriggerId in (select actTriggerId from MnxTriggersAction where triggerName like '%'+@trigname+'%') order by fkActTriggerId,email
END