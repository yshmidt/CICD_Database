
-- =============================================
-- Author:  Shivshankar P
-- Create date: 25/08/2017
-- Description:	Get DEPT_QTY information according WONO
-- Shivshankar P :  12/25/17 Added columns in select
-- =============================================
CREATE PROCEDURE [dbo].[GetDeptQtyDataByWONO] 
   -- Add the parameters for the stored procedure here
    @woNO CHAR (10),
	@startRecord INT=1,
	@endRecord INT=10
AS
BEGIN
	
	SELECT DEPT_QTY.DEPT_ID,DEPTS.DEPT_NAME,CURR_QTY AS ActualQty,0 AS NewQty,CURR_QTY AS CURR_QTY, 
	        totalCount = COUNT(DEPT_QTY.UNIQUEREC) OVER(), -- Shivshankar P :  12/28/17 Added columns in select
	        WONO,DEPTKEY ,UNIQUEREC FROM DEPT_QTY 
	      LEFT JOIN DEPTS ON DEPTS.DEPT_ID = DEPT_QTY.DEPT_ID WHERE DEPT_QTY.WONO =@woNO AND 
	         DEPT_QTY.DEPT_ID NOT IN ('FGI ','SCRP') and CURR_QTY >0
			     ORDER BY DEPT_QTY.DEPT_ID
                    OFFSET (@startRecord -1) ROWS  
                    FETCH NEXT @endRecord ROWS ONLY;  

END