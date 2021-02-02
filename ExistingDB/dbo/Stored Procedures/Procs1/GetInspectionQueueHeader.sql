-- =============================================  
-- Author: Shivshankar Patil   
-- Create date: <03/16/16>  
-- Description: <Get PO Inspection Detail(Update the Inspection Queue record status)>   
-- 06/12/2017   Shivshankar P :  Get receiver Header and SupIfo for redirecting to the PO receiving  
--[dbo].[GetInspectionQueueHeader] 'XC7X701WL5','0','0','0','000000000001678','8768768'  
-- Nilesh Sa 2/28/2018 Added '' if null PONUM for General receving  
-- Nilesh Sa 04/05/2018 Modified Condition  
-- Nilesh Sa 4/05/2018 Removed condition no needed AND LTRIM(RTRIM(rh.recPklNo)) NOT IN (''' +  LTRIM(RTRIM(@currentPLNo)) + '''  
-- Nitesh B 01/10/2019 Add new column 'rh.inspectionSource'
-- =============================================  
CREATE PROCEDURE [dbo].[GetInspectionQueueHeader]   
@receiverDetailId varchar(25),  
@isNextRow bit=0,  
@isNextPONum bit=0,  
@isFirstPONum bit=0,  
@currentPONo varchar(max)= null,  
@currentPLNo varchar(max)= null  
  
AS  
BEGIN  
DECLARE @SQLQuery NVARCHAR(2000);  
DECLARE @qryMain  NVARCHAR(2000);   
--creating sql query to fetch Save and next functionality of PoRecDetail table 
-- Nitesh B 01/10/2019 Add new column 'rh.inspectionSource' 
SET @SQLQuery = 'select  top 2 rh.receiverHdrId, rh.ponum,id.RejectedAt, rh.recPklNo ,si.SUPNAME ,ir.PART_NO ,ir.REVISION ,rd.mfgr_pt_no ,rd.Partmfgr ,mfr.marking,ir.MATLTYPE,ir.PUR_UOFM  
,rd.Qty_rec,fs.FRSTARTDISP,fs.FRSTUNIQUE, id.inspHeaderId,id.FailedQty,rd.receiverDetId,rh.dockDate,  
id.ReturnQty, rh.InspectionSource,
(select aspbyer.Initials from POMAIN pn left join aspnet_Profile aspbyer on  pn.aspnetBuyer = aspbyer.UserId where pn.ponum  = rh.ponum)As BUYER,  
ir.INSP_REQ,ir.CERT_REQ,pt.FIRSTARTICLE,pt.INSPECTIONOTE,rh.carrier,si.UNIQSUPNO,si.SUPNAME,rh.receiverno, rh.waybill,  
pt.INSPEXCEPT,pt.INSPEXCNOTE,  
id.FRSTARTCHK as inspFrstArtChk,id.INSPCHK as inspReqChk,id.CERTCHK as inspCertChk,id.FRSTARTDISP as inspFrstArtDisp,id.FRSTARTNOTE as inspFrstArtNote  
from receiverHeader rh  inner join receiverDetail rd On rh.receiverHdrId = rd.receiverHdrId  
LEFT JOIN inspectionHeader id on  rd.receiverDetId  = id.receiverDetId  
Left JOIN aspnet_Profile asp on rh.recvBy = asp.UserId   
Left JOIN POMAIN pn on rh.ponum = pn.PONUM  
Left JOIN SUPINFO si on pn.UNIQSUPNO = si.UNIQSUPNO  
LEFT JOIN MfgrMaster mfr on rd.mfgr_pt_no = mfr.mfgr_pt_no AND rd.Partmfgr=mfr.PartMfgr  
LEFT JOIN POITEMS pt on rd.uniqlnno = pt.UNIQLNNO  
LEFT JOIN FSTARTDISP fs on id.inspHeaderId =  fs.FRSTUNIQUE  
INNER JOIN INVENTOR ir on rd.Uniq_key = ir.UNIQ_KEY WHERE rd.isinspReq = 1 AND rd.isinspCompleted = 0 '  
--Get Selected row Details  
--For the first time fetch the selected row  
IF (@isNextRow = 0)  
BEGIN  
SET @SQLQuery = @SQLQuery + ' AND LTRIM(RTRIM(rd.receiverDetId)) = ''' +  LTRIM(RTRIM(@receiverDetailId)) + '''  order by rh.ponum , rh.dockDate';  
END  
--Get Selected row Details with different part number of Same PO Number  
--Fetch the next row in queue  
ELSE IF(@currentPONo IS NOT NUll AND @currentPLNo IS NOT NULL AND @isNextPONum =0)  
BEGIN  
SET @SQLQuery = @SQLQuery + ' AND LTRIM(RTRIM(ISNULL(pn.PONUM,''''))) = LTRIM(RTRIM(rh.ponum)) and LTRIM(RTRIM(rh.ponum)) = ''' +  LTRIM(RTRIM(@currentPONo)) + ''' order by rh.ponum , rh.dockDate'; -- Nilesh Sa 4/05/2018 Removed codition no needed AND LTRIM(RTRIM(rh.recPklNo)) NOT IN (''' +  LTRIM(RTRIM(@currentPLNo)) + '''  
END -- Nilesh Sa 2/28/2018 Added '' if null PONUM for General receving  
-- Nilesh Sa 04/05/2018 Modified Condition  
--Get Selected row Details with next PO Number  
ELSE IF(@isNextPONum =1 AND @isNextRow = 1)  
BEGIN  
SET @SQLQuery = @SQLQuery + ' AND LTRIM(RTRIM(ISNULL(pn.PONUM,''''))) = LTRIM(RTRIM(rh.ponum)) and LTRIM(RTRIM(rh.ponum)) > ''' +  LTRIM(RTRIM(@currentPONo)) + ''' order by rh.ponum ,rh.dockDate';  
END -- Nilesh Sa 2/28/2018 Added '' if null PONUM for General receving  
  
  EXEC sp_executesql @SQLQuery     
END  
  