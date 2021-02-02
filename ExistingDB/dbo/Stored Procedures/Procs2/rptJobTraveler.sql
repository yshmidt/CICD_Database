
-- =============================================
-- Author:		Debbie
-- Create date: 05/02/2012
-- Description:	Created for Job Traveler reports within the Shop Floor Tracking module
-- Reports Using Stored Procedure:  jobtravw.rpt // jobtrvaa.rpt // jobtrvaw.rpt // jobtrvwa.rpt // jobtrvwi.rpt
-- Modified:  01/15/2014 DRP:  added the @userid parameter for WebManex
--			03/02/2015 DRP:  Changed from @lcTimeFormat to be @llDecimal so that I can use the already existing cloud parameter
--							 Rearranged some of the fields to work better with the QuickViews.  Took care of some of the Null Values.  Added the /*CUSTOMER LIST*/ 
-- Modified: 09/18/17 YS added JobType to Woentry table to separate Status (OpenClos) from Type
-- =============================================


CREATE PROCEDURE [dbo].[rptJobTraveler]
--declare
		@lcWoNo as char (10) = null
		,@llDecimal char(3) = 'Yes'	--Yes:  display results in Decimal format, No: display the results in hour format
		--,@lcTimeFormat as char (1) = 'Y'	03/02/2015 DRP:  Replaced by the above. 
		,@userId uniqueidentifier= null
		
as
begin


/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer

		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer	
		

select	rtrim(dept_qty.dept_id)dept_id,dept_qty.deptkey,depts.DEPT_NAME,isnull(actv_qty.ACTIV_ID,'') as ACTIV_ID,ISNULL(activity.ACTIV_NAME,'') AS ACTIV_NAME,quotdept.number,ISNULL(ACTV_QTY.NUMBERA,'0') AS NUMBERA
		,case when @llDecimal = 'Yes' then STR(ROUND(SETUPSEC/3600,3),7,3) else dbo.PADL(RTRIM(LTRIM(STR(FLOOR(SETUPSEC/3600)))),3,' ')+':'+
			dbo.PADL(RTRIM(LTRIM(STR(FLOOR((SETUPSEC-FLOOR(SETUPSEC/3600)*3600)/60)))),2,'0') + ':'+
				dbo.PADL(RTRIM(LTRIM(STR((SETUPSEC-FLOOR(SETUPSEC/3600)*3600) % 60,6,3))),6,'0') end as Setup
		,case when @llDecimal = 'Yes' then STR(ROUND(Runtimesec/3600,3),7,3) else 
			dbo.PADL(RTRIM(LTRIM(STR(FLOOR(Runtimesec/3600)))),3,' ')+':'+
				dbo.PADL(RTRIM(LTRIM(STR(FLOOR((Runtimesec-FLOOR(Runtimesec/3600)*3600)/60)))),2,'0') + ':'+
					dbo.PADL(RTRIM(LTRIM(STR((Runtimesec-FLOOR(Runtimesec/3600)*3600) % 60,6,3))),6,'0') end as Run
		,case when @llDecimal = 'Yes' then str(round((RUNTIMESEC/3600*BLDQTY)+SETUPSEC/3600,3),7,3) else 
			dbo.PADL(RTRIM(LTRIM(STR(FLOOR((Runtimesec/3600*bldqty)+setupsec/3600)))),3,' ')+':'+
				dbo.PADL(RTRIM(LTRIM(STR(FLOOR(((Runtimesec*BLDQTY)+setupsec-FLOOR((Runtimesec/3600*bldqty)+setupsec/3600)*3600)/60)))),2,'0') + ':'+
					dbo.PADL(RTRIM(LTRIM(STR(((Runtimesec*bldqty)+SETUPSEC-FLOOR((Runtimesec/3600*bldqty)+setupsec/3600)*3600) % 60,6,3))),6,'0')end as Total
		,ISNULL(case when @llDecimal = 'Yes' then STR(ROUND(SETUPASEC/3600,3),7,3) else 
			dbo.PADL(RTRIM(LTRIM(STR(FLOOR(SETUPASEC/3600)))),3,' ')+':'+
				dbo.PADL(RTRIM(LTRIM(STR(FLOOR((SETUPASEC-FLOOR(SETUPASEC/3600)*3600)/60)))),2,'0') + ':'+
					dbo.PADL(RTRIM(LTRIM(STR((SETUPASEC-FLOOR(SETUPASEC/3600)*3600) % 60,6,3))),6,'0')end,0.00) as ActvSetup
		,ISNULL(case when @llDecimal = 'Yes' then STR(ROUND(RUNTIMASEC/3600,3),7,3) else dbo.PADL(RTRIM(LTRIM(STR(FLOOR(RUNTIMASEC/3600)))),3,' ')+':'+
			dbo.PADL(RTRIM(LTRIM(STR(FLOOR((RUNTIMASEC-FLOOR(RUNTIMASEC/3600)*3600)/60)))),2,'0') + ':'+
				dbo.PADL(RTRIM(LTRIM(STR((RUNTIMASEC-FLOOR(RUNTIMASEC/3600)*3600) % 60,6,3))),6,'0') end,0.00) as ActvRun
		,ISNULL(case when @llDecimal = 'Yes' then str(round((RUNTIMASEC/3600*BLDQTY)+SETUPASEC/3600,3),7,3) else 
			dbo.PADL(RTRIM(LTRIM(STR(FLOOR((Runtimasec/3600*bldqty)+setupasec/3600)))),3,' ')+':'+
				dbo.PADL(RTRIM(LTRIM(STR(FLOOR(((Runtimasec*BLDQTY)+setupasec-FLOOR((RUNTIMASEC/3600*bldqty)+setupasec/3600)*3600)/60)))),2,'0') + ':'+
					dbo.PADL(RTRIM(LTRIM(STR(((Runtimasec*bldqty)+SETUPASEC-FLOOR((RUNTIMASEC/3600*bldqty)+SETUPASEC/3600)*3600) % 60,6,3))),6,'0')end,0.00) as ActvTotal
		,QUOTDEPT.STD_INSTR,quotdept.SPEC_INSTR,ISNULL(QUOTDPDT.STD_INSTR,'') AS ActvStdInstr,ISNULL(quotdpdt.SPEC_INSTR,'') as ActvSpecInstr,woentry.WONOTE
		,dept_qty.wono,woentry.due_date,woentry.openclos,CUSTNAME,woentry.UNIQ_KEY,part_no,revision,inventor.DESCRIPT,inventor.PROD_ID,part_class,part_type,inventor.matltype,inventor.PERPANEL
		,woentry.BLDQTY,case when inventor.perpanel = 0.00 then woentry.BLDQTY else cast(woentry.bldqty/inventor.perpanel as numeric (7,0))end as PnlBlank
		,woentry.sono,isnull(somain.pono,'')as pono	
		-- Modified: 09/18/17 YS added JobType to Woentry table to separate Status (OpenClos) from Type
	,Woentry.JobType
	from	
	DEPT_QTY
		left outer join ACTV_QTY on dept_qty.WONO+dept_qty.DEPTKEY = actv_qty.wono+actv_qty.DEPTKEY
		inner join WOENTRY on DEPT_QTY.wono = woentry.wono
		inner join customer on woentry.CUSTNO = customer.CUSTNO
		inner join INVENTOR on woentry.UNIQ_KEY = inventor.UNIQ_KEY
		left outer join somain on woentry.sono = somain.sono
		inner join quotdept on dept_qty.DEPTKEY = QUOTDEPT.UNIQNUMBER
		inner join DEPTS on dept_qty.DEPT_ID = depts.DEPT_ID
		left outer join ACTIVITY on actv_qty.ACTIV_ID = activity.ACTIV_ID
		LEFT OUTER JOIN QUOTDPDT ON ACTV_QTY.ACTVKEY = QUOTDPDT.UNIQNBRA
		

where	woentry.wono = dbo.padl(@lcWoNo,10,'0')
		and 1 = case when Customer.CUSTNO in (select CUSTNO from @tCustomer ) then 1 else 0 end
	

order by number

end