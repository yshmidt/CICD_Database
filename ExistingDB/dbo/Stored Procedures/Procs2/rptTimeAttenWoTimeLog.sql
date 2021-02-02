-- =============================================
-- Author:		Debbie	
-- Create date:	02/18/2016
-- Reports:		tmcard4
-- Description:	procedure is used to display the Work Order Time Log Activity
-- Modified:	11/22/16 DRP: needed to change within the procedure itself on how it pulled the data to no longer use the users table.
--				01/13/17 DRP: The TotalTimeSpent was calculating on all work orders selected.  I needed to make sure that it grouped on Work Order number. 						  
-- =============================================
CREATE PROCEDURE [dbo].[rptTimeAttenWoTimeLog] 

--declare
@lcWoNo as varchar(max) = ''
,@userId uniqueidentifier = null


as
begin

/*WORK ORDER LIST*/
		--09/13/2013 DRP:  added code to handle Wo List
			declare @WoNo table(WoNo char(10))
			if @lcWoNo is not null and @lcWoNo <> ''
				insert into @WoNo select * from dbo.[fn_simpleVarcharlistToTable] (@lcWoNo,',')


/*RECORD SELECTION SECTION*/

declare @TimeInfo as table(lnRunTotalTime numeric(15,3),lnSetupTotalTime numeric(15,3),Wono char(10),BldQty numeric(7,0),RunTotalTime numeric(15,3),RoutingHours INT,WcTimeVal numeric(15,2))

declare @logInfo as table (EmployeeName char(35),USERID char(40),SHIFT_DESC CHAR (25),DEPT_NAME CHAR(25),TMLOG_DESC CHAR(20),DATE_IN SMALLDATETIME,DATE_OUT SMALLDATETIME
							,Total_Spent NUMERIC (10,2),WONO char(10),PART_NO char(45), REVISION char(8),BldQty numeric(7,0),COMPLETE NUMERIC (7),BALANCE NUMERIC(7)
							,RoutingHours VARCHAR(10),TMLOG_NO VARCHAR(10),SORT NUMERIC(3),WcTimeVal numeric(10,2))



	--CALCULATE THE TOTAL RUN TIME
	;with zRunTotalTime as (
		SELECT	SUM(RunTimeSec) AS lnRunTotalTime, SUM(SetupSec) AS lnSetupTotalTime, Wono, BldQty
		FROM	Quotdept
				INNER JOIN Woentry ON QUOTDEPT.UNIQ_KEY = WOENTRY.UNIQ_KEY 
		WHERE	1 = case when @lcWono = 'All' then 1 when WOENTRY.WONO IN(select dbo.PADL(WONO,10,'0') from @WoNo) then 1 else 0 end
		GROUP BY wono,bldqty 
		)
	Insert into @TimeInfo	
		select Z.*,z.lnRunTotalTime*z.BLDQTY as RunTotalTime,(z.lnRunTotalTime*z.BLDQTY)+z.lnSetupTotalTime as RoutingHours,round(((z.lnRunTotalTime*z.BLDQTY)+z.lnSetupTotalTime)/3600,2) as WcTimeVal from zRunTotalTime Z
	--select * from @TimeInfo


	--GATHERS THE DETAILED LOG INFORMATION 
	INSERT INTO @logInfo
	select	rtrim(U.LastName) + ', ' + rtrim(u.FIRSTNAME) as EmployeeName,U.USERID,X.SHIFT_DESC,ISNULL(D.DEPT_NAME,'') AS DEPT_NAME,m.TMLOG_DESC,T.DATE_IN,T.DATE_OUT
			,ROUND((Time_used+OverTime)/60,2) AS Total_Spent,T.WONO,I.PART_NO,I.REVISION,W.BLDQTY,W.COMPLETE,W.BALANCE
			,(CASE WHEN LEN (CAST((RoutingHours / 3600) AS VARCHAR(2)))=2 
				THEN CAST((RoutingHours / 3600) AS VARCHAR(2)) 
					ELSE '0' +CAST((RoutingHours / 3600) AS VARCHAR(2)) END
			+
			CASE WHEN LEN (CAST(((RoutingHours % 3600) / 60) AS VARCHAR(2)))=2 
				THEN ':'+ CAST(((RoutingHours % 3600) / 60) AS VARCHAR(2)) 
					ELSE ':0' + CAST(((RoutingHours % 3600) / 60) AS VARCHAR(2)) END 
			+
			CASE WHEN LEN (CAST((RoutingHours % 60) AS VARCHAR(2)))=2 
				THEN ':'+ CAST((RoutingHours % 60) AS VARCHAR(2)) 
					ELSE ':0' + CAST((RoutingHours % 60) AS VARCHAR(2)) END) AS RoutingHours
			,M.TMLOG_NO,m.NUMBER AS SORT,wctimeval
	from	DEPT_LGT T
			--left outer join users U on T.INUSERID = U.fk_aspnetUsers	--11/22/16 DRP:  replaced with the below
			left outer join aspnet_profile U on t.inUserId = u.USERID
			inner join woentry W on T.WONO = W.WONO
			inner join inventor I on W.UNIQ_KEY = I.UNIQ_KEY
			LEFT OUTER JOIN DEPTS D ON T.DEPT_ID = D.DEPT_ID
			left outer join TMLOGTP M on T.TMLOGTPUK = M.TMLOGTPUK
			left outer JOIN WRKSHIFT X ON U.SHIFT_NO = X.SHIFT_NO 
			INNER JOIN @TimeInfo TM ON T.WONO = TM.WONO
	where	1 = case when @lcWono = 'All' then 1 when T.WONO IN(select dbo.PADL(WONO,10,'0') from @WoNo) then 1 else 0 end

--CALCULATING THE TOTALTIMESPENT
	--01/13/17 DRP:  the results were incorrectly totaling the TotaltimeSpent for all WoNo, it needed to be grouped by WONO, removed the below and added changes below in Final Results section
	--declare @lnTotalTimeSpent as numeric(10,2)
	--select	@lnTotalTimeSpent = SUM(TOTAL_SPENT) from @loginfo L

--FINAL RESULTS
	SELECT	L.*,T.TotalTimeSpent,T.TotalTimeSpent-L.WcTimeVal AS TimeVariance
	FROM	@LOGINFO L
			inner JOIN (SELECT WONO,SUM(TOTAL_SPENT) AS TotalTimeSpent FROM  @logInfo GROUP BY WONO) T ON L.WONO = T.WONO
	order by wono,dept_name,employeename,SHIFT_DESC,date_in

	/*--01/13/17 DRP:  replaced with the above 
	--SELECT	L.*,@lnTotalTimeSpent AS TotalTimeSpent,@lnTotalTimeSpent-L.WcTimeVal AS TimeVariance
	--FROM	@LOGINFO L
	--order by wono,dept_name,employeename,SHIFT_DESC,date_in*/

			
end
