-- =============================================
-- Author:		Debbie	
-- Create date:	02/05/2016
-- Description:	procedure to get list of the Time & Attendance Types for parameter selection
-- Modified:	
-- =============================================
create PROCEDURE [dbo].[getParamsTimeAttenType] 


--declare
@paramFilter varchar(200) = ''		--- first 3+ characters entered by the user
,@top int = null							-- if not null return number of rows indicated
--,@customerStatus varchar (20) = 'All'
,@userId uniqueidentifier = null

as
begin

if (@top is not null) 
	select  top(@top) t.TMLOGTPUK as Value,t.TMLOG_DESC AS Text 
	from	tmlogtp T
	order by NUMBER
else
	select  t.tmlogtpuk as Value,t.TMLOG_DESC as text 
	from	tmlogtp T
	where	1 = case when @paramFilter is null then 1 when t.TMLOGTPUK like '%'+@paramFilter+ '%' then 1 else 0 end 
	order by number
			
end