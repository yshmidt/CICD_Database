  
-- =============================================  
-- Author:  <Debbie>  
-- Create date: <12/07/2011>  
-- Description: <Compiles the data for DMR Packing List>  
-- Used On:     <Crystal Report {dmrplist.rpt}  
-- Modified: 08/26/13 YS   changed attention to varchar(200), increased length of the ccontact fields.   
--    01/15/2014 DRP:  Addwed the @userid parameter for WebManex  
--    07/29/2014 DRP:  found that the Remit To link that I had originally used was not working properly in the situations where the users had mor than one Remit To Address to choose from.  It would then duplicate the results on the report.   
--         change it to get the Remit To from the POmain table.  
--              07/23/2016 Khandu: Changed table "PORecMRB,PORECDTL,POITEMS" and used new tables "DMrheader,inspectionHeader,receiverDetailreceiverHeader"   
--                 need to changed DMR detail on report as per new functionality as well as new tables   
--    08/08/16 DRP:  replaced the ShipTo and BillTo address field into the combined ShipToAddress and RemitToAddress   
--    05/11/2017 Satish B: Remove Leading Zeros From DMR Number And PO Number  
--    05/11/2017 Satish B: Added defect note from inspectionDetail table(Append with Text value from Support table)  
-- 10/01/20 VL added to update PRINTDMR once it's printed  
-- 10/30/2020 Rajendra k : Added DMEMONOin selection list
-- EXEC rptDmrPList '0000000119'
-- =============================================  
CREATE PROCEDURE [dbo].[rptDmrPList]    
 @lcDMR AS VARCHAR (10) = ''  
   ,@userId UNIQUEIDENTIFIER= null   
AS  
BEGIN  
/*BEGIN SELECTION SECTION*/  
---08/26/13 YS   changed attn to varchar(200), increased length of the ccontact fields.  
SELECT  --05/11/2017 Satish B: Remove Leading Zeros From DMR Number And PO Number  
   SUBSTRING(DMrheader.dmr_no , PATINDEX('%[^0]%',DMrheader.dmr_no ), 10) AS dmr_no  
  ,SUBSTRING(DMrheader.PONUM, PATINDEX('%[^0]%',DMrheader.PONUM ), 10) AS PONUM  
        ,supname,DMrheader.dmr_Date,DMrheader.RMA_NO,DMrheader.confirmBy,DMrheader.FOB,DMrheader.SHIPVIA,DMrheader.WAYBILL  
  ,inventor.PART_NO,inventor.REVISION,inventor.DESCRIPT,recDetail.Partmfgr,recDetail.mfgr_pt_no,inventor.PUR_UOFM,recHeader.recPklNo  
  ,dmrDtl.RET_QTY  
    
  --05/11/2017 Satish B: Added defect note from inspectionDetail table(Append with Text value from Support table)  
  ,STUFF((SELECT ', ' + CAST(RTRIM(Text)+'('+defectNote+')' AS VARCHAR(MAX)) [text()]  
         FROM SUPPORT support inner join inspectionDetail inspDetail on support.uniqfield = inspDetail.def_code where inspHeaderId = insHeader.inspHeaderId  
   --AND uniqfield in (SELECT def_code FROM inspectionDetail WHERE inspHeaderId = insHeader.inspHeaderId)  
         FOR XML PATH(''), TYPE).value('.','NVARCHAR(MAX)'),1,2,' ') REJREASON   
  , CAST (rtrim(ccontact.firstname) + ' ' + rtrim(ccontact.lastname) AS VARCHAR (200)) as Attention  
  --08/08/16 DRP:  replaced the ShipTo and BillTo address field into the combined ShipToAddress and RemitToAddress   
  --,shipbill.SHIPTO AS shipto,shipbill.ADDRESS1 AS SAdd1,shipbill.ADDRESS2 AS SAdd2,shipbill.CITY AS SCity,shipbill.STATE AS SState,shipbill.ZIP AS SZip  
  --,shipbill.COUNTRY AS SCountry, sb2.SHIPTO AS RemitTo, sb2.ADDRESS1 AS RAdd1,sb2.ADDRESS2 AS RAdd2,sb2.CITY AS RCity,sb2.STATE AS RState,sb2.ZIP AS RZip  
  --,sb2.COUNTRY AS RCountry  
  ,rtrim(shipbill.Address1)+case when shipbill.address2<> '' then char(13)+char(10)+rtrim(shipbill.address2) else '' end+  
         -- 03/31/16 VL added Address3 and 4  
         case when shipbill.address3<> '' then char(13)+char(10)+rtrim(shipbill.address3) else '' end+  
         case when shipbill.address4<> '' then char(13)+char(10)+rtrim(shipbill.address4) else '' end+  
        CASE WHEN shipbill.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(shipbill.City)+',  '+rtrim(shipbill.State)+'      '+RTRIM(shipbill.zip)  ELSE '' END +  
        CASE WHEN shipbill.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(shipbill.Country) ELSE '' end+  
        case when shipbill.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(shipbill.PHONE) else '' end+  
        case when shipbill.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(shipbill.FAX) else '' end  as ShipToAddress  
  ,sb2.SHIPTO as RemitTo  
  ,rtrim(sb2.Address1)+case when sb2.address2<> '' then char(13)+char(10)+rtrim(sb2.address2) else '' end+  
         -- 03/31/16 VL added Address3 and 4  
         case when sb2.address3<> '' then char(13)+char(10)+rtrim(sb2.address3) else '' end+  
         case when sb2.address4<> '' then char(13)+char(10)+rtrim(sb2.address4) else '' end+  
        CASE WHEN sb2.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(sb2.City)+',  '+rtrim(sb2.State)+'      '+RTRIM(sb2.zip)  ELSE '' END +  
        CASE WHEN sb2.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(sb2.Country) ELSE '' end+  
        case when sb2.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(sb2.PHONE) else '' end+  
        case when sb2.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(sb2.FAX) else '' end  as RemitToAddress  
  ,DMEMOS.DMRUNIQUE  
  ,ISNULL(dmemos.DMEMONO,'') AS DMEMONO-- 10/30/2020 Rajendra k : Added DMEMONOin selection list
  --07/23/2016 Khandu N: PORecMRb has been changed to DMrheader  
FROM  -- PORecMRB  
  DMrheader   
  --LEFT OUTER JOIN PORECDTL ON PORECMRB.FK_UNIQRECDTL = PORECDTL.UNIQRECDTL  
  --LEFT OUTER JOIN POITEMS ON PORECDTL.UNIQLNNO = POITEMS.UNIQLNNO  
  -- Get DMR and line item details from new database table  
  --07/23/2016 Khandu N: Below tables are used to get DMR detials   
  LEFT OUTER JOIN DMRDetail AS dmrDtl ON DMrheader.DMRUNIQUE = dmrDtl.DMRUNIQUE  
  LEFT OUTER JOIN inspectionHeader AS insHeader ON dmrDtl.inspHeaderId =insHeader.inspHeaderId  
  LEFT OUTER JOIN receiverDetail AS recDetail ON  insHeader.receiverDetId = recDetail.receiverDetId  
  LEFT OUTER JOIN receiverHeader AS recHeader ON  recDetail.receiverHdrId = recHeader.receiverHdrId  
  LEFT OUTER JOIN POMAIN ON DMrheader.Ponum = POMAIN.PONUM  
  LEFT OUTER JOIN SUPINFO ON POMAIN.UNIQSUPNO = SUPINFO.UNIQSUPNO   
  LEFT OUTER join INVENTOR ON dmrDtl.UNIQ_KEY = inventor.UNIQ_KEY  
  LEFT OUTER join SHIPBILL ON DMrheader.LINKADD = shipbill.LINKADD  
  LEFT OUTER join CCONTACT ON shipbill.ATTENTION = ccontact.CID  
  LEFT OUTER join SHIPBILL AS sb2 ON pomain.r_link = sb2.LINKADD   
--07/29/2014 DRP: left outer join SHIPBILL as sb2 on shipbill.CUSTNO = sb2.CUSTNO and sb2.RECORDTYPE = 'R'  
  left outer join dmemos ON DMrheader.DMRUNIQUE = dmemos.DMRUNIQUE  
  
WHERE DMrheader.dmr_no = dbo.padl(@lcDMR,10,'0')  
  
-- 10/01/20 VL added to update PRINTDMR once it's printed  
UPDATE DMrheader SET PRINTDMR = 1 WHERE dmr_no = dbo.padl(@lcDMR,10,'0')  
  
END