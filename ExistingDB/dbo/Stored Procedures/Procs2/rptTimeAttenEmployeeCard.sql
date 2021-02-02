-- =============================================
-- Author:		Debbie	
-- Create date:	02/05/2016
-- Reports:		tmcard1 (tmcard2 is now combined into tmcard1)
-- Description:	procedure is used to display the Employee time card detail based upon the Department or Time Log Type the user selects
-- Modified:	VFP used to force the users to either select by Work Center or by Department.  Then they were only allowed to select one of those records at a time. 
--				In SQL it will have parameter selection available for both the Work Center and Department and the users can decide to display all or select specific ones for the listing
--				then the report will group off of the TMLOG_DESC and Dept_name next. 
--				11/22/16 DRP:  needed to change the /*USER LIST*/ section to pull the user name info from the aspnet_profile table instead of the users table.
--								also needed to change within the procedure itself on how it pulled the data to no longer use the users table. 
-- 10/04/17 VL changed from name char(15), firstname char(15) to char(35) for @tUsers table
-- =============================================
CREATE PROCEDURE [dbo].[rptTimeAttenEmployeeCard] 

--declare
	@lcDateStart as smalldatetime= null
	,@lcDateEnd as smalldatetime = null
	,@lcDeptId as varchar(max) = 'ALL'		-- work center	
	,@lcUserId as varchar(max)= 'All'		-- user the person wishes to view time card detail
	,@lcTmLogType as varchar(max) = 'ALL'	-- Time & Attendance Types (example:  user would select Time Clock, Holiday, etc. . . )
	,@lcRptType as char(10) = 'Summary'	-- (Detailed or Summary)  Added for Quickview results so it knows to display detailed or summary results. 
	,@userId uniqueidentifier=null
	

as 
begin

/*POPULATES THE DATE RANGE INFORMATION*/
SELECT @lcDateStart=CASE WHEN @lcDateStart is null then @lcDateStart else cast(@lcDateStart as smalldatetime)  END,
			@lcDateEnd=CASE WHEN @lcDateEnd is null then @lcDateEnd else DATEADD(day,1,cast(@lcDateEnd as smalldatetime))  END

/*DEPARTMENT LIST*/		
	DECLARE  @tDepts as tDepts
		DECLARE @Depts TABLE (dept_id char(4))
		-- get list of Departments for @userid with access
		INSERT INTO @tDepts (Dept_id,Dept_name,[Number]) EXEC DeptsView @userid ;
		--SELECT * FROM @tDepts	
		IF @lcDeptId is not null and @lcDeptId <>'' and @lcDeptId<>'All'
			insert into @Depts select * from dbo.[fn_simpleVarcharlistToTable](@lcDeptId,',') 
					where CAST (id as CHAR(4)) in (select Dept_id from @tDepts)
		ELSE

		IF  @lcDeptId='All'	
		BEGIN
			INSERT INTO @Depts SELECT Dept_id FROM @tDepts
		END


/*TIME LOG TYPE LIST*/
	DECLARE @tTmLogType as table (TMLOG_DESC CHAR(20),TMLOGTPUK CHAR(10))
		DECLARE @TmLogType as table(TMLOGTPUK CHAR(10))
	INSERT INTO @tTmLogType SELECT TMLOG_DESC,TMLOGTPUK FROM TMLOGTP

	IF @lcTmLogType is not null and @lcTmLogType <>'' and @lcTmLogType<>'All'
			insert into @TmLogType select * from dbo.[fn_simpleVarcharlistToTable](@lcTmLogType,',') 
					where CAST (id as CHAR(10)) in (select TMLOGTPUK from @tTmLogType)
		ELSE

		IF  @lcTmLogType='All'	
		BEGIN
			INSERT INTO @TmLogType SELECT TMLOGTPUK FROM @tTmLogType
		END



/*USER LIST*/
	-- 10/04/17 VL changed from name char(15), firstname char(15) to char(35) 
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

--select * from @users




/*RECORD SELECTION SECTION*/

DECLARE @TimeCard as table (EmployeeName char(35),USERID char(40),DEPT_NAME CHAR(25),TMLOG_DESC CHAR(20),DATE_IN SMALLDATETIME,DATE_OUT SMALLDATETIME
							,REGULAR_TIME NUMERIC (10,2),OVERTIME NUMERIC(10,2),OTHER_TIME NUMERIC(10,2),TMLOG_NO VARCHAR(10),WONO CHAR(10),SORT NUMERIC(3))



INSERT INTO @TimeCard
	select	rtrim(U.LastName) + ', ' + rtrim(u.FIRSTNAME) as EmployeeName
			,U.USERID
			,ISNULL(D.DEPT_NAME,'') AS DEPT_NAME,m.TMLOG_DESC,T.DATE_IN,T.DATE_OUT
			,ROUND(Time_used/60,2) AS Regular_time,ROUND(OverTime/60,2) AS OverTime,0.00 AS Other_time,M.TMLOG_NO,T.WONO,m.NUMBER AS SORT
	from	DEPT_LGT T
			--left outer join users U on T.INUSERID = U.fk_aspnetUsers	--11/22/16 DRP:  replaced with the below
			left outer join aspnet_profile U on T.inuserid = U.userid
			LEFT OUTER JOIN DEPTS D ON T.DEPT_ID = D.DEPT_ID
			left outer join TMLOGTP M on T.TMLOGTPUK = M.TMLOGTPUK
	where	--T.inUserId = @lcUserId
			 date_in >= @lcDateStart 
			and date_out <= @lcDateEnd
			and (@lcDeptid='All' OR exists (select 1 from @Depts B where B.dept_id=T.DEPT_ID))
			and (@lcTmLogType='All' OR exists (select 1 from @TmLogType F where F.TMLOGTPUK=T.TMLOGTPUK))
			and (@lcUserId='All' OR exists (select 1 from @Users U2 where U2.userid=T.inUserId))
			AND M.TMLOG_NO = 'T'

UNION
	select	rtrim(U.LastName) + ', ' + rtrim(u.FIRSTNAME) as EmployeeName,U.USERID,ISNULL(D.DEPT_NAME,'') AS DEPT_NAME,m.TMLOG_DESC,T.DATE_IN,T.DATE_OUT
			,0.00 AS Regular_time,0.00 AS OverTime,ROUND(TIME_USED/60,2) AS Other_time,M.TMLOG_NO,T.WONO,M.NUMBER AS SORT
	from	DEPT_LGT T
			--left outer join users U on T.INUSERID = U.fk_aspnetUsers	--11/22/16 DRP:  replaced with the below
			left outer join aspnet_profile U on T.inuserid = U.userid
			LEFT OUTER JOIN DEPTS D ON T.DEPT_ID = D.DEPT_ID
			left outer join TMLOGTP M on T.TMLOGTPUK = M.TMLOGTPUK
	where	--T.inUserId = @lcUserId
			 date_in >= @lcDateStart 
			and date_out <= @lcDateEnd
			and (@lcDeptid='All' OR exists (select 1 from @Depts B where B.dept_id=T.DEPT_ID))
			and (@lcTmLogType='All' OR exists (select 1 from @TmLogType F where F.TMLOGTPUK=T.TMLOGTPUK))
			and (@lcUserId='All' OR exists (select 1 from @Users U2 where U2.userid=T.inUserId))
			AND M.TMLOG_NO <> 'T'


if (@lcRptType = 'Detailed')
begin  --&&Detailed Begin
	SELECT E.*,REGULAR_TIME+OVERTIME+OTHER_TIME AS TOTAL_TIME  FROM @TIMECARD E ORDER BY EmployeeName,SORT
end		--&&Detailed End

else if (@lcRptType = 'Summary')
begin --&&Summary Begin
	SELECT	EmployeeName,USERID,DEPT_NAME,TMLOG_DESC,SUM(REGULAR_TIME) AS REGULAR_TIME,SUM(OVERTIME) AS OVERTIME,SUM(OTHER_TIME) AS OTHER_TIME, SUM(REGULAR_TIME+OVERTIME+OTHER_TIME) AS TOTAL_TIME,SORT  
	FROM	@TIMECARD E
	GROUP BY  EmployeeName,USERID,DEPT_NAME,TMLOG_DESC,SORT
	ORDER BY EmployeeName,SORT	

END	--&&Summary Begin

end