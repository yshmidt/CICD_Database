-- =============================================                            
-- Author:  Aloha                            
-- Create date: 03/08/2014                           
-- Description: Update PO Main details       

--Suraj Aloha, 03/20/2014 Change Error message                     
-- =============================================                            
CREATE PROCEDURE [dbo].[MnxPOMainUpdate]         
 @coNumber     NUMERIC(3,0),         
 @changeHistoryNote VARCHAR(max),           
 @isFreightInclude  BIT, 
 @poStatus  CHAR(8),
 @poUNIQUE     CHAR(10)         
AS                            
BEGIN                       
                      
BEGIN TRANSACTION BEGIN TRY;                           
                               
--Update  POMAIN table         
   UPDATE dbo.POMAIN                             
   SET                            
		lfreightinclude = @isFreightInclude,                    
		POSTATUS = @poStatus,        
		CONUM=@coNumber,        
		CurrChange=@changeHistoryNote,
		APPVNAME='',         --Clear PO Approve details on PO Edit
		FINALNAME=''                                      
   WHERE                               
		POUNIQUE   = @poUNIQUE                    
      
END TRY                      
                      
BEGIN CATCH                      
 RAISERROR('Error occurred in updating PO Header. This operation will be cancelled.',1,1)  IF @@TRANCOUNT > 0                      
  ROLLBACK TRANSACTION;                      
END CATCH                         
IF @@TRANCOUNT > 0                      
    COMMIT TRANSACTION;                      
END 