-- =============================================              
-- Author:  Aloha              
-- Create date: 12/06/2013              
-- Description: Update PO Approve details              
-- =============================================              
CREATE PROCEDURE [dbo].[POApproveUpdate]   
 @poApproveStatus     CHAR(15),         
 @poNum     CHAR(15),              
 @poStatus    CHAR(8),   
 @poApproveBy   CHAR(8)   
    
AS              
BEGIN         
        
BEGIN TRANSACTION      
 BEGIN TRY;              
       
 UPDATE dbo.POMAIN               
 SET              
    POSTATUS = @poStatus                  
 WHERE                 
    PONUM   = @poNum     
      
    
  --Update PO Approved in POMAIN table          
 if (@poApproveStatus='First Approve')                    
    BEGIN                    
  UPDATE dbo.POMAIN                     
  SET                    
   APPVNAME = @poApproveBy                              
  WHERE                       
   PONUM   = @poNum            
 END                      
 ELSE                
    BEGIN              
  UPDATE dbo.POMAIN                     
  SET                    
   FINALNAME = @poApproveBy              
  WHERE                       
   PONUM   = @poNum                   
    END            
          
END TRY        
        
BEGIN CATCH        
 RAISERROR('Error occurred in updating PO Details. This operation will be cancelled.',1,1)  IF @@TRANCOUNT > 0        
  ROLLBACK TRANSACTION;        
END CATCH           
IF @@TRANCOUNT > 0        
    COMMIT TRANSACTION;        
END 