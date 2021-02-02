

-- =============================================
-- Author:			Debbie
-- Create date:		06/05/2014
-- Description:		Compiles the details for the Master Defect List
-- Used On:			dfctmast
-- Modifications:	
-- =============================================
CREATE PROCEDURE  [dbo].[rptQaMasterDefectList]

@userId uniqueidentifier=null


as
begin

select	text2 as DefectCode,text3 as DefectDesc
		,cast((case when text4='' then '0.00' 
				when patindex('%[^0-9]%',ltrim(rtrim(text4)))<>0 and patindex('%.%',text4)=0 then '0.00'
					when patindex('%.%',text4)=0 then LTRIM(RTRIM(text4)) 
				ELSE LTRIM(RTRIM(SUBSTRING(text4,1,patindex('%.%',text4)-1)))+'.'+LTRIM(RTRIM(SUBSTRING(text4,patindex('%.%',text4)+1,LEN(text4)))) end)as numeric(6,2)) as DefectCost
from	support
where	FIELDNAME = 'DEF_CODE'
ORDER BY TEXT3
end