-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 12/19/2017
-- Description:	Add subscribers to Action Triggers
-- =============================================
CREATE PROCEDURE AddSubscribersToActionTriggers 
	-- Add the parameters for the stored procedure here
	--declare 
	@emailAdd nvarchar(max)='',	  --- can add multiple emails coma separated
	@emailRemove nvarchar(max),  -- can remove multiple emails coma separated
	@triggername nvarchar(max)   --- can work with multiple triggers, all emails apply at the same time
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @emailAddList table (email nvarchar(256))

	declare @emailRemoveList table (email nvarchar(256))
	declare @triggers table (triggerName nvarchar(50))

	--- parse email list and triggers

	

	insert into @emailAddList select id from dbo.fn_simpleVarcharlistToTable(@emailadd,',') 

	insert into @emailRemoveList SELECT id from dbo.fn_simpleVarcharlistToTable(@emailRemove,',') 


	insert into @triggers SELECT id from dbo.fn_simpleVarcharlistToTable(@triggername,',') 

	--select * from @emailAddList
	--select * from @emailRemoveList
	--select * from @triggers
	--select userid from aspnet_Membership where email in (select ltrim(email) from @emailAddList)

	--- first remove
	;with T
	as
	(
	select * from MnxTriggersAction m where exists (select 1 from @triggers t where m.triggerName like '%'+t.triggerName+'%')
	)
	--select * from t

	delete from wmTriggersActionSubsc where exists (select 1 from t where t.actTriggerId=fkActTriggerId) 
	and fkuserid in (select userid from aspnet_Membership where email in (select ltrim(email) from @emailRemoveList))

	--- now add

	;with
	newuser
	as
	(
	select actTriggerId, e.UserId,'E' as notificationType
		from MnxTriggersAction m 
		cross apply
		(select userid from aspnet_Membership where email in (select ltrim(email) from @emailAddList)) E
		where exists (select 1 from @triggers t where m.triggerName like '%'+t.triggerName+'%')
		and not exists
		(select 1 from wmTriggersActionSubsc o where o.fkUserId=e.UserId and o.fkActTriggerId=m.ActTriggerId)
	)
	insert into wmTriggersActionSubsc (fkActTriggerId,fkUserId,notificationType) select actTriggerId, UserId,notificationType from newuser
END