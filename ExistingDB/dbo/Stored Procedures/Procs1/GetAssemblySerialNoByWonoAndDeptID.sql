-- =============================================
-- Author:		Sachin B
-- Create date: 09/11/2016
-- Description:	this procedure will be called from the SF module and get assembly Serial no by wono and DeptID
-- [dbo].[GetAssemblySerialNoByWonoAndDeptID] '0000000514' , 'STAG',1,3000,'',''  
-- [dbo].[GetAssemblySerialNoByWonoAndDeptID] '0000000514' , 'FGI',1,3000,'',''  
-- =============================================

CREATE PROCEDURE [dbo].[GetAssemblySerialNoByWonoAndDeptID] 
	-- Add the parameters for the stored procedure here
	@Wono char(10),
	@DeptID char(4),
	@StartRecord INT,
	@EndRecord INT, 
	@SortExpression CHAR(1000) = null,
	@Filter NVARCHAR(1000) = null
AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
IF OBJECT_ID('dbo.#TEMP', 'U') IS NOT NULL      
DROP TABLE dbo.#TEMP;

DECLARE @SQL nvarchar(max);

Declare @AssemblySerialNoList table(
SerialUniq char(10),
SerialNo char(30),
DeptID char(4)
);

if(@DeptID = 'FGI')
   BEGIN
        INSERT INTO @AssemblySerialNoList
		SELECT DISTINCT ser.SERIALUNIQ,SUBSTRING(ser.SERIALNO, PATINDEX('%[^0]%', ser.SERIALNO+'.'), LEN(ser.SERIALNO)) as SERIALNO , @DeptID as DeptID
		FROM INVTSER ser
		left outer join TRANSFER t on ser.WONO =t.WONO
		WHERE 
		(ser.ID_KEY ='DEPTKEY' and ser.ID_VALUE in (Select deptkey from DEPT_QTY where WONO = @Wono and DEPT_ID = @DeptID) and ser.WONO = @Wono)
		or
		(ser.ID_KEY ='W_KEY' and ser.WONO = @Wono)
	END
ELSE
    BEGIN

	   INSERT INTO @AssemblySerialNoList
	   SELECT DISTINCT ser.SERIALUNIQ,SUBSTRING(ser.SERIALNO, PATINDEX('%[^0]%', ser.SERIALNO+'.'), LEN(ser.SERIALNO)) as SERIALNO , @DeptID as DeptID
		FROM INVTSER ser
		left outer join TRANSFER t on ser.WONO =t.WONO
		WHERE 
		(ser.ID_KEY ='DEPTKEY' and ser.ID_VALUE in (Select deptkey from DEPT_QTY where WONO = @Wono and DEPT_ID = @DeptID) and ser.WONO = @Wono)
		or
		(ser.ID_KEY ='W_KEY' and ser.ID_VALUE in (Select deptkey from DEPT_QTY where WONO = @Wono and DEPT_ID = @DeptID) and ser.WONO = @Wono)
		or
		(ser.ID_KEY ='WONO' and ser.ID_VALUE = @Wono and ser.WONO = @Wono and t.FR_DEPT_ID = 'FGI' and t.TO_DEPT_ID = @DeptID)
	END

	SELECT identity(int,1,1) as RowNumber,*INTO #TEMP from @AssemblySerialNoList

	IF @filter <> '' AND @sortExpression <> ''
  BEGIN
   SET @SQL=N'select  t.* ,(SELECT COUNT(RowNumber) FROM #TEMP WHERE '+@filter+') AS TotalCount from #TEMP  t  WHERE '+@filter+' and
   RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+' ORDER BY '+ @SortExpression+''
   END
  ELSE IF @filter = '' AND @sortExpression <> ''
  BEGIN
    SET @SQL=N'select  t.*,(SELECT COUNT(RowNumber) FROM #TEMP ) AS TotalCount from #TEMP  t  WHERE 
    RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+' ORDER BY '+ @sortExpression+''
	END
  ELSE IF @filter <> '' AND @sortExpression = ''
  BEGIN
      SET @SQL=N'select  t.* ,(SELECT COUNT(RowNumber) FROM #TEMP WHERE '+@filter+') AS TotalCount from #TEMP  t  WHERE  '+@filter+' and
      RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+''
   END
   ELSE
     BEGIN
      SET @SQL=N'select  t.*,(SELECT COUNT(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE 
   RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+''
   END
   exec sp_executesql @SQL
END