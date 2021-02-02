-- =============================================        
-- Author:  Aloha        
-- Create date: 11/15/2013        
-- Description: Update Billing Information details        
-- =============================================        
CREATE PROCEDURE [dbo].[PomainBlinkUpdate]         
 @bLink    CHAR(10),         
 @poNum    CHAR(15)        
AS        
BEGIN        
    
BEGIN TRANSACTION BEGIN TRY;    
    
 UPDATE dbo.POMAIN         
 SET           
   b_link  = @bLink           
 WHERE           
   PONUM   = @poNum                 
    
END TRY    
    
BEGIN CATCH    
 RAISERROR('Error occurred in updating PO Details. This operation will be cancelled.',1,1)  IF @@TRANCOUNT > 0    
  ROLLBACK TRANSACTION;    
END CATCH       
IF @@TRANCOUNT > 0    
    COMMIT TRANSACTION;    
END 