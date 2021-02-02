-- =============================================        
-- Author:  Aloha        
-- Create date: 11/13/2013        
-- Description: Get Receive TO edit details        
-- =============================================        
CREATE PROCEDURE [dbo].[GetPOReceiverDetails]         
AS        
BEGIN        
 exec PmtTermsView         
 exec FOBView        
 exec ShipChargeView        
 exec ShipViaView        
END 
