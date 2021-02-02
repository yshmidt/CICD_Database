
-- 11/13/12 VL Found the SELECT statement was not populated by passing in parameters, has to change to take 2 parameters

CREATE PROC [dbo].[ErrSysView] @FromDate AS smalldatetime = NULL, @ToDate AS smalldatetime = NULL
AS
BEGIN
SET NOCOUNT ON;

SELECT *
	FROM Errsys
	WHERE CONVERT(VARCHAR(10),Err_date,111) BETWEEN CONVERT(VARCHAR(10),@FromDate,111) AND CONVERT(VARCHAR(10),@ToDate,111)
	ORDER BY ERR_DATE
END 
