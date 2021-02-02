-- =============================================
-- Author:		Shripati U 	
-- Create date: <08/26/2017>
-- Description:Get Work Order list
-- 10/12/2017  -Shripati U :-Fixed work order repeated issue     
-- 11/09/2017  -Shripati U :-Implement Sorting functinality 
-- 12/11/2017  -Shripati U :-Add the kitstatus, kit completed date 
-- 12/29/2017  -Shripati U :-Add the filter On basis of the Late on On Hold 
-- 01/04/2018  -Shripati U :-Search the Work Order on basis of Work Order, Assembly No, Sales Order, Customer 
-- 01/10/2018  -Shripati U :-In search functinality consider the work order status.
-- 08/20/2018  -Shripati U :-Removed leading zero's from workOrder.
-- GetWorkOrderList '','','','','Open',0,150,''
-- =============================================

CREATE PROCEDURE [dbo].[GetWorkOrderList]
(
@assemblyNumber NVARCHAR(35) = ' ',
@woNo NVARCHAR(35) = ' ',
@soNo NVARCHAR(35) = ' ',
@custName NVARCHAR(35) = ' ',
@status NVARCHAR(10) = ' ',
@pageIndex INT,
@pageSize INT,
@skip INT,
@sortExpression CHAR(1000) = null
)
AS
BEGIN
DECLARE @SQL NVARCHAR(MAX);  

       -- 12/11/2017  -Shripati U :-Add the kitstatus, kit completed date 
	   -- 08/20/2018  -Shripati U :-Removed leading zero's from workOrder.
 SET @SQL = N'SELECT dbo.fRemoveLeadingZeros(Wono) AS WorkOrder, w.DUE_DATE AS DueDate,w.BALANCE AS BalQty,w.OPENCLOS AS STATUS,
        w.kitstatus AS KitStatus, w.kitclosedt AS KitClosedDate,i.Part_No AS AssemblyNumber,i.REVISION,
		COUNT(1) OVER() AS TotalCount FROM WOENTRY w INNER JOIN INVENTOR i ON w.UNIQ_KEY=i.UNIQ_KEY where '
        -- 01/10/2018  -Shripati U :-In search functinality consider the work order status.
		--IF @status <> ''
		--BEGIN
		--12/29/2017  -Shripati U :-Added the filter On basis of the Late on On Hold
		 	SET @SQL = @SQL + '('''+@status+'''=''Open'' and w.OPENCLOS IN (''Open'',''Mfg Hold'',''Admin Hold'') OR '''+@status+'''=''Closed'' and w.OPENCLOS IN(''Closed'',''Cancel'') OR '''+@status+'''=''On Hold'' and w.OPENCLOS IN(''Mfg Hold'',''Admin Hold'') OR '''+@status+'''=''Late'' and w.OPENCLOS IN(''Open'') and w.DUE_DATE < GETDATE()) '
		--END
		-- 01/04/2018  -Shripati U :-Search the Work Order on basis of Work Order, Assembly No, Sales Order, Customer
		IF @assemblyNumber <> ''
	    BEGIN			 
			SET @SQL = @SQL + 'and (i.PART_NO like ''%'+@assemblyNumber+'%'')'				
		END  
		ELSE IF @soNo <> ''
	    BEGIN			 
			SET @SQL = @SQL + 'and (w.SONO like ''%'+@soNo+'%'')'				
		END  
		ELSE IF @woNo <> ''
	    BEGIN			 
			SET @SQL = @SQL + 'and (w.WONO like ''%'+@woNo+'%'')'				
		END  
		ELSE IF @custName <> ''
	    BEGIN			 
			SET @SQL = @SQL + 'and (w.custno IN (select custno from customer where custname like ''%'+@custName+'%''))'				
		END 
   	 	IF @sortExpression <> ''
	    BEGIN
			SET @SQL = @SQL + 'ORDER BY ' +@sortExpression+' OFFSET '+CONVERT(VARCHAR,@skip)+' ROWS FETCH NEXT ('+CONVERT(varchar,@pageSize)+') ROWS ONLY;'
		END
		ELSE 
	    BEGIN
			SET @SQL = @SQL + 'ORDER BY WorkOrder OFFSET '+CONVERT(VARCHAR,@skip)+' ROWS FETCH NEXT ('+CONVERT(VARCHAR,@pageSize)+') ROWS ONLY;'
		END
		
		EXEC SP_EXECUTESQL @SQL		
END