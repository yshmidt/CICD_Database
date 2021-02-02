-- =============================================
-- Author:		<Vicky Lu>
-- Create date: <?>
-- Description:	<Qkview for Kit Required>
-- Modification:
-- 12/07/12 VL changed the calculation of ReqDate and LateDay, the Kit_lunit was mistakenly used by Prod_lUnit
-- 06/12 15 VL found 'REL' need woentry.Kit = 1 and 'ALL' don't need
-- 06/12/2015 DRP:  I changed the Parameter options to the following to work better with the Cloud UI. ALL, BOMs Only, Released WO
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 08/25/17 VL we had different ways of calculating required date.  MRP and BOM counts 5 days for a week, 20 days for a month, here we had 7 days for a week, 30 days for a mont, changed to work the same as MRP and BOM
---09/18/17 YS added new column to Woentry; JobType to separate Status (openCloc) and Job type
---02/09/18 YS creaqted new function fnGetTotalLeadTimeAndCount() to return total production and kit leadtimes for all sub-assemblies and total count of items (excluding make parts) 
--- will be used for occurate calculation of the kit schedule 
--- Also combine the code to use one sql statement 
-- =============================================
CREATE PROCEDURE [dbo].[QkViewKitRequiredView]
 --declare
 @lcFilter AS char(12) = 'ALL'			--ALL, BOMs Only, Released WO
 , @userId uniqueidentifier=null 
AS
BEGIN


-- @lcFilter:  'ALL', 'BOM', 'REL'
SET NOCOUNT ON;
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 02/09/18 YS added leadtime as int (saved in number of days
DECLARE @ZKitRequired TABLE (Wono char(10), Part_no char(35), Revision char(8), Descript char(45), Balance numeric(7,0), Uniq_key char(10),
							Due_date smalldatetime, leadtime int,
							ReqDate smalldatetime, LateDay numeric(4,0), BomCnt numeric(4,0) default 0)


-- 08/25/17 VL changed days for a week from 7 to 5, days for a month from 30 to 20
--02/09/18 YS combine the code instead of using IF
--02/09/18 YS remove calculation for the reqdate untill populated from the sub-assembly. Calculate late days later
--IF @lcFilter = 'BOMs Only'
	
	INSERT @ZKitRequired (Wono, Part_no, Revision, Descript, Balance, Uniq_key, Due_date,leadTime )
		SELECT Wono, Part_no, Revision, Descript, Balance, Woentry.Uniq_key, Due_date,
			Prod_ltime*(CASE WHEN Prod_lunit = 'DY' THEN 1 
						     WHEN Prod_lunit = 'WK' THEN 5 
						     WHEN Prod_lunit = 'MO' THEN 20 ELSE 1 END) + 
				Kit_ltime*(CASE WHEN Kit_lunit = 'DY' THEN 1 
						        WHEN Kit_lunit = 'WK' THEN 5 
								WHEN Kit_lunit = 'MO' THEN 20 ELSE 1 END) AS LeadTime
		FROM Woentry INNER JOIN Inventor 
		ON  Woentry.Uniq_key = Inventor.Uniq_key 
		AND Woentry.OpenClos <> 'Closed'
		AND Woentry.OpenClos <> 'Cancel'
		AND Woentry.KitStatus = ''
		AND Woentry.Balance > 0 
		--02/09/18 YS added AND for the @lcFilter. 
		-- from the old code
		-- @lcFilter='BOMs Only' - connection to the bom_det
		-- @lcFilter='All' - no need to have bom records
		-- @lcFilter = 'Released WO' - Woentry.Kit = 1
		AND ((@lcFilter='All' ) OR 
		(@lcFilter='BOMs Only' and exists (select 1 from bom_det where bom_det.BOMPARENT=woentry.uniq_key)) 
		OR (@lcFilter = 'Released WO' AND Woentry.Kit = 1))
		AND CHARINDEX('Rework',JobType)=0
		

		;with
		Leadt
		as
		(
		select wono,Uniq_key,due_date,h.SubLeadTime,h.nItems
		FROM @ZKitRequired t 
		cross apply (select nItems,subleadtime from dbo.fnGetTotalLeadTimeAndCount(t.Uniq_key,t.due_date) ) H
		)
		update @ZKitRequired set leadtime=leadtime+isnull(l.SubLeadTime,0),
		BomCnt=isnull(l.nItems,0) ,
		ReqDate=dbo.fn_GetWorkDayWithOffset(l.Due_date, leadtime+isnull(l.SubLeadTime,0), '-'),
		LateDay=dbo.fn_FindNumberOfWorkingDays(dbo.fn_GetWorkDayWithOffset(l.Due_date, leadtime+isnull(SubLeadTime,0), '-'),Getdate()) 
		from Leadt L where l.wono=[@ZKitRequired].wono
	    select * from @ZKitRequired order by ReqDate
END			