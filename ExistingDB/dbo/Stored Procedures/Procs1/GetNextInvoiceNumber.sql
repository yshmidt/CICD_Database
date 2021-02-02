 -- =============================================
-- Author: Nitesh B	
-- Create date: 1/8/2020
-- Description:	Get Next Invoice Number
-- EXEC [GetNextInvoiceNumber] ''
-- Nitesh B 01/09/2020 Get Invoice Number from LastInvoiceNumber setting and Remove old code 
-- =============================================
CREATE PROCEDURE [dbo].[GetNextInvoiceNumber]   
 @pcNextNumber char(10) OUTPUT  
AS   
 DECLARE @lExit bit=0   
 WHILE (1=1)  
  BEGIN  
   BEGIN TRANSACTION  
   BEGIN TRY  
   -- Nitesh B 01/09/2020 Get Invoice Number from LastInvoiceNumber setting and Remove old code 
    --SELECT @pcNextNumber= dbo.PADL(CONVERT(bigint,LastInvno)+1,10,DEFAULT) FROM MicsSys  
    --UPDATE Micssys SET LastInvno = @pcNextNumber 
	SELECT @pcNextNumber= dbo.PADL(CONVERT(bigint,settingValue)+1,10,DEFAULT) FROM wmsettingsManagement
	WHERE settingId = (SELECT settingId FROM MnxSettingsManagement WHERE settingName='LastInvoiceNumber' AND settingModule = 'Invoices')   
	UPDATE wmsettingsManagement SET settingValue = @pcNextNumber 
	WHERE settingId = (SELECT settingId FROM MnxSettingsManagement WHERE settingName='LastInvoiceNumber' AND settingModule = 'Invoices')  
   END TRY  
   BEGIN CATCH  
    set @lExit=1;  
    IF @@TRANCOUNT>0  
     ROLLBACK  
       
   END CATCH  
   IF @lExit=0  
   BEGIN  
    IF @@TRANCOUNT>0  
    COMMIT  
    --check if the number already in use  
    SELECT Invoiceno FROM Plmain WHERE Invoiceno=@pcNextNumber  
    IF @@ROWCOUNT<>0  
     CONTINUE  
    ELSE  
     BREAK  
   END  
   ELSE -- IF lExit=0  
   BREAK  
  END -- WHILE (1=1)  
  IF  @lExit=1  
  BEGIN  
   RAISERROR('Error occurred selecting next Invoice number.',11,1)  
   set @pcNextNumber=' '  
   RETURN -1  
  END  
     
 