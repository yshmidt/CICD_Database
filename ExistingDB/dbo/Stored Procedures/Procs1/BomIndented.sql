
-- =============================================
-- Author:		Yelena Shmidt
-- Create date:	03/01/2012 
-- Description:	Indented BOM with make and phantom parts exploded.
-- Modified:	03/19/14 YS Need to add Buyer column
--				09/22/15 DRP/YS:  found that we needed to add the @lcDate Parameter to the procedure so we could make sure that we were filtering out obsolete items from the results when needed.
--								  the default for the @lcDate parameter will be null for situation where the user or other places this is used  needs to display history.
--				10/29/15 DRP/YS:  needed to change the Where clause on the section that explodes out the Phantom components.  It was still having issues with displaying components that were obsoleted on the phantom levels.  
--				09/30/16	 YS make top level 1 instead of 0. Paramit PG has problem with 0 when printing reports
---08/14/17 YS added PR currency 
-- 02/12/19 DRP:  due to new manex restructure of the notes we needed to change how we pull the note information on thsi procedure. 
-- 03/01/19 VL: Change how inventory note and bom item note works due to data structure changes to pull latest note.  Need to change Debbie 02/12/19 code it should use RecordType = 'BOM_DET' and use Uniqbomno for item_note,
--				Also, only add at the last SQL, OUTTER JOIN not allowed in recursive CTE.  Added criteria the note date has to be =< @lcDate
-- 05/24/19 Shrikant Added column Bom_Note to avoid Duplicate code for report new note structure for header note 
-- BomIndented '_39P0RLDFH', 1, 1, '49f80792-e15e-4b62-b720-21b360e3108a', '05/24/2019', null
-- =============================================
CREATE PROCEDURE [dbo].[BomIndented]
--DECLARE
	-- Add the parameters for the stored procedure here
	@lcBomParent char(10)=' ' ,	@IncludeMakeBuy bit=1 , @ShowIndentation bit=1,
	@UserId uniqueidentifier=null,@lcDate smalldatetime = null, @gridId varchar(50) = null
	
	-- list of parameters:
	-- 1. @lcBomParent - top level BOM uniq_key 
	-- 2. @IncludeMakeBuy if the value is 1 will explode make/buy parts ; if 0 - will not (default 1)
	-- 3. @ShowIndentation add spaces in front of the PartView value to clearly show indentation (for now 4 spaces if =1, no spaces if =0, can customize later)
	-- 4. @UserId - for now is optional will be ignored if null. Will be used by WEB fron to identify if the user has rights to see the BOM.
	-- 5. @gridId - optional web application is using it to customize grid display
	-- 6. @lcDate - if left null it should display all items on the results even if they are obsolete, otherwise it will more than likely be populated with the current date from other procedure that uses BomIndented
	

AS
BEGIN


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET ANSI_PADDING ON;



    -- Insert statements for procedure here
     --- 03/19/14 YS Need to add Buyer column
	
	 WITH BomExplode as 
  (
  SELECT B.bomParent,M.BOMCUSTNO,B.UNIQ_KEY, B.item_no,C.PART_NO,C.Revision,c.Part_sourc ,
  CAST(CASE WHEN C.part_sourc='CONSG' THEN C.Custpartno ELSE C.Part_no END as varchar(max)) AS ViewPartNo,
  CASE WHEN C.part_sourc='CONSG' THEN C.Custrev ELSE C.Revision END AS ViewRevision,
	C.Part_class, C.Part_type, C.Descript,
	--08/10/2012 DRP: added Material Type
	c.MATLTYPE,B.Dept_id
	-- 03/01/19 VL comment out here, will add at last SQL
	--,N1.NOTE AS ITEM_NOTE	--, B.Item_note	02/12/19 DRP:  new manex note restructure
	, B.Offset, B.Term_dt, B.Eff_dt, B.Used_inKit,C.Custno
	-- 03/01/19 VL comment out here, will add at last SQL
	--, C.Inv_note
	, C.U_of_meas, C.Scrap, C.Setupscrap,M.USESETSCRP,M.STDBLDQTY,  
	C.Phant_Make, C.StdCost, C.Make_buy, C.Status, 
	cast(1.00 as numeric(10,2)) as TopQty,
	B.qty  as Qty, 
    --	09/30/16	 YS make top level 1 instead of 0. Paramit PG has problem with 0 when printing reports
   cast(1 as Integer) as Level ,
  '/'+CAST(bomparent as varchar(max)) as path,
	CAST(dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY Item_no) as varchar(max))),4,'0') as varchar(max)) AS Sort,
	B.UNIQBOMNO,c.BUYER_TYPE as Buyer ,
	---08/14/17 YS added PR currency 
	c.stdcostpr,c.funcFcUsed_uniq,c.PrFcUsed_uniq
	FROM BOM_DET B INNER JOIN INVENTOR C ON B.UNIQ_KEY =C.UNIQ_KEY 
	INNER JOIN INVENTOR M on B.BOMPARENT =M.UNIQ_KEY 
	-- 03/01/19 VL comment out here, will add at last SQL
	--LEFT OUTER JOIN (select n.recordid, R.NOTE,R.CreatedDate,ROW_NUMBER() OVER(PARTITION BY N.RECORDID ORDER BY R.CREATEDDATE DESC) AS N 
	--					from wmNotes N inner join wmNoteRelationship R on N.NoteID = R.FkNoteId WHERE N.RecordType = 'INVENTOR' ) N1 ON B.UNIQ_KEY = N1.RecordId  -- 02/12/19 DRP: new manex note restructure
	WHERE B.BOMPARENT=@lcBomParent 
	 and (@lcDate is NULL 
	 or ((Eff_dt is null or DATEDIFF(day,EFF_DT,@lcDate)>=0) 
	 and (Term_dt is Null or DATEDIFF(day,TERM_DT,@lcDate)<0)))	--09/22/15 DRP: Added
		  -- 03/01/19 VL comment out next line, it caused if no note the bom_det would not show
		  -- AND N1.N = 1		--02/12/19 DRP:  new manex note restructure

	UNION ALL
	--- 03/19/14 YS Need to add Buyer column
	SELECT  B2.BOMPARENT, M2.BOMCUSTNO ,B2.Uniq_key,B2.item_no  ,C2.PART_NO,C2.Revision,c2.Part_sourc 
	,CAST(CASE WHEN @ShowIndentation=1 THEN SPACE((P.level+1)*4) ELSE SPACE(0) END +CASE WHEN C2.part_sourc='CONSG' THEN C2.Custpartno ELSE C2.Part_no  END as varchar(max)) AS ViewPartNo,
	CASE WHEN C2.part_sourc='CONSG' THEN C2.Custrev ELSE C2.Revision END AS ViewRevision,
	C2.Part_class, C2.Part_type, C2.Descript,
	--08/10/2012 DRP: added Material Type
	c2.MATLTYPE,
	B2.Dept_id
	-- 03/01/19 VL comment out here, will add at last SQL
	--, B2.Item_note
	, B2.Offset, B2.Term_dt, B2.Eff_dt, B2.Used_inKit,C2.Custno, 
	-- 03/01/19 VL comment out here, will add at last SQL
	--C2.Inv_note
	C2.U_of_meas, C2.Scrap, C2.Setupscrap,M2.USESETSCRP,M2.STDBLDQTY,
	C2.Phant_Make, C2.StdCost, C2.Make_buy, C2.Status, 
	CAST(P.Qty*P.TopQty as numeric(10,2)) as TopQty,B2.QTY, P.Level+1,
	CAST(RTRIM(LTRIM(P.Path))+'/'+B2.bomparent as varchar(max)) as path ,
	CAST(RTRIM(p.Sort)+'-'+	dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY b2.Item_no) as varchar(4))),4,'0') as varchar(max)) AS Sort,
	B2.UNIQBOMNO,c2.BUYER_TYPE as Buyer   ,
	---08/14/17 YS added PR currency 
	c2.stdcostpr,c2.funcFcUsed_uniq,c2.PrFcUsed_uniq
	FROM BomExplode as P INNER JOIN BOM_DET as B2 ON P.UNIQ_KEY =B2.BOMPARENT 
	INNER JOIN INVENTOR C2 ON B2.UNIQ_KEY =C2.UNIQ_KEY 
	INNER JOIN INVENTOR M2 ON B2.BOMPARENT =M2.UNIQ_KEY 
	--WHERE P.PART_SOURC='PHANTOM' or (P.PART_SOURC='MAKE' and P.MAKE_BUY=CASE WHEN @IncludeMakeBuy=1 THEN P.MAKE_BUY ELSE 0 END)
	--	  and (@lcDate is NULL or ((b2.Eff_dt is null or DATEDIFF(day,b2.EFF_DT,@lcDate)>=0) and (b2.Term_dt is Null or DATEDIFF(day,b2.TERM_DT,@lcDate)<0)))	-- 09/22/15 DRP: Added	--10/29/15 DRP:  replaced by the below.
	WHERE (P.PART_SOURC='PHANTOM' or (P.PART_SOURC='MAKE' and P.MAKE_BUY=0) OR ( @IncludeMakeBuy=1 and P.Part_sourc='MAKE'))
		  and (@lcDate is NULL or ((b2.Eff_dt is null or DATEDIFF(day,b2.EFF_DT,@lcDate)>=0) and (b2.Term_dt is Null or DATEDIFF(day,b2.TERM_DT,@lcDate)<0)))	-- 10/29/15 DRP: Added
  )
	-- 03/01/19 has to list all columns because now item_note and Inv_note are not in Explode, so dont need to change all SP that use this SP
	--SELECT	E.*,isnull(CustI.CUSTPARTNO,space(25)) as CustPartno,isnull(CustI.CUSTREV,SPACE(8)) as CustRev,ISNULL(CustI.UNIQ_KEY,SPACE(10)) as CustUniqKey, N1.Note AS Item_note, N2.Note AS Inv_note  
	SELECT Bomparent, E.Bomcustno, E.Uniq_key, E.Item_no, E.Part_no, E.Revision, E.Part_sourc, ViewPartNo, ViewRevision, E.Part_class,
	 E.Part_type, E.Descript, E.Matltype, Dept_id
	 , N1.Note AS Item_note, OFfset, TERM_DT, Eff_dt
	 ,USED_INKIT, E.Custno, N2.Note AS Inv_note, E.U_of_meas, E.Scrap, E.Setupscrap, E.USESETSCRP, E.STDBLDQTY, E.PHANT_MAKE
	 ,E.STDCOST, E.Make_buy, E.Status, E.TopQty, E.Qty, Level, Path, Sort, UniqBomno, Buyer
	 ,E.STDCOSTPR, E.FUNCFCUSED_UNIQ, E.PRFCUSED_UNIQ, isnull(CustI.CUSTPARTNO,space(25)) as CustPartno
	 ,isnull(CustI.CUSTREV,SPACE(8)) as CustRev,ISNULL(CustI.UNIQ_KEY,SPACE(10)) as CustUniqKey
	 , N3.Note  AS Bom_note
	from	BomExplode E 
			LEFT OUTER JOIN INVENTOR CustI ON E.UNIQ_KEY =CustI.INT_UNIQ and E.BOMCUSTNO=CustI.CUSTNO 
	-- 03/01/19 VL change for BOM item_note and moved N1.N = 1 from WHERE to here
	LEFT OUTER JOIN (select n.recordid, R.NOTE,R.CreatedDate
	                    ,ROW_NUMBER() OVER(PARTITION BY N.RECORDID ORDER BY R.CREATEDDATE DESC) AS N 
						from wmNotes N inner join wmNoteRelationship R 
						on N.NoteID = R.FkNoteId 
						WHERE N.RecordType = 'BOM_DET' AND (@lcDate IS NULL OR DATEDIFF(day,R.CreatedDate,@lcDate)>=0) ) N1 
						ON E.UNIQBOMNO = N1.RecordId  AND N1.N = 1 -- 02/12/19 DRP: new manex note restructure
	-- 03/01/19 VL added for BOM item inv_note
	LEFT OUTER JOIN (select n.recordid, R.NOTE,R.CreatedDate
	                    ,ROW_NUMBER() OVER(PARTITION BY N.RECORDID ORDER BY R.CREATEDDATE DESC) AS N 
						from wmNotes N inner join wmNoteRelationship R on N.NoteID = R.FkNoteId
						WHERE N.RecordType = 'INVENTOR' AND (@lcDate IS NULL OR DATEDIFF(day,R.CreatedDate,@lcDate)>=0) ) N2 
						ON E.UNIQ_KEY = N2.RecordId  AND N2.N = 1


	-- 05/24/19 Shrikant Added column Bom_Note to avoid Duplicate code for report with new note structure for header note 
	LEFT OUTER JOIN (SELECT n.recordid, R.NOTE,R.CreatedDate
						,ROW_NUMBER() OVER(PARTITION BY N.RECORDID ORDER BY R.CREATEDDATE DESC) AS N 
						FROM wmNotes N INNER JOIN wmNoteRelationship R ON N.NoteID = R.FkNoteId
						WHERE N.RecordType = 'BOM_Header' 
					    AND (@lcDate IS NULL OR DATEDIFF(day,R.CreatedDate,@lcDate)>=0)
						 ) N3 
						ON E.Bomparent = N3.RecordId  AND N3.N = 1	

	ORDER BY sort OPTION (MAXRECURSION 100)  ;
		
														 
	--3/20/2012 added by David Sharp to return grid personalization with the results
	IF NOT @gridId IS NULL
		EXEC MnxUserGetGridConfig @userId, @gridId
END