

-- =============================================
-- Author:		Debbie
-- Create date: 08/11/2011
-- Description:	This Stored Procedure was created for the "Unused Inventory List"
-- Reports Using Stored Procedure:  icrpt8.rpt
-- Modified:	09/25/2012 DRP:  added the micssys.lic_name within the Stored Procedure and removed it from the Crystal Report
--				01/08/2013 DRP/YS:	The date filter was not properly filtering out the last used information and needed to be moved within the code.  
--									We also had to change the left outer join to inner join when selecting the data from the Tall table.  
--									The left outer join that I used to have was pulling ALL of the inventory parts no matter on the last used. 
--				09/13/2013 DRP:  per conversation with David/Yelena I went through and remove the '*' from the parameters   then added code how to handle null or '*'  should now work for both the CR and Stimulsoft reports
--				09/09/2014 DRP:  created this version of the procedure to work with the CloudManex . . . added @userId to properly filter out results based on the user id. 
--								 changed the @lcCust from using the Customer Name to @lcCustNo and using the Customer No and also added the Customer Selection section to work with the User Id.
--								 changed the @lcSupZero from Yes or No to be 1 = Yes Suppress records with Zero Qty on hand and 0 = No Don't Suppress any values.
--								 Changed @lcClass to be varchar(max) and created a new ParClass List code to work properly with the comma seperator. 
--				10/10/14 YS replace invtmfhd with 2 new tables
-- 01/06/2015 DRP: Added @customerStatus Filter
-- 04/14/15 YS Location length is changed to varchar(256)
--				06/22/2015 DRP:  changed part range paramaters from lcpart to lcuniq_key 
--				09/16/15 DRP:  Added the /*WAREHOUSE LIST*/,@lcUniqWh and the filter per request 
--				01/25/17 VL:	 added functional currency code
--- 03/28/17 YS changed length of the part_no column from 25 to 35
--08/01/17 YS moved part_class setup from "support" table to partClass table
--09/27/2017 Vijay G commented the zPoDmr table does not exist in the current database
-- 07/16/18 VL changed custname from char(35) to char(50)
-- =============================================

CREATE PROCEDURE [dbo].[rptInvtNotUsedWM]

		@lcClass as varchar(Max) = 'All'
		--,@lcPartStart as varchar(25)=''		--06/22/2015 DRP:  Removed
		--,@lcPartEnd as varchar(25)=''			--06/22/2015 DRP:  Removed
		,@lcUniq_keyStart char(10)= null
		,@lcUniq_keyEnd char(10)= null
		,@lcType as char (20) = 'Internal'			--where the user would specify Internal, Internal & In Store, In Store, Consigned
		,@lcCustNo varchar(max) = 'All'				
		,@lcDate as smalldatetime= null
		,@lcSupZero as char(3) = 'No'				--1 = Yes Suppress records with Zero Qty on hand and 0 = No Don't Suppress any values.
		,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
		,@lcUniqWh as varchar (max) = 'All'	--09/16/15 DRP:  Added
		,@userId as uniqueidentifier  = null
		
as		
Begin

		--- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--06/22/2015 DRP changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
	declare @lcPartStart char(35)='',@lcRevisionStart char(8)='',
		@lcPartEnd char(35)='',@lcRevisionEnd char(8)=''

		----09/13/2013 DRP: If null or '*' then pass '' for Part No
		--	IF @lcPartStart is null OR @lcPartStart = '*'
		--		select @lcPartStart=''
		--	IF @lcPartEnd is null OR @lcPartEnd = '*'
		--		select @lcPartEnd=''	
				
		--09/13/2013 DRP:  added code to handle Cust List
			--declare @Cust table(Cust char(35))
			--if @lcCust is not null and @lcCust <> ''
			--	insert into @Cust select * from dbo.[fn_simpleVarcharlistToTable](@lcCust,',')

	--06/22/2015 DRP changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
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
	--select @lcPartStart, @lcRevisionStart	,@lcPartEnd,@lcRevisionEnd

/*CUSTOMER LIST*/
--09/09/2014 DRP:  replaced the above with this Cust Selection List
	DECLARE  @tCustomer as tCustomer
			DECLARE @Customer TABLE (custno char(10))
		-- get list of Customers for @userid with access
		INSERT INTO @tCustomer EXEC aspmnxSP_Getcustomers4user @userid,null,@customerStatus ;
		--SELECT * FROM @tCustomer	
		IF @lcCustno is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select Custno from @tCustomer)
		ELSE

		IF  @lccustNo='All'	
		BEGIN
			INSERT INTO @Customer SELECT Custno FROM @tCustomer
		END		
		

-- 09/13/2013 YS/DRP added code to handle class list
	--DECLARE @PartClass TABLE (part_class char(8))
	--IF @lcClass is not null and @lcClass <>''
	--	INSERT INTO @PartClass SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcClass,',') --09/09/2014 DRP:  needed to remove this Part Class List and replace it with the below so it would work with the comma seperator
	
/*PARTCLASS LIST*/
DECLARE @PartClass TABLE (part_class char(8))
	IF @lcClass is not null and @lcClass <>'' and @lcClass <> 'All'
		INSERT INTO @PartClass SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcClass,',')
			
	else
	if @lcClass = 'All'
	begin
	--08/01/17 YS moved part_class setup from "support" table to partClass table
		--insert into @PartClass SELECT TEXT2 AS PART_CLASS FROM SUPPORT WHERE FIELDNAME = 'PART_CLASS'
		insert into @PartClass SELECT part_class FROM partClass
	end	

/*WAREHOUSE LIST*/	--09/16/15 DRP:  Added
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

if (@lcType = 'Consigned')
begin
-- 04/14/15 YS Location length is changed to varchar(256)
-- 01/25/17 VL added functional currency code
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 07/16/18 VL changed custname from char(35) to char(50)
declare  @zInvRep table	(uniq_key char(10), part_no char(35), revision char (8), descript char(45), custno char(10), custname char(50)
						, part_sourc char(10), part_class char(8), part_type char (8), uniqmfgrhd char (10), partmfgr char(8), mfgr_pt_no char(30)
						, warehouse char (6), w_key char (10),location varchar (256),stdcost numeric(12,5), qty_oh numeric (12,2), extcost numeric(12,2) 
						,Instore bit,lastused  smalldatetime, stdcostPR numeric(12,5),extcostPR numeric(12,2), PSymbol char(3), FSymbol char(3))
						;
 
		WITH PARTS AS
		--				10/10/14 YS replace invtmfhd with 2 new tables
		(
					SELECT  inventor.uniq_key,inventor.CUSTPARTNO as part_no,inventor.CUSTREV as revision,inventor.descript,inventor.CUSTNO,CUSTNAME
					,Part_sourc,Part_class,Part_type, L.UNIQMFGRHD, PARTMFGR, MFGR_PT_NO
					, WAREHOUSE, W_KEY ,INVTMFGR.LOCATION,STDCOST, QTY_OH, ROUND(STDCOST * QTY_OH ,5) AS ExtCost, INSTORE
					,cast (null as smalldatetime) as LastUsed
					-- 01/25/17 VL added functional currency code, symbol will be updated later if FC installed
					,STDCOSTPR, ROUND(STDCOSTPR * QTY_OH ,5) AS ExtCostPR
					 
					FROM	INVENTOR
					--	10/10/14 YS replace invtmfhd with 2 new tables
					--INNER JOIN INVTMFHD ON INVENTOR.UNIQ_KEY = INVTMFHD.UNIQ_KEY
					INNER JOIN InvtMPNLink L ON Inventor.Uniq_key=l.Uniq_key
					INNER JOIN MfgrMaster M ON l.mfgrMasterId=M.MfgrMasterId
					INNER JOIN INVTMFGR ON L.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD
					LEFT OUTER JOIN CUSTOMER ON INVENTOR.CUSTNO = CUSTOMER.CUSTNO
					INNER JOIN WAREHOUS ON INVTMFGR.UNIQWH = WAREHOUS.UNIQWH
--09/13/2013 DRP:		--where invtmfhd.IS_DELETED =0
					--and INVTMFGR.IS_DELETED = 0
					--and inventor.CUSTPARTNO>= case when @lcPartStart='*' then inventor.CUSTPARTNO else @lcPartStart END
					--and INVENTOR.CUSTPARTNO<= CASE WHEN @lcPartEnd='*' THEN INVENTOR.CUSTPARTNO ELSE @lcPartEnd END
					--and PART_CLASS LIKE CASE WHEN @lcclass='*' THEN '%' ELSE @lcclass+'%' END
					--and PART_SOURC = 'CONSG'
					--and Customer.CUSTNAME like case when @lcCust ='*' then '%' else @lcCust+'%' end
					--and QTY_OH> CASE WHEN @lcSupZero = 'Yes' then 0.00 else -1 end
					where l.IS_DELETED =0
					and INVTMFGR.IS_DELETED = 0
					and (custpartno+custrev BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)
					--and inventor.CUSTPARTNO>= case when @lcPartStart='' OR  @lcPartStart='*'  then CUSTPARTNO else @lcPartStart END	--06/22/2015 DRP:  Removed
					--and custPARTNO<= CASE WHEN @lcPartEnd='' OR @lcPartEnd='*' THEN custPARTNO ELSE @lcPartEnd END					--06/22/2015 DRP:  Removed
					--and 1 = case when PART_CLASS like Case when @lcClass = '*' then '%' else @lcClass+'%' end then 1 
					--		when @lcClass IS Null OR @lcClass='' THEN 1 else 0 end 	 --09/09/2014 DRP:  changed to work with the new PartClass selection below
					and 1 = case when PART_CLASS In (select PART_CLASS from @PartClass) then 1 else 0 end 
					and PART_SOURC = 'CONSG'
					--and 1 = case when Customer.CUSTNAME like case when @lcCust ='*' then '%' else @lcCust+'%' end then 1
					--		when @lcCust is null or @lcCust = '' then 1 else 0 end --09/09/2014 DRP:  changes to work with CustNo and UserId below 
					and 1= case WHEN inventor.custNO IN (SELECT custno FROM @CUSTOMER) THEN 1 ELSE 0  END 
					and QTY_OH> CASE WHEN @lcSupZero = 'Yes' then 0.00 else -1 end
					and (@lcUniqWH='All' OR exists (select 1 from @Whse t inner join warehous w on t.uniqwh=w.uniqwh where w.uniqwh=WAREHOUS.uniqwh))	--09/15/15 DRP:  Added
					

		),
		zissu as
				(
				select UNIQMFGRHD,  MAX(date) as LastUsed
				from INVT_ISU
				where UNIQ_KEY IN (SELECT Uniq_key from Parts)
--01/08/2013 DRP:commented out --and DATE <= @lcDate +1
				group by UNIQMFGRHD
				
				)
				,
		 zrec as		
				(
				select UNIQMFGRHD, MAX(date) as LastUsed
				from INVT_REC
				where UNIQ_KEY IN (SELECT Uniq_key from Parts)
--01/08/2013 DRP:commented out	--and DATE <= @lcDate +1
				group by UNIQMFGRHD
								)
				,
		ztran as		
				(
				select UNIQMFGRHD, MAX(date) as LastUsed
				from INVTTRNS
				where UNIQ_KEY IN (SELECT Uniq_key from Parts)
--01/08/2013 DRP:commented out	--and DATE <= @lcDate +1
				group by UNIQMFGRHD
				)
				,

		zResv as
				(
				Select invtmfgr.UNIQMFGRHD, max(INVT_res.datetime) as LastUsed
				from invt_res
				inner join invtmfgr on invt_res.w_key = invtmfgr.w_key
				where invtmfgr.UNIQ_KEY in (select uniq_key from parts)
--01/08/2013 DRP:commented out	--and DATETIME <= @lcDate +1
				group by INVTMFGR.UNIQMFGRHD
				)
				,
				
		tall as	(
				select Uniqmfgrhd, MAX(lastused) as LastUsed
				from	(select zissu.* from zissu
						union all
						select zrec.* from zrec
						union all
						select ztran.* from ztran 
						union all
						select zResv.* from zResv
						)T 
				group by uniqmfgrhd HAVING MAX(LASTUSED) <= dateadd(DAY,1,@lcDate)
--01/08/2013 DRP/YS:  removed the following and replaced it with the above.    				
				--group by uniqmfgrhd 				
				)
		-- 01/25/17 VL added functional currency code
		INSERT INTO @zInvRep (uniq_key ,part_no , revision, descript, custno , custname 
				, part_sourc , part_class , part_type , uniqmfgrhd , partmfgr , mfgr_pt_no 
				, warehouse , w_key ,location ,stdcost , qty_oh , extcost 
				,instore,lastused, stdcostPR, extcostPR) 				
		select Parts.uniq_key ,Parts.part_no , Parts.revision, Parts.descript, Parts.custno , Parts.custname 
				, Parts.part_sourc ,Parts.part_class , Parts.part_type , Parts.uniqmfgrhd , Parts.partmfgr , Parts.mfgr_pt_no 
				, Parts.warehouse , Parts.w_key ,Parts.location ,Parts.stdcost , Parts.qty_oh , Parts.extcost ,PARTS.INSTORE
				,tall.lastused, Parts.stdcostPR, Parts.extcostPR
				 FROM Parts inner join Tall on PARTS.UNIQMFGRHD = tall.UNIQMFGRHD

		-- 01/25/17 VL added functional currency code
		IF dbo.fn_IsFCInstalled() = 1
			UPDATE @zInvRep SET PSymbol = PF.Symbol, FSymbol = FF.Symbol
				FROM @zInvRep zInvRep INNER JOIN Inventor ON zInvRep.Uniq_key = Inventor.Uniq_key 
					INNER JOIN Fcused PF ON Inventor.PrFcused_uniq = PF.Fcused_uniq
					INNER JOIN Fcused FF ON Inventor.FuncFcused_uniq = FF.Fcused_uniq	
									
		select I1.* from @zinvrep as I1 order by part_no

	End
	
	
	
else if (@lcType <> 'Consigned') 
	Begin 
	-- 04/14/15 YS Location length is changed to varchar(256)
	-- 01/25/17 VL added functional currency code
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 07/16/18 VL changed custname from char(35) to char(50)
declare  @zInvRep2 table	(uniq_key char(10), part_no char(35), revision char (8), descript char(45), custno char(10), custname char(50)
						, part_sourc char(10), part_class char(8), part_type char (8), uniqmfgrhd char (10), partmfgr char(8), mfgr_pt_no char(30)
						, warehouse char (6), w_key char (10),location varchar (256),stdcost numeric(12,5), qty_oh numeric (12,2), extcost numeric(12,2) 
						,instore bit,lastused  smalldatetime, stdcostPR numeric(12,5),extcostPR numeric(12,2), PSymbol char(3), FSymbol char(3))
						;
 
WITH PARTS AS
--				10/10/14 YS replace invtmfhd with 2 new tables
(
					SELECT  inventor.uniq_key,inventor.PART_NO,inventor.REVISION,inventor.descript,inventor.CUSTNO,CUSTNAME
					,Part_sourc,Part_class,Part_type, L.UNIQMFGRHD, PARTMFGR, MFGR_PT_NO
					, WAREHOUSE, W_KEY ,INVTMFGR.LOCATION,STDCOST, QTY_OH, ROUND(STDCOST * QTY_OH ,5) AS ExtCost, INSTORE
					,cast (null as smalldatetime) as LastUsed, STDCOSTPR, ROUND(STDCOSTPR * QTY_OH ,5) AS ExtCostPR
					 
					FROM	INVENTOR
					--				10/10/14 YS replace invtmfhd with 2 new tables
					--INNER JOIN INVTMFHD ON INVENTOR.UNIQ_KEY = INVTMFHD.UNIQ_KEY
					INNER JOIN InvtMPNLink L ON Inventor.UNIQ_KEY=l.uniq_key
					INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
					INNER JOIN INVTMFGR ON L.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD
					LEFT OUTER JOIN CUSTOMER ON INVENTOR.CUSTNO = CUSTOMER.CUSTNO
					INNER JOIN WAREHOUS ON INVTMFGR.UNIQWH = WAREHOUS.UNIQWH
--09/13/2013 DRP:	--where invtmfhd.IS_DELETED =0
					--and INVTMFGR.IS_DELETED = 0
					--and inventor.PART_NO>= case when @lcPartStart='*' then inventor.PART_NO else @lcPartStart END
					--and INVENTOR.PART_NO<= CASE WHEN @lcPartEnd='*' THEN INVENTOR.PART_NO ELSE @lcPartEnd END
					--and PART_CLASS LIKE CASE WHEN @lcclass='*' THEN '%' ELSE @lcclass+'%' END
					--AND INSTORE = CASE WHEN @lcType = 'Internal' then 0 when @lcType = 'In Store' then 1 when @lctype = 'Internal & In Store' then instore end
					--and PART_SOURC <> 'CONSG'
					--and QTY_OH> CASE WHEN @lcSupZero = 'Yes' then 0.00 else -1 end
					where l.IS_DELETED =0
					and INVTMFGR.IS_DELETED = 0
					--and 1 = case when PART_CLASS like Case when @lcClass = '*' then '%' else @lcClass+'%' end then 1 
					--	when @lcClass IS Null OR @lcClass='' THEN 1 else 0 end --09/09/2014 DRP:  changed to work with the new PartClass selection below
					and 1 = case when PART_CLASS In (select PART_CLASS from @PartClass) then 1 else 0 end 
					and (PART_NO+revision  BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)
					--and Part_no>= case when @lcPartStart='' OR  @lcPartStart='*'  then Part_no else @lcPartStart END	--06/22/2015 DRP:  Removed
					--and PART_NO<= CASE WHEN @lcPartEnd='' OR @lcPartEnd='*' THEN PART_NO ELSE @lcPartEnd END			--06/22/2015 DRP:  Removed
					AND INSTORE = CASE WHEN @lcType = 'Internal' then 0 when @lcType = 'In Store' then 1 when @lctype = 'Internal & In Store' then instore end
					and PART_SOURC <> 'CONSG'
					and QTY_OH> CASE WHEN @lcSupZero = 'Yes' then 0.00 else -1 end
					and (@lcUniqWH='All' OR exists (select 1 from @Whse t inner join warehous w on t.uniqwh=w.uniqwh where w.uniqwh=WAREHOUS.uniqwh))	--09/15/15 DRP:  Added
					

		),
		zissu as
				(
				select UNIQMFGRHD,  MAX(date) as LastUsed
				from INVT_ISU
				where UNIQ_KEY IN (SELECT Uniq_key from Parts)
--01/08/2013 DRP:commented out		--and DATE <= @lcDate +1
				group by UNIQMFGRHD
				)
				,
		 zrec as		
				(
				select UNIQMFGRHD, MAX(date) as LastUsed
				from INVT_REC
				where UNIQ_KEY IN (SELECT Uniq_key from Parts)
--01/08/2013 DRP:commented out		--and DATE <= @lcDate +1
				group by UNIQMFGRHD
				)
				,
		ztran as		
				(
				select UNIQMFGRHD, MAX(date) as LastUsed
				from INVTTRNS
				where UNIQ_KEY IN (SELECT Uniq_key from Parts)
--01/08/2013 DRP:commented out		--and DATE <= @lcDate +1
				group by UNIQMFGRHD
				)
				,
		zPoRec as
				(
				select porecdtl.UNIQMFGRHD,  MAX(recvdate) as LastUsed
				from PORECDTL
				inner join INVTMFGR on PORECDTL.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD
				where uniq_key in (select uniq_key from PARTS)
--01/08/2013 DRP:commented out		--and RECVDATE <= @lcDate +1
				group by porecdtl.UNIQMFGRHD
				)
				,
		-- 01/25/17 VL comment out next line for now because porecmrb data struture is changed, will come back later to modify it
		------------------------------------------------------------------------------------
--		zPoDmr as		
--				(
--				Select PORECDTL.UNIQMFGRHD, MAX(dmr_date) as LastUsed
--				from PORECDTL
--				inner join INVTMFGR on PORECDTL.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD
--				inner join PORECMRB on PORECDTL.TRANSNO = PORECMRB.TRANSNO
--				where UNIQ_KEY in (select UNIQ_KEY from PARTS)
----01/08/2013 DRP:commented out		--and DMR_DATE <= @lcDate +1
--				and PORECDTL.REJQTY <> 0.00
--				group by PORECDTL.UNIQMFGRHD
--				)
--				,
		zResv as
				(
				Select invtmfgr.UNIQMFGRHD, max(INVT_res.datetime) as LastUsed
				from invt_res
				inner join invtmfgr on invt_res.w_key = invtmfgr.w_key
				where invtmfgr.UNIQ_KEY in (select uniq_key from parts)
--01/08/2013 DRP:commented out		--and DATETIME <= @lcDate +1
				group by INVTMFGR.UNIQMFGRHD
				)
				,
				
		tall as	(
				select Uniqmfgrhd, MAX(lastused) as LastUsed
				from	(select zissu.* from zissu
						union all
						select zrec.* from zrec
						union all
						select ztran.* from ztran 
						union all
						select zPoRec.* from zPoRec
						--09/27/2017 table does not exist in the current database
						--union all
						--select zPoDmr.* from zPoDmr
						union all
						select zResv.* from zResv
						)T
				group by uniqmfgrhd HAVING MAX(LASTUSED) <= dateadd(DAY,1,@lcDate)
--01/08/2013 DRP/YS:  removed the following and replaced it with the above.    				
				--group by uniqmfgrhd 
				)

		-- 01/25/17 VL added functional currency code
		INSERT INTO @zInvRep2(uniq_key ,part_no , revision, descript, custno , custname 
				, part_sourc , part_class , part_type , uniqmfgrhd , partmfgr , mfgr_pt_no 
				, warehouse , w_key ,location ,stdcost , qty_oh , extcost,instore 
				,lastused, stdcostPR, extcostPR) 				
		select Parts.uniq_key ,Parts.part_no , Parts.revision, Parts.descript, Parts.custno , Parts.custname 
				, Parts.part_sourc ,Parts.part_class , Parts.part_type , Parts.uniqmfgrhd , Parts.partmfgr , Parts.mfgr_pt_no 
				, Parts.warehouse , Parts.w_key ,Parts.location ,Parts.stdcost , Parts.qty_oh , Parts.extcost,PARTS.INSTORE 
				,tall.lastused, Parts.stdcostPR, Parts.extcostPR FROM Parts inner JOIN Tall on PARTS.UNIQMFGRHD = tall.UNIQMFGRHD

		-- 01/25/17 VL added functional currency code
		IF dbo.fn_IsFCInstalled() = 1
			UPDATE @zInvRep2 SET PSymbol = PF.Symbol, FSymbol = FF.Symbol
				FROM @zInvRep2 zInvRep INNER JOIN Inventor ON zInvRep.Uniq_key = Inventor.Uniq_key 
					INNER JOIN Fcused PF ON Inventor.PrFcused_uniq = PF.Fcused_uniq
					INNER JOIN Fcused FF ON Inventor.FuncFcused_uniq = FF.Fcused_uniq	
									
		select I2.* from @zinvrep2 as I2 ORDER BY part_no
end
end