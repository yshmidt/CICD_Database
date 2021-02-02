-- =============================================    
-- Author:  Yelena Shmidt    
-- Create date: 03/05/2012    
-- Description: BOM information with AVL     
-- Modified: 10/02/2013 DRP:   Found MatlType char (8) should have been MatlType char (10)    
--    03/19/14 YS added Buyer column to [BomIndented]    
--    10/08/14 YS replace invtmfhd with 2 new tables    
--    10/29/14    move orderpref to invtmpnlink    
--    09/22/15 DRP:  added @lcDate parameter to the procedure.  the default will be Null to pass all items (active, obsolete,etc . . .)  if populated with date then passed to BomIndented.    
--- 03/28/17 YS changed length of the part_no column from 25 to 35    
---08/14/17 YS added PR currency   
-- 05/24/2019 Shrikant added column Bom_note for assembly note  
-- BOMIndentedWithAvl '_39P0RLDFH', 1,1  
-- =============================================    
CREATE PROCEDURE [dbo].[BOMIndentedWithAvl]     
 -- Add the parameters for the stored procedure here    
 @lcBomParent char(10)=' ',@IncludeMakeBuy bit=1 ,@ShowIndentation bit=1, 
 @UserId uniqueidentifier=NULL, 
 @lcDate smalldatetime = null, @gridId varchar(50) = null    
 AS    
BEGIN    
 -- SET NOCOUNT ON added to prevent extra result sets from    
 -- interfering with SELECT statements.    
 SET NOCOUNT ON;    
     
 -- list of parameters:    
 -- 1. @lcBomParent - top level BOM uniq_key     
 -- 2. @IncludeMakeBuy if the value is 1 will explode make/buy parts ; if 0 - will not (default 1)    
 -- 3. @ShowIndentation add spaces in front of the PartView value to clearly show indentation (for now 4 spaces if =1, no spaces if =0, can customize later)    
 -- 3. @UserId - for now is optional will be ignored if null. Will be used by WEB fron to identify if the user has rights to see the BOM.    
     
 --- this sp will     
 ----- 1. find BOM information and explode PHANTOM and Make parts. If the make part has make/buy flag and @IncludeMakeBuy=0, then Make/Buy will not be indented to the next level    
 ----- 2. Figure out AVL (if internal part, but BOM assigned to a customer, an appropriate consign part AVL will be found    
 ----- 3. Remove AVL if any AntiAvl are assigned    
    
    -- Insert statements for procedure here    
 -- 03/29/12 YS added Bom_note and Bom_status to BomIndented SP    
 --08/10/2012 DRP: added the Material Type to the BOMIndented procedure so I had to insert IT here within this table    
 --10/02/2013 DRP:   Found MatlType char (8) should have been MatlType char (10)    
 --    03/19/14 YS added Buyer column to [BomIndented]    
 --- 03/28/17 YS changed length of the part_no column from 25 to 35    
 declare @tBom table (bomParent char(10),bomcustno char(10),UNIQ_KEY char(10),item_no numeric(4),PART_NO char(35),Revision char(8),Part_sourc char(10) ,    
 ViewPartNo varchar(max),ViewRevision char(8),Part_class char(8),Part_type char(8),Descript char(45),MatlType char (10),Dept_id char(8),Item_note varchar(max),Offset numeric(4,0),    
 Term_dt date,Eff_dt date, Used_inKit char(1),custno char(10),Inv_note varchar(max),U_of_meas char(4), Scrap numeric(6,2),SetupScrap numeric(4,0),USESETSCRP bit,STDBLDQTY numeric(8,0),    
 Phantom_make bit,    
 StdCost numeric(13,5),Make_buy bit,Status char(10),    
 TopQty numeric(10,2),qty numeric(9,2),Level integer ,    
  path varchar(max),sort varchar(max),    
   UniqBomNo char(10),Buyer char(3),    
   ---08/14/17 YS added PR currency     
 stdcostpr numeric(13,5),funcFcUsed_uniq char(10),PrFcUsed_uniq char(10),    
   CustPartNo char(35),CustRev char(8),CustUniqKey char(10)
   -- 05/24/2019 Shrikant added column Bom_note for assembly note
    , Bom_note varchar(max) )    
      
    
  INSERT INTO @tBom EXEC  [BomIndented] @lcBomParent,@IncludeMakeBuy,@ShowIndentation,@UserId,@lcDate; --09/22/15 DRP:  Added @lcDate;    
      
  --select B.* from @tBom B     
  -- find all mfgrs    
 -- select B.*,InvtMfhd.PARTMFGR ,Invtmfhd.MFGR_PT_NO,Invtmfhd.ORDERPREF FROM @tBom B LEFT OUTER JOIN INVTMFHD ON B.UNIQ_KEY=INVTMFHD.UNIQ_KEY and Invtmfhd.IS_DELETED =0 order by path,item_no,ORDERPREF     
  -- now finad  AVLS (will have to check if the BOM is assigned to a customer and if consign part has different avl set) and remove antiavls    
  -- add default supplier if sullpier assigned but not defaulted add the first one in alphabetical order    
  --08/10/2012 DRP: added the Material Type to the below section so that it is available at the AVL level also    
    
  --10/08/14 YS replace Invtmfhd with 2 new tables    
  WITH BomWithAvl    
  AS    
  (    
  select B.*,    
  --InvtMfhd.PARTMFGR ,Invtmfhd.MFGR_PT_NO,Invtmfhd.ORDERPREF ,Invtmfhd.UNIQMFGRHD,Invtmfhd.MatlType as MfgrMatlType,INVTMFHD.MATLTYPEVALUE    
 -- 10/29/14    move orderpref to invtmpnlink    
 M.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF ,L.UNIQMFGRHD,M.MatlType as MfgrMatlType,M.MATLTYPEVALUE    
 FROM @tBom B     
 LEFT OUTER JOIN InvtMPNLink L ON B.CustUniqKey=L.UNIQ_KEY     
 LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId    
 --LEFT OUTER JOIN INVTMFHD ON B.CustUniqKey=INVTMFHD.UNIQ_KEY     
 WHERE B.CustUniqKey<>' '    
 AND M.IS_DELETED =0  AND L.is_deleted=0    
 --and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.CustUniqKey and A.PARTMFGR =INVTMFHD.PARTMFGR and A.MFGR_PT_NO =Invtmfhd.MFGR_PT_NO )    
 and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.CustUniqKey and A.PARTMFGR =M.PARTMFGR and A.MFGR_PT_NO =M.MFGR_PT_NO )    
UNION ALL    
 select B.*,    
 --InvtMfhd.PARTMFGR ,Invtmfhd.MFGR_PT_NO,Invtmfhd.ORDERPREF ,Invtmfhd.UNIQMFGRHD ,Invtmfhd.MatlType as MfgrMatlType,INVTMFHD.MATLTYPEVALUE    
 -- 10/29/14    move orderpref to invtmpnlink    
 M.PARTMFGR ,M.MFGR_PT_NO,L.ORDERPREF ,L.UNIQMFGRHD ,M.MatlType as MfgrMatlType,M.MATLTYPEVALUE    
 FROM @tBom B     
 --LEFT OUTER JOIN INVTMFHD ON B.UNIQ_KEY=INVTMFHD.UNIQ_KEY     
 LEFT OUTER JOIN InvtMPNLink L ON B.UNIQ_KEY=L.UNIQ_KEY     
 LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId    
 WHERE B.CustUniqKey=' '    
 --AND Invtmfhd.IS_DELETED =0     
 AND M.IS_DELETED=0 and l.is_deleted=0    
 --and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.UNIQ_KEY and A.PARTMFGR =INVTMFHD.PARTMFGR and A.MFGR_PT_NO =Invtmfhd.MFGR_PT_NO )    
 and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.UNIQ_KEY and A.PARTMFGR =M.PARTMFGR and A.MFGR_PT_NO =M.MFGR_PT_NO )    
 )    
 SELECT   * from BomWithAvl ORDER BY Sort     
     
 --3/20/2012 added by David Sharp to return grid personalization with the results    
 IF NOT @gridId IS NULL    
    EXEC MnxUserGetGridConfig @userId, @gridId      
      
END