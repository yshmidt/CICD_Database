  
-- =============================================  
-- Author:  <Debbie>  
-- Create date: <11/28/2011>  
-- Description: <Compiles information for the the Material Receipt Labels>  
-- Used On:     <Crystal Report {poreclbl.rpt} and {poreclbz.rpt}   
-- Modified: 04/17/2015 DRP: upon review of the label reports I find that in the past we did not have a record per ReceiverNo. Went through the below and removed the Receipt information from the results.   
-- added CAST (1 as numeric (3,0))as LabelQty to the results   
-- 12/10/15 DRP:  due to updates made to the Label Grid to work with part ranges on other procedures we had to make sure and add @userId to this procedure and any other label report      
-- 05/16/16 DRP:  needed to pull the partmfgr info from the PORECDTL table instead of the POITEMS table   
-- 08/24/16 DRP:  Added the ABC code for request of customer on the new 4x1 labels,  Added the Location field as requested.  Added Receiver Initials  
-- 08/29/16 DRP:  New request to add the Lot Code information to the results  
-- 09/08/16 DRP:  Needed to fix how I joined the Lot code tables  . . . the way that I did it on 8/29 returned too many records because it was not linked properly   
-- 05/01/17 DRP:  added the @lcLabelQty parameter per request of the users.  This way they can enter in a Label Qty to be populated into the grid, but should also then be able to change within the grid if needed.   
-- 07/09/2019 Rajendra K : 'INVTMFHD' table replaced by 'InvtMPNLink' and 'MfgrMaster' Get Initial from aspnet_Profile  
-- =============================================  
CREATE PROCEDURE [dbo].[rptMatlRecptLabel]  
 --declare  
  @lcPoNum as varchar (15) = ''  
  ,@lcLabelQty as int = null  --05/01/17 DRP:  added  
  ,@userid uniqueidentifier = null    
   
  
AS  
begin   
  
select t1.PONUM,t1.CONUM,SUPNAME,t1.UNIQSUPNO,t1.ITEMNO,t1.poittype,t1.UNIQLNNO,t1.Part_no,t1.Rev,t1.Descript  
  ,t1.part_class,t1.part_type,t1.MATLTYPE,t1.UNIQMFGRHD,t1.PARTMFGR,t1.MFGR_PT_NO,t1.reqtype,t1.Req_Alloc  
  --,CAST (1 as numeric (3,0))as LabelQty --05/01/17 DRP:  replaced with below.   
  ,case when @lcLabelQty is null then 1 else @lcLabelQty end as LabelQty  
  --,t1.PORECPKNO,t1.RECVDATE,t1.RECEIVERNO --04/17-2015 DRP:  removed  
  ,t1.abc,t1.LOCATION,t1.Initials ----07/09/2019 Rajendra K: Get Initial from aspnet_Profile ,08/24/16 DRP:  Added   
  ,t1.lotcode --08/29/16 DRP:  Added  
  
from(  
SELECT POMAIN.PONUM,CONUM,SUPNAME,POMAIN.UNIQSUPNO,POITEMS.ITEMNO,poitems.POITTYPE,POITEMS.UNIQLNNO  
    
  ,case when poitems.POITTYPE = 'MRO' or poitems.POITTYPE ='Services' then poitems.PART_NO else Inventor.PART_NO end as Part_no  
  ,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.REVISION else inventor.REVISION end as Rev  
  ,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.DESCRIPT else inventor.DESCRIPT end as Descript  
  ,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.PART_CLASS else inventor.PART_CLASS end as Part_Class  
  ,case when POITEMS.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then POITEMs.PART_TYPE else inventor.PART_TYPE end as part_type  
  ,MfgrMaster.MatlType  
  ,porecdtl.uniqmfgrhd,porecdtl.partmfgr,porecdtl.mfgr_pt_no  
  --,POitems.UNIQMFGRHD,POITEMS.PARTMFGR,poitems.MFGR_PT_NO --05/16/16 DRP:  replaced with the above, pulling form porecdtl tables instead of poitem  
  ,CASE WHEN POITTYPE <> 'Invt Part' and REQUESTTP <> 'MRO' then REQUESTTP else   
    case when POITTYPE = 'Invt Part' then requesttp  end end as ReqType    
  ,CASE WHEN POITTYPE <> 'Invt Part' and REQUESTTP <> 'MRO' then WOPRJNUMBER else   
    case when POITTYPE = 'Invt Part' then WOPRJNUMBER end end as Req_Alloc    
  --,PORECDTL.PORECPKNO,RECVDATE,PORECDTL.RECEIVERNO --04/17/2015 DRP:  removed  
  ,inventor.ABC,POITSCHD.LOCATION,aspnet_Profile.Initials  -- 07/09/2019 Rajendra K: Get Initial from aspnet_Profile, --08/24/16 DRP:  Added  
  ,isnull(poreclot.lotcode,'') as Lotcode --08/19/16 DRP:  Added  
FROM POMAIN  
  INNER JOIN SUPINFO ON POMAIN.UNIQSUPNO = SUPINFO.UNIQSUPNO  
  INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM  
  LEFT OUTER JOIN INVENTOR ON POITEMS.UNIQ_KEY = INVENTOR.UNIQ_KEY  
  left outer join POITSCHD on POitems.UNIQLNNO = POITSCHD.UNIQLNNO   
  --LEFT OUTER JOIN POITSCHD ON PORECLOC.UNIQDETNO = POITSCHD.UNIQDETNO --04/17/2015 DRP:  Removed and replaced by the line above.   
  --left outer join INVTMFHD on poitems.UNIQMFGRHD = invtmfhd.UNIQMFGRHD  --07/09/2019 Rajendra K : 'INVTMFHD' table replaced by 'InvtMPNLink' and 'MfgrMaster'  
  LEFT OUTER JOIN InvtMPNLink ON poitems.UNIQMFGRHD = InvtMPNLink.UNIQMFGRHD  
  LEFT OUTER JOIN MfgrMaster ON   InvtMPNLink.MfgrMasterId = MfgrMaster.MfgrMasterId  
  --left outer join WAREHOUS on PORECLOC.UNIQWH = warehous.UNIQWH  
  --left outer join PORECLOT on porecloc.LOC_UNIQ = poreclot.LOC_UNIQ  
  --left outer join PORECSER on PORECLOT.LOt_UNIQ = porecser.LOT_UNIQ  
  inner join PORECDTL on poitems.UNIQLNNO = PORECDTL.UNIQLNNO --04/17/2015 DRP: Removed --05/16/16 DRP:  added this table back into the script  
  --LEFT OUTER JOIN PORECLOC ON PORECDTL.UNIQRECDTL = PORECLOC.FK_UNIQRECDTL --04/17/2015 DRP:  Removed  
  --left outer join poreclot on porecdtl.receiverno = poreclot.RECEIVERNO --08/29/16 DRP:  added --09/09/16 DRP:  Removed and replaced by the below two lines.   
  inner join porecloc on porecdtl.UNIQRECDTL = PORECLOC.FK_UNIQRECDTL  
  Left outer join  aspnet_Profile on   aspnet_Profile.UserId = PORECDTL.Edituserid  
  left outer join poreclot on porecloc.loc_uniq = poreclot.loc_uniq  
    
    
WHERE POMAIN.PONUM = dbo.padl(@lcPoNum,15,'0')  
  
) t1  
  
end   