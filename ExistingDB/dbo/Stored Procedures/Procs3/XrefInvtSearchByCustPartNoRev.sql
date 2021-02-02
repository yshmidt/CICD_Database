  
-- =============================================  
-- Author:  <Yelena Shmidt>  
-- Create date: <05/13/10>  
-- Description: <This Proceudre is used by the frmpartxreffind>  
-- Modified : 10/10/14 YS removed invtmfhd and replaced with 2 new tables  
-- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int  
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- 03/11/20 Shivshankar P : Added IsChecked column to bind checkbox in grid on UI   
-- 05/20/20 Shivshankar P : Apply ORDER BY Part_no for Internal Part Number result set
-- =============================================  
CREATE PROCEDURE [dbo].[XrefInvtSearchByCustPartNoRev]  
 -- Add the parameters for the stored procedure here  
 -- 09/26/19 YS modified part number/customer part number char(25) to char(35)  
 @lcCustPartNo char(35)=' ', @lcCustRev char(8)=' '  
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
 -- 06/22/12 YS added OrderPref  
 -- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int  
 DECLARE @ZIntMfgrPart TABLE (PartMfgr char(8),Mfgr_pt_no char(30),UniqMfgrHd Char(10),Uniq_key Char(10),OrderPref int,Qty_oh Numeric(12,2))  
  
 DECLARE @ZCustMfgrPart TABLE (PartMfgr char(8),Mfgr_pt_no char(30),UniqMfgrHd Char(10),Uniq_key Char(10),OrderPref int,Qty_oh Numeric(12,2))  
 
 -- 03/11/20 Shivshankar P : Added IsChecked column to bind checkbox in grid on UI  
 SET @lcmd = 'SELECT 0 AS IsChecked,CustPartno,CustRev,Descript,CustName,Inventor.CustNo,Uniq_key,Int_uniq,Inventor.Status  FROM Inventor,Customer WHERE '+  
    'Part_sourc=''CONSG'' AND Inventor.Custno=Customer.Custno AND '+  
    CASE WHEN @lcCustPartNo <>' ' and  @lcCustRev <>' ' THEN 'CHARINDEX('''+RTRIM(@lcCustPartNo)+''',CustPartNo)>0 and   
     CHARINDEX(UPPER('''+RTRIM(@lcCustRev)+'''),UPPER(CustRev))>0'  
     WHEN @lcCustPartNo <>' ' and  @lcCustRev =' ' THEN 'CHARINDEX('''+RTRIM(@lcCustPartNo)+''',CustPartNo)>0'  
     ELSE 'CustPartNo='' ''' END   
  
 INSERT INTO @ZConsgnPart EXEC (@lcmd)  
 
 -- 03/11/20 Shivshankar P : Added IsChecked column to bind checkbox in grid on UI  
 INSERT INTO @ZIntPart SELECT DISTINCT 0 AS IsChecked,Inventor.Part_no,Inventor.Revision,Inventor.Descript,Inventor.Part_class,  
    Inventor.Part_type,Inventor.Uniq_key,Inventor.part_sourc,Inventor.Status   
    FROM Inventor WHERE   
    Inventor.Part_sourc<>'CONSG' AND Inventor.Uniq_key IN (SELECT Int_Uniq FROM @ZConsgnPart)  
  
 -- get Internal part SqlResult  
 -- 05/20/20 Shivshankar P : Apply ORDER BY Part_no for Internal Part Number result set
 SELECT * FROM @ZIntPart ORDER BY Part_no
   
  
 --get all the parts with matching MPN to the parameters for internal parts  
 --06/22/12 YS added OrderPref  
 --10/10/14 YS removed invtmfhd and replaced with 2 new tables  
 --INSERT INTO @ZIntMfgrPart SELECT PartMfgr ,Mfgr_pt_no ,Invtmfhd.UniqMfgrHd,Invtmfhd.Uniq_key,OrderPref,  
 --   CAST(ISNULL(SUM(Invtmfgr.Qty_oh),0.00) as Numeric(12,2)) AS Qty_oh   
 --  FROM Invtmfhd LEFT OUTER JOIN Invtmfgr ON Invtmfhd.UniqMfgrhd=Invtmfgr.UniqMfgrHd   
 --  WHERE Invtmfhd.Is_deleted = 0 and Invtmfhd.Uniq_key IN (SELECT Uniq_key  FROM @ZIntPart)  
 --  GROUP BY PartMfgr ,Mfgr_pt_no ,Invtmfhd.UniqMfgrHd ,Invtmfhd.Uniq_key,OrderPref  
 -- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int  
 INSERT INTO @ZIntMfgrPart SELECT m.PartMfgr ,m.Mfgr_pt_no ,l.UniqMfgrHd,l.Uniq_key,l.OrderPref,  
    CAST(ISNULL(SUM(Invtmfgr.Qty_oh),0.00) as Numeric(12,2)) AS Qty_oh   
   FROM InvtMPNLink L INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId   
   LEFT OUTER JOIN Invtmfgr ON l.UniqMfgrhd=Invtmfgr.UniqMfgrHd   
   WHERE l.Is_deleted = 0 and M.IS_DELETED=0   
   and EXISTS (SELECT 1  FROM @ZIntPart z WHERE z.Uniq_key=L.uniq_key)  
   GROUP BY PartMfgr ,Mfgr_pt_no ,l.UniqMfgrHd ,l.Uniq_key,l.OrderPref  
  
 --- SqlResult1  
 SELECT * FROM @ZConsgnPart  
   
 --- SqlResult2  
 SELECT * FROM @ZIntMfgrPart  
  
 -- Get Consign PartMfgr information  
 --06/22/12 YS added OrderPref  
 --10/10/14 YS removed invtmfhd and replaced with 2 new tables  
 --INSERT INTO @ZCustMfgrPart   
 --  SELECT PartMfgr ,Mfgr_pt_no ,Invtmfhd.UniqMfgrHd ,Invtmfhd.Uniq_key ,OrderPref,  
 --    CAST(ISNULL(SUM(Invtmfgr.Qty_oh),0.00) as Numeric(12,2)) AS Qty_oh  
 --    FROM Invtmfhd LEFT OUTER JOIN Invtmfgr ON Invtmfhd.UniqMfgrhd=Invtmfgr.UniqMfgrHd   
 --  WHERE Invtmfhd.Uniq_key  IN (SELECT UNIQ_KEY FROM @ZConsgnPart)  
 --  AND Invtmfhd.is_deleted=0   
 --  GROUP BY PartMfgr ,Mfgr_pt_no ,Invtmfhd.UniqMfgrHd ,Invtmfhd.Uniq_key,OrderPref  
 -- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int  
 INSERT INTO @ZCustMfgrPart   
   SELECT m.PartMfgr ,m.Mfgr_pt_no ,l.UniqMfgrHd ,l.Uniq_key ,l.OrderPref,  
     CAST(ISNULL(SUM(Invtmfgr.Qty_oh),0.00) as Numeric(12,2)) AS Qty_oh  
     FROM InvtMPNLink l INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId   
     LEFT OUTER JOIN Invtmfgr ON L.UniqMfgrhd=Invtmfgr.UniqMfgrHd   
   WHERE EXISTS (SELECT 1 FROM @ZConsgnPart Z WHERE Z.Uniq_key=L.uniq_key)  
   AND L.is_deleted=0 and m.IS_DELETED=0  
   GROUP BY PartMfgr ,Mfgr_pt_no ,l.UniqMfgrHd ,l.Uniq_key,OrderPref  
   
 --- SqlResult3  
 SELECT * FROM @ZCustMfgrPart  
 -- Get Supplier part numbers - SQLResult4  
 --06/22/12 YS Make sure supplier part number is not removed  
 SELECT suplpartno,SupName,Invtmfsp.UniqSupNo,Invtmfsp.UniqMfgrHd   
  FROM Invtmfsp,Supinfo   
 WHERE Supinfo.UniqSupNO=Invtmfsp.UniqSupno   
 AND Invtmfsp.IS_DELETED =0  
 AND Invtmfsp.UniqMfgrHD IN (SELECT UniqMfgrHD FROM @ZIntMfgrPart)  
  
END