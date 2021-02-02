-- =============================================  
-- Author:  Yelena Shmidt  
-- Create date: <06/26/2013>  
-- Description: <Get company name and address information for reports>  
-- Modified: 04/01/16:  added the ForeignCurrency field to help with reporting formats.  I will use this column to control if I display FC results or not.   
--   04/20/16 DRP:  added the dateFormat to the results so I could change the date format on the reports.   
--   04/27/16 DRP:  had to change the ForeignCurrency and DateFormat to pull properly from WMsettings. . . firts before the mnxsetting. .   
--   06/03/16 DRP:  Removed the @lcDateFormat that I had added since we implemented the Culture settings we don't need this anymore  
--   08/02/16 DRP:  added packListSignature to the results to be able to display a Signature on the Packing List if loaded  
--   09/16/19 Sachin B Modify company logo field which will now getting from wmSettingsManagement table insted of micssys 
-- 08/12/20 VL changed to get PackingListFootNote and InvoiceFootNote from wmsettingManagement instead of from micssys
-- 02/01/21 VL changed to use empty string for OrderAcknowledgementFootNote, CreditMemoFootNote, DebitMemoFootNote, PurchaseOrderFootNote, RMAFootNote, QuoteFootNote for now until we have a place to enter in cube, otherwise, those fields get old data from micssys
-- =============================================  
  
CREATE PROCEDURE [dbo].[GetCompanyAddress]  
-- -- Add the parameters for the stored procedure here  
   
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
  DECLARE @lFCInstalled bit  
  SELECT @lFCInstalled = dbo.fn_IsFCInstalled()  

  --   09/16/19 Sachin B Modify company logo field which will now getting from wmSettingsManagement table insted of micssys 
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

  --select @lFCInstalled  
  
--06/03/16 DRP:  Removed  
 --DECLARE @lDateFormat varchar(max)  
 -- select @lDateFormat = dbo.fn_FindDateFormat()  
 -- --select @lDateFormat  
  
    -- Insert statements for procedure here  
 SELECT micssys.lic_name,rtrim(MICSSYS.LADDRESS1)+case when MICSSYS.LADDRESS2<> '' then char(13)+char(10)+rtrim(MICSSYS.laddress2) else '' end+  
  CASE WHEN MICSSYS.LCITY<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(MICSSYS.LCITY)+',  '+rtrim(MICSSYS.lState)+'      '+RTRIM(MICSSYS.lzip)  ELSE '' END +  
  CASE WHEN MICSSYS.LCOUNTRY<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(MICSSYS.LCOUNTRY) ELSE '' END+  
  case when micssys.LPHONE <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(MICSSYS.LPHONE) else '' end+  
  case when micssys.LFAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(micssys.LFAX) else '' end  as LicAddress,
  -- 09/16/19 Sachin B Modify company logo field which will now getting from wmSettingsManagement table insted of micssys 
  @CompanyLogo as CompanyLogo,  
 -- FIELD149 as CompanyLogo,    
 -- 08/12/20 VL changed to get PackingListFootNote and InvoiceFootNote from wmsettingManagement instead of from micssys
  --PKSTD_FOOT as PackingListFootNote,  
  --INSTD_FOOT as InvoiceFootNote,  
  dbo.fn_GetSettingValue('StandardPLFootnote') as PackingListFootNote,
  dbo.fn_GetSettingValue('StandardInvoiceFootnote') as InvoiceFootNote,  
  ---- 02/01/21 VL changed to use empty string for OrderAcknowledgementFootNote, CreditMemoFootNote, DebitMemoFootNote, PurchaseOrderFootNote, RMAFootNote, QuoteFootNote for now until we have a place to enter in cube, otherwise, those fields get old data from micssys
  --AKSTD_FOOT as OrderAcknowledgementFootNote,  
  --CRSTD_FOOT as CreditMemoFootNote,		
  --DMSTD_FOOT as DebitMemoFootNote,  
  --POSTD_FOOT as PurchaseOrderFootNote,  
  --RMA_FOOT as RMAFootNote,  
  --QTSTD_FOOT as QuoteFootNote,  
  '' as OrderAcknowledgementFootNote,  
  '' as CreditMemoFootNote,		
  '' as DebitMemoFootNote,  
  '' as PurchaseOrderFootNote,  
  '' as RMAFootNote,  
  '' as QuoteFootNote,
  --F.settingvalue as ForeignCurrency, --04/27/16 DRP: needed to change it to pull from the fn_IsFCInstalled()  
  @lFCInstalled as ForeignCurrency,  
  --rtrim(D.dateFormat) as [dateFormat], --0/27/16 DRP:  needed to change it to pull from the fn_FindDateFormat()  
  --rtrim(@lDateFormat) as [dateFormat] --06/03/16 DRP:  removed  
  [dbo].[fn_packListSignaturePath] () as packListSignature  
  
 FROM MICSSYS   
  --cross apply (select settingvalue from MnxSettingsManagement where settingname = 'ForeignCurrency') F --04/27/16 DRP:  replaced with the fn_IsFCInstalled()  
  --cross apply (select ISNULL(wm.settingValue,mnx.settingValue) as dateFormat  
  --     FROM MnxSettingsManagement mnx   
  --     LEFT OUTER JOIN wmSettingsManagement wm ON mnx.settingId = wm.settingId   
  --    WHERE mnx.settingName='dateFormat') D  --06/03/16 DRP:  removed    
    
   
END