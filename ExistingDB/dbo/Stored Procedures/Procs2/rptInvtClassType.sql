-- =============================================
-- Author:		Debbie
-- Create date: 09/08/2011
-- Description:	This Stored Procedure was created for the "Part Class & Type List"
-- Reports Using Stored Procedure:  icrpt16.rpt
-- Modified:  01/15/2014 DRP:  added the @userid parameter for WebManex
---08/01/17 YS move part_class setup from "Support" table to partClass
-- =============================================
CREATE PROCEDURE  [dbo].[rptInvtClassType] 

@userId uniqueidentifier=null

AS
BEGIN

--SELECT	LEFT(SUPPORT.TEXT2,8) AS Part_class, SUPPORT.TEXT AS DESCRIPT, ISNULL(part_type, space(8)) as Part_Type
--		,ISNULL(parttype.PREFIX,space(8)) as Prefix,TEMPLATE
--from	SUPPORT
--		FULL JOIN PARTTYPE ON SUPPORT.TEXT2 = PARTTYPE.PART_CLASS
--where	support.FIELDNAME = 'PART_CLASS'

select partclass.Part_class,ClassDescription as DESCRIPT,
ISNULL(part_type, space(8)) as Part_Type
	,ISNULL(parttype.PREFIX,space(8)) as Prefix,TEMPLATE
from partClass LEFT OUTER JOIN PartType on partClass.Part_class=PartType.Part_class

END