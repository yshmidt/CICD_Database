
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
		--				10/13/14 YS replaced invtmfhd table with 2 new tables
		-- 04/14/15 YS Location length is changed to varchar(256)
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 07/16/18 VL changed custname from char(35) to char(50)
		-- =============================================

		CREATE PROCEDURE [dbo].[rptInvtPhyWrkSheet]

					@lcType as char (20) = 'Internal'		--where the user would specify Internal, Internal & In Store, In Store, Consigned
					,@lcCust as varchar (35) = ''
					,@lcSource as char (4) = 'All'				--All, Buy or Make
					,@lcWhse as varchar(6) = ''
					--- 03/28/17 YS changed length of the part_no column from 25 to 35
					,@lcPartStart as varchar(35)='101-0001700'
					,@lcPartEnd as varchar(35)='101-0001710'
				
		AS 
		BEGIN
				
		--09/13/2013 DRP: If null or '*' then pass ''
			IF @lcPartStart is null OR @lcPartStart = '*'
				select @lcPartStart=''
			IF @lcPartEnd is null OR @lcPartEnd = '*'
				select @lcPartEnd=''	
		--09/13/2013 DRP:  added code to handle Wo List
			declare @Cust table(Cust char(35))
			if @lcCust is not null and @lcCust <> ''
				insert into @Cust select * from dbo.[fn_simpleVarcharlistToTable](@lcCust,',')
		--09/13/2013 DRP:  added code to handle Warehouse List
			declare @Whse table(Whse char(10))
			if @lcWhse is not null and @lcWhse <> ''
				insert into @Whse select * from dbo.[fn_simpleVarcharlistToTable](@lcWhse,',')

				--**INTERNAL** INVENTORY
				IF (@lcType <> 'Consigned') 
					BEGIN

				SELECT	T1.UNIQ_KEY, T1.PART_SOURC, T1.PART_NO, T1.REV, T1.CUSTNAME, T1.PART_CLASS, T1.PART_TYPE, T1.DESCRIPT,
						T1.U_OF_MEAS, T1.PARTMFGR, T1.MFGR_PT_NO, T1.WAREHOUSE, T1.LOCATION, T1.W_KEY,
						CASE WHEN ROW_NUMBER() OVER(Partition by UNIQ_KEY, W_KEY ORDER BY W_KEY)=1 Then QTY_OH ELSE CAST(0.00 as Numeric(20,2)) END AS QTY_OH,T1.INSTORE, T1.LOTCODE,
						T1.EXPDATE, T1.REFERENCE, T1.PONUM, T1.LOTQTY,MICSSYS.LIC_NAME
				FROM(
				-- 07/16/18 VL changed custname from char(35) to char(50)
				select	INVENTOR.UNIQ_KEY, PART_SOURC, PART_NO,REVISION AS REV, 
						CAST ('' AS CHAR (50)) AS CUSTNAME,
						-- 04/14/15 YS Location length is changed to varchar(256)
						PART_CLASS, PART_TYPE, DESCRIPT, U_OF_MEAS, PARTMFGR, MFGR_PT_NO, WAREHOUSE,CASE WHEN LOCATION = '' THEN CAST ('*None*' AS varCHAR (256)) ELSE LOCATION END AS LOCATION , 
						INVTMFGR.W_KEY,QTY_OH, INSTORE,ISNULL(INVTLOT.LOTCODE,CAST(' ' as CHAR(15))) as LotCode, 
						EXPDATE, ISNULL(INVTLOT.REFERENCE,CAST('' AS CHAR(10))) AS REFERENCE, ISNULL(INVTLOT.PONUM,CAST ('' AS CHAR (15))) AS PONUM, isnull(invtlot.LOTQTY, CAST(0.00 as numeric (12,2))) as LOTQTY
				from	INVENTOR
						LEFT OUTER JOIN CUSTOMER ON INVENTOR.CUSTNO = CUSTOMER.CUSTNO
						-- 10/13/14 YS replaced invtmfhd table with 2 new tables
						--LEFT OUTER JOIN INVTMFHD ON INVENTOR.UNIQ_KEY = INVTMFHD.UNIQ_KEY
						LEFT OUTER JOIN InvtMPNLink L On Inventor.UNIQ_KEY=L.uniq_key
						LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
						-- 10/13/14 YS replaced invtmfhd table with 2 new tables
						--LEFT OUTER JOIN INVTMFGR ON INVTMFHD.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD
						LEFT OUTER JOIN INVTMFGR ON L.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD
						INNER JOIN WAREHOUS ON INVTMFGR.UNIQWH = WAREHOUS.UNIQWH
						LEFT OUTER JOIN INVTLOT ON INVTMFGR.W_KEY = INVTLOT.W_KEy		
		--09/13/2013 DRP:		--WHERE	INSTORE = CASE WHEN @lcType = 'Internal' then 0 else case when @lcType = 'In Store' then 1 else case when @lctype = 'Internal & In Store' then instore end end end
				--		and PART_SOURC = case when @lcSource = 'Make' then 'Make' else CASe when @lcSource = 'Buy' then 'Buy' else PART_SOURC end end 
				--		and PART_SOURC <> 'CONSG' and PART_SOURC <> 'Phantom'
				--		and WAREHOUSE like case when @lcWhse = '*' then '%' else @lcWhse+'%' end
				--		and Part_no>= case when @lcPartStart='*' then PART_NO else @lcPartStart END
				--		and PART_NO<= CASE WHEN @lcPartEnd='*' THEN PART_NO ELSE @lcPartEnd END
				--		and inventor.STATUS <> 'Inactive'
				--		and INVTMFHD.IS_DELETED <> 1
				--		and invtmfgr.IS_DELETED <> 1
				WHERE	INSTORE = CASE WHEN @lcType = 'Internal' then 0 else case when @lcType = 'In Store' then 1 else case when @lctype = 'Internal & In Store' then instore end end end
						and PART_SOURC = case when @lcSource = 'Make' then 'Make' else CASe when @lcSource = 'Buy' then 'Buy' else PART_SOURC end end 
						and PART_SOURC <> 'CONSG' and PART_SOURC <> 'Phantom'
						and 1 = case when WAREHOUSE like case when @lcWhse = '*' then '%' else @lcWhse+'%'end then 1
								when @lcWhse IS null OR @lcWhse = '' then 1 else 0 end 
						and Part_no>= case when @lcPartStart='' OR  @lcPartStart='*'  then Part_no else @lcPartStart END
						and PART_NO<= CASE WHEN @lcPartEnd='' OR @lcPartEnd='*' THEN PART_NO ELSE @lcPartEnd END	
						and L.IS_DELETED <> 1
						and invtmfgr.IS_DELETED <> 1
						and inventor.STATUS <> 'INACTIVE' --07/31/2014 DRP:  added 		
				
				) T1 cross join MICSSYS
				ORDER BY PART_NO, REV


				END
				--**CONSIGNED INVENTORY**
				ELSE IF (@lcType = 'Consigned')

					BEGIN

				SELECT	T1.UNIQ_KEY, T1.PART_SOURC, T1.PART_NO, T1.REV, T1.CUSTNAME, T1.PART_CLASS, T1.PART_TYPE, T1.DESCRIPT,
						T1.U_OF_MEAS, T1.PARTMFGR, T1.MFGR_PT_NO, T1.WAREHOUSE, T1.LOCATION, T1.W_KEY,
						CASE WHEN ROW_NUMBER() OVER(Partition by UNIQ_KEY, W_KEY ORDER BY W_KEY)=1 Then QTY_OH ELSE CAST(0.00 as Numeric(20,2)) END AS QTY_OH,T1.INSTORE, T1.LOTCODE,
						T1.EXPDATE, T1.REFERENCE, T1.PONUM, T1.LOTQTY,MICSSYS.LIC_NAME	
				FROM(
				select	INVENTOR.UNIQ_KEY, PART_SOURC, CUSTPARTNO AS PART_NO,CUSTREV AS REV, 
						CUSTNAME,
						-- 04/14/15 YS Location length is changed to varchar(256)
						PART_CLASS, PART_TYPE, DESCRIPT, U_OF_MEAS, PARTMFGR, MFGR_PT_NO, WAREHOUSE,CASE WHEN LOCATION = '' THEN CAST ('*None*' AS varCHAR (256)) ELSE LOCATION END AS LOCATION , 
						INVTMFGR.W_KEY,QTY_OH, INSTORE,ISNULL(INVTLOT.LOTCODE,CAST(' ' as CHAR(15))) as LotCode, 
						EXPDATE, ISNULL(INVTLOT.REFERENCE,CAST('' AS CHAR(10))) AS REFERENCE, ISNULL(INVTLOT.PONUM,CAST ('' AS CHAR (15))) AS PONUM, isnull(invtlot.LOTQTY, CAST(0.00 as numeric (12,2))) as LOTQTY	

				from	INVENTOR
						LEFT OUTER JOIN CUSTOMER ON INVENTOR.CUSTNO = CUSTOMER.CUSTNO
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
		--09/13/2013 DRP:		--WHERE	inventor.CUSTPARTNO>= case when @lcPartStart='*' then inventor.custPARTNO else @lcPartStart END
				--		and INVENTOR.CUSTPARTNO<= CASE WHEN @lcPartEnd='*' THEN INVENTOR.CUSTPARTNO ELSE @lcPartEnd END
				--		and PART_SOURC = 'CONSG' AND PART_SOURC <> 'Phantom'
				--		--07/07/2011:  and custname LIKE '%'+ @lcCust+'%'	
				--		and Customer.CUSTNAME like case when @lcCust ='*' then '%' else @lcCust+'%' end
				--		and WAREHOUSE like case when @lcWhse = '*' then '%' else @lcWhse+'%' end
				--		and inventor.STATUS <> 'Inactive'
				--		and INVTMFHD.IS_DELETED <> 1
				--		and invtmfgr.IS_DELETED <> 1	
				WHERE	inventor.CUSTPARTNO>= case when @lcPartStart='*' or @lcPartStart = '' then inventor.custPARTNO else @lcPartStart END
						and INVENTOR.CUSTPARTNO<= CASE WHEN @lcPartEnd='*' OR @lcPartEnd = '' THEN INVENTOR.CUSTPARTNO ELSE @lcPartEnd END
						and PART_SOURC = 'CONSG' AND PART_SOURC <> 'Phantom'
						and 1 = case when Customer.CUSTNAME like case when @lcCust ='*' then '%' else @lcCust+'%' end then 1
								when @lcCust is null or @lcCust = '' then 1 else 0 end
						and 1 = case when WAREHOUSE like case when @lcWhse = '*' then '%' else @lcWhse+'%'end then 1
								when @lcWhse IS null OR @lcWhse = '' then 1 else 0 end 
						and inventor.STATUS <> 'Inactive'
						and L.IS_DELETED <> 1
						and invtmfgr.IS_DELETED <> 1
						and inventor.STATUS <> 'INACTIVE' --07/31/2014 DRP:  added 
				) T1 cross join MICSSYS
				ORDER BY PART_NO, REV

				END
		end