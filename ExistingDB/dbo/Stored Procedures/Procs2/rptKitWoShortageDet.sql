
-- =============================================
-- Author:		Debbie
-- Create date:	05/18/2015
-- Description:	Created for the Work Order Detail Shortage Report within Kitting
-- Reports:		shrtwodt.rpt 
-- Modifications:	--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 07/16/18 VL changed custname from char(35) to char(50)
-- =============================================
CREATE PROCEDURE [dbo].[rptKitWoShortageDet]

--declare

		@lcWono AS char(10) = ''
		,@userId uniqueidentifier =''

--PARAMETER EXPLANATION:
--1.  @lcWoNo:  the Work Order number


AS
BEGIN


/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer

		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer	





SET @lcWono=dbo.PADL(@lcWoNo,10,'0')
--@T table will be populated with the Work Order header information
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 07/16/18 VL changed custname from char(35) to char(50)
		DECLARE @t TABLE	(WoNo char(10),DueDt smalldatetime,WoBldQty numeric(7,0),ParentPartNo CHAR (35),ParentRev CHAR(8),Parent_Desc char (45),ParentUniqkey CHAR (10)
							,ParentMatlType char(10),ParentBomCustNo char(10),ParentCustName char(50),PUseSetScrap bit,PStdBldQty numeric(8),WoStatus char(10),KitStatus char(10))	

		INSERT @T	select	wono,DUE_DATE,BLDQTY,part_no,revision,descript,woentry.UNIQ_KEY,matltype,BOMCUSTNO,isnull(custname,''),USESETSCRP,STDBLDQTY,OPENCLOS,KITSTATUS
					from	woentry
							inner join inventor on woentry.UNIQ_KEY = inventor.UNIQ_KEY 
							left outer join CUSTOMER on woentry.CUSTNO = customer.CUSTNO 
					where	woentry.wono = @lcWoNo 
							AND PART_SOURC <> 'CONSG'
							and  EXISTS (SELECT 1 FROM @tCustomer PC where PC.custno=WOENTRY.CUSTNO)

							--select * from @t
--I am delcaring the parameters that would be needed to pull the information from the KitBomView Procedure
		declare	@lcUniq_key char(10) 
				,@lcDueDt smalldatetime
		--populate the parameter with the uniq_key and DueDate for the Work order Product 				
				select	@lcUniq_key = t1.ParentUniqKey
						,@lcDueDt = t1.DueDt 
				from	@t as t1

--delcaring the below table so I can pull all of the information from the KitBomView Procedure	
--- 03/28/17 YS changed length of the part_no column from 25 to 35
		DECLARE @ZKitBom TABLE (Ignorekit char (1), Item_no numeric(4,0), Part_no char(35), Revision char(8), CustPartno char(35),
				CustRev char(8), Qty numeric(9,2), ReqQty numeric(12,2), IssuedQty numeric(12,2), ShortQty numeric(12,2),
				Part_Sourc char(10), ChildUniq_key char(10), Descript char(63), UniqBomNo char(10), Kaseqnum char(10), 
				Eff_dt smalldatetime, Term_dt smalldatetime,LineShort bit,Dept_id char(4));

		insert @ZKitBom exec KitBomView @lcWono, @lcUniq_key,@lcDueDt,''
			--1.  @gWono:  Taking the Work order # from the declared parameter above
			--2.  @gUniq_key:  This is the uniq_key of the product
			--3.  @ldDue_date:  This is the Work Order Due Date
			--4.  @cDept_id:  This would be populated with the DeptID, but for this procedure we are leaving it blank '' so that all Depts are pulled fwd

			--select * from @ZKitBom

; with tResults as
(
--The first section below I am gathering the information from the KitBomView created by Vicky, plus I am adding additional information that I need for the Report puposes.	
		select	CAST(dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY k1.kaseqnum) as varchar(max))),4,'0') as varchar(max)) AS Sort,case when K1.lineshort = 1 then cast ('LS' as char(2)) else CAST('' as CHAR(2)) end as LineShort
				,case when K1.Ignorekit = 'X' then cast('Y' as char(1)) else cast('' as char(1)) end as IgnoreKit
				,K1.Item_no,case when K1.part_sourc = 'CONSG' then K1.CustPartNo else K1.Part_no end as PartNo
				,case when k1.Part_sourc = 'CONSG' then K1.CustRev else K1.Revision end as Revision
				,K1.Qty,K1.ReqQty,K1.IssuedQty as TotalIssueQty,Kadetail.ShortQty,AUDITDATE,KADETAIL.SHORTBAL,KADETAIL.AUDITBY,KADETAIL.SHREASON,DEPT_NAME
				,KADETAIL.SHQUALIFY,K1.Part_Sourc,K1.ChildUniq_key,I1.Part_Class,I1.Part_type,I1.Descript,K1.UniqBomNo,K1.Kaseqnum,K1.Eff_dt,K1.Term_dt
				,case when I1.UNIQ_KEY <> @lcUniq_key and I1.PART_SOURC = 'MAKE' and I1.MAKE_BUY = 1 then CAST('Make/Buy' as CHAR(8)) else cast('' as CHAR(8))  end as MbPhSource
				,i1.SCRAP,i1.SETUPSCRAP,T1.*
		from	@zKitBom as K1
				left outer join inventor as I1 on K1.ChildUniq_key = I1.uniq_key
				left outer join KADETAIL on k1.Kaseqnum = KADETAIL.KASEQNUM
				inner join DEPTS on k1.Dept_id = DEPTS.DEPT_ID
				cross join @t as T1		
		where	k1.Kaseqnum <> '' 


--Then I union the below to add any Misc Items that might have been added to the kit
		union

		select	CAST('' as varchar(max)) as Sort,cast ('MS' as char(2)) as SpecFlag,cast('' as char) as Ignorekit,cast (0 as numeric(4,0)) as Item_no,M1.Part_no, M1.Revision
				,M1.Qty,cast (0.00 as numeric (12,2)) as ReqQty, cast(0.00 as numeric(12,2)) as TotalIssuedQty,M1.ShortQty,null as AuditDate
				,m1.SHORTQTY as ShortBal,m1.cSavedBy, m1.SHREASON,DEPT_name,m1.cSavedBy,M1.Part_Sourc,cast ('' as char (10)) as ChildUniq_key,M1.Part_Class,M1.Part_type
				,M1.Descript,M1.MISCKEY as UniqBomNo, cast('' as char(10)) as Kaseqnum,null as Eff_dt,null as Term_dt
				,cast ('' as char(8)) as MbPhSource,cast (0.00 as numeric(6,2)) as SCRAP,cast (0 as numeric (4,0)) as SETUPSCRAP,T1.*
		from	MISCMAIN as M1
				inner join DEPTS on m1.Dept_id = DEPTS.DEPT_ID
				cross join @t as T1
		where	M1.WONO = @lcWoNo
)

select * from tResults order by Kaseqnum,AUDITDATE	

end