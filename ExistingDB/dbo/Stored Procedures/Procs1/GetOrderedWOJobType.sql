
--IF (EXISTS(SELECT * FROM sys.objects WHERE [object_id] = OBJECT_ID(N'[dbo].[GetOrderedWOJobType]') AND [type]='P'))
--drop procedure GetOrderedWOJobType

-- =============================================          
-- Author:          
-- Create date:         
-- Description:Get Work Order Job Type list   
-- exec GetOrderedWOJobType
-- =============================================    
CREATE PROCEDURE [dbo].[GetOrderedWOJobType]          
         
AS          
BEGIN
          
SET NOCOUNT ON;
 
SELECT * FROM WOJobTypes
ORDER BY JobTypeCheckOrder

END