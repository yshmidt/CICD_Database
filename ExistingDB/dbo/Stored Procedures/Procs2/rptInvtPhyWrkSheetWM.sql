
-- =============================================
-- Author:		Debbie
-- Create date: 02/15/2011
-- Description:	This Stored Procedure was created for the Physical Inventory Worksheet 
-- Reports Using Stored Procedure:  icrpt11.rpt
-- Modified:	<Debbie, 07/07/2011>
--				09/25/2012 DRP:  added the micssys.lic_name within the Stored Procedure and removed it from the Crystal Report
--				07/07/2011:  Found that the Customer Filter was not working properly within the Consigned section of code.
--				03/08/2013 DRP:  it was found that it was not filtering out Inactive inventory parts.  added the needed filter below. 
--				03/09/2013 DRP:  I also forgot to filter out is_deleted = 1 from the INVTMFHD and INVTMFGR tables.  Updated the where sections of code below. 
--				09/13/2013 DRP:  per conversation with David/Yelena I went through and remove the '*' from the parameters   then added code how to handle null or '*'  should now work for both the CR and Stimulsoft reports
--				07/31/2014 DRP:  we were listing out part numbers that had a status of inactive.  made changes to filter those out. 
---				03/02/15 YS this procedure used in CR, making copy with 'WM' in the name
--				03/02/15 YS changed part range paramaters from lcpart to lcuniq_key
--				07/09/15 DRP:  The Warehouse List section was not working properly.  found that the filter <<inventor.STATUS <> 'ACTIVE'>>  Should have been <<inventor.STATUS = 'ACTIVE'>>
--							   found that the Consigned was not pass the custpartno and custrev to the PartStart and PartEnd values.  It was alwasy passing the internal pn and rev
--								Added the @lcSort to the procedure so the QuickView will match the Sort Selection.
--								Added the @lcBookQty and changed the Qty_OH formula to display null in this field if @lcBookQty = "No'
--				07/21/15 DRP:  Added the @lcBookQty and changed the LotQty formula to display null in this field if @lcBookQty = "No'
--							   Added the LOTDETAIL field to help with the Report layout. 
--				10/13/14 YS replaced invtmfhd table with 2 new tables
--- 03/28/17 YS changed length of the part_no column from 25 to 35
--10/02/17 YS add table name for the location column
-- 07/16/18 VL changed custname from char(35) to char(50)
-- =============================================

		CREATE PROCEDURE [dbo].[rptInvtPhyWrkSheetWM]
--declare
					@lcType as char (20) = 'Internal'		--where the user would specify Internal, Internal & In Store, In Store, Consigned
					-- 03/02/15 YS change to allow multiple customers
					,@lcCustNo as varchar (max) = 'All'
					,@lcSource as char (4) = 'All'				--All, Buy or Make
					--03/02/15 YS changed to use warehouse selection box
					--,@lcWhse as varchar(max) = ''
					,@lcUniqWH varchar(max)='ALL'
					--,@lcPartStart as varchar(25)='101-0001700'
					--,@lcPartEnd as varchar(25)='101-0001710'
					--	03/02/15 YS changed part range paramaters from lcpart to lcuniq_key. Debbie you should stop saving your test values :)
					,@lcUniq_keyStart char(10)='',
					@lcUniq_keyEnd char(10)='',
					@lcSort char(20) = 'Warehouse/Location',		--''Warehouse/Location,Part Number/Rev'	--07/09/15 DRP:  Added 
					@lcBookQty char(3) = 'Yes',				--Yes:  Displays the Qty_oh or No:  will show all null in the qty _oh field.  
					@userId uniqueidentifier = null	--03/03/15 YS added userid

		AS 
		BEGIN
				
		--03/02/15 YS changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
		declare @lcPartStart char(35)='',@lcRevisionStart char(8)='',
		@lcPartEnd char(35)='',@lcRevisionEnd char(8)=''
		--03/02/15 YS changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
		-- find starting part number
		IF  @lcUniq_keyStart IS NULL or  @lcUniq_keyStart ='' 
			SELECT @lcPartStart=' ', @lcRevisionStart=' '
		ELSE
			SELECT @lcPartStart= case when @lctype='Consigned' THEN ISNULL(I.Custpartno,' ') ELSE  ISNULL(I.Part_no,' ') END,	--07/09/15 DRP added the Case when for the Consigned
				@lcRevisionStart = case when @lctype='Consigned' THEN ISNULL(I.Custrev,' ') ELSE ISNULL(I.Revision,' ') END		--07/09/15 DRP added the Case when for the Consigned
			FROM Inventor I where Uniq_key=@lcUniq_keyStart
		
		-- find ending part number
		IF  @lcUniq_keyEnd IS NULL or  @lcUniq_keyEnd ='' 
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
			SELECT @lcPartEnd = REPLICATE('Z',35), @lcRevisionEnd=REPLICATE('Z',8)
		ELSE
			SELECT @lcPartEnd =case when @lctype='Consigned' THEN ISNULL(I.custpartno,' ') ELSE ISNULL(I.Part_no,' ') END,		--07/09/15 DRP added the Case when for the Consigned
				@lcRevisionEnd= case when @lctype='Consigned' THEN ISNULL(I.Custrev,' ') ELSE  ISNULL(I.Revision,' ') END		--07/09/15 DRP added the Case when for the Consigned
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

		/*07/09/15 DRP:  replaced with the above WAREHOUSE LIST
		--03/02/15 changed warehouse selection
		DECLARE @Warehouse TABLE (UniqWH char(10))
		IF (@lcUniqWH<>'All' and @lcUniqWH<>' ' and @lcUniqWH IS NOT NULL)
		INSERT INTO @Warehouse (UniqWH) select id  from dbo.[fn_simpleVarcharlistToTable](@lcUniqWH,',')
		select * from @Warehouse
		*/


--**INTERNAL** INVENTORY
		IF (@lcType <> 'Consigned') 
		BEGIN
			
			SELECT	T1.UNIQ_KEY, T1.PART_SOURC, T1.PART_NO, T1.REV, T1.CUSTNAME, T1.PART_CLASS, T1.PART_TYPE, T1.DESCRIPT,
						T1.U_OF_MEAS, T1.PARTMFGR, T1.MFGR_PT_NO, T1.WAREHOUSE, T1.LOCATION, T1.W_KEY,
						case when @lcBookQty = 'No' then null else 
							CASE WHEN ROW_NUMBER() OVER(Partition by UNIQ_KEY, W_KEY ORDER BY W_KEY)=1 Then QTY_OH ELSE CAST(0.00 as Numeric(20,2)) END end AS QTY_OH,	--07/09/15 DRP:  added the case when @lcBookQty - 'No'
						T1.INSTORE,t1.LOTDETAIL,
						 T1.LOTCODE,
						T1.EXPDATE, T1.REFERENCE, T1.PONUM, case when @lcBookQty = 'No' then null else T1.LOTQTY end as LOTQTY	--07/21/15 DRP:  added the case when @lcBookQty = 'No'
						
				FROM(
				-- 07/16/18 VL changed custname from char(35) to char(50)
				select	INVENTOR.UNIQ_KEY, PART_SOURC, PART_NO,REVISION AS REV, 
						CAST ('' AS CHAR (50)) AS CUSTNAME,
						inventor.PART_CLASS, inventor.PART_TYPE, DESCRIPT, inventor.U_OF_MEAS, PARTMFGR, MFGR_PT_NO, WAREHOUSE,
						--10/02/17 YS add table name for the location column
						invtmfgr.LOCATION , 
						INVTMFGR.W_KEY,QTY_OH, INSTORE,LOTDETAIL
						,ISNULL(INVTLOT.LOTCODE,CAST(' ' as CHAR(15))) as LotCode, 
						EXPDATE, ISNULL(INVTLOT.REFERENCE,CAST('' AS CHAR(12))) AS REFERENCE, 
						ISNULL(INVTLOT.PONUM,CAST ('' AS CHAR (15))) AS PONUM, isnull(invtlot.LOTQTY, CAST(0.00 as numeric (12,2))) as LOTQTY
				from	INVENTOR
						-- 10/13/14 YS replaced invtmfhd table with 2 new tables
						--LEFT OUTER JOIN INVTMFHD ON INVENTOR.UNIQ_KEY = INVTMFHD.UNIQ_KEY
						LEFT OUTER JOIN InvtMPNLink L On Inventor.UNIQ_KEY=L.uniq_key
						LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
						-- 10/13/14 YS replaced invtmfhd table with 2 new tables
						--LEFT OUTER JOIN INVTMFGR ON INVTMFHD.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD
						INNER JOIN INVTMFGR ON L.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD
						INNER JOIN WAREHOUS ON INVTMFGR.UNIQWH = WAREHOUS.UNIQWH
						LEFT OUTER JOIN INVTLOT ON INVTMFGR.W_KEY = INVTLOT.W_KEY
						left outer join parttype on inventor.PART_CLASS + inventor.PART_TYPE = parttype.PART_CLASS+PARTTYPE.PART_TYPE
					WHERE	((@lcType='Internal & In Store') OR (@lcType='In Store' and Invtmfgr.instore=1) 
						OR (@lcType='Internal' and (Invtmfgr.instore=0 or Invtmfgr.instore is null)))
					AND ((@lcSource = 'Make' and Part_sourc='MAKE') OR (@lcSource='Buy' and Part_sourc='BUY') OR (@lcSource='All' and Part_sourc IN ('MAKE','BUY')))
					and (@lcUniqWH='All' OR exists (select 1 from @Whse t where t.uniqwh=warehous.uniqwh))
					AND (part_no+revision BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)
					and warehous.is_deleted=0
					and INVTMFGR.IS_DELETED =0
					and L.IS_DELETED =0 and m.is_deleted=0
					AND inventor.STATUS = 'ACTIVE' 	--07/09/15 DRP: found that this was incorrectly set as  inventor.STATUS <> 'ACTIVE'
				) T1 

				ORDER BY CASE @lcSort WHEN 'Warehouse/Location' then WAREHOUSE +t1.LOCATION+part_no+rev+PARTMFGR+MFGR_PT_NO end,
						 case @lcsort when 'Part Number/Rev' then Part_no + Rev+warehouse+t1.location+partmfgr+mfgr_pt_no end		
				--ORDER BY PART_NO, REV --07/09/15 DRP:  replaced by the above sort







			END
				--**CONSIGNED INVENTORY**
			ELSE IF (@lcType = 'Consigned')
			BEGIN
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

				SELECT	T1.UNIQ_KEY, T1.PART_SOURC, T1.PART_NO, T1.REV, T1.CUSTNAME, T1.PART_CLASS, T1.PART_TYPE, T1.DESCRIPT,
						T1.U_OF_MEAS, T1.PARTMFGR, T1.MFGR_PT_NO, T1.WAREHOUSE, T1.LOCATION, T1.W_KEY,
						case when @lcBookQty = 'No' then null else 
							CASE WHEN ROW_NUMBER() OVER(Partition by UNIQ_KEY, W_KEY ORDER BY W_KEY)=1 Then QTY_OH ELSE CAST(0.00 as Numeric(20,2)) END end AS QTY_OH,	--07/09/15 DRP:  added the case when @lcBookQty - 'No'
						T1.INSTORE,LOTDETAIL, T1.LOTCODE,
						T1.EXPDATE, T1.REFERENCE, T1.PONUM,case when @lcBookQty = 'No' then null else T1.LOTQTY end as LOTQTY	--07/21/15 DRP:  added the case when @lcBookQty = 'No"
				FROM(
				select	INVENTOR.UNIQ_KEY, PART_SOURC, CUSTPARTNO AS PART_NO,CUSTREV AS REV, 
						Customer.CUSTNAME,
						inventor.PART_CLASS, inventor.PART_TYPE, DESCRIPT, inventor.U_OF_MEAS, PARTMFGR, MFGR_PT_NO, WAREHOUSE,
						--10/02/17 YS add table name for the location column
						invtmfgr.LOCATION , 
						INVTMFGR.W_KEY,QTY_OH, INSTORE,LOTDETAIL
						,ISNULL(INVTLOT.LOTCODE,CAST(' ' as CHAR(15))) as LotCode, 
						EXPDATE, ISNULL(INVTLOT.REFERENCE,CAST('' AS CHAR(12))) AS REFERENCE, 
						ISNULL(INVTLOT.PONUM,CAST ('' AS CHAR (15))) AS PONUM, isnull(invtlot.LOTQTY, CAST(0.00 as numeric (12,2))) as LOTQTY	
				from	INVENTOR
						INNER JOIN @Customer C ON Inventor.custno=C.Custno
						INNER JOIN CUSTOMER ON C.CUSTNO = CUSTOMER.CUSTNO
						--10/13/14 YS new tables in place of invtmfhd
						--LEFT OUTER JOIN INVTMFHD ON INVENTOR.UNIQ_KEY = INVTMFHD.UNIQ_KEY
						LEFT OUTER JOIN InvtMPNLink L ON INVENTOR.UNIQ_KEY = L.UNIQ_KEY
						--10/13/14 YS new tables in place of invtmfhd
						LEFT OUTER JOIN MfgrMaster M ON l.mfgrMasterId=M.MfgrMasterId
						--10/13/14 YS new tables in place of invtmfhd
						--LEFT OUTER JOIN INVTMFGR ON INVTMFHD.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD
						LEFT OUTER JOIN INVTMFGR ON L.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD
						INNER JOIN WAREHOUS ON INVTMFGR.UNIQWH = WAREHOUS.UNIQWH
						LEFT OUTER JOIN INVTLOT ON INVTMFGR.W_KEY = INVTLOT.W_KEY
						left outer join parttype on inventor.PART_CLASS + inventor.PART_TYPE = parttype.PART_CLASS+PARTTYPE.PART_TYPE
					WHERE part_sourc='CONSG' 
						and (custpartno+custrev BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)	--07/09/15 DRP:  needed to change this to be Part_no+Rev
						and (@lcUniqWH='All' OR exists (select 1 from @Whse t where t.uniqwh=warehous.uniqwh))
						and inventor.STATUS = 'Active'		--07/09/15 DRP: found that this was incorrectly set as  inventor.STATUS <> 'ACTIVE'
						and warehous.is_deleted=0
						and L.IS_DELETED =0 and m.is_deleted=0
						and invtmfgr.IS_DELETED =0
				) T1 
				ORDER BY CASE @lcSort WHEN 'Warehouse/Location' then custname+WAREHOUSE +t1.LOCATION+part_no+rev+PARTMFGR+MFGR_PT_NO end,
						 case @lcsort when 'Part Number/Rev' then custname+Part_no + Rev+warehouse+t1.location+partmfgr+mfgr_pt_no end	
				--ORDER BY PART_NO, REV --07/09/15 DRP:  replaced by the above sort

			END -- IF (@lcType = 'Consigned')
		end