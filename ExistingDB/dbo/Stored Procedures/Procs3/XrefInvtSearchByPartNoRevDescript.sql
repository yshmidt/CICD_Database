  
-- =============================================  
-- Author:  <Yelena Shmidt>  
-- Create date: <05/12/10>  
-- Description: <This Proceudre is used by the frmpartxreffind>  
-- Modified: 10/10/14 YS removed invtmfhd and replaced with 2 new tables  
-- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int  
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)  
-- 03/11/20 Shivshankar P : Added IsChecked column to bind checkbox in grid on UI 
-- 05/20/20 Shivshankar P : Apply ORDER BY Part_no for Internal Part Number result set
-- =============================================  
CREATE PROCEDURE [dbo].[XrefInvtSearchByPartNoRevDescript]  
 -- Add the parameters for the stored procedure here  
 -- 09/26/19 YS modified part number/customer part number char(25) to char(35)  
 @lcPart_no char(35)=' ', @lcRevision char(8)=' ', @lcDescript char(45)=' '  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
 DECLARE @lcmd varchar(500)  
 -- 09/26/19 YS modified part number/customer part number char(25) to char(35) 
 -- 03/11/20 Shivshankar P : Added IsChecked column to bind checkbox in grid on UI  
 DECLARE @ZIntPart TABLE (IsChecked bit, Part_no Char(35),Revision char(8),Descript char(45),Part_class char(8),Part_type char(8),  
     Uniq_key char(10),part_sourc char(10),Status  char(8))   
 -- 09/26/19 YS modified part number/customer part number char(25) to char(35)  
 DECLARE @ZConsgnPart TABLE (IsChecked bit, CustPartno Char(35),CustRev char(8),Descript char(45),CustName Char(35),Custno char(10),  
     Uniq_key char(10),Int_uniq char(10),Status  char(8))   
 -- 06/22/12 YS added orderpref      
 DECLARE @ZIntMfgrPart TABLE (PartMfgr char(8),Mfgr_pt_no char(30),UniqMfgrHd Char(10),Uniq_key Char(10),OrderPref int,Qty_oh Numeric(12,2))  
  
 DECLARE @ZCustMfgrPart TABLE (PartMfgr char(8),Mfgr_pt_no char(30),UniqMfgrHd Char(10),Uniq_key Char(10),OrderPref int,Qty_oh Numeric(12,2))  
   
  
 -- get internal parts for selected criteria  
 -- 03/11/20 Shivshankar P : Added IsChecked column to bind checkbox in grid on UI  
 SET @lcmd = 'SELECT 0 AS IsChecked, Part_no,Revision,Descript,Part_class,Part_type,Uniq_key,part_sourc,Status FROM Inventor WHERE '+  
    'Part_sourc<>''CONSG'' AND '+  
 CASE WHEN @lcPart_no <>' ' and  @lcRevision <>' ' THEN 'CHARINDEX('''+RTRIM(@lcPart_no)+''',Part_no)>0 and   
   CHARINDEX(UPPER('''+RTRIM(@lcRevision)+'''),UPPER(Revision))>0'  
    WHEN @lcPart_no <>' ' and  @lcRevision =' ' THEN 'CHARINDEX('''+RTRIM(@lcPart_no)+''',Part_no)>0'  
    WHEN @lcDescript <>' ' THEN  'CHARINDEX(UPPER('''+RTRIM(@lcDescript)+'''),UPPER(Descript))>0' END  
    
   
 INSERT INTO @ZIntPart EXEC (@lcmd)  
 -- SqlResult  
 -- 05/20/20 Shivshankar P : Apply ORDER BY Part_no for Internal Part Number result set
 SELECT * FROM @ZIntPart ORDER BY Part_no 
  
 -- get Consign parts  
 -- 03/11/20 Shivshankar P : Added IsChecked column to bind checkbox in grid on UI 
 INSERT INTO @ZConsgnPart SELECT 0 AS IsChecked, Inventor.CustPartno,Inventor.CustRev,Inventor.Descript,CustName,Inventor.CustNo,Inventor.Uniq_key,Inventor.Int_uniq,Inventor.Status   
   FROM Inventor,Customer WHERE Inventor.Int_uniq IN (SELECT Uniq_key FROM @ZIntPart)  
   AND Inventor.Custno=Customer.Custno   
   AND Inventor.Part_sourc='CONSG'  
   
 --- SqlResult1  
 SELECT * FROM @ZConsgnPart  
   
 -- Get Internal PartMfgr information  
 -- 10/10/14 YS removed invtmfhd and replaced with 2 new tables  
 --INSERT INTO @ZIntMfgrPart   
 --  SELECT PartMfgr ,Mfgr_pt_no ,Invtmfhd.UniqMfgrHd ,Invtmfhd.Uniq_key ,OrderPref,  
 --    CAST(ISNULL(SUM(Invtmfgr.Qty_oh),0.00) as Numeric(12,2)) AS Qty_oh  
 --    FROM Invtmfhd LEFT OUTER JOIN Invtmfgr ON Invtmfhd.UniqMfgrhd=Invtmfgr.UniqMfgrHd   
 --  WHERE Invtmfhd.Uniq_key  IN (SELECT UNIQ_KEY FROM @zIntPart)  
 --  AND Invtmfhd.is_deleted=0   
 --  GROUP BY PartMfgr ,Mfgr_pt_no ,Invtmfhd.UniqMfgrHd ,Invtmfhd.Uniq_key,ORDERPREF   
 -- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int  
 INSERT INTO @ZIntMfgrPart   
   SELECT PartMfgr ,Mfgr_pt_no ,l.UniqMfgrHd ,l.Uniq_key ,OrderPref,  
     CAST(ISNULL(SUM(Invtmfgr.Qty_oh),0.00) as Numeric(12,2)) AS Qty_oh  
     FROM InvtMpnLink L INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId   
     LEFT OUTER JOIN Invtmfgr ON L.UniqMfgrhd=Invtmfgr.UniqMfgrHd   
   WHERE EXISTS (SELECT 1 FROM @zIntPart z where z.Uniq_key=l.uniq_key)  
   AND l.is_deleted=0 and m.IS_DELETED=0  
   GROUP BY PartMfgr ,Mfgr_pt_no ,l.UniqMfgrHd ,l.Uniq_key,ORDERPREF   
  
 --- SqlResult2  
 SELECT * FROM @ZIntMfgrPart  
  
 -- Get Consign PartMfgr information  
 -- 10/10/14 YS removed invtmfhd and replaced with 2 new tables  
 --INSERT INTO @ZCustMfgrPart   
 --  SELECT PartMfgr ,Mfgr_pt_no ,Invtmfhd.UniqMfgrHd ,Invtmfhd.Uniq_key ,OrderPref,  
 --    CAST(ISNULL(SUM(Invtmfgr.Qty_oh),0.00) as Numeric(12,2)) AS Qty_oh  
 --    FROM Invtmfhd LEFT OUTER JOIN Invtmfgr ON Invtmfhd.UniqMfgrhd=Invtmfgr.UniqMfgrHd   
 --  WHERE Invtmfhd.Uniq_key  IN (SELECT UNIQ_KEY FROM @ZConsgnPart)  
 --  AND Invtmfhd.is_deleted=0   
 --  GROUP BY PartMfgr ,Mfgr_pt_no ,Invtmfhd.UniqMfgrHd ,Invtmfhd.Uniq_key,ORDERPREF   
  
 INSERT INTO @ZCustMfgrPart   
   SELECT PartMfgr ,Mfgr_pt_no ,l.UniqMfgrHd ,l.Uniq_key ,OrderPref,  
     CAST(ISNULL(SUM(Invtmfgr.Qty_oh),0.00) as Numeric(12,2)) AS Qty_oh  
     FROM InvtmpnLink L INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId   
     LEFT OUTER JOIN Invtmfgr ON L.UniqMfgrhd=Invtmfgr.UniqMfgrHd   
   WHERE EXISTS (SELECT 1 FROM @ZConsgnPart z where z.Uniq_key=L.uniq_key)  
   AND l.is_deleted=0 and m.IS_DELETED=0  
   GROUP BY PartMfgr ,Mfgr_pt_no ,l.UniqMfgrHd ,l.Uniq_key,ORDERPREF   
  
 --- SqlResult3  
 SELECT * FROM @ZCustMfgrPart  
 -- Get Supplier part numbers - SQLResult4  
 -- 06/22/12 YS check for is_deleted  
 SELECT suplpartno,SupName,Invtmfsp.UniqSupNo,Invtmfsp.UniqMfgrHd   
  FROM Invtmfsp,Supinfo   
 WHERE Supinfo.UniqSupNO=Invtmfsp.UniqSupno   
 AND Invtmfsp.IS_DELETED =0  
 AND Invtmfsp.UniqMfgrHD IN (SELECT UniqMfgrHD FROM @ZIntMfgrPart)  
  
END