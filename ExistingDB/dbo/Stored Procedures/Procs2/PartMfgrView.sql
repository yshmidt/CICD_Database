
-- =============================================
-- Author:		
-- Create date: 
-- Description:	This Stored Procedure was created for the Part Mfgr List within inventory
-- Modified:	09/26/2014 DRP:  needed to add the @userId
-- =============================================
CREATE procedure [dbo].[PartMfgrView]

 @userId uniqueidentifier= null
 
as
begin

SELECT LEFT(Text2,8) as PartMfgr,Text as PartMfgrDescript FROM Support WHERE Fieldname = 'PARTMFGR' ORDER BY 1

end