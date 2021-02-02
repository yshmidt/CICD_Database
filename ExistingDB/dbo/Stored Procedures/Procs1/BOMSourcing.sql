
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/05/2012
-- Description:	BOM information with AVL and Supplier information
-- Modified: 08/13/14 YS select top 1 in each subquery (last and most)
--			10/08/14 YS replace invtmfhd with 2 new tables
-- 10/29/14    move orderpref to invtmpnlink
--- 03/28/17 YS changed length of the part_no column from 25 to 35
--- 07/11/18 YS supname increased from 30 to 50
-- =============================================
CREATE PROCEDURE [dbo].[BOMSourcing] 
	-- Add the parameters for the stored procedure here
	@lcBomParent char(10)=' ',@UserId uniqueidentifier=NULL, @gridId varchar(50) = null, @dDate smalldatetime = '19000101'
	AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- 07/27/2012 YS added new @dDate parameter, 
	-- by default request parts, which are current for today's date  (cannot use GETDATE() function when assign a value to a parameter) 
	-- if user pass NULL all the parts has to be included
	-- otherwise only those parts that are active for the given @dDate
	
	
	--- this sp will 
	----- 1. find BOM information and explode PHANTOM parts if any on the BOM
	----- 2. Figure out AVL (if internal part, but BOM assigned to a customer, an appropriate AVL will be found
	----- 3. Remove AVL if any AntiAvl are assigned
	----- 4. Check if any supplier assigned and pick default supplier for a specific AVL for a part  ('Assigned' column)
	----- 5. If no default supplier assigned but there are suppliers assigned to an MPN, pick the first sorted by name
	----- 6. Add a column for the supplier name with the most recent PO ('Last 'column)
	----- 7. Add a column for the supplier name with the most qty ordered ('Most' column)
	----- 8. Group parts together, do not show which level they came from
    -- Insert statements for procedure here
    --  07/27/12 DATEADD(day, DATEDIFF(day, 0, @dDate), 0) to get rid of the time pasrt
    SET @dDate = CASE WHEN @dDate='19000101' THEN DATEADD(day, DATEDIFF(day, 0, GETDATE()), 0) 
					WHEN  NOT @dDate IS NULL THEN DATEADD(day, DATEDIFF(day, 0, @dDate), 0) ELSE @dDate END
	--- 03/28/17 YS changed length of the part_no column from 25 to 35				
	declare @tBom table (bomParent char(10),bomcustno char(10),UNIQ_KEY char(10),item_no numeric(4),PART_NO char(35),Revision char(8),Part_sourc char(10) ,
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
	ViewPartNo char(35),ViewRevision char(8),Part_class char(8),Part_type char(8),Descript char(45),Dept_id char(8),Item_note varchar(max),Offset numeric(4,0),
	Term_dt date,Eff_dt date, Used_inKit char(1),custno char(10),Inv_note varchar(max),U_of_meas char(4), Scrap numeric(6,2),SetupScrap numeric(4,0),USESETSCRP bit,STDBLDQTY numeric(8,0),
	Phantom_make bit,
	StdCost numeric(13,5),Make_buy bit,Status char(10),
	topqty numeric(9,2),qty numeric(9,2),Level integer ,
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
  path varchar(max),Sort varchar(max),UniqBomNo char(10),CustPartNo char(35),CustRev char(8),CustUniqKey char(10))
  INSERT INTO @tBom EXEC  [BomTopLevelAndPhantomExploded] @lcBomParent,0;
  
  --select B.* from @tBom B 
  -- find all mfgrs
 -- select B.*,InvtMfhd.PARTMFGR ,Invtmfhd.MFGR_PT_NO,Invtmfhd.ORDERPREF FROM @tBom B LEFT OUTER JOIN INVTMFHD ON B.UNIQ_KEY=INVTMFHD.UNIQ_KEY and Invtmfhd.IS_DELETED =0 order by path,item_no,ORDERPREF 
  -- now finad  AVLS (will have to check if the BOM is assigned to a customer and if consign part has different avl set)  and remove antiavls
  -- add default supplier if sullpier assigned but not defaulted add the first one in alphabetical order
 -- 07/27/12 YS add effective date filter
 --	10/08/14 YS replace invtmfhd with 2 new tables
  WITH BomWithAvl
  AS
  (
  select B.*,
  --InvtMfhd.PARTMFGR ,Invtmfhd.MFGR_PT_NO,Invtmfhd.ORDERPREF ,Invtmfhd.UNIQMFGRHD 
 -- 10/29/14    move orderpref to invtmpnlink
  M.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF ,L.UNIQMFGRHD 
	FROM @tBom B LEFT OUTER JOIN InvtMPNLink L ON B.CustUniqKey=L.UNIQ_KEY 
	LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
	--LEFT OUTER JOIN INVTMFHD ON B.CustUniqKey=INVTMFHD.UNIQ_KEY 
	WHERE B.CustUniqKey<>' '
	--AND Invtmfhd.IS_DELETED =0 
	AND l.is_deleted= 0 and m.IS_DELETED=0
	AND 1 =
		CASE WHEN NOT @dDate IS NULL THEN 
				CASE WHEN (Eff_dt is null or DATEDIFF(day,EFF_DT,@dDate)>=0)
				AND (Term_dt is Null or DATEDIFF(day,TERM_DT,@dDate)<0) THEN 1 ELSE 0 END
			ELSE 1
			END
	--AND NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.CustUniqKey and A.PARTMFGR =INVTMFHD.PARTMFGR and A.MFGR_PT_NO =Invtmfhd.MFGR_PT_NO )
	AND NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.CustUniqKey and A.PARTMFGR =M.PARTMFGR and A.MFGR_PT_NO =M.MFGR_PT_NO )
  UNION ALL
	select B.*,
	--InvtMfhd.PARTMFGR ,Invtmfhd.MFGR_PT_NO,Invtmfhd.ORDERPREF ,Invtmfhd.UNIQMFGRHD 
	 M.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF ,L.UNIQMFGRHD 
	FROM @tBom B LEFT OUTER JOIN InvtMPNLink L ON B.Uniq_Key=L.UNIQ_KEY 
	LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
	--LEFT OUTER JOIN INVTMFHD ON B.UNIQ_KEY=INVTMFHD.UNIQ_KEY 
	WHERE B.CustUniqKey=' '
	--AND Invtmfhd.IS_DELETED =0 
	AND l.is_deleted= 0 and m.IS_DELETED=0
	AND 1 =
		CASE WHEN NOT @dDate IS NULL THEN 
				CASE WHEN (Eff_dt is null or DATEDIFF(day,EFF_DT,@dDate)>=0)
				AND (Term_dt is Null or DATEDIFF(day,TERM_DT,@dDate)<0) THEN 1 ELSE 0 END
			ELSE 1
			END
	--and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.UNIQ_KEY and A.PARTMFGR =INVTMFHD.PARTMFGR and A.MFGR_PT_NO =Invtmfhd.MFGR_PT_NO )
	and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.UNIQ_KEY and A.PARTMFGR =M.PARTMFGR and A.MFGR_PT_NO =M.MFGR_PT_NO )
	),
	AssignedSuppl
	AS 
	(SELECT Invtmfsp.Uniqsupno,Supinfo.SupName,invtmfsp.UNIQMFGRHD,PFDSUPL 
		FROM INVTMFSP INNER JOIN SUPINFO ON Invtmfsp.uniqsupno =Supinfo.UNIQSUPNO 
		where invtmfsp.PFDSUPL=1 and Invtmfsp.UNIQMFGRHD IN( SELECT UNIQMFGRHD FROM BomWithAvl)   
	UNION
	SELECT Invtmfsp.Uniqsupno,Supinfo.SupName,invtmfsp.UNIQMFGRHD ,PFDSUPL
		FROM INVTMFSP INNER JOIN SUPINFO ON Invtmfsp.uniqsupno =Supinfo.UNIQSUPNO 
		where invtmfsp.PFDSUPL=0 and Invtmfsp.UNIQMFGRHD IN( SELECT UNIQMFGRHD FROM BomWithAvl)
	),
	PrefSuppl
	AS (SELECT Uniqsupno,SupName,UNIQMFGRHD ,PFDSUPL,ROW_NUMBER () OVER (Partition By  UNIQMFGRHD ORDER BY PFDSUPL DESC,SupName) as nSuppl
		FROM AssignedSuppl ),
	--08/13/14 YS select top 1 in each subquery (last and most)
	BomWithAvlPrefSuppl
	AS
	(
	--- 07/11/18 YS supname increased from 30 to 50
	SELECT ISNULL(PrefSuppl.PFDSUPL,0) as PFDSUPL ,ISNULL(PrefSuppl.Uniqsupno,space(10)) as Uniqsupno,
			ISNULL(PrefSuppl.Supname,space(50)) as 'Assigned',ISNULL(L.Supname,space(50)) as 'Last',
			ISNULL(Q.Supname,space(50)) as 'Most',
		 BomWithAvl.*  
		FROM BomWithAvl LEFT OUTER JOIN PrefSuppl ON BomWithAvl.UNIQMFGRHD   = PrefSuppl.UNIQMFGRHD and PrefSuppl.nSuppl =1
		OUTER APPLY (SELECT TOP(1)  Supinfo.Supname, Pomain.UNIQSUPNO,Poitems.UNIQMFGRHD ,MAX(POMAIN.PODATE) as LatestOrdered 
				from POMAIN inner join SUPINFO on pomain.UNIQSUPNO =supinfo.UNIQSUPNO 
				INNER JOIN POITEMS ON pomain.PONUM=poitems.PONUM 
				WHERE pomain.POSTATUS<>'CANCELLED' 
				and Poitems.LCANCEL =0 
				and Poitems.UNIQMFGRHD=BomWithAvl.UNIQMFGRHD 
				GROUP BY Supinfo.Supname, Pomain.UNIQSUPNO,Poitems.UNIQMFGRHD ORDER BY MAX(POMAIN.PODATE)) L
		OUTER APPLY (SELECT TOP(1) Supinfo.Supname, Pomain.UNIQSUPNO,Poitems.UNIQMFGRHD ,MAX(Poitems.ORD_QTY) as MostQty 
				from POMAIN inner join SUPINFO on pomain.UNIQSUPNO =supinfo.UNIQSUPNO 
				INNER JOIN POITEMS ON pomain.PONUM=poitems.PONUM 
				WHERE pomain.POSTATUS<>'CANCELLED' 
				and Poitems.LCANCEL =0 
				and Poitems.UNIQMFGRHD=BomWithAvl.UNIQMFGRHD 
				GROUP BY Supinfo.Supname, Pomain.UNIQSUPNO,Poitems.UNIQMFGRHD ORDER BY MAX(Poitems.ORD_QTY)) Q		
	)
	
	SELECT DISTINCT [Assigned],[Last],[Most],UNIQ_KEY,PART_NO,Revision,Part_sourc,ViewPartNo,ViewRevision,Part_class,Part_type,Descript,
		custno,U_of_meas,StdCost,Make_buy,Status,CustPartNo,CustRev,CustUniqKey,PARTMFGR,MFGR_PT_NO
	 from BomWithAvlPrefSuppl  WHERE Part_sourc<>'PHANTOM'	
		
	--3/20/2012 added by David Sharp to return grid personalization with the results
	IF NOT @gridId IS NULL
	   EXEC MnxUserGetGridConfig @userId, @gridId
END