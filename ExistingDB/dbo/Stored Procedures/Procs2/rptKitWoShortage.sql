
-- =============================================
-- Author:		Debbie
-- Create date: 08/30/2012
-- Description:	Created for the Work Order Shortage Report within Kitting
-- Reports Using Stored Procedure:  shrtwosu.rpt 
-- Modifications:	10/02/2012 DRP:  Found that the Parent_desc within the @T table was only set to Char(40) and it needed to be Char(45) otherwise it could have truncate issues.
--					10/29/2012 DRP:  Due to some changes within Crystal Report I changed @lcIgnore = '' to @lcIgnore = 'No' 
--					06/05/2015 DRP:  Needed to add Dept_Id to the @ZKitBom section 
--					09/10/15 DRP:  Found that if the user happen to have the Kitting Default within setup set to not include scrap within Kitting that the report would then double deduct the Scrap values from the View Short Qty field. 
--						           the rounding was not working right for the Scrap Calculation either had to change it from <<round((((K1.Qty * T1.WoBldQty)*I1.Scrap)/100),0)>> to be <<ceiling((((K1.Qty * T1.WoBldQty)*I1.Scrap)/100))>>
--					10/30/15 DRP:  added the @userId, removed the micssys and configured to work with the WebMAnex
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 07/16/18 VL changed custname from char(35) to char(50)
-- =============================================
CREATE PROCEDURE [dbo].[rptKitWoShortage]
--declare
		@lcWono AS char(10) = ''
		,@lcIgnore as char(20) = 'No'
		,@userId uniqueidentifier = null

--PARAMETER EXPLANATION:
--1.  @lcWoNo:  the Work Order number
--2.  @lcIgnore:  This is used in the Report for the users to indicate if they wish to ignore any of the Scrap settings. and is used to populate the ViewShortQty field  
		-- '' =  Blank it will not filter any scrap
		-- 'Ignore Scrap' = will remove the Scrap % only
		-- 'Ignore Setup Scrap' will remove the Setup Scrap Only
		-- 'Ignore Both Scraps' will remove both the Scrap% and Setup Scrap from the Qty


AS
BEGIN

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

--I am delcaring the parameters that would be needed to pull the information from the KitBomView Procedure
		declare	@lcUniq_key char(10) 
				,@lcDueDt smalldatetime
				,@lcKitIgnoreScrapDefault bit	--09/10/15:  Added
--populate the parameter with the uniq_key and DueDate for the Work order Product 				
		select	@lcUniq_key = t1.ParentUniqKey
				,@lcDueDt = t1.DueDt 
		from	@t as t1
--populate the parameter with the system default for ignore scrap or not within kitting	--09/10/15 DRP:  Added
		select @lcKitIgnoreScrapDefault = LKITIGNORESCRAP from KITDEF

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


--The first section below I am gathering the information from the KitBomView created by Vicky, plus I am adding additional information that I need for the Report puposes.	
		select	case when K1.lineshort = 1 then cast ('LS' as char(2)) else CAST('' as CHAR(2)) end as LineShort,K1.Ignorekit,K1.Item_no
				,case when K1.part_sourc = 'CONSG' then K1.CustPartNo else K1.Part_no end as PartNo,case when k1.Part_sourc = 'CONSG' then K1.CustRev else K1.Revision end as Revision
				,K1.Qty,K1.ReqQty,K1.IssuedQty,K1.ShortQty
				--,case when @lcIgnore = 'No' then K1.ShortQty 
				--	else case when @lcIgnore = 'Ignore Scrap' then K1.ShortQty - round((((K1.Qty * T1.WoBldQty)*I1.Scrap)/100),0)
				--		else case when @lcIgnore = 'Ignore Setup Scrap' then K1.ShortQty - I1.SETUPSCRAP  
				--			else case when @lcIgnore = 'Ignore Both Scraps' then (K1.ShortQty - round((((K1.Qty * T1.WoBldQty)*I1.Scrap)/100),0)) - I1.SETUPSCRAP   end end end end as ViewShortQty		--09/10/15 DRP:  repladed with the below
				,case when @lcIgnore = 'No'		
					or (@lcIgnore = 'Ignore Scrap' and @lcKitIgnoreScrapDefault = 1) 
					or (@lcIgnore = 'Ignore Setup Scrap' and @lcKitIgnoreScrapDefault = 1) 
					or (@lcIgnore = 'Ignore Both Scraps' and @lcKitIgnoreScrapDefault = 1) 
					or (@lcIgnore = 'Ignore Setup Scrap' and (@lcKitIgnoreScrapDefault = 0 and t1.PUseSetScrap = 0)) then k1.ShortQty
						else case when (@lcIgnore = 'Ignore Scrap'  and  @lcKitIgnoreScrapDefault = 0)
						or  (@lcIgnore = 'Ignore Both Scraps' and @lcKitIgnoreScrapDefault = 0 and t1.PUseSetScrap = 0)  then K1.ShortQty - ceiling((((K1.Qty * T1.WoBldQty)*I1.Scrap)/100))
							else case when @lcIgnore = 'Ignore Setup Scrap' and (@lcKitIgnoreScrapDefault = 0 and t1.PUseSetScrap = 1) then K1.ShortQty - I1.SETUPSCRAP
								else case when @lcIgnore = 'Ignore Both Scraps' and (@lcKitIgnoreScrapDefault = 0 and t1.PUseSetScrap = 1) then K1.ShortQty - ceiling((((K1.Qty * T1.WoBldQty)*I1.Scrap)/100))-I1.SETUPSCRAP
									 end end end end  as ViewShortQty
				,K1.Part_Sourc,K1.ChildUniq_key,I1.Part_Class,I1.Part_type,I1.Descript,K1.UniqBomNo,K1.Kaseqnum,K1.Eff_dt,K1.Term_dt
				,case when I1.UNIQ_KEY <> @lcUniq_key and I1.PART_SOURC = 'MAKE' and I1.MAKE_BUY = 1 then CAST('Make/Buy' as CHAR(8)) else cast('' as CHAR(8))  end as MbPhSource
				,i1.SCRAP,i1.SETUPSCRAP,T1.*	--,MICSSYS.LIC_NAME	--10/30/15 DRP:  removed
		from	@zKitBom as K1
				left outer join inventor as I1 on K1.ChildUniq_key = I1.uniq_key
				cross join @t as T1
				--cross join MICSSYS	--10/30/15 DRP:  removed		
		where	k1.Kaseqnum <> '' 
				and K1.ShortQty > 0.00
				and K1.Ignorekit <> 'X'

--Then I union the below to add any Misc Items that might have been added to the kit
		union

		select	cast ('MS' as char(2)) as SpecFlag,cast(0 as bit) as Ignorekit,cast (0 as numeric(4,0)) as Item_no,M1.Part_no, M1.Revision
				,M1.Qty,cast (0.00 as numeric (12,2)) as ReqQty, cast(0.00 as numeric(12,2)) as IssuedQty,M1.ShortQty,m1.SHORTQTY as ViewShortQty
				,M1.Part_Sourc,cast ('' as char (10)) as ChildUniq_key,M1.Part_Class,M1.Part_type,M1.Descript,M1.MISCKEY as UniqBomNo, cast('' as char(10)) as Kaseqnum
				,cast(1900-01-01 as smalldatetime) as Eff_dt,cast(1900-01-01 as smalldatetime) as Term_dt
				,cast ('' as char(8)) as MbPhSource,cast (0.00 as numeric(6,2)) as SCRAP,cast (0 as numeric (4,0)) as SETUPSCRAP,T1.*	--,MICSSYS.LIC_NAME	--10/30/15 DRP: removed

		from	MISCMAIN as M1
				cross join @t as T1
				--cross join MICSSYS	--10/30/15 DRP:  removed
		where	M1.WONO = @lcWoNo
			
				
end