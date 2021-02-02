
--IF (EXISTS(SELECT * FROM sys.objects WHERE [object_id] = OBJECT_ID(N'[dbo].[GetWOJobTypes]') AND [type]='P'))
--drop procedure GetWOJobTypes

-- =============================================          
-- Author:          
-- Create date:         
-- Description:Get Work Order Job Type list   
-- exec [GetWOJobTypes]
-- =============================================    
CREATE PROCEDURE [dbo].[GetWOJobTypes]          
         
AS          
BEGIN
          
SET NOCOUNT ON;
 
SELECT JobTypeId AS Id, JobTypeName AS Name, JobTypeValue AS Value, JobTypeIsRemovable AS IsRemovable,JobTypeCheckOrder AS CheckOrder
FROM WOJobTypes
ORDER BY CheckOrder

END