
		-- =============================================
		-- Author:			Debbie 
		-- Create date:		03/12/2013
		-- Description:		Created for the MRP PO Action Report ~ by Buyer
		-- Reports:			mrppoact.rpt 
		-- Modifications:	09/13/2013 DRP:  per discussion with Yelena/David . . . I took example code from Yelena's [rptMrpPoActionDetail] procedure and implemented it throughout this procedure so that it will work properly with Webmanex
		--					10/01/2013 DRP:  Removed @lcWhere and modificed the MrpFullActionView call per Yelena changes.
		--					12/03/2013  YS:  Default 'All' where multiple selection is allowed 
		--										added @userid and get list of approved suppliers for this user
		--					01/22/2014 DRP: we found that if the user left All for the supplier that it was incorrectly not displaying the suppliers that were approved for the userid.  It was bringing forward all suppliers regardless if the user was approved for the Userid or not. 
		--					12/12/14 DS Added supplier status filter
		--					03/02/15 DRP: changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
		--- 06/13/18 YS contract structure has changed
-- 07/16/18 VL changed supname from char(30) to char(50)
		-- =============================================
		CREATE PROCEDURE  [dbo].[rptMrpPoActionBuyer]


--10/01/2013 DRP:	@lcWhere varchar(max)= '1=1'	-- this will actually be populated from the MRP Filter screen, using Vicky's code
		-- 09/13/2013 DRP remove bomparentrev parameter, changed @lcBomParentPart to @lcUniqBomParent
		@lcUniqBomParent char(10)=''	-- this is the Bom Parent Part.  This too will be populated by the MRP Filter Screen.
		--09/13/2013		--,@lcBomParentPart char(25)=''	-- this is the Bom Parent Part.  This too will be populated by the MRP Filter Screen.
		--09/13/2013		--,@lcBomPArentRev char(8)=''		-- this is the BOM Revision.  This too will be populated by the MRP Filter screen.
		,@lcUniq_keyStart char(10)=''
		--,@lcPartStart as varchar(25)=''	--This is the component start range that will be populated by the users within the report parameter selection screen		--03/02/15 DRP:  replaced by @lcUniq_keyStart
		--,@lcPartEnd as varchar(25)=''	--This is the component end range that will be populated by the users within the report parameter selection screen				--03/02/15 DRP:  replaced by @lcUniq_keyEnd
		,@lcUniq_keyEnd char(10)=''
		,@lcLastAction as smalldatetime = null	--This is the Last Action Date filter which should defaulted from the MRP Find Filter screen.  Vicky will have to pass this to the procedure.
		-- 12/03/13 YS if multiple classes need to have varchar(max) type for the parameter and All for ALl instead of ''
		,@lcClass as varchar (max) = 'All'	--user would select to include all Classes or select from selection list.
		-- 12/03/13 YS if multiple classes need to have varchar(max) type for the parameter  and All for ALl instead of ''
		,@lcBuyer varchar(max) = 'All'			-- user would select to include ALL buyers or Select from Selection list. 
		,@lcContract char(50) = 'All'	-- All = All Parts Contract and Non-Contract
										-- Parts with no Supplier Contract = results will only display parts with no Supplier Contract in the system.
										-- Parts with Supplier Contract = results will only display parts with Supplier Contracts associated to it. 
		-- 12/03/13 YS if multiple classes need to have varchar(max) type for the parameter and All for ALl instead of ''
		,@lcUniqSupNo varchar(max) = 'All'	-- if user selects "Parts with Supplier Contracts" then this second parameter will be display to select from a Supplier Selection box. 
		-- 12/03/13 added userid
		,@userid uniqueidentifier = NULL
		,@supplierStatus varchar(20) = 'All'
				
			
		aS
		BEGIN

/*PART RANGE*/
		SET NOCOUNT ON;
		--03/02/15 DRP changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
		declare @lcPartStart char(25)='',@lcRevisionStart char(8)='',
		@lcPartEnd char(25)='',@lcRevisionEnd char(8)=''
		
		--03/02/15 DRP changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key	
		--09/13/2013 DRP: If null or '*' then pass ''
		IF  @lcUniq_keyStart IS NULL or  @lcUniq_keyStart ='' 
			SELECT @lcPartStart=' ', @lcRevisionStart=' '
		ELSE
		SELECT @lcPartStart = ISNULL(I.Part_no,' '), 
			@lcRevisionStart = ISNULL(I.Revision,' ') 
		FROM Inventor I where Uniq_key=@lcUniq_keyStart
		
		-- find ending part number
		IF  @lcUniq_keyEnd IS NULL or  @lcUniq_keyEnd ='' 
			SELECT @lcPartEnd = REPLICATE('Z',25), @lcRevisionEnd=REPLICATE('Z',8)
		ELSE
			SELECT @lcPartEnd =ISNULL(I.Part_no,' '), 
				@lcRevisionEnd = ISNULL(I.Revision,' ') 
			FROM Inventor I where Uniq_key=@lcUniq_keyEnd	
		
	
				
		-- 09/13/2013 YS/DRP if no @lcLastAction provided use default	
			if @lcLastAction is null
			SELECT @lcLastAction=DATEADD(Day,Mpssys.VIEWDAYS,getdate()) FROM MPSSYS 
			 
		--declaring the table so that it can be populated using Yelena Stored Procedured called MrpFullActionView
			Declare @MrpActionView as table (Uniq_key char(10),Part_class char(8),Part_Type char(8),Part_no char(25),Revision char(8)
											,CustPartNo char(25),CustRev char(8),Descript char(45),Part_sourc char(10),UniqMrpAct char(10))
		--09/13/2013 YS/DRP changed to receive @lcUniqBomParent for the parameters have to send part and revision
			DECLARE @lcBomParentPart char(25)='',@lcBomPArentRev char(8) =''
			if @lcUniqBomParent is null OR @lcUniqBomParent=''
				SELECT @lcBomParentPart ='',@lcBomPArentRev =''
			else
				SELECT @lcBomParentPart = I.Part_no,@lcBomPArentRev =I.Revision FROM INVENTOR I where UNIQ_KEY=@lcUniqBomParent 
		--09/13/2013 YS/DRP}	
--10/01/2013 DRP:  modified the call to the MrpFullActionView below											
			--Insert into @MrpActionView exec MrpFullActionView @lcWhere,@lcBomParentPart,@lcBomPArentRev
			Insert into @MrpActionView exec MrpFullActionView @lcBomParentPart=@lcBomParentPart,@lcBomPArentRev=@lcBomPArentRev									
			
			--12/03/13 YS get list of approved suppliers for this user
			DECLARE @tSupplier tSupplier

			INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, @supplierStatus;

			
			--09/13/2013 YS/DRP added code to handle suplier list
			DECLARE @Supplier TABLE (Uniqsupno char(10))
--01/23/2014 FRP:			--SELECT @lcUniqSupno =  CASE WHEN @lcContract <>'Parts with Supplier Contract' THEN '' 
							--			ELSE @lcUniqSupno END
			SELECT @lcUniqSupno =  CASE WHEN @lcContract ='Parts with no Supplier Contract' THEN '' 
									ELSE @lcUniqSupno END
						
			--IF @lcUniqSupno is not null and @lcUniqSupno <>'' and 
			--INSERT INTO @Supplier SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcUniqSupno,',')
			 --12/03/13	YS	use 'All' in place of ''. Empty or null means no supplier is entered  	
			IF @lcUniqSupNo<>'All' and @lcUniqSupNo<>'' and @lcUniqSupNo is not null
				insert into @Supplier  select * from  dbo.[fn_simpleVarcharlistToTable](@lcUniqSupNo,',') 
					WHERE cast(ID as char(10)) IN (SELECT UniqSupno from @tSupplier)
			ELSE
			BEGIN
			IF @lcUniqSupNo='All'
			BEGIN
				-- select only one with access
				insert into @Supplier select UniqSupno from @tSupplier
			END
			END			
			--SELECT * FROM @Supplier



		--09/13/2013 YS/DRP added code to handle buyer list
			DECLARE @BuyerList TABLE (BUYER_TYPE char(3))
			 --12/03/13	YS	use 'All' in place of ''.
			IF @lcBuyer is not null and @lcBuyer <>'' and @lcBuyer <>'All'
				INSERT INTO @BuyerList SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcBuyer,',')

		--09/13/2013 YS/DRP added code to handle class list
			DECLARE @PartClass TABLE (part_class char(8))
			 --12/03/13	YS	use 'All' in place of ''.
			IF @lcClass is not null and @lcClass <>'' and @lcClass <>'All'
				INSERT INTO @PartClass SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcClass,',')


		--Below will gather all of the MRP Action information that pertain to PO Actions

		--&&& Begin "ALL":  This section will collect all PO Actions regardless if it has a Contract or not
		-- 12/03/13 @userid controls which supplier user can see
			if (@lcContract = 'All')
				--- 06/13/18 YS contract structure has changed
				Begin
				select	m.PART_NO,m.revision,m.PART_CLASS,m.PART_TYPE,m.DESCRIPT,i.U_OF_MEAS,i.PUR_UOFM,I.STDCOST,i.buyer_type,MrpAct.* 
						,isnull(h.UniqSupno,'')as UniqSupno,isnull(supinfo.SupName,'')as SupName,ISNULL(supinfo.phone,'') as Phone,ISNULL(supinfo.fax,'') as Fax
						,h.STARTDATE as ContractStartDt,h.EXPIREDATE as ContractExpDt
						,micssys.LIC_NAME,MPSSYS.MRPDATE
				from	@MrpActionView M 
						inner join INVENTOR I on m.Uniq_key = i.uniq_key 
						INNER JOIN MRPACT on M.UniqMrpAct = Mrpact.UniqMrpAct
						left outer join CONTRACT on MRPACT.UNIQ_KEY = contract.UNIQ_KEY 
						left outer join contractHeader h on contract.contracth_unique=h.contracth_unique
						left outer join SUPINFO on H.UniqSupno = SUPINFO.UNIQSUPNO 
						cross join MICSSYS 
						cross join MPSSYS
				where	CHARINDEX('PO',Action)<>0
				
						--09/13/2013 YS/DRP change default for part number from '*' to '', indicating all parts are to be selected
						and m.Part_no>= case when @lcPartStart='' then m.Part_no else @lcPartStart END
						and m.PART_NO<= CASE WHEN @lcPartEnd='' THEN m.PART_NO ELSE @lcPartEnd END
						--09/13/2013 YS/DRP change to be able to use multiple part clasees CSV
						--12/03/13 YS use 'All' for all 
						AND 1= CASE WHEN @lcClass='All' THEN 1    -- any class
						WHEN m.Part_class IN (SELECT Part_class FROM @PartClass) THEN 1 ELSE 0  END
						--09/13/2013 YS/DRP change to be able to use multiple buyers CSV
						--12/03/13 YS use 'All' for All
						AND 1= CASE WHEN @lcBuyer ='All' THEN 1    -- any class
						WHEN I.BUYER_TYPE IN (SELECT BUYER_TYPE FROM @BuyerList) THEN 1 ELSE 0  END
						and DATEDIFF(Day,MRPACT.DTTAKEACT,@lcLastAction)>=0 
						--12/03/13 if contract is available show only contract for which the user has an acess, based on a supplier
						-- use @tSupplier here, b/c @Supplier will be empty
--01/23/2014 DRP:  --	and 1 = CASE WHEN Contract.UniqSupno  IS null then 1 --- no supplier/contract no restrictions
--									when Contract.UniqSupno IN (select UniqSupno from @tSupplier) THEN 1 ELSE 0 END
						--- 06/13/18 YS contract structure has changed
						AND (h.uniqsupno is null or  EXISTS (select 1 from @supplier s where s.uniqsupno=h.uniqsupno))
						--1= case WHEN CONTRACT.UNIQSUPNO IN (SELECT Uniqsupno FROM @Supplier) THEN 1 ELSE 0  END			 
						--09/13/2013 YS/DRP move this code to the LEFT OUTER JOIN
						--09/13/2013 YS/DRP contract.PRIM_SUP = 1
				ORDER BY PART_CLASS,Part_no,REVISION,DTTAKEACT
			end
		--&&& END "ALL"

		--&&& Begin "No Supplier Contract":  This will list all PO Actions for parts that have no existing Supplier Contract. 
			else if (@lcContract = 'Parts with no Supplier Contract') 
				Begin
				-- 07/16/18 VL changed supname from char(30) to char(50)
				select	m.PART_NO,m.revision,m.PART_CLASS,m.PART_TYPE,m.DESCRIPT,i.U_OF_MEAS,i.PUR_UOFM,I.STDCOST,i.buyer_type,MrpAct.* 
						,CAST('' as CHAR(10)) as UniqSupNo,CAST('' as char(50)) as SupName,CAST('' as CHAR(15)) as Phone,CAST('' as CHAR(15)) as Fax
						,cast(null as smalldatetime) as   ContractStartDt,cast(null as smalldatetime) as  ContractExpDt
						,micssys.LIC_NAME,MPSSYS.MRPDATE
				from	@MrpActionView M 
						inner join INVENTOR I on m.Uniq_key = i.uniq_key 
						INNER JOIN MRPACT on M.UniqMrpAct = Mrpact.UniqMrpAct
						cross join MICSSYS 
						cross join MPSSYS
				where	CHARINDEX('PO',Action)<>0
						--09/13/2013 YS/DRP change default for part number from '*' to '', indicating all parts are to be selected
						and m.Part_no>= case when @lcPartStart='' then m.Part_no else @lcPartStart END
						and m.PART_NO<= CASE WHEN @lcPartEnd='' THEN m.PART_NO ELSE @lcPartEnd END
						--09/13/2013 YS/DRP change to be able to use multiple part clasees CSV
						--12/03/13 YS use 'All' for all 
						AND 1= CASE WHEN @lcClass ='All' THEN 1    -- any class
						WHEN m.Part_class IN (SELECT Part_class FROM @PartClass) THEN 1 ELSE 0  END
						--09/13/2013 YS/DRP change to be able to use multiple buyers CSV
						--12/03/13 YS use 'All' for all 
						AND 1= CASE WHEN @lcBuyer ='All' THEN 1    -- any class
						WHEN I.BUYER_TYPE IN (SELECT BUYER_TYPE FROM @BuyerList) THEN 1 ELSE 0  END
						and DATEDIFF(Day,MRPACT.DTTAKEACT,@lcLastAction)>=0  
						and i.UNIQ_KEY not in (select UNIQ_KEY from CONTRACT)
				ORDER BY PART_CLASS,Part_no,REVISION,DTTAKEACT
			end
		--&&& END "No Supplier Contract"

		--&&& Begin "With Supplier Contract":  This will list all PO Actions for parts that have existing Supplier Contract. 
			else if (@lcContract = 'Parts with Supplier Contract') 
				Begin
				--- 06/13/18 YS contract structure has changed
				select	m.PART_NO,m.revision,m.PART_CLASS,m.PART_TYPE,m.DESCRIPT,i.U_OF_MEAS,i.PUR_UOFM,I.STDCOST,i.buyer_type,MrpAct.* 
						,supinfo.UniqSupNo,supinfo.SupName,supinfo.phone,supinfo.fax,h.STARTDATE as ContractStartDt,h.EXPIREDATE as ContractExpDt
						,micssys.LIC_NAME,MPSSYS.MRPDATE
				from	@MrpActionView M 
						inner join INVENTOR I on m.Uniq_key = i.uniq_key 
						INNER JOIN MRPACT on M.UniqMrpAct = Mrpact.UniqMrpAct
						inner join CONTRACT on i.UNIQ_KEY = contract.UNIQ_KEY
						inner join contractheader h on contract.contractH_unique=h.ContractH_unique
						inner join SUPINFO on h.UniqSupno = SUPINFO.UNIQSUPNO
						cross join MICSSYS 
						cross join MPSSYS
				where	CHARINDEX('PO',Action)<>0
						--09/13/2013 YS/DRP change default for part number from '*' to '', indicating all parts are to be selected
						and m.Part_no>= case when @lcPartStart='' then m.Part_no else @lcPartStart END
						and m.PART_NO<= CASE WHEN @lcPartEnd='' THEN m.PART_NO ELSE @lcPartEnd END
						--09/13/2013 YS/DRP change to be able to use multiple part clasees CSV
						--12/03/13 YS use 'All' for all 
						AND 1= CASE WHEN @lcClass ='All' THEN 1    -- any class
						WHEN m.Part_class IN (SELECT Part_class FROM @PartClass) THEN 1 ELSE 0  END
						--09/13/2013 YS/DRP change to be able to use multiple buyers CSV
						--12/03/13 YS use 'All' for all 
						AND 1= CASE WHEN @lcBuyer ='All' THEN 1    -- any class
						WHEN I.BUYER_TYPE IN (SELECT BUYER_TYPE FROM @BuyerList) THEN 1 ELSE 0  END
						and DATEDIFF(Day,MRPACT.DTTAKEACT,@lcLastAction)>=0
						and h.primSupplier = 1
						--09/13/2013 YS/DRP added ability to have CSV for the supplier
						--12/03/13 YS use 'All' for all 
--01-24-2014 DRP:		AND 1= CASE WHEN @lcUniqSupno ='All' THEN 1    -- any supplier
--						WHEN SUPINFO.UNIQSUPNO IN (SELECT UniqSupno FROM @Supplier) THEN 1 ELSE 0  END
						--06/13/18 YS structure changed
						and EXISTS (select 1 from @supplier s where s.uniqsupno=h.uniqsupno) 
						--AND 1= case WHEN CONTRACT.UNIQSUPNO IN (SELECT Uniqsupno FROM @Supplier) THEN 1 ELSE 0  END			 

						
				ORDER BY PART_CLASS,Part_no,REVISION,DTTAKEACT
			end
		--&&& END "With Supplier Contract"

		END