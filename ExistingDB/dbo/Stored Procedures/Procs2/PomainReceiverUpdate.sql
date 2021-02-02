-- =============================================        
-- Author:  Aloha        
-- Create date: 11/14/2013        
-- Description: Update Receive details        
-- =============================================        
CREATE PROCEDURE [dbo].[PomainReceiverUpdate]        
 @fob    CHAR(15),        
 @delTime   CHAR(8),        
 @iLink    CHAR(10),        
 @isTax    BIT,        
 @poNum    CHAR(15),        
 @scTAxPct   NUMERIC(7,4),        
 @shipCharge   CHAR(15),        
 @shipChgAmt   NUMERIC(8,2),        
 @shipVia   CHAR(15),        
 @terms    CHAR(15)        
AS        
BEGIN      
    
BEGIN TRANSACTION BEGIN TRY;    
      
 UPDATE dbo.POMAIN         
 SET        
   FOB   = @fob,        
   DELTIME  = @delTime,        
   I_LINK  = @iLink,        
   IS_SCTAX  = @isTax,        
   SCTAXPCT  = @scTAxPct,        
   SHIPCHARGE = @shipCharge,        
   SHIPCHG  = @shipChgAmt,        
   SHIPVIA  = @shipVia,        
   TERMS   = @terms        
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