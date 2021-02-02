-- =============================================
-- Author:		Debbie	
-- Create date:	02/18/2016
-- Reports:		tmcard3
-- Description:	procedure is used to display Employee Work Order & Work Center Activity Detail
-- Modified:		11/22/16 DRP:  needed to change the /*USER LIST*/ section to pull the user name info from the aspnet_profile table instead of the users table.
--								also needed to change within the procedure itself on how it pulled the data to no longer use the users table.  
-- 10/04/17 VL changed from name char(15), firstname char(15) to char(35) for @tUsers table
-- =============================================
CREATE PROCEDURE [dbo].[rptTimeAttenEmpWoWcActivityDetail] 

--declare
	@lcDateStart as smalldatetime= null
	,@lcDateEnd as smalldatetime = null
	,@lcUserId as varchar(max)= null		-- user the person wishes to view time card detail
	,@userId uniqueidentifier=null


as
begin

/*USER LIST*/
	-- 10/04/17 VL changed from name char(15), firstname char(15) to char(35) for @tUsers table
	DECLARE @tUsers table (UserId char(40),name char(35),firtname char(35))
		DECLARE @Users table (UserId char(40))
	--insert into @tUsers select cast(A.USERID as char(40)),users.name,users.FIRSTNAME from aspnet_Users A left outer join  users on A.UserName= users.USERID	--11/22/16 DRP:  replaced with the below
		insert into @tUsers select cast(A.USERID as char(40)),P.LastName,P.FirstName from aspnet_Users A inner join aspnet_profile P on A.UserId= P.USERID

	if (@lcUserId is not null and @lcUserId <> '' and @lcUserId <>'All')
		insert into @Users select * from dbo.[fn_simpleVarcharlistToTable](@lcUserId,',') 
	
	else
	if @lcUserId = 'All'
	Begin
		insert into @Users select userId from @tUsers
	end



/*RECORD SELECTION SECTION*/
select	rtrim(U.Lastname) + ', ' + rtrim(u.FIRSTNAME) as EmployeeName,U.USERID,ISNULL(D.DEPT_NAME,'') AS DEPT_NAME,m.TMLOG_DESC,DC.DATE_IN,DC.DATE_OUT
		,ROUND((Time_used+OverTime)/60,2) AS Total_Hours,M.TMLOG_NO,DC.WONO,m.NUMBER AS SORT
from	(select * from dept_cur where  Date_in is not null and date_out is not null)  DC 
		--left outer join users U on DC.INUSERID = U.fk_aspnetUsers	--11/22/16 DRP:  replaced with the below
		inner join aspnet_profile U on DC.inuserid = U.userid
		LEFT OUTER JOIN DEPTS D ON DC.DEPT_ID = D.DEPT_ID
		left outer join TMLOGTP M on DC.TMLOGTPUK = M.TMLOGTPUK
where	datediff(day,date_in,@lcDateStart)<=0 and datediff(day,date_out,@lcDateEnd)>=0
		AND Date_out >= Date_in 
		and (@lcUserId='All' OR exists (select 1 from @Users U2 where U2.userid=DC.inUserId))

union

select	rtrim(U.lastname) + ', ' + rtrim(u.FIRSTNAME) as EmployeeName,U.USERID,ISNULL(D.DEPT_NAME,'') AS DEPT_NAME,m.TMLOG_DESC,DL.DATE_IN,DL.DATE_OUT
		,ROUND((Time_used+OverTime)/60,2) AS Total_Hours,M.TMLOG_NO,DL.WONO,m.NUMBER AS SORT
from	(select * from dept_lgt where  Date_in is not null and date_out is not null)  DL 
		--left outer join users U on DL.INUSERID = U.fk_aspnetUsers	--11/22/16 DRP:  replaced with the below
		inner join aspnet_profile U on DL.inuserid = U.userid
		LEFT OUTER JOIN DEPTS D ON DL.DEPT_ID = D.DEPT_ID
		left outer join TMLOGTP M on DL.TMLOGTPUK = M.TMLOGTPUK
where	datediff(day,date_in,@lcDateStart)<=0 and datediff(day,date_out,@lcDateEnd)>=0
		AND Date_out >= Date_in 
		and (@lcUserId='All' OR exists (select 1 from @Users U2 where U2.userid=DL.inUserId))

order by EmployeeName,wono,dept_name

end