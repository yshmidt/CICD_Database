-- =============================================                
-- Author:  Aloha                
-- Create date: 12/06/2013                
-- Description: Update PO Approve details   
  
--Suraj Aloha, 03/27/2014 Update POMAIN,POITEMS,POITSCHD temporary PO number with permanent PO number.  
--Suraj Aloha, 04/01/2014 Rename procedure 'POApproveUpdate' with 'MnxPoApproveUpdate'
-- =============================================                
CREATE PROCEDURE [dbo].[MnxPOApproveUpdate]     
 @newPONum   CHAR(15),  
 @poApproveStatus   CHAR(15),           
 @oldPONum   CHAR(15),                
 @poStatus   CHAR(8),     
 @poApproveBy  CHAR(8)   
AS                
BEGIN           
          
BEGIN TRANSACTION        
 BEGIN TRY;                
  
--Update temporary PO number with permanent PO number.  
UPDATE POMAIN  
SET PONUM=@newPONum,  
 POSTATUS = @poStatus     
WHERE PONUM=@oldPONum  
  
UPDATE POITEMS  
SET PONUM=@newPONum  
WHERE PONUM=@oldPONum   
   
UPDATE POITSCHD  
SET  PONUM=@newPONum  
WHERE PONUM=@oldPONum    
        
      
 --Update PO Approved in POMAIN table            
 IF(@poApproveStatus='First Approve')                      
 BEGIN                      
   UPDATE dbo.POMAIN                       
   SET APPVNAME = @poApproveBy                                
   WHERE PONUM   = @newPONum --If PO is updating with new PO number that time @newPONum has permanent PO value otherwise existing PO number
 END                        
 ELSE                  
 BEGIN                
   UPDATE dbo.POMAIN                       
   SET FINALNAME = @poApproveBy                
   WHERE PONUM   = @newPONum                     
 END              
            
END TRY          
          
BEGIN CATCH          
 RAISERROR('Error occurred in approving PO Details. This operation will be cancelled.',1,1)  IF @@TRANCOUNT > 0          
  ROLLBACK TRANSACTION;          
END CATCH             
IF @@TRANCOUNT > 0          
    COMMIT TRANSACTION;          
END 