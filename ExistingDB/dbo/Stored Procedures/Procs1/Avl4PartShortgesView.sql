-- =============================================  
-- Author:  <Yelena Shmidt>  
-- Create date: <01/07/2011>  
-- Description: <Gather AVL information for a given part, which currently has shortages>  
-- Modified: 10/08/14 YS use new tables in place of Invtmfhd  
--- 03/28/17 YS changed length of the part_no column from 25 to 35  
--  03/15/2017 Shivshankar P : Added columns  
--- 02/14/2020 Vijay G: Changed length of the part_no column from 35 to 50
-- =============================================  
CREATE PROCEDURE [dbo].[Avl4PartShortgesView]   
 -- Add the parameters for the stored procedure here  
 @lcUniq_key char(10)=' '  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
 --- 03/28/17 YS changed length of the part_no column from 25 to 35  
 --  03/15/2017 Shivshankar P : Added columns  
 --- 02/14/2020 Vijay G: Changed length of the part_no column from 35 to 50
 DECLARE @ShortageView TABLE (due_date smalldatetime,wono char(10),custname char(50),  PrjWoNumber VARCHAR(100) ,part_no char(35),  
  Revision char(8),ShortQty numeric(12,2), Uniq_key char(10),dept_id char(4),qtyissue numeric (12,2),  
  OrgReserveQty numeric (12,2),PrjUnique char(10),ShortBalance numeric(12,2),KaSeqNum char(10),Approved bit,Bomparent char(10),  
  Dept_name char(25),PRJNUMBER char(10),LineShort VARCHAR(10));   
   
 INSERT INTO @ShortageView EXEC [ShortagesView] @lcUniq_key;  
 --- 10/08/14 YS use new tables in place of Invtmfhd  
 SELECT S.BOMPARENT,BOM_DET.UNIQ_KEY,M.PARTMFGR,M.MFGR_PT_NO    
  FROM @ShortageView S INNER JOIN BOM_DET ON BOM_DET.BOMPARENT=S.BOMPARENT AND BOM_DET.UNIQ_KEY=S.UNIQ_KEY   
  INNER JOIN InvtMPNLink L ON L.UNIQ_KEY=S.UNIQ_KEY   
  INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId   
  INNER JOIN INVENTOR T ON T.UNIQ_KEY= BOM_DET.BOMPARENT   
  WHERE   
  M.IS_DELETED=0 AND l.is_deleted=0  
  AND BOM_DET.UNIQ_KEY+T.BOMCUSTNO   
   NOT IN (SELECT INT_UNIQ+CUSTNO FROM INVENTOR)   
  AND BOM_DET.BOMPARENT+BOM_DET.UNIQ_KEY+M.PARTMFGR+M.MFGR_PT_NO   
   NOT IN (SELECT BOMPARENT+UNIQ_KEY+PARTMFGR+MFGR_PT_NO  FROM ANTIAVL )    
 UNION    
 SELECT S.BOMPARENT,BOM_DET.UNIQ_KEY,M.PARTMFGR,M.MFGR_PT_NO    
  FROM @SHORTAGEVIEW S INNER JOIN BOM_DET ON BOM_DET.BOMPARENT=S.BOMPARENT and BOM_DET.UNIQ_KEY=S.UNIQ_KEY   
  INNER JOIN INVENTOR C ON C.INT_UNIQ= BOM_DET.UNIQ_KEY    
  INNER JOIN InvtMPNLink L ON L.UNIQ_KEY=C.UNIQ_KEY   
  INNER JOIN MfgrMaster M ON M.MfgrMasterId=L.mfgrMasterId  
  INNER JOIN INVENTOR  P ON BOM_DET.BOMPARENT =P.UNIQ_KEY AND C.CUSTNO=P.BOMCUSTNO   
  WHERE   
  M.IS_DELETED=0 AND L.is_deleted=0   
  AND BOM_DET.BOMPARENT+C.UNIQ_KEY+M.PARTMFGR+M.MFGR_PT_NO   
  NOT IN (SELECT BOMPARENT+UNIQ_KEY+PARTMFGR+MFGR_PT_NO FROM ANTIAVL )    
 ORDER BY 1   
END