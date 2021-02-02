-- =============================================
-- Author:		Debbie	
-- Create date:	11/20/15
-- Description:	procedure to get list of Users that are not Supervisors
-- Modified:	
-- 03/31/2020 VL changed to not user users table, only use aspnet_profile table
-- =============================================
CREATE PROCEDURE [dbo].[getParamsUsers] 

--declare
@paramFilter varchar(200) = ''		--- first 3+ characters entered by the user
,@top int = null							-- if not null return number of rows indicated
,@customerStatus varchar (20) = 'All'
,@userId uniqueidentifier = null

as
begin

if (@top is not null) 
	select  top(@top) P.userid as Value,rtrim(P.LastName)+', '+ rtrim(P.firstname) AS Text 
	from	aspnet_Profile P
	order by LastName,firstname
else
	select  P.userid as Value,rtrim(P.Lastname)+', '+ rtrim(P.firstname) AS Text 
	from	aspnet_Profile P
	where	1 = case when @paramFilter is null then 1 when P.userid like '%'+@paramFilter+ '%' then 1 else 0 end 
	order by Lastname,firstname
			
end

