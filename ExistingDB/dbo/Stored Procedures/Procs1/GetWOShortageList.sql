-- =============================================
-- Author : Rajendra K	
-- Create date : <12/21/2017>
-- Description : Get WO ShortageList data
-- Modification
   -- 01/09/2018 Rajendra K : Added condition K.SHORTQTY > 0 in where clause
   -- 01/23/2018 Rajendra K : Included condition for @gUniq_key check in brackets   
   -- 04/24/2018 Rajendra K : Added new condition in where clause for WO Status
   -- 06/05/2018 Rajendra K : Changed condition in where clause
-- EXEC GetWOShortageList '_1LR0NALAI'
-- =============================================
CREATE PROCEDURE [dbo].[GetWOShortageList]
(
@gUniq_key char(10)=' ' 
)
AS
BEGIN
	SET NOCOUNT ON;			
	SELECT DISTINCT 
		   CAST(dbo.fremoveLeadingZeros(W.WONO) AS VARCHAR(MAX)) AS Wono
		  ,K.dept_id AS WorkCenter
		  ,W.DUE_DATE AS DueDate		
		  ,SUM(K.SHORTQTY) AS Shortage
		  ,W.WONO AS WorkOrderNumber
		  ,IR.PART_NO 
		  ,0 AS ponum
	FROM INVENTOR I
		  RIGHT JOIN KAMAIN K ON k.UNIQ_KEY=I.UNIQ_KEY 
		  INNER JOIN WOENTRY W ON W.WONO=K.WONO
		  INNER JOIN INVENTOR IR ON W.UNIQ_KEY  = IR.UNIQ_KEY 
    WHERE K.SHORTQTY >0      -- 01/09/2018 Rajendra K : Added condition
	AND (@gUniq_key = NULL OR @gUniq_key ='' OR I.UNIQ_KEY = @gUniq_key)
	-- 01/23/2018 Rajendra K : Included condition for @gUniq_key check in brackets   
	AND   W.OPENCLOS NOT IN ('Cancel','Closed') AND W.KITSTATUS <> 'KIT CLOSED' -- 04/24/2018 Rajendra K : Added new condition in where clause
																				-- 06/05/2018 Rajendra K : Changed condition in where clause
	GROUP BY W.WONO 
		  ,K.dept_id
		  ,W.DUE_DATE
		  ,IR.PART_NO 
    ORDER BY W.WONO
END
	