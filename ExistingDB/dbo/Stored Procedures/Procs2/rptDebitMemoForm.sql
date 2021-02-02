  
-- =============================================  
-- Author:   Debbie  
-- Create date:  02/19/2013  
-- Description:  Created for the AP Debit Memo Form  
-- Reports:   dmemonew.rpt  
-- Modifications:       
-- 02/11/15 VL: Added FC code  
-- 04/01/16 VL: Added TCurrency (Transaction Currency) and FCurrency (Functional Currency) fields and address3 and 4  
--  04/08/16 VL: Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement  
-- 07/11/16 DRP:   added @userId parameter   
-- 07/22/16 VL: Added nTaxAmt, nTaxAmtFC, nDiscAmt, nDiscAmtFC  
-- 01/19/17 VL: Added functional currency code  
-- 03/09/17 DRP: Needed to make sure the Main Total fields listed their value only once so that the Report forms would work properly when I totaled on those fields  
-- 03/17/17 DRP:   found that two of the new fields were missing from the Non-Foreign currency section of results. nTaxAmt and nDiscAmt  
-- 09/17/19 Sachin B Modify company logo field which will now getting from wmSettingsManagement table insted of micssys 
-- =============================================  
CREATE PROCEDURE [dbo].[rptDebitMemoForm]  
    
@lcDmemoNo char(10) = ''  
,@userId uniqueidentifier = null --07/11/16 DRP:  added  
  
as   
begin  
  
  
/*SUPPLIER LIST*/ --07/11/16 DRP:  added  
-- get list of approved suppliers for this user  
DECLARE @tSupplier tSupplier  
declare @tSupNo as table (Uniqsupno char (10))  

  -- 09/16/19 Sachin B Modify company logo field which will now getting from wmSettingsManagement table insted of micssys 
  DECLARE  @CompanyLogo NVARCHAR (MAX) ,@RootDirectory NVARCHAR (MAX)
  SET @CompanyLogo =  (SELECT settingValue FROM wmSettingsManagement WHERE settingId = (SELECT settingId FROM MnxSettingsManagement WHERE settingName = 'DefaultCompanyLogo'))
  SET @RootDirectory =(SELECT settingValue FROM wmSettingsManagement WHERE settingId = (SELECT settingId FROM MnxSettingsManagement WHERE settingName = 'rootDirectory'))

  IF (@RootDirectory IS NULL)
  BEGIN
     SET @RootDirectory =  (SELECT settingValue FROM MnxSettingsManagement WHERE settingName = 'rootDirectory')
  END
  SET @RootDirectory =@RootDirectory + '\CompanyLogo'

  IF (@CompanyLogo IS NULL)
  BEGIN
     SET @CompanyLogo =  (SELECT settingValue FROM MnxSettingsManagement WHERE settingName = 'DefaultCompanyLogo')
  END

  SET @CompanyLogo =@RootDirectory + '\'+ @CompanyLogo
  
INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, 'All';  
--select * from @tSupplier  
  
  
SET @lcDmemoNo=CASE WHEN LEFT(@lcDmemoNo,2)='DM' THEN @lcDmemoNo ELSE 'DM'+dbo.PADL(@lcDmemoNo ,8,'0') END  
  
-- 02/11/16 VL added for FC installed or not  
DECLARE @lFCInstalled bit  
-- 04/08/16 VL changed to get FC installed from function  
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()  
  
BEGIN  
IF @lFCInstalled = 0  
   
 BEGIN  
 select dmemos.UNIQDMHEAD,DMEMOS.DMDATE,dmemos.DMEMONO,dmemos.DMSTATUS,dmemos.INVNO,apmaster.INVDATE,ISNULL(sinvoice.SUPPKNO,'') AS SUPPKNO  
   ,pomain.podate,isnull(PORECMRB.RMA_NO,'')as RMA_NO,porecmrb.RMA_DATE,isnull(porecmrb.DMRPLNO,'') as DMRPLNO  
   ,ISNULL(porecmrb.DMR_NO,'') AS DMR_NO,porecmrb.DMR_DATE,dmemos.PONUM  
   --,dmemos.DMTOTAL --03/09/17 DRP:  replaced with the below  
   ,CASE WHEN ROW_NUMBER() OVER(Partition by dmemono Order by dmemono)=1 Then dmemos.DMTOTAL else CAST(0.00 as Numeric(20,2)) END AS DMTOTAL  
   ,dmemos.UNIQSUPNO,dmemos.R_LINK,Dmemos.DMRUNIQUE  
   ,DMTYPE,dmemos.UNIQAPHEAD,Dmemos.DMNOTE,apdmdetl.ITEM_NO,apdmdetl.ITEM_DESC,apdmdetl.QTY_EACH,apdmdetl.PRICE_EACH  
   ,APDMDETL.QTY_EACH*APDMDETL.pRICE_EACH AS ItemTotal,APDMDETL.TAX_PCT,APDMDETL.ITEM_TOTAL as ItemTotTax  
   --02/19/2013 DRP:  for the time being the IS_TAX field is not being populated.  So I will display it as taxable if the Tax_Pct is populated.  --,APDMDETL.IS_TAX  
   ,case when apdmdetl.TAX_PCT > 0.00 then CAST(1 as bit) else cast (0 as bit) END as IS_TAX  
   ,ConfirmTo.SHIPTO as ConfirmTo, rtrim(ConfirmTo.Address1)+case when ConfirmTo.address2<> '' then char(13)+char(10)+rtrim(ConfirmTo.address2) else '' end+  
       CASE WHEN ConfirmTo.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(ConfirmTo.City)+',  '+rtrim(ConfirmTo.State)+'      '+RTRIM(confirmto.zip)  ELSE '' END +  
       CASE WHEN ConfirmTo.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(ConfirmTo.Country) ELSE '' end as ConfirmToAddress  
   ,RemitTo.SHIPTO as RemitTo,rtrim(RemitTo.Address1)+case when RemitTo.address2<> '' then char(13)+char(10)+rtrim(RemitTo.address2) else '' end+  
       -- 04/01/16 VL added address3 and address4  
       case when RemitTo.address3<> '' then char(13)+char(10)+rtrim(RemitTo.address3) else '' end+  
       case when RemitTo.address4<> '' then char(13)+char(10)+rtrim(RemitTo.address4) else '' end+  
       CASE WHEN RemitTo.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(RemitTo.City)+',  '+rtrim(RemitTo.State)+'      '+RTRIM(RemitTo.zip) ELSE '' END+  
       CASE WHEN RemitTo.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(RemitTo.Country) ELSE '' END  as RemitToAddress  
   ,micssys.LIC_NAME,rtrim(MICSSYS.LADDRESS1)+case when MICSSYS.LADDRESS2<> '' then char(13)+char(10)+rtrim(MICSSYS.laddress2) else '' end+  
       CASE WHEN MICSSYS.LCITY<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(MICSSYS.LCITY)+',  '+rtrim(MICSSYS.lState)+'      '+RTRIM(MICSSYS.lzip)  ELSE '' END ++  
       CASE WHEN MICSSYS.LCOUNTRY<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(MICSSYS.LCOUNTRY) ELSE '' END+  
       case when micssys.LPHONE <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(MICSSYS.LPHONE) else '' end+  
       case when micssys.LFAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(micssys.LFAX) else '' end  as LicAddress  
    -- 09/17/19 Sachin B Modify company logo field which will now getting from wmSettingsManagement table insted of micssys 
    --,MICSSYS.FIELD149
   ,@CompanyLogo AS FIELD149
   ,micssys.DMSTD_FOOT  
   --03/17/17 DRP:  needed to add nTaxAmt and nDiscAmt to the results   
   ,CASE WHEN ROW_NUMBER() OVER(Partition by dmemono Order by dmemono)=1 Then dmemos.NTAXAMT else CAST(0.00 as Numeric(20,2)) END AS nTaxAmt  
   ,CASE WHEN ROW_NUMBER() OVER(Partition by dmemono Order by dmemono)=1 Then dmemos.NDISCAMT else CAST(0.00 as Numeric(20,2)) END AS nDiscAmt  
    
 from DMEMOS  
   left outer join POMAIN on dmemos.PONUM = pomain.PONUM  
   left outer join APMASTER on dmemos.UNIQAPHEAD = apmaster.uniqaphead  
   left outer join SINVOICE on apmaster.UNIQAPHEAD = sinvoice.fk_uniqaphead  
   left outer join PORECMRB on dmemos.DMRUNIQUE = porecmrb.DMRUNIQUE  
   left outer join APDMDETL on dmemos.UNIQDMHEAD = apdmdetl.UNIQDMHEAD  
   left outer join SHIPBILL as RemitTo on dmemos.R_LINK = RemitTo.LINKADD  
   inner join SUPINFO on dmemos.UNIQSUPNO = supinfo.UNIQSUPNO  
   left outer join SHIPBILL as ConfirmTo on supinfo.C_LINK = confirmto.LINKADD  
   cross join MICSSYS  
   
 where dmemos.DMEMONO = @lcDmemoNo  
   and  exists (select 1 from @tSupplier t  where t.uniqsupno=dmemos.uniqsupno) --07/11/16 DRP:  added  
  
 END  
ELSE  
-- FC installed  
 BEGIN  
 -- 01/20/17 VL comment out following code, will get 3 currency symbols in SQL statement  
 -- 04/01/16 VL realized that I need to add HC (Functional currency later)  
 --DECLARE @FCurrency char(3) = ''  
 -- 04/08/16 VL changed to use function  
 --SELECT @FCurrency = Symbol FROM Fcused WHERE Fcused_uniq = dbo.fn_GetHomeCurrency()  
  
 select dmemos.UNIQDMHEAD,DMEMOS.DMDATE,dmemos.DMEMONO,dmemos.DMSTATUS,dmemos.INVNO,apmaster.INVDATE,ISNULL(sinvoice.SUPPKNO,'') AS SUPPKNO  
   ,pomain.podate,isnull(PORECMRB.RMA_NO,'')as RMA_NO,porecmrb.RMA_DATE,isnull(porecmrb.DMRPLNO,'') as DMRPLNO  
   ,ISNULL(porecmrb.DMR_NO,'') AS DMR_NO,porecmrb.DMR_DATE,dmemos.PONUM  
   --,dmemos.DMTOTAL --03/09/17 DRP  replaced with the below  
   ,CASE WHEN ROW_NUMBER() OVER(Partition by dmemono Order by dmemono)=1 Then dmemos.DMTOTAL else CAST(0.00 as Numeric(20,2)) END AS DMTOTAL  
   ,dmemos.UNIQSUPNO,dmemos.R_LINK,Dmemos.DMRUNIQUE  
   ,DMTYPE,dmemos.UNIQAPHEAD,Dmemos.DMNOTE,apdmdetl.ITEM_NO,apdmdetl.ITEM_DESC,apdmdetl.QTY_EACH,apdmdetl.PRICE_EACH  
   ,APDMDETL.QTY_EACH*APDMDETL.pRICE_EACH AS ItemTotal,APDMDETL.TAX_PCT,APDMDETL.ITEM_TOTAL as ItemTotTax  
   --02/19/2013 DRP:  for the time being the IS_TAX field is not being populated.  So I will display it as taxable if the Tax_Pct is populated.  --,APDMDETL.IS_TAX  
   ,case when apdmdetl.TAX_PCT > 0.00 then CAST(1 as bit) else cast (0 as bit) END as IS_TAX  
   ,ConfirmTo.SHIPTO as ConfirmTo, rtrim(ConfirmTo.Address1)+case when ConfirmTo.address2<> '' then char(13)+char(10)+rtrim(ConfirmTo.address2) else '' end+  
       CASE WHEN ConfirmTo.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(ConfirmTo.City)+',  '+rtrim(ConfirmTo.State)+'      '+RTRIM(confirmto.zip)  ELSE '' END +  
       CASE WHEN ConfirmTo.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(ConfirmTo.Country) ELSE '' end as ConfirmToAddress  
   ,RemitTo.SHIPTO as RemitTo,rtrim(RemitTo.Address1)+case when RemitTo.address2<> '' then char(13)+char(10)+rtrim(RemitTo.address2) else '' end+  
       -- 04/01/16 VL added address3 and address4  
       case when RemitTo.address3<> '' then char(13)+char(10)+rtrim(RemitTo.address3) else '' end+  
       case when RemitTo.address4<> '' then char(13)+char(10)+rtrim(RemitTo.address4) else '' end+  
       CASE WHEN RemitTo.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(RemitTo.City)+',  '+rtrim(RemitTo.State)+'      '+RTRIM(RemitTo.zip) ELSE '' END+  
       CASE WHEN RemitTo.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(RemitTo.Country) ELSE '' END  as RemitToAddress  
   ,micssys.LIC_NAME,rtrim(MICSSYS.LADDRESS1)+case when MICSSYS.LADDRESS2<> '' then char(13)+char(10)+rtrim(MICSSYS.laddress2) else '' end+  
       CASE WHEN MICSSYS.LCITY<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(MICSSYS.LCITY)+',  '+rtrim(MICSSYS.lState)+'      '+RTRIM(MICSSYS.lzip)  ELSE '' END ++  
       CASE WHEN MICSSYS.LCOUNTRY<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(MICSSYS.LCOUNTRY) ELSE '' END+  
       case when micssys.LPHONE <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(MICSSYS.LPHONE) else '' end+  
       case when micssys.LFAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(micssys.LFAX) else '' end  as LicAddress  
    -- 09/17/19 Sachin B Modify company logo field which will now getting from wmSettingsManagement table insted of micssys 
    --,MICSSYS.FIELD149
   ,@CompanyLogo AS FIELD149
   ,micssys.DMSTD_FOOT  
   --,dmemos.DMTOTALFC --03/19/17 DRP:  replaced with below  
   ,CASE WHEN ROW_NUMBER() OVER(Partition by dmemono Order by dmemono)=1 Then dmemos.DMTOTALFC else CAST(0.00 as Numeric(20,2)) END AS DMTOTALFC  
   ,apdmdetl.PRICE_EACHFC,APDMDETL.QTY_EACH*APDMDETL.pRICE_EACHFC AS ItemTotalFC,APDMDETL.ITEM_TOTALFC as ItemTotTaxFC  
   -- 01/19/17 VL comment currency code  
   -- 04/01/16 VL added TCurrency and FCurrency  
   --,Fcused.Symbol AS TCurrency, @FCurrency AS FCurrency  
   -- 07/22/16 VL added nTaxAmt, nTaxAmtFC, nDiscAmt, nDiscAmtFC  
   --,nTaxAmt, nTaxAmtFC, nDiscAmt, nDiscAmtFC --03/09/17 DRP:  replaced with the below   
   ,CASE WHEN ROW_NUMBER() OVER(Partition by dmemono Order by dmemono)=1 Then dmemos.NTAXAMT else CAST(0.00 as Numeric(20,2)) END AS nTaxAmt  
   ,CASE WHEN ROW_NUMBER() OVER(Partition by dmemono Order by dmemono)=1 Then dmemos.NTAXAMTFC else CAST(0.00 as Numeric(20,2)) END AS nTaxAmtFC  
   ,CASE WHEN ROW_NUMBER() OVER(Partition by dmemono Order by dmemono)=1 Then dmemos.NDISCAMT else CAST(0.00 as Numeric(20,2)) END AS nDiscAmt  
   ,CASE WHEN ROW_NUMBER() OVER(Partition by dmemono Order by dmemono)=1 Then dmemos.NDISCAMTFC else CAST(0.00 as Numeric(20,2)) END AS nDiscAmtFC  
   -- 01/19/17 VL added functional currency code  
   --,dmemos.DMTOTALPR --03/09/2017 DRP:  Replaced with the below  
   ,CASE WHEN ROW_NUMBER() OVER(Partition by dmemono Order by dmemono)=1 Then dmemos.DMTOTALPR else CAST(0.00 as Numeric(20,2)) END AS DMTOTALPR  
   ,apdmdetl.PRICE_EACHPR,APDMDETL.QTY_EACH*APDMDETL.pRICE_EACHPR AS ItemTotalPR,APDMDETL.ITEM_TOTALPR as ItemTotTaxPR  
   --,nTaxAmtPR, nDiscAmtPR --03/09/17 DRP:  replaced with below  
   ,CASE WHEN ROW_NUMBER() OVER(Partition by dmemono Order by dmemono)=1 Then dmemos.NTAXAMTPR else CAST(0.00 as Numeric(20,2)) END AS nTaxAmtPR  
   ,CASE WHEN ROW_NUMBER() OVER(Partition by dmemono Order by dmemono)=1 Then dmemos.NDISCAMTPR else CAST(0.00 as Numeric(20,2)) END AS nDiscAmtPR  
   , TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol  
   FROM DMEMOS  
   -- 01/19/17 VL changed criteria to get 3 currencies  
   INNER JOIN Fcused PF ON DMEMOS.PrFcused_uniq = PF.Fcused_uniq  
   INNER JOIN Fcused FF ON DMEMOS.FuncFcused_uniq = FF.Fcused_uniq     
   INNER JOIN Fcused TF ON DMEMOS.Fcused_uniq = TF.Fcused_uniq  
   left outer join POMAIN on dmemos.PONUM = pomain.PONUM  
   left outer join APMASTER on dmemos.UNIQAPHEAD = apmaster.uniqaphead  
   left outer join SINVOICE on apmaster.UNIQAPHEAD = sinvoice.fk_uniqaphead  
   left outer join PORECMRB on dmemos.DMRUNIQUE = porecmrb.DMRUNIQUE  
   left outer join APDMDETL on dmemos.UNIQDMHEAD = apdmdetl.UNIQDMHEAD  
   left outer join SHIPBILL as RemitTo on dmemos.R_LINK = RemitTo.LINKADD  
   inner join SUPINFO on dmemos.UNIQSUPNO = supinfo.UNIQSUPNO  
   left outer join SHIPBILL as ConfirmTo on supinfo.C_LINK = confirmto.LINKADD  
   cross join MICSSYS  
   
 where dmemos.DMEMONO = @lcDmemoNo  
 and  exists (select 1 from @tSupplier t  where t.uniqsupno=dmemos.uniqsupno) --07/11/16 DRP:  added  
  
 END--end of FC installed  
END -- end of IF FC installed  
  
-- code to just indicate if the Debit Memo has been printed   
UPDATE dmemos SET  IS_printed = 1 WHERE dmemos.dmemono = @lcDmemoNo  
end