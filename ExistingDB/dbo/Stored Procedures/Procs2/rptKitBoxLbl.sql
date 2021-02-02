
-- =============================================
-- Author:			Debbie
-- Create date:		12/11/15
-- Description:		Compiles the details for the Kit Box Labels
-- Used On:			kitblabl, kitblabz
-- Modified:		12/11/15 DRP:  I was originally going to use the rptkitpartlbl procedure for this label also, but realized that it would display way too many columns in the label grid that were not needed for this report.
--								   So thought it would be best to create its own procedure with only the needed fields displaying. 	
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 05/01/17 DRP:  added the @lcLabelQty parameter per request of the users.  This way they can enter in a Label Qty to be populated into the grid, but should also then be able to change within the grid if needed.
-- 07/16/18 VL changed custname from char(35) to char(50)
-- 05/07/20 VL changed table variable data structure because KitMainView was changed
-- 10/02/20 VL added allocatedQty, userid into @ZKitMainView because [KitMainView] are changed
-- =============================================
		CREATE PROCEDURE  [dbo].[rptKitBoxLbl]
--declare
				 @lcWono AS char(10) = ''	-- Work order number
				 ,@lcLabelQty as int = null		--05/01/17 DRP:  added
				,@userId uniqueidentifier = null

as 
begin		
		SET NOCOUNT ON;

		SET @lcWono=dbo.PADL(@lcWono,10,'0')
		declare @lcKitStatus Char(10)

		--Main Kitting Information
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
		-- 05/07/20 VL changed table variable data structure because KitMainView was changed
		-- 10/02/20 VL added allocatedQty, userid into @ZKitMainView because [KitMainView] are changed
		DECLARE @ZKitMainView TABLE (DispPart_no char(35),Req_Qty numeric(12,2),Phantom char(1),DispRevision char(8),Part_class char(8),Part_type char(8),Kaseqnum char(10)
									,Entrydate smalldatetime,Initials char(8)--,Rej_qty numeric(12,2),Rej_date smalldatetime,Rej_reson char(10)
									,Kitclosed bit,Act_qty numeric(12,2)
									,Uniq_key char(10),Dept_id char(4),Dept_name char(25),Wono char(10),Scrap numeric(6,2),Setupscrap numeric(4,0),Bomparent char(10)
									,Shortqty numeric(12,2),Lineshort bit,Part_sourc char(10),Qty numeric(12,2),Descript char(45),Inv_note text,U_of_meas char(4),Pur_uofm char(4)
									,Ref_des char(15),
									--- 03/28/17 YS changed length of the part_no column from 25 to 35
									Part_no char(35),Custpartno char(35),Ignorekit bit,Phant_make bit,Revision char(8),Serialyes bit,Matltype char(10),CustRev char(8)
									-- 10/02/20 VL added allocatedQty, userid into @ZKitMainView because [KitMainView] are changed
									,allocatedQty numeric(12,2), userid uniqueidentifier)

--- 03/28/17 YS changed length of the part_no column from 25 to 35
		-- 07/16/18 VL changed custname from char(35) to char(50)
		declare @results table	(wono char(10),uniq_key char(10),custname char(50),ParentBomPn char(35),ParentBomRev char(25),ParentBomDesc char(45),ParentBomClass char(8),ParentBomType char(8)
								,BldQty numeric(7,0),sono char(10),Dept_Id char(4),Label_Id uniqueidentifier)
		


		select @lcKitStatus = woentry.KITSTATUS from WOENTRY where @lcWono = woentry.WONO 

		IF @@ROWCOUNT <> 0
		BEGIN							
		--This section will then pull all of the detailed information from the KaMAIN tables because the kit has been put into process.  
		--Otherwise, if not in process ever we will then have to later pull from the BOM information  					
			if ( @lcKitStatus <> '')
			Begin	
				
			INSERT @ZKitMainView EXEC [KitMainView] @lcwono 

			insert into @results 
				select	ZMain2.Wono,zmain2.bomparent,isnull(customer.custname,'') as CustName,i4.PART_NO as ParentBomPn,i4.REVISION as ParentBomRev,i4.DESCRIPT as ParentBomDesc
						,i4.part_class as ParentBomClass,i4.part_type as ParentBomType,woentry.bldqty,woentry.sono,ZMain2.Dept_id,NEWID()
				from	@ZKitMainView as ZMain2
						left outer join bom_det on zmain2.Bomparent = bom_det.BOMPARENT and  zmain2.uniq_key = bom_det.Uniq_key
						inner join WOENTRY on zmain2.Wono = woentry.WONO
						inner join CUSTOMER on woentry.custno = customer.CUSTNO
						inner join INVENTOR as I4 on woentry.UNIQ_KEY = i4.UNIQ_KEY
						left outer join INVENTOR as I5 on ZMain2.Uniq_key = i5.INT_UNIQ and woentry.CUSTNO=i5.CUSTNO 


				select	wono,custname,ParentBomPn,ParentBomRev,ParentBomDesc,ParentBomClass,ParentBomType,BldQty,sono
						,Dept_Id
						--, CAST (1 as numeric (3,0))as LabelQty  --05/01/17 DRP replaced with below
						,case when @lcLabelQty is null then 1 else @lcLabelQty end as LabelQty
				from	@results as R2
				group by wono,custname,ParentBomPn,ParentBomRev,ParentBomDesc,ParentBomClass,ParentBomType,BldQty,sono,Dept_Id
				
		end

		--if the kit has never been put into process then the below section will gather the information from the Bill of Material
			else if ( @lcKitStatus = '')
			begin
			declare		@lcBomParent char(10)
						,@IncludeMakebuy bit = 1 
						,@ShowIndentation bit =1
						,@gridId varchar(50)= null	
							
			select @lcBomParent = woentry.UNIQ_KEY from WOENTRY where @lcWono = woentry.wono				
			--- 03/28/17 YS changed length of the part_no column from 25 to 35
			declare @tBom table	(bomParent char(10),bomcustno char(10),UNIQ_KEY char(10),item_no numeric(4),PART_NO char(35),Revision char(8),Part_sourc char(10) 
								,ViewPartNo varchar(max),ViewRevision char(8),Part_class char(8),Part_type char(8),Descript char(45),MatlType char (10),Dept_id char(8)
								,Item_note varchar(max),Offset numeric(4,0),Term_dt date,Eff_dt date, Used_inKit char(1),custno char(10),Inv_note varchar(max)
								,U_of_meas char(4), Scrap numeric(6,2),SetupScrap numeric(4,0),USESETSCRP bit,STDBLDQTY numeric(8,0),Phantom_make bit,StdCost numeric(13,5)
								,Make_buy bit,Status char(10),TopQty numeric(9,2),qty numeric(9,2),Level integer,path varchar(max),sort varchar(max),UniqBomNo char(10))
			;
			WITH BomExplode as (
								SELECT	B.bomParent,M.BOMCUSTNO,B.UNIQ_KEY, B.item_no,C.PART_NO,C.Revision,c.Part_sourc
										,CAST(CASE WHEN C.part_sourc='CONSG' THEN C.Custpartno ELSE C.Part_no END as varchar(max)) AS ViewPartNo
										,CASE WHEN C.part_sourc='CONSG' THEN C.Custrev ELSE C.Revision END AS ViewRevision,C.Part_class,C.Part_type,C.Descript,c.MATLTYPE
										,B.Dept_id, B.Item_note, B.Offset, B.Term_dt, B.Eff_dt, B.Used_inKit,C.Custno, C.Inv_note, C.U_of_meas, C.Scrap, C.Setupscrap,M.USESETSCRP
										,M.STDBLDQTY, C.Phant_Make, C.StdCost, C.Make_buy, C.Status,cast(1.00 as numeric(9,2)) as TopQty,B.qty as Qty, cast(0 as Integer) as Level
										,'/'+CAST(bomparent as varchar(max)) as path,CAST(dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY Item_no) as varchar(max))),4,'0') as varchar(max)) AS Sort
										,B.UNIQBOMNO 
								FROM	BOM_DET B INNER JOIN INVENTOR C ON B.UNIQ_KEY =C.UNIQ_KEY 
										INNER JOIN INVENTOR M on B.BOMPARENT =M.UNIQ_KEY 
								WHERE	B.BOMPARENT=@lcBomParent 
				
			UNION ALL
				
								SELECT  B2.BOMPARENT, M2.BOMCUSTNO ,B2.Uniq_key,B2.item_no  ,C2.PART_NO,C2.Revision,c2.Part_sourc 
										,CAST(CASE WHEN @ShowIndentation=1 THEN SPACE((P.level+1)*4) ELSE SPACE(0) END +CASE WHEN C2.part_sourc='CONSG' THEN C2.Custpartno ELSE C2.Part_no  END as varchar(max)) AS ViewPartNo
										,CASE WHEN C2.part_sourc='CONSG' THEN C2.Custrev ELSE C2.Revision END AS ViewRevision,C2.Part_class, C2.Part_type, C2.Descript,c2.MATLTYPE,B2.Dept_id
										,B2.Item_note, B2.Offset, B2.Term_dt, B2.Eff_dt, B2.Used_inKit,C2.Custno,C2.Inv_note, C2.U_of_meas, C2.Scrap, C2.Setupscrap,M2.USESETSCRP,M2.STDBLDQTY
										,C2.Phant_Make, C2.StdCost, C2.Make_buy, C2.Status,P.Qty as TopQty,B2.QTY, P.Level+1,CAST(RTRIM(LTRIM(P.Path))+'/'+B2.bomparent as varchar(max)) as path 
										,CAST(RTRIM(p.Sort)+'-'+	dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY b2.Item_no) as varchar(4))),4,'0') as varchar(max)) AS Sort,B2.UNIQBOMNO   
								FROM	BomExplode as P 
										INNER JOIN BOM_DET as B2 ON P.UNIQ_KEY =B2.BOMPARENT 
										INNER JOIN INVENTOR C2 ON B2.UNIQ_KEY =C2.UNIQ_KEY 
										INNER JOIN INVENTOR M2 ON B2.BOMPARENT =M2.UNIQ_KEY 
								WHERE	P.PART_SOURC='PHANTOM'
										or (p.PART_SOURC = 'MAKE' and P.PHANT_MAKE = 1) 
								)

			insert into @tbom	SELECT	E.* 
								from	BomExplode E 
								where	(Term_dt>GETDATE() OR Term_dt IS NULL)
										AND (Eff_dt<GETDATE() OR Eff_dt IS NULL)
										AND E.Status = 'Active'			
								ORDER BY sort OPTION (MAXRECURSION 100)
					
			insert into @results
			select	woentry.Wono,woentry.UNIQ_KEY,isnull(customer.custname,'') as CustName,i4.PART_NO as ParentBomPn,i4.REVISION as ParentBomRev,i4.DESCRIPT as ParentBomDesc
					,i4.part_class as ParentBomClass,i4.part_type as ParentBomType,woentry.bldqty,woentry.sono,t1.Dept_id,NEWID()						
			from	@tBom as T1
					inner join WOENTRY on t1.UNIQ_KEY = t1.UNIQ_KEY
					inner join CUSTOMER on woentry.custno = customer.CUSTNO
					inner join INVENTOR as I4 on woentry.UNIQ_KEY = i4.UNIQ_KEY
					left outer join bom_det on t1.Bomparent = bom_det.BOMPARENT and t1.uniq_key = bom_det.Uniq_key and t1.item_no = bom_Det.ITEM_NO
					left outer join DEPTS on t1.Dept_id = depts.DEPT_ID
			where	@lcWono = woentry.WONO
					AND T1.part_sourc <> 'PHANTOM'
					AND t1.Phantom_make <> 1		
			

			select	wono,custname,ParentBomPn,ParentBomRev,ParentBomDesc,ParentBomClass,ParentBomType,BldQty,sono
					,Dept_Id
					--, CAST (1 as numeric (3,0))as LabelQty  --05/01/17 DRP replaced with below
						,case when @lcLabelQty is null then 1 else @lcLabelQty end as LabelQty
			from	@results as R1
			group by wono,custname,ParentBomPn,ParentBomRev,ParentBomDesc,ParentBomClass,ParentBomType,BldQty,sono,Dept_Id
			
		end 
		 
		--select * from @results	order by item_no	
		ELSE -- ELSE of @@ROWCOUNT <> 0
			select	wono,custname,ParentBomPn,ParentBomRev,ParentBomDesc,ParentBomClass,ParentBomType,BldQty,sono
					,Dept_Id
					--, CAST (1 as numeric (3,0))as LabelQty  --05/01/17 DRP replaced with below
						,case when @lcLabelQty is null then 1 else @lcLabelQty end as LabelQty
			from	@results as R2
			group by wono,custname,ParentBomPn,ParentBomRev,ParentBomDesc,ParentBomClass,ParentBomType,BldQty,sono,Dept_Id
		end
end