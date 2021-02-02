
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/23/2012
-- Description:	Get information according to find screen of the MRP module
-- Modified: 09/30/2013 YS remove lcWhere and add individual parameters
-- 10/02/2013 YS if no actions the DTTAKEACT will have null and comapring to lst action date will filter records w/o action
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 06/13/17-06/14/17 YS added bomparent and effectivity and termination date to the output of the [fn_getAllUniqKey4BomParent] function. Use this information 
-- when specific bomparent provided to see if the
 -- part is still active for the action
--- 07/18/17 Shivshankar P : Get Buyer and Merged the columns PART_CLASS ,PART_TYPE and Descript changed Descript to Descript_View
--- 08/23/17 Shivshankar P :  Add fetch,totalCount and next for server paging 
--- 08/25/17 YS for the desktop no limit on the number of records @EndRecord int=10000 is not good enough. We have users with the count 20000+
--- default to @endRecord = null and add the could to replace @endRecord with toal number of records  
-- 09/07/17 YS if the count() of rows is 0 need to assign any number more than that or receive an error FETCH clause must be greater than zero
 --01/24/18 YS changed filed to use when checking if the parts is effective (seraching by BOM). Use due_date not req_date. Req_date is when part is require, not the work order
 --02/06/18 YS 
  /*
 struggle with effectivity days. 
 Another issue was found because a component had effectivity day 02/01/2018 and parent work order had a due date on 03/01/2018. 
 Means that component should show when searching for parent part, but because component had firm PO due on  2017-12-28 (past), 
 the system took that due date and was used as a date to compare with the effective date. Adding due_date from mrpsch2, which should sho parent due date  
*/
--- 06/15/18 YS more struge changed to filter all the eff and term dates in Sch CTE Otherwise if the part is on the bomparent that we are searchig
--			and on the sub-assy that is not in the effect it is going to get off the list
-- modified [fn_getAllUniqKey4BomParent] see comments in function
--- PS really need to have better tracability for mrp actions vs demands
-- 12/03/2018 Shivshankar P: Removed columns BUYER_TYPE, totalCount, Descript_view and also removed server paging
-- =============================================
CREATE PROCEDURE [dbo].[MrpFullActionView]
	-- Add the parameters for the stored procedure here
	--@lcWhere varchar(max)='1=2', 
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
	@StartPartNo char(35)=' ',
	@EndPartNo char(35)=' ',
	@Buyer char(3)=' ',
	@PartClass char(8)=' ',
	@partType char(8)=' ',
	@partStatus varchar(10)='All',
	@MrCode varchar(20)=' ',
	@mrpAction varchar(50)='All Actions',   
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
	@ProjectUnique char(10)=' ',
	@LastActionDate smalldatetime=NULL,
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
	@lcBomParentPart char(35)=' ',
	@lcBomPArentRev char(8)=' ' 
	--@StartRecord int=0, -- 12/03/2018 Shivshankar P: Removed server paging
	--@EndRecord int=10000    --Used for Desktop with default rows for web each time passing 150 (@EndRecord=150) server paging
	--- 08/25/17 YS for the desktop no limit on the number of records @EndRecord int=10000 is not good enough. We have users with the count 20000+
	--- default to @endRecord = null and add the could to replace @endRecord with toal number of records  
	--@EndRecord int = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- 12/03/2018 Shivshankar P: Removed server paging
	--- 08/25/17 YS for the desktop no limit on the number of records @EndRecord int=10000 is not good enough. We have users with the count 20000+
	--- default to @endRecord = null and add the could to replace @endRecord with toal number of records  
	--if @EndRecord is null  
	-- 09/07/17 YS if the count() of rows is 0 need to assign any number more than that or receive an error FETCH clause must be greater than zero
		--select @EndRecord=case when count(*)=0 then 1 else count(*) end from mrpact

    -- Insert statements for procedure here
 	IF @LastActionDate is null  -- get default
 		select @LastActionDate=cast (mpssys.viewdays + getdate() as date) from mpssys
 	
	DECLARE @lcUniq_key as char(10)=' ',@lnResult int=0
	DECLARE @lcSql nvarchar(max)
	IF (@lcBomParentPart <>' ')
	BEGIN
		SELECT @lcUniq_key=Uniq_key FROM INVENTOR 
			where PART_NO=@lcBomParentPart 
		and REVISION=@lcBomPArentRev 
		and (PART_SOURC='MAKE' OR PART_SOURC='PHANTOM')
		
		SET @lnResult=@@ROWCOUNT
		
		--IF (@lnResult<>0)
		--BEGIN
		--	INSERT INTO @tBom exec [BomIndented] @lcUniq_key
		--	SET @lnResult=@@ROWCOUNT
		--END -- IF (@lnResult<>0)
	END -- IF (@lcBomParentPart <>' ')
	-- 06/28/12 check for if bom parent was required, but failed to find
	-- 09/30/13 YS for mrp part_sourc<>'CONSG' - always unless we start adding consign parts to mrp.
	IF (@lnResult=0 and @lcBomParentPart =' ')  -- NO BOM parent
	BEGIN	
		SELECT DISTINCT A.Uniq_key, Part_Class, Part_Type, Part_no, Revision, CustPartNo, CustRev,Descript,
		-- PART_CLASS + '/' + PART_TYPE + '/'+ Descript AS Descript_view,-- 07/18/17 Shivshankar P Merged the columns PART_CLASS ,PART_TYPE and Descript
		-- 12/03/2018 Shivshankar P: Removed columns BUYER_TYPE, totalCount, Descript_view 
			Part_Sourc , UniqMrpAct
			--, totalCount = COUNT(A.Uniq_key) OVER() --- 18/07/17 Shivshankar P Get Buyer and Total Number of Rows
			
		FROM MrpAct A INNER JOIN Mrpinvt M ON A.uniq_key=M.Uniq_key
		WHERE M.PART_SOURC<>'CONSG'
		AND M.Part_no>= case when @StartPartNo=' ' then M.Part_no else @StartPartNo END
		AND M.PART_NO<= CASE WHEN @EndPartNo ='' THEN m.PART_NO ELSE @EndPartNo  END
		AND M.PART_CLASS = CASE WHEN @PartClass IS Null OR @PartClass=' ' THEN M.PART_CLASS     -- any class
					ELSE @PartClass END
		AND M.Part_type = CASE WHEN @partType  IS Null OR @partType =' ' THEN M.PART_TYPE     -- any class
					ELSE  @partType   END			
		AND M.BUYER_TYPE= CASE WHEN @Buyer  IS Null OR @Buyer =' ' THEN M.BUYER_TYPE    -- any buyer
					ELSE  @Buyer   END
		AND M.[Status]=CASE WHEN @partStatus='All' THEN M.[Status]  -- any status
					ELSE @partStatus END			
		AND M.MRC = CASE WHEN @MrCode IS null OR @MrCode=' ' THEN  M.MRC -- any code
					ELSE @MrCode END		
		AND A.PRJUNIQUE = CASE WHEN @ProjectUnique is null or @ProjectUnique=' ' THEN A.PRJUNIQUE -- any project
					ELSE @ProjectUnique END
		AND 1 = CASE WHEN @mrpAction='All Actions' THEN 1
				WHEN @mrpAction='All PO Actions' and A.[Action]<>'No PO Action' and (A.[ACTION] LIKE '%PO%' OR A.[Action] LIKE '%RESCH P%') THEN 1
				WHEN @mrpAction ='All WO Actions' 
				and (A.[Action] LIKE '%WO%' OR A.[Action] like '%Order Kitted%' 
				OR (A.[ACTION] LIKE '%Firm Planned%' AND LEFT(A.Ref,2) = 'WO')) THEN 1
				WHEN @mrpAction ='Pull-Ins'  AND  CHARINDEX('RESCH',A.[Action])<>0 AND DATEDIFF(Day,A.ReqDate ,A.Due_Date)>0 THEN 1
				WHEN @mrpAction='Push-Outs' AND CHARINDEX('RESCH',A.[Action])<>0 AND DATEDIFF(Day,A.Due_Date,A.ReqDate)>0 THEN 1
				WHEN @mrpAction='Release PO' AND CHARINDEX('Release PO',A.[Action])<>0 THEN 1
				WHEN @mrpAction='Release WO' AND CHARINDEX('Release WO',A.[Action])<>0  THEN 1
				WHEN @mrpAction='Cancel PO' AND CHARINDEX('Cancel PO',A.[Action])<>0 THEN 1
				WHEN @mrpAction='Cancel WO'	AND CHARINDEX('Cancel WO',A.[Action])<>0 THEN 1 ELSE 0 END 					
		--10/02/13 YS if no actions the DTTAKEACT will have null and comapring to lst action date will filter records w/o action
		AND (DATEDIFF(Day,A.DTTAKEACT,@LastActionDate)>=0 OR A.DTTAKEACT IS NULL) 
		-- ORDER BY A.Uniq_key    --- 08/23/17 Shivshankar P :  Add fetch,totalCount and next for server paging 
                   -- OFFSET (@StartRecord) ROWS  
                   -- FETCH NEXT @EndRecord ROWS ONLY;  
		
		
		--SELECT @lcSql=
		--N'SELECT DISTINCT MrpAct.Uniq_key, Part_Class, Part_Type, Part_no, Revision, CustPartNo, CustRev, Descript, 
		--	Part_Sourc ,UniqMrpAct
		--FROM MrpAct INNER JOIN Mrpinvt ON MrpAct.uniq_key=MrpInvt.Uniq_key
		--WHERE '+@lcWhere 
	END --IF (@lnResult=0)  -- NO BOM parent
	ELSE -- IF (@lnResult=0)  -- NO BOM parent
	BEGIN
		;with
			BOMIndented
			as
			(
			SELECT Uniq_key,bomparent,term_dt,eff_dt FROM dbo.fn_getAllUniqKey4BomParent(@lcUniq_key) 
			),
			 --02/06/18 YS 
			/*
			struggle with effectivity days. 
			Another issue was found because a component had effectivity day 02/01/2018 and parent work order had a due date on 03/01/2018. 
			Means that component should show when searching for parent part, but because component had firm PO due on  2017-12-28 (past), 
			the system took that due date and was used as a date to compare with the effective date. Adding due_date from mrpsch2, which should sho parent due date  
			*/
			--06/15/18 YS changed to filter all the eff and term dates in Sch CTE Otherwise if the part is on the bomparent that we are searchig
			---and on the sub-assy that is not in the effect it is going to get off the list
			--Sch
			--as
			--(select distinct s.Uniq_key,s.ParentPt ,b.term_dt,b.eff_dt,sp.reqdate as due_date
			--	from mrpsch2 S inner join BOMIndented B on S.UNIQ_KEY=b.Uniq_key and s.PARENTPT=b.bomparent
			--	--- if the component a line shortage the reference will be something like WO0000098587Line Shortag
			--	-- and it will not find the parent reqdate, but will stay on the list because the due_date (reqdate of the parent)
			--	--- will be null . That works
			--	left outer JOIN mrpsch2 SP ON b.bomparent=sp.UNIQ_KEY and right(s.ref,10)=right(sp.ref,10)
			--	UNION
			--	select Uniq_key,bomparent,term_dt,eff_dt,null as due_date from BOMIndented where Uniq_key=@lcUniq_key
	
			--)

			Sch
			as
			(select distinct s.Uniq_key,s.ParentPt ,b.term_dt,b.eff_dt,sp.reqdate as due_date
				from mrpsch2 S inner join BOMIndented B on S.UNIQ_KEY=b.Uniq_key and s.PARENTPT=b.bomparent
				--- if the component a line shortage the reference will be something like WO0000098587Line Shortag
				-- and it will not find the parent reqdate, but will stay on the list because the due_date (reqdate of the parent)
				--- will be null . That works
				left outer JOIN mrpsch2 SP ON b.bomparent=sp.UNIQ_KEY and right(s.ref,10)=right(sp.ref,10)
				where ((sp.reqdate is null and 
					(eff_dt is null OR (eff_dt is not null and datediff(day,eff_dt,getdate())>=0)) 
					and (term_dt is null or (term_dt is not null and datediff(day,getdate(),term_dt)>0)))
						or ((eff_dt is null or datediff(day,eff_dt,sp.reqdate)>=0) 
							and (term_dt is null or  datediff(day,sp.reqdate,term_dt)>0)))
				UNION
				select Uniq_key,bomparent,term_dt,eff_dt,null as due_date from BOMIndented where Uniq_key=@lcUniq_key
			)


		SELECT DISTINCT A.Uniq_key, Part_Class, Part_Type, Part_no, Revision, CustPartNo, CustRev, Descript, 
			--PART_CLASS + '/' + PART_TYPE + '/'+ Descript AS Descript_view,-- 07/18/17 Shivshankar P Merged the columns PART_CLASS ,PART_TYPE and Descript
			-- 12/03/2018 Shivshankar P: Removed columns BUYER_TYPE, totalCount, Descript_view 
			Part_Sourc ,UniqMrpAct --- 18/07/17 Shivshankar P Get Buyer and Total Number of Rows
			 --totalCount = COUNT(A.Uniq_key) OVER()
		FROM MrpAct A INNER JOIN Mrpinvt M ON A.uniq_key=M.Uniq_key
		WHERE M.PART_SOURC<>'CONSG'
		AND M.Part_no>= case when @StartPartNo=' ' then M.Part_no else @StartPartNo END
		AND M.PART_NO<= CASE WHEN @EndPartNo ='' THEN m.PART_NO ELSE @EndPartNo  END
		AND M.PART_CLASS = CASE WHEN @PartClass IS Null OR @PartClass=' ' THEN M.PART_CLASS     -- any class
					ELSE @PartClass END
		AND M.Part_type = CASE WHEN @partType  IS Null OR @partType =' ' THEN M.PART_TYPE     -- any class
					ELSE  @partType   END			
		AND M.BUYER_TYPE= CASE WHEN @Buyer  IS Null OR @Buyer =' ' THEN M.BUYER_TYPE    -- any buyer
					ELSE  @Buyer   END
		AND M.[Status]=CASE WHEN @partStatus='All' THEN M.[Status]  -- any status
					ELSE @partStatus END			
		AND M.MRC = CASE WHEN @MrCode IS null OR @MrCode=' ' THEN  M.MRC -- any code
					ELSE @MrCode END		
		AND A.PRJUNIQUE = CASE WHEN @ProjectUnique is null or @ProjectUnique=' ' THEN A.PRJUNIQUE -- any project
					ELSE @ProjectUnique END
		AND 1 = CASE WHEN @mrpAction='All Actions' THEN 1
				WHEN @mrpAction='All PO Actions' and A.[Action]<>'No PO Action' and (A.[ACTION] LIKE '%PO%' OR A.[Action] LIKE '%RESCH P%') THEN 1
				WHEN @mrpAction ='All WO Actions' 
				and (A.[Action] LIKE '%WO%' OR A.[Action] like '%Order Kitted%' 
				OR (A.[ACTION] LIKE '%Firm Planned%' AND LEFT(A.Ref,2) = 'WO')) THEN 1
				WHEN @mrpAction ='Pull-Ins'  AND  CHARINDEX('RESCH',A.[Action])<>0 AND DATEDIFF(Day,A.ReqDate ,A.Due_Date)>0 THEN 1
				WHEN @mrpAction='Push-Outs' AND CHARINDEX('RESCH',A.[Action])<>0 AND DATEDIFF(Day,A.Due_Date,A.ReqDate)>0 THEN 1
				WHEN @mrpAction='Release PO' AND CHARINDEX('Release PO',A.[Action])<>0 THEN 1
				WHEN @mrpAction='Release WO' AND CHARINDEX('Release WO',A.[Action])<>0  THEN 1
				WHEN @mrpAction='Cancel PO' AND CHARINDEX('Cancel PO',A.[Action])<>0 THEN 1
				WHEN @mrpAction='Cancel WO'	AND CHARINDEX('Cancel WO',A.[Action])<>0 THEN 1 ELSE 0 END 					
		--10/02/13 YS if no actions the DTTAKEACT will have null and comapring to lst action date will filter records w/o action
		AND (DATEDIFF(Day,A.DTTAKEACT,@LastActionDate)>=0 OR A.DTTAKEACT IS NULL)
		--AND DATEDIFF(Day,A.DTTAKEACT,@LastActionDate)>=0 
		--AND M.Uniq_key IN (SELECT Uniq_key FROM dbo.fn_getAllUniqKey4BomParent(@lcUniq_key))
		---06/14/17 YS change the next row to try identify if any of the prts expired on a given BOM
		 --01/24/18 YS changed filed to use when checking if the parts is effective (seraching by BOM). Use due_date not req_date. Req_date is when part is require, not the work order
		--and exists (select 1 from Sch where m.UNIQ_KEY=sch.UNIQ_KEY and 
		--(a.REQDATE is null or ((sch.eff_dt is null or datediff(day,eff_dt,reqdate)>=0) and (sch.term_dt is null or  datediff(day,reqdate,term_dt)>0))))
		 --02/06/18 YS 
		/*
		struggle with effectivity days. 
		Another issue was found because a component had effectivity day 02/01/2018 and parent work order had a due date on 03/01/2018. 
		Means that component should show when searching for parent part, but because component had firm PO due on  2017-12-28 (past), 
		the system took that due date and was used as a date to compare with the effective date. Adding due_date from mrpsch2, which should sho parent due date  
		*/
		--and exists (select 1 from Sch where m.UNIQ_KEY=sch.UNIQ_KEY and 
		--(a.due_date is null or ((sch.eff_dt is null or datediff(day,eff_dt,due_date)>=0) and (sch.term_dt is null or  datediff(day,DUE_DATE,term_dt)>0))))
		and exists (select 1 from Sch where m.UNIQ_KEY=sch.UNIQ_KEY )
		--- 06/15/18 YS changed to filter all the eff and term dates in Sch CTE Otherwise if the part is on the bomparent that we are searchig
		---	and on the sub-assy that is not in the effect it is going to get off the list
		--and 
		--(sch.due_date is null or ((sch.eff_dt is null or datediff(day,eff_dt,sch.due_date)>=0) and (sch.term_dt is null or  datediff(day,sch.DUE_DATE,term_dt)>0))))
		 --ORDER BY A.Uniq_key  --- 08/23/17 Shivshankar P :  Add fetch,totalCount and next for server paging 
		 --OFFSET (@StartRecord) ROWS  
         --FETCH NEXT @EndRecord ROWS ONLY;  
	
		
		--SELECT DISTINCT A.Uniq_key, Part_Class, Part_Type, Part_no, Revision, CustPartNo, CustRev, Descript,
		-- PART_CLASS + '/' + PART_TYPE + '/'+ Descript AS Descript_view,-- 07/18/17 Shivshankar P Merged the columns PART_CLASS ,PART_TYPE and Descript
		--	Part_Sourc ,BUYER_TYPE,UniqMrpAct, --- 18/07/17 Shivshankar P Get Buyer and Total Number of Rows
		--	 totalCount = COUNT(A.Uniq_key) OVER()
		--FROM MrpAct A INNER JOIN Mrpinvt M ON A.uniq_key=M.Uniq_key
		--WHERE M.PART_SOURC<>'CONSG'
		--AND M.Part_no>= case when @StartPartNo=' ' then M.Part_no else @StartPartNo END
		--AND M.PART_NO<= CASE WHEN @EndPartNo ='' THEN m.PART_NO ELSE @EndPartNo  END
		--AND M.PART_CLASS = CASE WHEN @PartClass IS Null OR @PartClass=' ' THEN M.PART_CLASS     -- any class
		--			ELSE @PartClass END
		--AND M.Part_type = CASE WHEN @partType  IS Null OR @partType =' ' THEN M.PART_TYPE     -- any class
		--			ELSE  @partType   END			
		--AND M.BUYER_TYPE= CASE WHEN @Buyer  IS Null OR @Buyer =' ' THEN M.BUYER_TYPE    -- any buyer
		--			ELSE  @Buyer   END
		--AND M.[Status]=CASE WHEN @partStatus='All' THEN M.[Status]  -- any status
		--			ELSE @partStatus END			
		--AND M.MRC = CASE WHEN @MrCode IS null OR @MrCode=' ' THEN  M.MRC -- any code
		--			ELSE @MrCode END		
		--AND A.PRJUNIQUE = CASE WHEN @ProjectUnique is null or @ProjectUnique=' ' THEN A.PRJUNIQUE -- any project
		--			ELSE @ProjectUnique END
		--AND 1 = CASE WHEN @mrpAction='All Actions' THEN 1
		--		WHEN @mrpAction='All PO Actions' and A.[Action]<>'No PO Action' and (A.[ACTION] LIKE '%PO%' OR A.[Action] LIKE '%RESCH P%') THEN 1
		--		WHEN @mrpAction ='All WO Actions' 
		--		and (A.[Action] LIKE '%WO%' OR A.[Action] like '%Order Kitted%' 
		--		OR (A.[ACTION] LIKE '%Firm Planned%' AND LEFT(A.Ref,2) = 'WO')) THEN 1
		--		WHEN @mrpAction ='Pull-Ins'  AND  CHARINDEX('RESCH',A.[Action])<>0 AND DATEDIFF(Day,A.ReqDate ,A.Due_Date)>0 THEN 1
		--		WHEN @mrpAction='Push-Outs' AND CHARINDEX('RESCH',A.[Action])<>0 AND DATEDIFF(Day,A.Due_Date,A.ReqDate)>0 THEN 1
		--		WHEN @mrpAction='Release PO' AND CHARINDEX('Release PO',A.[Action])<>0 THEN 1
		--		WHEN @mrpAction='Release WO' AND CHARINDEX('Release WO',A.[Action])<>0  THEN 1
		--		WHEN @mrpAction='Cancel PO' AND CHARINDEX('Cancel PO',A.[Action])<>0 THEN 1
		--		WHEN @mrpAction='Cancel WO'	AND CHARINDEX('Cancel WO',A.[Action])<>0 THEN 1 ELSE 0 END 					
		----10/02/13 YS if no actions the DTTAKEACT will have null and comapring to lst action date will filter records w/o action
		--AND (DATEDIFF(Day,A.DTTAKEACT,@LastActionDate)>=0 OR A.DTTAKEACT IS NULL)
		----AND DATEDIFF(Day,A.DTTAKEACT,@LastActionDate)>=0 
		--AND M.Uniq_key IN (SELECT Uniq_key FROM dbo.fn_getAllUniqKey4BomParent(@lcUniq_key))
	 --  ORDER BY A.Uniq_key  --- 08/23/17 Shivshankar P :  Add fetch,totalCount and next for server paging 
  --              OFFSET (@StartRecord) ROWS  
  --              FETCH NEXT @EndRecord ROWS ONLY;  
	
	END	 -- END ELSE IF (@lnResult=0)  -- NO BOM parent
	
	--execute sp_executesql @lcSql	
	
	
END