-- =============================================
-- Author:		Debbie
-- Create date: 07/10/2014
-- Description:	
-- Used On:		dfct_wc
-- Modified:	
-- =============================================
create PROCEDURE [dbo].[rptQaDefectListByWc]
	
		@userId uniqueidentifier= null

as
begin 

select	depts.DEPT_NAME as WorkCenter,cudefdet.Def_Code,DEPTS.Number
		,case when SUPPORT.TEXT4 = '' then CAST (0.00 as numeric(9,2)) else CAST(support.text4 as numeric(9,2))end as Cost
		,support.TEXT3 as Def_Desc
from	SUPPORT
		inner join CUDEFDET on support.text2 = cudefdet.DEF_CODE
		inner join DEPTS on cudefdet.DEPT_ID = depts.DEPT_ID
order by NUMBER,DEF_CODE

end