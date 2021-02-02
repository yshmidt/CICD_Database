-- =============================================  
-- Author:  Yelena Shmidt  
-- Create date: 2018.06.12  
-- Description: Compare 2 BOM  
--- Parameters  
--- @uniq_key1 - uniq_key linked to the first product  
--- @uniq_key - uniq_key linked to the second product  
--- @compareType -possible values  'by Item', 'by Ref Designator','Both'  
-- 'by Item' will compare each item number and find differences   
-- 'by Ref Designator' will compare by Ref Designator and find the differences  
-- 'Both' will produce 2 results   
--  @UserId - to make sure that the user is an internal user and has rights to see customer's data  
-- Vijay G: 07/23/2018: To keep consistency of the column name changed the column name.  
-- Vijay G: 07/27/2018 - Get Ref Designator values  
-- 07/27/18 YS updated sort order. Want to see bu item, then by ref designator 
-- 07/28/18 Vijay G: rename column from comavls2 to compavls2
-- BomCompareTool 'L27PP8EMXM','L27PP8EMXM','By Ref Designator','49f80792-e15e-4b62-b720-21b360e3108a'
-- =============================================  
CREATE PROCEDURE BomCompareTool  
 -- Add the parameters for the stored procedure here  
 @uniq_key1 char(10) ='',  
 @uniq_key2 char(10) = '',  
 @compareType char(20) = 'by Item',  
 @UserId uniqueidentifier = null ---- '49F80792-E15E-4B62-B720-21B360E3108A'  
  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
 declare @IncludeMakeBuy bit=0,  
 @customerStatus varchar (20) = 'All',   
 @showSubAssembly bit=1 ;   
   
 declare @tBom1 table (bomParent char(10),item_no int,uniqbomno char(10),bomcustno char(10),UNIQ_KEY char(10),Part_sourc char(10) ,  
  Make_buy bit,Status char(10),[Level] integer ,  
  [path] varchar(max),[sort] varchar(max),[sort2] varchar(max),qty numeric(15,4), CustUniqKey char(10)) ;  
  
 declare @tBom2 table (bomParent char(10),item_no int,uniqbomno char(10),bomcustno char(10),UNIQ_KEY char(10),Part_sourc char(10) ,  
  Make_buy bit,Status char(10),[Level] integer ,  
  [path] varchar(max),[sort] varchar(max),[sort2] varchar(max),qty numeric(15,4), CustUniqKey char(10)) ;  
  
 IF OBJECT_ID('tempdb..#tbomc1') IS NOT NULL  
 begin  
  DROP TABLE #tbomc1 ;  
 end  
 IF OBJECT_ID('tempdb..#tbomc2') IS NOT NULL  
  DROP TABLE #tbomc2 ;  
  
 IF OBJECT_ID('tempdb..#ref1') IS NOT NULL  
  DROP TABLE #ref1 ;  
 IF OBJECT_ID('tempdb..#ref2') IS NOT NULL  
  DROP TABLE #ref2 ;  
   
 /*  
  !!! The code has to be modified in the miniBomIndented SP  
  for now I have the code in this SP , since miniBomIndented is missing item number and   
  ignoring effectivity dates  
 */  
 --- copy from miniBomExplode but I added check for eff_dt and term_dt and itemNo  
 ;WITH BomExplode as   
 (  
 SELECT B.bomParent,b.ITEM_NO, B.uniqbomno,M.BOMCUSTNO,B.UNIQ_KEY,c.Part_sourc ,  
  C.Make_buy, C.Status,   
     -- 09/30/16  YS make top level 1 instead of 0. Paramit PG has problem with 0 when printing reports  
    cast(1 as Integer) as [Level] ,  
  '/'+CAST(bomparent as varchar(max)) as [path],  
  CAST(dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY Item_no) as varchar(max))),4,'0') as varchar(max)) AS [Sort],  
  CAST(dbo.padl(RTRIM(CAST(Item_no as varchar(4))),4,'0') as varchar(max)) AS [Sort2],  
  b.qty  
 FROM BOM_DET B INNER JOIN INVENTOR C ON B.UNIQ_KEY =C.UNIQ_KEY   
  INNER JOIN INVENTOR M on B.BOMPARENT =M.UNIQ_KEY   
  WHERE B.BOMPARENT=@uniq_key1   
  and   
  (term_dt is null or datediff(day,getdate(),term_dt)>=0 )  
  and (EFF_DT is null or datediff(day,eff_dt, getdate())>=0 )  
 UNION ALL  
 SELECT  B2.BOMPARENT,b2.ITEM_NO ,B2.UNIQBOMNO, M2.BOMCUSTNO ,B2.Uniq_key,c2.Part_sourc ,  
  C2.Make_buy, C2.[Status],   
  P.Level+1,  
  CAST(RTRIM(LTRIM(P.Path))+'/'+B2.bomparent as varchar(max)) as [path] ,  
  CAST(RTRIM(p.Sort)+'-'+ dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY b2.Item_no) as varchar(4))),4,'0') as varchar(max)) AS [Sort],  
  CAST(RTRIM(p.Sort)+'-'+ dbo.padl(RTRIM(CAST(b2.Item_no as varchar(4))),4,'0') as varchar(max)) AS [Sort2],  
  b2.qty  
 FROM BomExplode as P INNER JOIN BOM_DET as B2 ON P.UNIQ_KEY =B2.BOMPARENT   
 INNER JOIN INVENTOR C2 ON B2.UNIQ_KEY =C2.UNIQ_KEY   
 INNER JOIN INVENTOR M2 ON B2.BOMPARENT =M2.UNIQ_KEY   
 WHERE P.PART_SOURC='PHANTOM' or (P.PART_SOURC='MAKE' and @showSubAssembly=1 and (P.MAKE_BUY=CASE WHEN @IncludeMakeBuy=1 THEN P.MAKE_BUY ELSE 0 END))  
 and   
 (b2.term_dt is null or datediff(day,getdate(),b2.term_dt)>=0 )  
 and (b2.EFF_DT is null or datediff(day,b2.eff_dt, getdate())>=0 )  
  )  
  insert into @tBom1  
  SELECT E.*,ISNULL(CustI.UNIQ_KEY,SPACE(10)) as CustUniqKey    
  from BomExplode E LEFT OUTER JOIN INVENTOR CustI ON E.UNIQ_KEY =CustI.INT_UNIQ and E.BOMCUSTNO=CustI.CUSTNO ORDER BY sort OPTION (MAXRECURSION 100)  ;  
;WITH BomExplode as   
 (  
 SELECT B.bomParent,b.ITEM_NO, B.uniqbomno,M.BOMCUSTNO,B.UNIQ_KEY,c.Part_sourc ,  
  C.Make_buy, C.Status,   
     -- 09/30/16  YS make top level 1 instead of 0. Paramit PG has problem with 0 when printing reports  
    cast(1 as Integer) as [Level] ,  
  '/'+CAST(bomparent as varchar(max)) as [path],  
  CAST(dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY Item_no) as varchar(max))),4,'0') as varchar(max)) AS [Sort],  
  CAST(dbo.padl(RTRIM(CAST(Item_no as varchar(4))),4,'0') as varchar(max)) AS [Sort2],  
  b.qty  
 FROM BOM_DET B INNER JOIN INVENTOR C ON B.UNIQ_KEY =C.UNIQ_KEY   
  INNER JOIN INVENTOR M on B.BOMPARENT =M.UNIQ_KEY   
  WHERE B.BOMPARENT=@uniq_key2   
  and   
  (term_dt is null or datediff(day,getdate(),term_dt)>=0 )  
  and (EFF_DT is null or datediff(day,eff_dt, getdate())>=0 )  
 UNION ALL  
 SELECT  B2.BOMPARENT,b2.ITEM_NO ,B2.UNIQBOMNO, M2.BOMCUSTNO ,B2.Uniq_key,c2.Part_sourc ,  
  C2.Make_buy, C2.[Status],   
  P.Level+1,  
  CAST(RTRIM(LTRIM(P.Path))+'/'+B2.bomparent as varchar(max)) as [path] ,  
  CAST(RTRIM(p.Sort)+'-'+ dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY b2.Item_no) as varchar(4))),4,'0') as varchar(max)) AS [Sort],  
  CAST(RTRIM(p.Sort)+'-'+ dbo.padl(RTRIM(CAST(b2.Item_no as varchar(4))),4,'0') as varchar(max)) AS [Sort2],  
  b2.qty  
 FROM BomExplode as P INNER JOIN BOM_DET as B2 ON P.UNIQ_KEY =B2.BOMPARENT   
 INNER JOIN INVENTOR C2 ON B2.UNIQ_KEY =C2.UNIQ_KEY   
 INNER JOIN INVENTOR M2 ON B2.BOMPARENT =M2.UNIQ_KEY   
 WHERE P.PART_SOURC='PHANTOM' or (P.PART_SOURC='MAKE' and @showSubAssembly=1 and (P.MAKE_BUY=CASE WHEN @IncludeMakeBuy=1 THEN P.MAKE_BUY ELSE 0 END))  
 and   
 (b2.term_dt is null or datediff(day,getdate(),b2.term_dt)>=0 )  
 and (b2.EFF_DT is null or datediff(day,b2.eff_dt, getdate())>=0 )  
  )  
  insert into @tBom2  
  SELECT E.*,ISNULL(CustI.UNIQ_KEY,SPACE(10)) as CustUniqKey    
  from BomExplode E LEFT OUTER JOIN INVENTOR CustI ON E.UNIQ_KEY =CustI.INT_UNIQ and E.BOMCUSTNO=CustI.CUSTNO ORDER BY sort OPTION (MAXRECURSION 100)  ;  
  
  
 --- test only  
 --select * from @tBom2 order by sort  
  
 DECLARE @tCustomers tCustomer ;  
 INSERT INTO @tCustomers EXEC [aspmnxSP_GetCustomers4User] @userid,null,@customerStatus ;  
   
 -- get avls for the first product. Concatenate AVLS for each item  
 ;WITH BomWithAvl1  
 AS  
 (  
 ---- 10/29/14 YS move orderpref to invtmpnlink  
 select B.*,M.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF ,L.UNIQMFGRHD,M.MatlType as MfgrMatlType,M.MATLTYPEVALUE  
  FROM @tBom1 B   
 INNER JOIN @tCustomers t on B.bomcustno=t.custno  
 --LEFT OUTER JOIN INVTMFHD ON B.CustUniqKey=INVTMFHD.UNIQ_KEY  
 LEFT OUTER JOIN InvtMPNLink L ON  B.CustUniqKey=L.UNIQ_KEY  
 LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId  
 WHERE B.CustUniqKey<>' '  
 AND M.IS_DELETED =0   
 and L.is_deleted=0  
 and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.CustUniqKey and A.PARTMFGR =M.PARTMFGR and A.MFGR_PT_NO =M.MFGR_PT_NO )  
 UNION ALL  
 select B.*,M.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF ,L.UNIQMFGRHD ,M.MatlType as MfgrMatlType,M.MATLTYPEVALUE  
 FROM @tBom1 B   
 INNER JOIN @tCustomers t on B.bomcustno=t.custno  
 --LEFT OUTER JOIN INVTMFHD ON B.UNIQ_KEY=INVTMFHD.UNIQ_KEY   
 LEFT OUTER JOIN InvtMPNLink L ON  B.Uniq_Key=L.UNIQ_KEY  
 LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId  
 WHERE B.CustUniqKey=' '  
 AND M.IS_DELETED =0   
 AND l.is_deleted=0  
 and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.UNIQ_KEY and A.PARTMFGR =M.PARTMFGR and A.MFGR_PT_NO =M.MFGR_PT_NO )  
 )  
 SELECT distinct bomparent,item_no,uniqbomno,btop.UNIQ_KEY,c.part_no,c.Revision,c.part_sourc,sort,sort2,qty,CustUniqKey,     
 STUFF(  
 (SELECT CAST(', [' + RTRIM(partmfgr)+' '+ RTRIM(mfgr_pt_no)+']' AS VARCHAR(MAX))   
 from BomWithAvl1 BXml   
 where bXml.uniqbomno=bTop.uniqbomno  
 ORDER BY PartMfgr,Mfgr_pt_no  
 for XML PATH('')  
 ),1,2,'')   
 as Avls  
 INTO #tbomc1  
 FROM BomWithAvl1 bTop inner join inventor c on btop.UNIQ_KEY=c.UNIQ_KEY  
  
   
 -- get avls for the second product. Concatenate AVLS for each item  
 ;WITH BomWithAvl2  
 AS  
 (  
  ---- 10/29/14 YS move orderpref to invtmpnlink  
 select B.*,M.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF ,L.UNIQMFGRHD,M.MatlType as MfgrMatlType,M.MATLTYPEVALUE  
  FROM @tBom2 B   
 INNER JOIN @tCustomers t on B.bomcustno=t.custno  
 --LEFT OUTER JOIN INVTMFHD ON B.CustUniqKey=INVTMFHD.UNIQ_KEY  
 LEFT OUTER JOIN InvtMPNLink L ON  B.CustUniqKey=L.UNIQ_KEY  
 LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId  
 WHERE B.CustUniqKey<>' '  
 AND M.IS_DELETED =0   
 and L.is_deleted=0  
 and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.CustUniqKey and A.PARTMFGR =M.PARTMFGR and A.MFGR_PT_NO =M.MFGR_PT_NO )  
 UNION ALL  
 select B.*,M.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF ,L.UNIQMFGRHD ,M.MatlType as MfgrMatlType,M.MATLTYPEVALUE  
 FROM @tBom2 B   
 INNER JOIN @tCustomers t on B.bomcustno=t.custno  
 --LEFT OUTER JOIN INVTMFHD ON B.UNIQ_KEY=INVTMFHD.UNIQ_KEY   
 LEFT OUTER JOIN InvtMPNLink L ON  B.Uniq_Key=L.UNIQ_KEY  
 LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId  
 WHERE B.CustUniqKey=' '  
 AND M.IS_DELETED =0   
 AND l.is_deleted=0  
 --and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.UNIQ_KEY and A.PARTMFGR =INVTMFHD.PARTMFGR and A.MFGR_PT_NO =Invtmfhd.MFGR_PT_NO )  
 and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.UNIQ_KEY and A.PARTMFGR =M.PARTMFGR and A.MFGR_PT_NO =M.MFGR_PT_NO )  
 )  
   
 SELECT distinct bomparent,item_no,uniqbomno,btop.UNIQ_KEY,c.part_no,c.Revision,c.part_sourc,sort,sort2,qty,CustUniqKey,     
 STUFF(  
 (SELECT CAST(', [' + RTRIM(partmfgr)+' '+ RTRIM(mfgr_pt_no) +']' AS VARCHAR(MAX))   
 from BomWithAvl2 BXml   
 where bXml.uniqbomno=bTop.uniqbomno  
 ORDER BY PartMfgr,Mfgr_pt_no  
 for XML PATH('')  
 ),1,2,'') as Avls  
 INTO #tbomc2  
 FROM BomWithAvl2 bTop inner join inventor c on btop.UNIQ_KEY=c.UNIQ_KEY  
  
 --- test only  
 --select * from #tbomc1 order by sort  
 --select * from #tbomc2 order by sort  
   
  
  
 --- part number is different - red  
 --- Qty is different - orange  
 -- Avls are different - yellow  
 -- item number is missing - purple  
 -- AVLs are going to be compared using difference() function, returns number 0 through 4 where 4 is the most commom found  
  
 --- find the differences by item  
 IF @compareType in ('by Item','Both')   
 BEGIN  
  select '' as RefDes, 0  as MissingRefDes,  
  t1.sort,t1.sort2, t1.item_no,case when t.item_no is null then 1 else 0 end as MissingitemNo,  
  c1.part_no as compPartBom1, c1.REVISION as compRevBom1, c1.PART_SOURC as compSourceBom1,  
  t.compPartBom2, t.compRevBom2,t.PART_SOURC as compSourceBom2,  
  case when t1.uniq_key<>t.UNIQ_KEY then 1 else 0 end as DiffPartNo,  
  -- 07/28/18 Vijay G: rename column from comavls2 to compavls2
  t1.Qty as Qty1,t.Qty2 ,case when t1.qty<>t.qty2 then 1 else 0 end as  QtyDifferent,  
  Avls as compAvls1, Avls2 as compavls2,case when t1.Avls=t.Avls2 then 0 else 1 end as AvlDifference ,   
  t1.uniq_key as uniqkey1,t.uniq_key as uniqkey2  
  from #tbomc1 t1 inner join inventor c1 on t1.uniq_key=c1.uniq_key  
  left outer join   
  (select t2.sort,t2.sort2, t2.uniq_key, item_no,c2.part_no as compPartBom2, c2.REVISION as compRevBom2,t2.Qty as Qty2,Avls as Avls2,c2.PART_SOURC  
   from #tbomc2 t2 inner join inventor c2 on t2.uniq_key=c2.uniq_key) t  
   on t1.sort2=t.sort2  
   --order by sort  
  UNION      
  select '' as RefDes, 0  as MissingRefDes, t2.sort,t2.sort2, t2.item_no,1 as MissingitemNo,  
  null as compPartBom1, null as compRevBom1, null as compSourceBom1,  
  c2.part_no as compPartBom2,  c2.REVISION as compRevBom2,c2.PART_SOURC as compSourceBom2,  
  0  as DiffPartNo,  
  null as Qty1,t2.qty as Qty2 ,0 as  QtyDifferent,  
  -- 07/28/18 Vijay G: rename column from comavls2 to compavls2
  null as compAvls1, t2.Avls as compavls2,0 as AvlDifference ,   
  null as uniqkey1,t2.uniq_key as uniqkey2  
  from #tbomc2 t2 inner join inventor c2 on t2.uniq_key=c2.uniq_key  
  where not exists (select 1 from  #tbomc1 t1 where t2.sort2=t1.sort2)  
  order by sort  
 END --- IF @compareType='buy Item'  
   
   
  
  
   
 IF @compareType in ('by Ref Designator','Both')  
 BEGIN   
 -- Vijay G: 07/23/2018: To keep consistency of the column name compAvls1.  
  select d1.sort, d1.sort2,d1.ITEM_NO,d1.Part_sourc as compSourceBom1,d1.PART_NO as compPartBom1,d1.revision as compRevBom1, d1.qty as qty1,d1.UNIQ_KEY as uniqkey1,   
  d1.avls as compAvls1,  
  r1.*   
  into #ref1  
  from bom_ref r1 inner join #tbomc1 d1 on d1.UNIQBOMNO=r1.UNIQBOMNO   
  order by d1.sort  
 -- Vijay G: 07/23/2018: To keep consistency of the column name compAvls2.  
  select d2.sort, d2.sort2,d2.ITEM_NO,d2.Part_sourc as compSourceBom2,d2.PART_NO as compPartBom2,d2.revision as compRevBom2, d2.qty as qty2,d2.UNIQ_KEY as uniqkey2,   
  d2.avls as compAvls2,  
  r2.*   
  into #ref2  
  from bom_ref r2 inner join #tbomc2 d2 on d2.UNIQBOMNO=r2.UNIQBOMNO   
  order by d2.sort  
   
  ---- compare  
  -- Vijay G: 07/23/2018: To keep consistency of the column name item_no.  
    -- Vijay G: 07/27/2018 - Get Ref Designator values  
  select r1.REF_DES AS RefDes, case when r2.REF_DES is null or r1.REF_DES<>r2.REF_DES then 1 else 0 end as MissingRefDes,  
    r1.nbr,r1.sort as sortBom, r1.sort2, r1.item_no,  
  --r2.sort as sortBom2,r2.item_no as itemnoBom2,  
  case when r2.item_no is null or r1.item_no<>r2.item_no then 1 else 0 end as MissingitemNo,  
  r1.compPartBom1, r1.compRevBom1,r1.compSourceBom1,  
  r2.compPartBom2, r2.compRevBom2,r2.compSourceBom2,  
  case when r1.uniqkey1<>r2.uniqkey2 then 1 else 0 end as DiffPartNo,  
  -- Vijay G: 07/23/2018: To keep consistency of the column name. Changed the DiffQty as QtyDifferent column name  
  r1.qty1,r2.qty2, case when r1.qty1<>r2.qty2 then 1 else 0 end as QtyDifferent,  
  -- Vijay G: 07/23/2018: To keep consistency of the column name compAvls1 and compAvls2.  
  r1.compAvls1,r2.compAvls2,case when r1.compAvls1=r2.compAvls2 then 0 else 1 end as AvlDifference ,   
  r1.uniqkey1, r2.uniqkey2   
  from #ref1 r1 left outer join #ref2 r2 on r1.REF_DES=r2.REF_DES and r1.sort2=r2.sort2  
  --order by REF_DES  
  UNION  
  -- Vijay G: 07/23/2018: To keep consistency of the column name item_no.  
    -- Vijay G: 07/27/2018 - Get Ref Designator values  
  select r2.REF_DES AS RefDes,1 AS MissingRefDes,  
    r2.nbr,r2.sort as sortBom,r2.sort2, r2.item_no, 1 as MissingitemNo,  
  null as compPartBom1, null as compRevBom1,null as compSourceBom1,  
  r2.compPartBom2, r2.compRevBom2,r2.compSourceBom2,  
  0 as DiffPartNo,  
  -- Vijay G: 07/23/2018: To keep consistency of the column name. Changed the column name DiffQty as QtyDifferent  
  null as qty1,r2.qty2, 0 as QtyDifferent,  
  null as compAvls1,r2.compAvls2, 0 as AvlDifference ,   
  null as uniqkey1, r2.uniqkey2   
  from #ref2 r2   
  where not exists (select 1 from #ref1 r1 where r1.REF_DES=r2.REF_DES and r1.sort2=r2.sort2)  
  --07/27/18 YS updated sort order. Want to see bu item, then by ref designator  
  order by sortBom,RefDes,nbr 
 END --- IF @compareType='by Ref Designator'  
  
END