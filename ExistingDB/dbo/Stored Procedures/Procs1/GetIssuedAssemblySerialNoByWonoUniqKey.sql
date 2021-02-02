-- =============================================
-- Author:		Sachin B
-- Create date: 09/11/2016
-- Description:	this procedure will be called from the SF module and get all issued assembly Serial no by wono and UniqKey
-- [dbo].[GetIssuedAssemblySerialNoByWonoUniqKey] '0000000556','_1EP0LM58C',1,3000,'',''  
-- =============================================

CREATE PROCEDURE [dbo].[GetIssuedAssemblySerialNoByWonoUniqKey] 
	-- Add the parameters for the stored procedure here
	@Wono char(10),
	@UniqKey char(10),
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

INSERT INTO @AssemblySerialNoList
SELECT DISTINCT SERIALUNIQ,SUBSTRING(SERIALNO, PATINDEX('%[^0]%', SERIALNO+'.'), LEN(SERIALNO)) as SERIALNO , 'STAG' as DeptID
FROM SerialComponentToAssembly Where WONO = @Wono and uniq_key = @UniqKey
	

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