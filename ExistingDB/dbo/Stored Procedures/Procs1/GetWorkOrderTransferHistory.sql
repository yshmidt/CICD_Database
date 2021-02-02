-- =============================================
-- Author:	Anuj K
-- Create date: 05/25/2016
-- Description:	this procedure will be called from the SF module and Pull the working work orders for provided work center
-- GetWorkOrderTransferHistory '0000000141',2
-- =============================================
CREATE PROCEDURE GetWorkOrderTransferHistory 
@wono CHAR(10),
@deptNumber INT
AS
SET NoCount ON; 
DECLARE @StartCount INT = (SELECT SUM(CURR_QTY) FROM DEPT_QTY WHERE WONO =@wono);

DECLARE @tempQuantityIn Table
(
    DATE DATETIME
   ,QtyIn INT
   ,QtyOut INT
   ,RowNumber INT   
)
--Temp Table for which items are come in WC
DECLARE @tempQuantityOut TABLE (
    DATE DATETIME
   ,QtyIn INT
   ,QtyOut INT
   ,RowNumber INT   
)

--Insert Data to table for which items are come in WC
INSERT INTO @tempQuantityIn(
DATE,
QtyIn,
QtyOut,
RowNumber
)
SELECT  Date,SUM(QTY) AS 'QtyIn',0 AS QtyOut,
ROW_NUMBER() OVER (ORDER BY DATE) AS RowNumber
FROM TRANSFER WHERE WONO=@wono AND TO_NUMBER =@deptNumber
GROUP BY DATE,wono,TO_DEPT_ID,TO_NUMBER
order by Date

--Insert Data to table for which items are out from WC
INSERT INTO @tempQuantityOut(
DATE,
QtyIn,
QtyOut,
RowNumber
)
SELECT DATE,
0 AS 'QtyIn', --In Case of staging for the first move the item QtyIn is Total Item in work center
SUM(QTY) AS 'QtyOut',
ROW_NUMBER() OVER (ORDER BY DATE) AS RowNumber
FROM TRANSFER 
where WONO=@wono and FR_NUMBER =@deptNumber
GROUP BY DATE,wono,FR_DEPT_ID,FR_NUMBER
order by Date

--For Other row in staging except first row QtyIn is Zero
if @deptNumber = 1
	BEGIN
		 if ((select count(*) from @tempQuantityOut) > 0)
		 BEGIN
		  INSERT INTO @tempQuantityIn select top 1 DATEADD(ss, -30, date) ,@StartCount,0,1 from @tempQuantityOut order by DATE
		 END
	END
ELSE
   BEGIN
	 UPDATE @tempQuantityOut SET QtyIn = 0 
	END

--Get All data in one table for the @tempQuantityIn and @tempQuantityOut table
;WITH transhist1
AS
(
SELECT DATE,QtyIn,QtyOut  FROM @tempQuantityIn 
UNION ALL
SELECT DATE,QtyIn,QtyOut  FROM @tempQuantityOut   
)

SELECT DATE, QtyIn as 'QuantityIn',QtyOut As 'QuantityOut', 
SUM(QtyIn) OVER (ORDER BY DATE ROWS UNBOUNDED PRECEDING) - SUM(QtyOut) OVER (ORDER BY DATE ROWS UNBOUNDED PRECEDING)AS Balance
FROM transhist1
ORDER BY DATE