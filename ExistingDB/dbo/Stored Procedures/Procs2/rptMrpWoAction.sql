
-- =============================================
-- Author:			Debbie
-- Create date:		11/12/2012
-- Description:		Created for the MRP Action Report ~ WO Actions within MRP
-- Reports:			mrprpt2.rpt 
-- Modified: 09/30/2013 YS remove lcWhere and add individual parameters	
--					10/30/13 DRP:  in order to get the WO Action report to only display PO Actions for results we had to remove the @mrpAction from the parameters
--								   and declared it within the procedure.
--					11/24/15 DRP:  Changed the parameters, Changed the record selection section to work with the WebManex version of the report.  Make note that in the previous version we were not pulling Phantom action fwd.  But I noticed in VFP that we did, not sure if there was an reason for removing them or not. 
--09/29/17 YS changed contract structure. Need to check why we need contract here at all
-- 09/26/19 YS changed part no and cust part no from char(25) to char(35)
-- 12/11/20 now the buyer is not saved in Buyer_type, it's saved in AspnetBuyer
-- =============================================

		CREATE PROCEDURE  [dbo].[rptMrpWoAction]
		--declare
				---10/01/13 YS remove @lcWhere
				--@lcWhere varchar(max)= '1=1'	-- this will actually be populated from the MRP Filter screen, using Vicky's code
				-- 10/01/13 YS Beginning of new parameters. All parameters have default value and are optional
				
		
				@lcUniqBomParent char(10)=''	-- this is the Bom Parent Part.  This too will be populated by the MRP Filter Screen.
				,@lcUniq_keyStart char(10)=''
				,@lcUniq_keyEnd char(10)=''
				,@lcLastAction as smalldatetime = null	
				,@lcClass as varchar (max) = 'All'		--user would select to include all Classes or select from selection list.
				,@lcBuyer varchar(max) = 'All'			-- user would select to include ALL buyers or Select from Selection list. 
				, @userId uniqueidentifier=null 	
				,@lcPartType as varchar(max) = 'All'	--11/24/15 DRP:
					
				/*
				/*REPLACED WITH THE ABOVE*/
				@StartPartNo char(25)=' ',
				@EndPartNo char(25)=' ',
				@Buyer char(3)=' ',
				@PartClass char(8)=' ',
				@partType char(8)=' ',
				@partStatus varchar(10)='All',
				@MrCode varchar(20)=' ',
				@ProjectUnique char(10)=' ',
				@LastActionDate smalldatetime=NULL
				-- 10/01/13 YS End of new parameters.
				,@lcBomParentPart char(25)=''	-- this is the Bom Parent Part.  This too will be populated by the MRP Filter Screen.
				,@lcBomPArentRev char(8)=''		-- this is the BOM Revision.  This too will be populated by the MRP Filter screen.
				*/
			
			
			--	@mrpAction varchar(50)='All WO Actions',   --10/30/13 DRP:  REMOVED FROM PARAMETER   
			--- possible values for mrpAction
			-- 'All Actions' - default
			-- 'All PO Actions'
			-- 'All WO Actions'
			-- 'Pull-Ins'
			-- 'Push-Outs'
			-- 'Release PO'
			-- 'Release WO'
			-- 'Cancel PO'
			-- 'Cancel WO'
				
			
		aS
		BEGIN



/*PART RANGE*/
SET NOCOUNT ON;
--11/24/15 DRP changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
-- 09/26/19 YS changed part no and cust part no from char(25) to char(35)
declare @lcPartStart char(35)='',@lcRevisionStart char(8)='',
	@lcPartEnd char(35)='',@lcRevisionEnd char(8)=''
		
		--11/24/15 DRP changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key	
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
				
		-- if no @lcLastAction provided use default	
			if @lcLastAction is null
			SELECT @lcLastAction=DATEADD(Day,Mpssys.VIEWDAYS,getdate()) FROM MPSSYS 
			 
		--declaring the table so that it can be populated using Yelena Stored Procedured called MrpFullActionView
		-- 09/26/19 YS changed part no and cust part no from char(25) to char(35)
			Declare @MrpActionView as table (Uniq_key char(10),Part_class char(8),Part_Type char(8),Part_no char(35),Revision char(8)
											,CustPartNo char(35),CustRev char(8),Descript char(45),Part_sourc char(10),UniqMrpAct char(10))

			-- 09/26/19 YS changed part no and cust part no from char(25) to char(35)
			DECLARE @lcBomParentPart char(35)='',@lcBomPArentRev char(8) =''
			if @lcUniqBomParent is null OR @lcUniqBomParent=''
				SELECT @lcBomParentPart ='',@lcBomPArentRev =''
			else
				SELECT @lcBomParentPart = I.Part_no,@lcBomPArentRev =I.Revision FROM INVENTOR I where UNIQ_KEY=@lcUniqBomParent 
			Insert into @MrpActionView exec MrpFullActionView @lcBomParentPart=@lcBomParentPart,@lcBomPArentRev=@lcBomPArentRev		
			 
			-- added code to handle buyer list
			-- 12/11/20 now the buyer is not saved in Buyer_type, it's saved in AspnetBuyer
			--DECLARE @BuyerList TABLE (BUYER_TYPE char(3))
			DECLARE @BuyerList TABLE (BuyerId uniqueidentifier)    
			--12/03/13 YS use 'All' in place of ''
			IF @lcBuyer is not null and @lcBuyer <>'' and @lcBuyer <>'All'
				INSERT INTO @BuyerList SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcBuyer,',')

			--  added code to handle class list
			DECLARE @PartClass TABLE (part_class char(8))
			-- use 'All' in place of ''
			IF @lcClass is not null and @lcClass <>'' and @lcClass <>'All'
				INSERT INTO @PartClass SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcClass,',')


/*RECORD SELECTION SECTION*/	
		select	m.PART_NO,m.revision,m.PART_CLASS,m.PART_TYPE,m.DESCRIPT,i.U_OF_MEAS,i.PUR_UOFM,I.STDCOST
				-- 12/11/20 VL also changed i.buyer_type to aspnet_users.username
				--,i.buyer_type
				,aspnet_Users.UserName
				,MrpAct.* 
				,MPSSYS.MRPDATE
		from	@MrpActionView M 
				inner join INVENTOR I on m.Uniq_key = i.uniq_key 
				INNER JOIN MRPACT on M.UniqMrpAct = Mrpact.UniqMrpAct
					--09/29/17 YS changed contract structure
				left outer join CONTRACT on MRPACT.UNIQ_KEY = contract.UNIQ_KEY 
				left outer join contractheader h on contract.contracth_unique=h.contracth_unique
				and h.primSupplier = 1
				left outer join SUPINFO on H.UniqSupno = SUPINFO.UNIQSUPNO 
				-- 12/11/20 VL also changed i.buyer_type to aspnet_users.username
				LEFT OUTER JOIN aspnet_Users ON i.AspnetBuyer = aspnet_Users.UserId
				cross join MPSSYS
		where	(Action LIKE '%WO%' OR Action like '%Order Kitted%'	OR ACTION LIKE '%Phantom%' or (ACTION LIKE '%Firm Planned%' AND LEFT(Ref,2) = 'WO')) 
				-- 08/08/13 YS change default for part number from '*' to '', indicating all parts are to be selected
				and m.Part_no>= case when @lcPartStart='' then m.Part_no else @lcPartStart END
				and m.PART_NO<= CASE WHEN @lcPartEnd='' THEN m.PART_NO ELSE @lcPartEnd END
				--08/08/13 YS change to be able to use multiple part clasees CSV
				--12/03/13 YS use 'All' in place of ''
				AND 1= CASE WHEN @lcClass ='All' THEN 1    -- any class
				WHEN m.Part_class IN (SELECT Part_class FROM @PartClass) THEN 1 ELSE 0  END
				--08/08/13 YS change to be able to use multiple buyers CSV
				--12/03/13 YS use 'All' in place of ''
				AND 1= CASE WHEN @lcBuyer ='All' THEN 1    -- any class
				-- 12/11/20 now the buyer is not saved in Buyer_type, it's saved in AspnetBuyer
				--WHEN I.BUYER_TYPE IN (SELECT BUYER_TYPE FROM @BuyerList) THEN 1 ELSE 0  END
				WHEN I.AspnetBuyer IN (SELECT BuyerId FROM @BuyerList) THEN 1 ELSE 0  END
				and (DATEDIFF(Day,MRPACT.DTTAKEACT,@lcLastAction)>=0 or MRPACT.DTTAKEACT is null)		--06/24/2015 DRP  Replaced:  and DATEDIFF(Day,MRPACT.DTTAKEACT,@lcLastAction)>=0 			

			ORDER BY PART_CLASS,Part_no,REVISION,DTTAKEACT
	
	end	
		
		

/*11/24/15 DRP:  old code below was replaced by the above. */
/***********************************/
/*************OLD CODE**************/
/*		
		--10/30/13 DRP:  moved from the parameters and declared it here.
		declare @mrpAction varchar(50)='All WO Actions'
		
			--10/01/13 YS populate default if nothing is entered 
			IF @LastActionDate is null  -- get default
 				select @LastActionDate=cast (mpssys.viewdays + getdate() as date) from mpssys
			--declaring the table so that it can be populated using Yelena Stored Procedured called MrpFullActionView
			Declare @MrpActionView as table (Uniq_key char(10),Part_class char(8),Part_Type char(8),Part_no char(25),Revision char(8)
											,CustPartNo char(25),CustRev char(8),Descript char(45),Part_sourc char(10),UniqMrpAct char(10))
			---- 10/01/13 YS New parameters in place of @lcWhere.								
			--Insert into @MrpActionView exec MrpFullActionView @lcWhere,@lcBomParentPart,@lcBomPArentRev
			INSERT INTO @MrpActionView EXEC MrpFullActionView 
									@StartPartNo, @EndPartNo,
									@Buyer, @PartClass, @partType, 
									@partStatus, @MrCode, 
									@mrpAction, @ProjectUnique, @LastActionDate, 
									@lcBomParentPart , @lcBomPArentRev
			--Below will gather all of the MRP Action information that pertain to WO Actions
			select	m.PART_NO,m.revision,m.PART_CLASS,m.PART_TYPE,m.DESCRIPT,i.U_OF_MEAS,i.PUR_UOFM,MrpAct.* ,micssys.LIC_NAME,MPSSYS.MRPDATE
			from	@MrpActionView M 
					inner join INVENTOR I on m.Uniq_key = i.uniq_key 
					INNER JOIN MRPACT on M.UniqMrpAct = Mrpact.UniqMrpAct
					cross join MICSSYS 
					cross join MPSSYS
			--10/01/13 YS mrp action default for this report to all WO acction and will be returned by @MrpActionView
			--where	CHARINDEX('PO',Action)=0 --this will only pull records fwd where the action does not have 'PO' within it
			ORDER BY PART_CLASS,Part_no,REVISION,DTTAKEACT
			
		--end
				*/				

--  #28  REPAIR THE DATE RANGE FILTER ~ VICKY 11/14/2012 ==================================================================================================