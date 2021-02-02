
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/01/2012 
-- Description:	Indented BOM with make and phantom parts exploded
 --	09/30/16	 YS make top level 1 instead of 0. Paramit PG has problem with 0 when printing reports
-- =============================================
CREATE PROCEDURE [dbo].[BomTopLevelAndPhantomExploded]
	-- Add the parameters for the stored procedure here
	@lcBomParent char(10)=' ' ,@ShowIndentation bit =1,	@UserId uniqueidentifier=NULL 
	---@gridId varchar(50) = null
	
	-- list of parameters:
	-- 1. @lcBomParent - top level BOM uniq_key 
	-- 2. @UserId - for now is optional will be ignored if null. Will be used by WEB fron to identify if the user has rights to see the BOM.
	-- 3. @ShowIndentation add spaces in front of the PartView value to clearly show indentation (for now 4 spaces if =1, no spaces if =0, can customize later)
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	 WITH BomExplode as 
  (
  SELECT B.bomParent,M.BOMCUSTNO, B.UNIQ_KEY, B.item_no,C.PART_NO,C.Revision,c.Part_sourc ,
  CAST(CASE WHEN C.part_sourc='CONSG' THEN C.Custpartno ELSE C.Part_no END as varchar(max)) AS ViewPartNo,
  CASE WHEN C.part_sourc='CONSG' THEN C.Custrev ELSE C.Revision END AS ViewRevision,
	C.Part_class, C.Part_type, C.Descript,
	B.Dept_id, B.Item_note, B.Offset, B.Term_dt, B.Eff_dt, B.Used_inKit,C.Custno, C.Inv_note, C.U_of_meas, C.Scrap, C.Setupscrap,M.USESETSCRP,M.STDBLDQTY,
	C.Phant_Make, C.StdCost, C.Make_buy, C.Status, 
    cast(1.00 as numeric(9,2)) as TopQty, B.Qty , 
	 --	09/30/16	 YS make top level 1 instead of 0. Paramit PG has problem with 0 when printing reports
	cast(1 as Integer) as Level ,
	'/'+CAST(bomparent as varchar(max)) as path,
	CAST(dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY Item_no) as varchar(max))),4,'0') as varchar(max)) AS Sort,
	B.UniqBomNo
	FROM BOM_DET B INNER JOIN INVENTOR C ON B.UNIQ_KEY =C.UNIQ_KEY 
	INNER JOIN INVENTOR M on B.BOMPARENT =M.UNIQ_KEY 
	WHERE B.BOMPARENT=@lcBomParent 
	
	UNION ALL
	
	SELECT  B2.BOMPARENT,M2.BOMCUSTNO , B2.Uniq_key,B2.item_no ,C2.PART_NO,C2.Revision,c2.Part_sourc ,
	CAST(CASE WHEN @ShowIndentation=1 THEN SPACE((P.level+1)*4) ELSE SPACE(0) END +CASE WHEN C2.part_sourc='CONSG' THEN C2.Custpartno ELSE C2.Part_no  END as varchar(max)) AS ViewPartNo,
	CASE WHEN C2.part_sourc='CONSG' THEN C2.Custrev ELSE C2.Revision END AS ViewRevision,
	C2.Part_class, C2.Part_type, C2.Descript,
	B2.Dept_id, B2.Item_note, B2.Offset, B2.Term_dt, B2.Eff_dt, B2.Used_inKit,C2.Custno, 
	C2.Inv_note, C2.U_of_meas, C2.Scrap, C2.Setupscrap,M2.USESETSCRP,M2.STDBLDQTY,
	C2.Phant_Make, C2.StdCost, C2.Make_buy, C2.Status, 
	P.Qty as TopQty,B2.QTY, P.Level+1,
	CAST(RTRIM(LTRIM(P.Path))+'/'+B2.bomparent as varchar(max)) as path   ,
	CAST(RTRIM(p.Sort)+'-'+	dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY b2.Item_no) as varchar(4))),4,'0') as varchar(max)) AS Sort,
	B2.UNIQBOMNO 
	FROM BomExplode as P INNER JOIN BOM_DET as B2 ON P.UNIQ_KEY =B2.BOMPARENT 
	INNER JOIN INVENTOR C2 ON B2.UNIQ_KEY =C2.UNIQ_KEY 
	INNER JOIN INVENTOR M2 on B2.BOMPARENT =M2.UNIQ_KEY 
	WHERE P.PART_SOURC='PHANTOM'
  )
  -- cannot use outer join in the recursive part of recursive common table expression
	SELECT   E.*,isnull(CustI.CUSTPARTNO,space(25)) as CustPartno,isnull(CustI.CUSTREV,SPACE(8)) as CustRev,ISNULL(CustI.UNIQ_KEY,SPACE(10)) as CustUniqKey  
		from BomExplode E LEFT OUTER JOIN INVENTOR CustI ON E.UNIQ_KEY =CustI.INT_UNIQ and E.BOMCUSTNO=CustI.CUSTNO  ORDER BY Sort

	--3/20/2012 added by David Sharp to return grid personalization with the results
	--EXEC MnxUserGetGridConfig @userId, @gridId


END