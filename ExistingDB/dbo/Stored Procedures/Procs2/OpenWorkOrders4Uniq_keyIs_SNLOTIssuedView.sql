-- =============================================      
-- Author:  Vicky Lu      
-- Create date: 2013/07/18      
-- Description: Get open work list and field to show if the WO has serialized or lot code component already issued to the work order, used in ECO      
-- Modified:       
-- 06/04/14 VL Added DISTINCT in last SQL otherwise might have same work order appear several times      
-- 03/09/15 VL Changed to LEFT OUTER JOIN for parttype, otherwise empty inventor.part_type won't be selected      
-- 09/20/17 YS added jobtype to a woentry table to separate status (openClos) from the Jobtype      
-- 08/24/18 Vijay G Add Parameter @gUniqEcNo And Add Left join With ECWO Table    
-- 02/24/2020 Vijay G: Added two different block of code one is for before completing ECO and another for display data after completed ECO  
-- =============================================      
CREATE PROCEDURE [dbo].[OpenWorkOrders4Uniq_keyIs_SNLOTIssuedView]     
@gUniq_key AS char(10) ='' , @gUniqEcNo AS char(10) = ' '          
AS      
BEGIN       
     
DECLARE @status VARCHAR(200)    
SELECT @status=ECSTATUS FROM ECMAIN WHERE UNIQECNO=@gUniqEcNo    
-- 02/24/2019 Vijay G: Added two different block of code one is for before completing ECO and another for display data after completed ECO    
IF(@status<>'Completed')    
BEGIN    
;WITH ZAllOpenWo       
AS      
(      
-- 09/20/17 YS added jobtype to a woentry table to separate status (openClos) from the Jobtype      
 SELECT Wono, BldQty, Complete, Balance, Sono, Due_date, ReleDate, OpenClos, Custname,JobType      
  FROM Customer, Woentry      
  WHERE Woentry.Custno = Customer.Custno      
  AND ((OpenClos<>'Closed'       
  AND OpenClos<>'Cancel'      
  AND OpenClos<>'ARCHIVED'      
  AND BALANCE > 0  ))    
  AND Woentry.Uniq_key =  @gUniq_key       
)      
,      
ZKitSNLot      
AS      
(      
-- 03/09/15 VL Changed to LEFT OUTER JOIN for parttype, otherwise empty inventor.part_type won't be selected      
 --SELECT Wono      
 -- FROM Kamain, INVENTOR, Parttype       
 -- WHERE Kamain.WONO IN       
 --  (SELECT Wono       
 --   FROM ZAllOpenWo)      
 -- AND Kamain.Uniq_key = Inventor.UNIQ_KEY      
 -- AND Inventor.PART_CLASS = Parttype.PART_CLASS      
 -- AND Inventor.PART_TYPE = Parttype.PART_TYPE      
 -- AND ACT_QTY <> 0      
 -- AND (Inventor.SERIALYES = 1      
 -- OR Parttype.LOTDETAIL = 1)      
 SELECT Wono      
  FROM Kamain, INVENTOR LEFT OUTER JOIN Parttype       
  ON Inventor.PART_CLASS = Parttype.PART_CLASS      
  AND Inventor.PART_TYPE = Parttype.PART_TYPE      
  WHERE Kamain.WONO IN       
   (SELECT Wono       
    FROM ZAllOpenWo)      
  AND Kamain.Uniq_key = Inventor.UNIQ_KEY      
  AND ACT_QTY <> 0      
  AND (Inventor.SERIALYES = 1      
  OR Parttype.LOTDETAIL = 1)      
      
)      
SELECT DISTINCT ECWO.UniqECWONo,ECWO.UniqECNo,ZAllOpenWo.WONo,ZAllOpenWo.BALANCE,ZAllOpenWo.DUE_DATE as DueDate,ZAllOpenWo.OPENCLOS AS JobType,ECWO.NewWono, CAST(CASE WHEN ECWO.CHANGE IS NULL THEN 0 ELSE 1 END AS BIT) AS Change,      
    CAST(CASE WHEN ECWO.IS_SnLotIssued IS NULL THEN 0 ELSE 1 END AS Bit) AS IsSNLotIssued      
 FROM ZAllOpenWo      
  LEFT OUTER JOIN ZKitSNLot ON ZAllOpenWo.Wono = ZKitSNLot.WONO      
  LEFT OUTER JOIN ECWO on ECWO.UNIQECNO = @gUniqEcNo and ECWO.WONO = ZAllOpenWo.Wono      
      
-- 07/19/13 VL comment out the code that check if has SN or lot from invt_isu table because user might un-issue back, but invt_isu still has records      
--SELECT DISTINCT Woentry.Wono, BldQty, Complete, Balance, Sono, Due_date, ReleDate, OpenClos, CustName, CAST(CASE WHEN Invt_isu.INVTISU_NO IS NULL THEN 0 ELSE 1 END AS Bit) AS IS_SnLotIssued      
--  FROM Customer, Woentry LEFT OUTER JOIN INVT_ISU       
--  ON Woentry.Wono = Invt_isu.Wono      
--  AND (Invt_isu.SerialUniq <> ''      
--  OR Invt_isu.LotCode <> '')      
--  WHERE Woentry.Custno = Customer.Custno      
--  AND (OpenClos<>'Closed'       
--  AND OpenClos<>'Cancel'      
--  AND OpenClos<>'ARCHIVED')      
--  AND BALANCE > 0      
--  AND Woentry.Uniq_key =  @gUniq_key       
--  ORDER BY Woentry.Wono      
END    
IF(@status='Completed')    
BEGIN    
;WITH ZAllOpenWo       
AS      
(      
 SELECT Wono, BldQty, Complete, Balance, Sono, Due_date, ReleDate, OpenClos, Custname,JobType      
  FROM Customer, Woentry      
  WHERE Woentry.Custno = Customer.Custno      
  AND ((OpenClos<>'Closed'       
  AND OpenClos<>'Cancel'      
  AND OpenClos<>'ARCHIVED'      
  AND BALANCE > 0  ))    
  AND Woentry.Uniq_key =  @gUniq_key          
  UNION     
  SELECT WOENTRY.Wono,BLDQTY,Complete, WOENTRY.Balance,Sono,Due_date,ReleDate,OpenClos,'',JobType FROM ECWO    
  JOIN WOENTRY on ECWO.WONO = WOENTRY.WONO     
   WHERE UNIQECNO =@gUniqEcNo    
)      
,      
ZKitSNLot      
AS      
(       
 SELECT Wono      
  FROM Kamain, INVENTOR LEFT OUTER JOIN Parttype       
  ON Inventor.PART_CLASS = Parttype.PART_CLASS      
  AND Inventor.PART_TYPE = Parttype.PART_TYPE      
  WHERE Kamain.WONO IN       
   (SELECT Wono       
    FROM ZAllOpenWo)      
  AND Kamain.Uniq_key = Inventor.UNIQ_KEY      
  AND ACT_QTY <> 0      
  AND (Inventor.SERIALYES = 1      
  OR Parttype.LOTDETAIL = 1)      
      
)      
SELECT DISTINCT ECWO.UniqECWONo,ECWO.UniqECNo,ZAllOpenWo.WONo,ZAllOpenWo.BALANCE,ZAllOpenWo.DUE_DATE as DueDate,ZAllOpenWo.OPENCLOS AS JobType,ECWO.NewWono, CAST(CASE WHEN ECWO.CHANGE IS NULL THEN 0 ELSE 1 END AS BIT) AS Change,      
    CAST(CASE WHEN ECWO.IS_SnLotIssued IS NULL THEN 0 ELSE 1 END AS Bit) AS IsSNLotIssued      
 FROM ZAllOpenWo      
  LEFT OUTER JOIN ZKitSNLot ON ZAllOpenWo.Wono = ZKitSNLot.WONO      
  LEFT OUTER JOIN ECWO on ECWO.UNIQECNO = @gUniqEcNo and ECWO.WONO = ZAllOpenWo.Wono      
END    
END