-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 06/09/2014
-- Description:	get minimum information for the given BOM, use in other procedures like AVl4Bom, RefDes4BOM
 --	09/30/16	 YS make top level 1 instead of 0. Paramit PG has problem with 0 when printing reports
-- =============================================
CREATE PROCEDURE [dbo].[miniBomIndented]
	-- Add the parameters for the stored procedure here
	@BomParent char(10)=' ', @showSubAssembly bit=0, @IncludeMakeBuy bit=0 

	-- list of parameters:
	-- 1. @BomParent - top level BOM uniq_key 
	-- 2. @showSubAssembly - explode 'MAKE' parts
	-- 2. @IncludeMakeBuy - if showSubAssembly = 1 this parameter indicates if make/buy parts will be exploded as well; if 0 - will not (default 1)
	-- 3. @UserId - check if user allowed to view a bom based on the customer list assigned to a user
	
	--- this sp will 
	----- 1. find BOM information and explode PHANTOM. It will also explode Make parts if @showSubAssembly=1. If the make part has make/buy flag and @IncludeMakeBuy=0, then Make/Buy will not be indented to the next level
	----- 2. Figure out AVL (if internal part, but BOM assigned to a customer, an appropriate consign part AVL will be found
	----- 3. Remove AVL if any AntiAvl are assigned
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	
	;WITH BomExplode as 
	(
	SELECT B.bomParent,B.uniqbomno,M.BOMCUSTNO,B.UNIQ_KEY,c.Part_sourc ,
		C.Make_buy, C.Status, 
	    --	09/30/16	 YS make top level 1 instead of 0. Paramit PG has problem with 0 when printing reports
	   cast(1 as Integer) as [Level] ,
		'/'+CAST(bomparent as varchar(max)) as [path],
		CAST(dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY Item_no) as varchar(max))),4,'0') as varchar(max)) AS [Sort]
	FROM BOM_DET B INNER JOIN INVENTOR C ON B.UNIQ_KEY =C.UNIQ_KEY 
		INNER JOIN INVENTOR M on B.BOMPARENT =M.UNIQ_KEY 
		WHERE B.BOMPARENT=@BomParent 
	UNION ALL
	SELECT  B2.BOMPARENT,B2.UNIQBOMNO, M2.BOMCUSTNO ,B2.Uniq_key,c2.Part_sourc ,
		C2.Make_buy, C2.[Status], 
		P.Level+1,
		CAST(RTRIM(LTRIM(P.Path))+'/'+B2.bomparent as varchar(max)) as [path] ,
		CAST(RTRIM(p.Sort)+'-'+	dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY b2.Item_no) as varchar(4))),4,'0') as varchar(max)) AS [Sort]
	FROM BomExplode as P INNER JOIN BOM_DET as B2 ON P.UNIQ_KEY =B2.BOMPARENT 
	INNER JOIN INVENTOR C2 ON B2.UNIQ_KEY =C2.UNIQ_KEY 
	INNER JOIN INVENTOR M2 ON B2.BOMPARENT =M2.UNIQ_KEY 
	WHERE P.PART_SOURC='PHANTOM' or (P.PART_SOURC='MAKE' and @showSubAssembly=1 and (P.MAKE_BUY=CASE WHEN @IncludeMakeBuy=1 THEN P.MAKE_BUY ELSE 0 END))
  )
  SELECT E.*,ISNULL(CustI.UNIQ_KEY,SPACE(10)) as CustUniqKey  
		from BomExplode E LEFT OUTER JOIN INVENTOR CustI ON E.UNIQ_KEY =CustI.INT_UNIQ and E.BOMCUSTNO=CustI.CUSTNO ORDER BY sort OPTION (MAXRECURSION 100)  ;

END