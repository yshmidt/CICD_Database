  -- =============================================  
-- Author:   Sachin B  
-- Create date:  11/09/2017  
-- Description:  Created for the FGI label Report  
-- Reports:   fgilabelreport.rmt  
-- Sachin B 09/21/2017 Remove parameter LotCode,LotRefDate and LotExpDate and add parameter InvtRecNo and join with PartType table  
-- Sachin B 09/25/2017 Add join with PartType,Invt_rec and iRecIpKey tables  
-- Sachin B 10/03/2017 Add i.useipkey,i.SERIALYES in select statement and trim partno  
-- Sachin B 10/23/2017 Get Transfer Qty Conditionaly for SID and Manual Part  
-- Sachin B 10/31/2017 Apply RTRIM and LTRIM to ipKeyUnique  
-- Sachin B 11/03/2017 Implement functionality for the rePrinting and remove parameters @SerialUniqList,@InvtRecNo,@isRePrinting because XFER_UNIQ primary key of transfer lable  
--                     linked with invt_rec table so we will get sid and serial info from iRecIpKey and iRecSerial tables so I removed If/Else block  
-- Sachin B 04/04/2018 Getting Transfer Quantity Conditionaly for manual,SID and Serialized Parts  
-- Sachin B 05/23/2019 - Get user name based on BY column of TRANSFER table  
-- Sachin B 09/24/2019 - Fix the Issue related to FGI Label is Not display convert Inner join to left join in PARTTYPE table
-- Sachin B 12/26/2019 - Add and Condition ISNULL(recip.ipkeyunique,'') = recSer.ipkeyunique for the FGI label are dublicated for the SID and Serial Parts 
-- Sachin B 10/28/2020 - Fix the Issue in the in the FGI Label wrong receive qty is displaying
-- rptFGIlabelReport '636ITY22EW'
-- =============================================  
CREATE PROCEDURE [dbo].[rptFGIlabelReport]   
  @XFER_UNIQ VARCHAR (35) = ''  
AS  
BEGIN  
  
-- SET NOCOUNT ON added to prevent extra result sets from  
SET NOCOUNT ON;  
    -- Sachin B 11/03/2017 Implement functionality for the rePrinting and remove parameters @SerialUniqList,@InvtRecNo,@isRePrinting because XFER_UNIQ primary key of transfer lable  
    --                     linked with invt_rec table so we will get sid and serial info from iRecIpKey and iRecSerial tables so I removed If/Else block  
 -- Sachin B 05/23/2019 - Get user name based on BY column of TRANSFER table  
  SELECT DISTINCT  w.WONO,CONCAT(RTRIM(LTRIM(i.part_no)),'/',i.REVISION) AS part_no,i.DESCRIPT,RTRIM(LTRIM(i.PART_CLASS)) AS PART_CLASS,RTRIM(LTRIM(i.PART_TYPE)) AS PART_TYPE  
 ,i.useipkey,i.SERIALYES, c.CUSTNAME,w.SONO,t.FR_DEPT_ID AS fromDept,RTRIM(LTRIM(t.TO_DEPT_ID)) AS toDept,t.QTY,u.UserName As [BY],t.DATE,rec.EXPDATE,rec.REFERENCE,    
 dbo.fRemoveLeadingZeros(recSer.SERIALNO) AS SERIALNO,  
 -- Sachin B 10/31/2017 Apply RTRIM and LTRIM to ipKeyUnique  
 rec.LOTCODE AS Lotcode, RTRIM(LTRIM(ISNULL(recip.ipkeyunique,''))) AS ipkeyunique,pt.LOTDETAIL,  
 -- Sachin B 04/04/2018 Getting Transfer Quantity Conditionaly for manual,SID and Serialized Parts  
 CASE WHEN i.SERIALYES=1 THEN 1  
    WHEN i.SERIALYES=0 and i.useipkey =1 THEN recip.qtyReceived  
    ELSE t.QTY  
    END AS qtyPerPackage  
 FROM TRANSFER t   
 JOIN WOENTRY w ON w.WONO = t.WONO AND t.XFER_UNIQ=@XFER_UNIQ  
 JOIN INVENTOR i ON w.UNIQ_KEY = i.UNIQ_KEY  
 -- Sachin B 09/24/2019 - Fix the Issue related to FGI Label is Not display convert Inner join to left join in PARTTYPE table
 LEFT JOIN PARTTYPE pt ON i.PART_CLASS = pt.PART_CLASS AND i.PART_TYPE = pt.PART_TYPE  
 JOIN INVT_REC rec ON t.XFER_UNIQ =rec.XFER_UNIQ  
 LEFT JOIN iRecIpKey recip ON rec.INVTREC_NO =recip.invtrec_no  
 -- Sachin B 12/26/2019 - Add and Condition ISNULL(recip.ipkeyunique,'') = recSer.ipkeyunique   for the FGI label are dublicated for the SID and Serial Parts
 LEFT JOIN iRecSerial recSer ON rec.INVTREC_NO =recSer.invtrec_no AND ISNULL(recip.ipkeyunique,'') = recSer.ipkeyunique  
 LEFT JOIN dbo.CUSTOMER c ON i.CUSTNO = c.CUSTNO   
 LEFT JOIN aspnet_Users u on t.[BY] =  u.UserId  
END  
  