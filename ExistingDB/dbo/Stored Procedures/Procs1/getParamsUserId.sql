-- =============================================
-- Author:		Debbie	
-- Create date:	02/05/2016
-- Description:	procedure to get list of ALL Users and pass the UserId from the aspnet_users
-- Modified:	
-- =============================================
create PROCEDURE [dbo].[getParamsUserId] 

--declare
@paramFilter varchar(200) = ''		--- first 3+ characters entered by the user
,@top int = null							-- if not null return number of rows indicated
--,@customerStatus varchar (20) = 'All'
,@userId uniqueidentifier = null

as
begin

if (@top is not null) 
	select  top(@top) A.userid as Value,rtrim(u.name)+', '+ rtrim(u.firstname) AS Text 
	from	aspnet_users A inner join users U on a.UserId = U.fk_aspnetUsers
	order by name,firstname
else
	select  A.userid as Value,rtrim(u.name)+', '+ rtrim(u.firstname) AS Text 
	from	aspnet_users A inner join users U on a.UserId = U.fk_aspnetUsers
	where	1 = case when @paramFilter is null then 1 when a.userid like '%'+@paramFilter+ '%' then 1 else 0 end 
	order by name,firstname
			
end
