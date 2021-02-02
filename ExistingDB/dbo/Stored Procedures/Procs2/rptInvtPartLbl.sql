-- =============================================
-- Author:		<Debbie>
-- Create date: <09/27/2011>
-- Description:	<Compiles the details for the Inventory Labels>
-- Used On:     <Crystal Report {invtlbl.rpt} & {invtlblz}>
-- Modifications: 02/08/2012:  Add the depth,width,length and weight
--				  09/13/2013 DRP:  per conversation with David/Yelena I went through and remove the '*' from the parameters   then added code how to handle null or '*'  should now work for both the CR and Stimulsoft reports
--					10/10/14 YS replaced invtmfhd with 2 new tables
--				12/09/15 DRP:	Made modifications to the parameters to work with the WebParams.  also changed the INSTORE field to display "Y" if true so that StimulSoft would like it when I used it in a formula
	--				08/24/16 DRP:  Added the ABC code for request of customer on the new 4x1 labels
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 05/01/17 DRP:  added the @lcLabelQty parameter per request of the users.  This way they can enter in a Label Qty to be populated into the grid, but should also then be able to change within the grid if needed.
 --03/01/18 YS lotcode size change to 25
 -- 07/13/18 VL changed supname from char(30) to char(50) and custname from char(35) to char(50)
-- =============================================

		CREATE PROCEDURE [dbo].[rptInvtPartLbl]

@lcUniq_keyStart char(10)= ''
				,@lcUniq_keyEnd char(10)= ''
				,@lcType as char (20) = 'Internal'				--where the user would specify Internal, Internal & In Store, In Store, Consigned
				,@lcCustNo as varchar (max) = 'All'
				,@lcLoc as varchar(17) = ''
				,@lcUniqWH varchar(max)='All'					--12/07/15 DRP added parameter for user to be able to filter output by warehouse. Default to 'All' can coma separated. has to be multiselect list or All
				,@lcLabelQty as int = null		--05/01/17 DRP:  added
				,@userId uniqueidentifier = null

				--12/07/15 DRP:  BELOW PARAMS WERE REPLACED BY THE ABOVE
				/*
				--@lcPartStart as varchar(25)='',
				--@lcRevStart as VARchar (8) = '',
				--@lcPartEnd as varchar(25)='',
				--@lcRevEnd as VARchar (8) = '',
				--@lcType as char (20) = 'Internal',   --where the user would specify Internal, Internal & In Store, In Store, Consigned
				--@lcCust as varchar (35) = '',
				--@lcLoc as varchar(17) = '',
				--@lcWhse as varchar(6) = ''
				*/

				
		as
		begin
	--12/07/15 DRP:  ADDED
	-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
	SET NOCOUNT ON;
	--02/20/15 YS changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
	declare @lcPartStart char(35)='',@lcRevisionStart char(8)='',
		@lcPartEnd char(35)='',@lcRevisionEnd char(8)=''

	--12/07/15 DRP changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
	-- find starting part number
	IF  @lcUniq_keyStart IS NULL or  @lcUniq_keyStart ='' 
		SELECT @lcPartStart=' ', @lcRevisionStart=' '
	ELSE
		SELECT @lcPartStart = case when @lctype='Consigned' THEN ISNULL(I.Custpartno,' ') ELSE  ISNULL(I.Part_no,' ') END,	
			@lcRevisionStart = case when @lctype='Consigned' THEN ISNULL(I.Custrev,' ') ELSE ISNULL(I.Revision,' ') END		
		FROM Inventor I where Uniq_key=@lcUniq_keyStart
		
	-- find ending part number
	IF  @lcUniq_keyEnd IS NULL or  @lcUniq_keyEnd ='' 
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
		SELECT @lcPartEnd = REPLICATE('Z',35), @lcRevisionEnd=REPLICATE('Z',8)
	ELSE
		SELECT @lcPartEnd =case when @lctype='Consigned' THEN ISNULL(I.custpartno,' ') ELSE ISNULL(I.Part_no,' ') END,		
			@lcRevisionEnd = case when @lctype='Consigned' THEN ISNULL(I.Custrev,' ') ELSE  ISNULL(I.Revision,' ') END		
		FROM Inventor I where Uniq_key=@lcUniq_keyEnd


	/*WAREHOUSE LIST*/
		--09/13/2013 DRP:  added code to handle Warehouse List
			declare @Whse table(Uniqwh char(10))
			if @lcUniqWh is not null and @lcUniqWh <> '' AND @lcUniqWh <> 'All'
				insert into @Whse select * from dbo.[fn_simpleVarcharlistToTable](@lcUniqWh,',')

			else

			if @lcUniqWh = 'All'
			Begin
				insert into @Whse select uniqwh from WAREHOUS
			end
			--select * from @Whse

	--09/13/2013 DRP:  added code to handle Location List
	declare @Loc table(Loc char(17))
	if @lcLoc is not null and @lcLoc <> ''
		insert into @Loc select * from dbo.[fn_simpleVarcharlistToTable](@lcLoc,',')

	

		/*REPLACED THE BELOW WITH THE ABOVE SO THAT THE PARAMETERS WOULD WORK PROPERLY FOR THE WEB*/
		--select * from @customer

				----09/13/2013 DRP: If null or '*' then pass '' for Part No
				--	IF @lcPartStart is null OR @lcPartStart = '*'
				--		select @lcPartStart=''
				--	IF @lcPartEnd is null OR @lcPartEnd = '*'
				--		select @lcPartEnd=''	
				----09/13/2013 DRP: If null or '*' then pass '' for Revision
				--	IF @lcRevStart is null OR @lcRevStart = '*'
				--		select @lcRevStart=''
				--	IF @lcRevEnd is null OR @lcRevEnd = '*'
				--		select @lcRevEnd=''
				--09/13/2013 DRP:  added code to handle Wo List
					--declare @Cust table(Cust char(35))
					--if @lcCust is not null and @lcCust <> ''
					--	insert into @Cust select * from dbo.[fn_simpleVarcharlistToTable](@lcCust,',')
				--09/13/2013 DRP:  added code to handle Location List
					--declare @Loc table(Loc char(17))
					--if @lcLoc is not null and @lcLoc <> ''
					--	insert into @Loc select * from dbo.[fn_simpleVarcharlistToTable](@lcLoc,',')
				--09/13/2013 DRP:  added code to handle Warehouse List
					--declare @Whse table(Whse char(10))
					--if @lcWhse is not null and @lcWhse <> ''
					--	insert into @Whse select * from dbo.[fn_simpleVarcharlistToTable](@lcWhse,',')


/*RECORD SELECTION SECTION*/
					
					if (@lcType <> 'Consigned') 
					BEGIN
					--10/10/14 YS replaced invtmfhd with 2 new tables
					 --03/01/18 YS lotcode size change to 25
					 -- 07/13/18 VL changed supname from char(30) to char(50) and custname from char(35) to char(50)
					select	inventor.UNIQ_KEY, part_sourc,part_no, revision, part_class, part_type, DESCRIPt, inventor.CUSTNO, CUSTNAME 
							,invtmfgr.uniqsupno,case when INSTORE = 1 then cast('Y' as char(1)) else CAST('' AS CHAR(1)) end as INSTORE,warehouse,location,l.UNIQMFGRHD,PARTMFGR,MFGR_PT_NO,invtmfgr.W_KEY,m.MATLTYPE
							,inventor.STATUS,ISNULL(CAST(invtlot.lotcode AS CHAR (25)),cast(invtmfgr.W_KEY as char (15))) as Reference, case when INSTORE = 1 then supname else CAST ('' as char(50)) end as Owner
							,m.PTDEPTH,m.PTLENGTH,m.PTWIDTH,m.PTWT
							--,CAST (1 as numeric (3,0))as LabelQty	--05/01/17 DRP:  replaced with below
							,case when @lcLabelQty is null then 1 else @lcLabelQty end as LabelQty
							,inventor.ABC	--08/24/16 DRP:  added
							
					from	INVENTOR
							--10/10/14 YS replaced invtmfhd with 2 new tables
							--inner join INVTMFHD on inventor.UNIQ_KEY = invtmfhd.UNIQ_KEY
							inner join InvtMPNLink L ON Inventor.UNIQ_KEY=L.Uniq_key
							inner join MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
							inner join INVTMFGR on l.UNIQMFGRHD = invtmfgr.UNIQMFGRHD
							inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH
							left outer join INVTLOT on invtmfgr.W_KEY = invtlot.W_KEY
							left outer join CUSTOMER on inventor.CUSTNO = customer.CUSTNO
							left outer join SUPINFO on invtmfgr.uniqsupno = supinfo.UNIQSUPNO
					where	l.IS_DELETED = 0
							and invtmfgr.IS_DELETED = 0
							and (part_sourc='MAKE' or part_sourc='BUY')
							--and @lcUniq_key = inventor.UNIQ_KEY
							and (part_no+revision BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)
							and (@lcUniqWh = '' or EXISTS (SELECT 1 FROM @Whse wh WHERE WH.UNIQWH=WAREHOUS.UNIQWH))
							and invtmfgr.location = case when @lcLoc = '*' or @lcLoc = '' then invtmfgr.LOCATION else @lcLoc end
							AND INSTORE = CASE WHEN @lcType = 'Internal' then 0 when @lcType = 'In Store' then 1 when @lctype = 'Internal & In Store' then instore end	

		--12/07/15 DRP: replaced with the above		
					--where	l.IS_DELETED = 0
					--		and invtmfgr.IS_DELETED = 0
					--		and Part_no>= case when @lcPartStart='' OR  @lcPartStart='*'  then Part_no else @lcPartStart END
					--		and PART_NO<= CASE WHEN @lcPartEnd='' OR @lcPartEnd='*' THEN PART_NO ELSE @lcPartEnd END
					--		and inventor.REVISION >= case when @lcRevStart = '*' OR @lcRevStart = '' then inventor.REVISION else @lcRevStart end
					--		and inventor.REVISION >= case when @lcRevEnd = '*' OR @lcRevEnd = '' then inventor.REVISION else @lcRevEnd end
					--		and PART_SOURC <> 'CONSG'
					--		AND INSTORE = CASE WHEN @lcType = 'Internal' then 0 when @lcType = 'In Store' then 1 when @lctype = 'Internal & In Store' then instore end
					--		and invtmfgr.location = case when @lcLoc = '*' or @lcLoc = '' then invtmfgr.LOCATION else @lcLoc end
					--		and warehous.WAREHOUSE = case when @lcWhse = '*' or @lcWhse = '' then WAREHOUS.WAREHOUSE else @lcWhse end
			--09/13/2013 DRP:	--where	invtmfhd.IS_DELETED = 0
					--		and invtmfgr.IS_DELETED = 0
					--		and inventor.PART_NO>= case when @lcPartStart='*' then inventor.PART_NO else @lcPartStart END
					--		and INVENTOR.REVISION >= case when @lcRevStart = '*' then inventor.revision else @lcRevStart end
					--		and INVENTOR.PART_NO<= CASE WHEN @lcPartEnd='*' THEN INVENTOR.PART_NO ELSE @lcPartEnd END
					--		and INVENTOR.REVISION >= case when @lcRevEnd = '*' then inventor.revision else @lcRevEnd end
					--		and PART_SOURC <> 'CONSG'
					--		AND INSTORE = CASE WHEN @lcType = 'Internal' then 0 when @lcType = 'In Store' then 1 when @lctype = 'Internal & In Store' then instore end
					--		and invtmfgr.LOCATION = case when @lcLoc = '*' then invtmfgr.LOCATION else @lcloc end
					--		AND WAREHOUS.WAREHOUSE = CASE WHEN @lcWhse = '*' THEN WAREHOUS.WAREHOUSE ELSE @lcWhse END

					END
					else if (@lcType = 'Consigned')
					begin
					--GET LIST OF CUSTOMES FOR @USERID WITH ACCESS			
						DECLARE  @tCustomer as tCustomer
						DECLARE @Customer TABLE (custno char(10))
						INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userId ;
						IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
							insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
									where CAST (id as CHAR(10)) in (select CustNo from @tCustomer)
						ELSE
						BEGIN
							IF  @lcCustNo='All'	
							BEGIN
								INSERT INTO @Customer SELECT CustNo FROM @tCustomer
							END -- IF  @lcCustNo='All'	
						END -- IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
					--select * from @Customer	

					select	inventor.UNIQ_KEY, part_sourc,custpartno as part_no, custrev as revision, part_class, part_type, DESCRIPt, inventor.CUSTNO, CUSTNAME 
							,invtmfgr.uniqsupno,case when INSTORE = 1 then cast('Y' as char(1)) else CAST('' AS CHAR(1)) end as INSTORE,warehouse,location,l.UNIQMFGRHD,PARTMFGR,MFGR_PT_NO,invtmfgr.W_KEY,m.MATLTYPE
							 --03/01/18 YS lotcode size change to 25
							,inventor.STATUS,ISNULL(CAST(invtlot.lotcode AS CHAR (25)),cast(invtmfgr.W_KEY as char (15))) as Reference, custname as Owner
							,m.PTDEPTH,m.PTLENGTH,m.PTWIDTH,m.PTWT
							--,CAST (1 as numeric (3,0))as LabelQty	--05/01/17 DRP:  replaced with below
							,case when @lcLabelQty is null then 1 else @lcLabelQty end as LabelQty
							,inventor.ABC	--08/24/16 DRP:  added
								
					from	INVENTOR
					--10/10/14 YS replaced invtmfhd with 2 new tables
							--inner join INVTMFHD on inventor.UNIQ_KEY = invtmfhd.UNIQ_KEY
							inner join InvtMPNLink l ON inventor.UNIQ_KEY=l.uniq_key
							inner join MfgrMaster m on l.mfgrMasterId=m.MfgrMasterId
							inner join INVTMFGR on l.UNIQMFGRHD = invtmfgr.UNIQMFGRHD
							inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH
							left outer join INVTLOT on invtmfgr.W_KEY = invtlot.W_KEY
							left outer join CUSTOMER on inventor.CUSTNO = customer.CUSTNO
							left outer join SUPINFO on invtmfgr.uniqsupno = supinfo.UNIQSUPNO
						
					where	l.IS_DELETED = 0
							and invtmfgr.IS_DELETED = 0
							and PART_SOURC = 'CONSG'
							--and @lcUniq_key = inventor.UNIQ_KEY
							and (custpartno+custrev BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)
							and (@lcUniqWh = '' or EXISTS (SELECT 1 FROM @Whse wh WHERE WH.UNIQWH=WAREHOUS.UNIQWH))
							and invtmfgr.location = case when @lcLoc = '*' or @lcLoc = '' then invtmfgr.LOCATION else @lcLoc end
							and (@lcCustNo='All' OR exists (select 1 from @Customer t inner join customer c on t.custno=c.custno where c.custno=inventor.custno))
	--12/07/15 DRP:  replaced below with the above to work with the web
					--where	l.IS_DELETED = 0
					--		and invtmfgr.IS_DELETED = 0
					--		and inventor.CUSTPARTNO>= case when @lcPartStart='' OR  @lcPartStart='*'  then CUSTPARTNO else @lcPartStart END
					--		and custPARTNO<= CASE WHEN @lcPartEnd='' OR @lcPartEnd='*' THEN custPARTNO ELSE @lcPartEnd END
					--		and inventor.CUSTREV >= case when @lcRevStart = '*' OR @lcRevStart = '' then inventor.custREV else @lcRevStart end
					--		and inventor.CUSTREV >= case when @lcRevEnd = '*' OR @lcRevEnd = '' then inventor.CUSTREV else @lcRevEnd end
					--		and PART_SOURC = 'CONSG'
					--		and 1 = case when Customer.CUSTNAME like case when @lcCust ='*' then '%' else @lcCust+'%' end then 1
					--					when @lcCust is null or @lcCust = '' then 1 else 0 end
					--		and 1 = case when WAREHOUSE like case when @lcWhse = '*' then '%' else @lcWhse+'%'end then 1
					--					when @lcWhse IS null OR @lcWhse = '' then 1 else 0 end 
					--		and invtmfgr.location =  case when  @lcLoc = '*' OR @lcLoc = '' OR @lcLoc IS null then invtmfgr.LOCATION else @lcLoc end		
			--09/13/2013 DRP:--where	invtmfhd.IS_DELETED = 0
					--		and invtmfgr.IS_DELETED = 0
					--		and inventor.custpartno>= case when @lcPartStart='*' then inventor.CUSTPARTNO else @lcPartStart END
					--		and INVENTOR.CUSTREV >= case when @lcRevStart = '*' then inventor.CUSTREV else @lcRevStart end
					--		and INVENTOR.custpartno<= CASE WHEN @lcPartEnd='*' THEN INVENTOR.CUSTPARTNO ELSE @lcPartEnd END
					--		and INVENTOR.CUSTREV >= case when @lcRevEnd = '*' then inventor.CUSTREV else @lcRevEnd end
					--		and PART_SOURC = 'CONSG'
					--		and Customer.CUSTNAME like case when @lcCust ='*' then '%' else @lcCust+'%' end
					--		--and custname LIKE '%'+ @lcCust+'%'
					--		and invtmfgr.LOCATION = case when @lcLoc = '*' then invtmfgr.LOCATION else @lcloc end
					--		AND WAREHOUS.WAREHOUSE = CASE WHEN @lcWhse = '*' THEN WAREHOUS.WAREHOUSE ELSE @lcWhse END

					end
		end