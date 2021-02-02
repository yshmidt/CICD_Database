-- ==========================================================================================    
-- Modifications: 01/15/2014 DRP:  added the @userid parameter for WebManex     
-- 02/04/16 YS added cashFlow column (logical) to gl_nbrs table. To indocate that account should included in the cash flow statement    
-- 02/17/16 YS changed cashflow to cashflowcode    
-- 06/05/2020 Satyawan added filter and sorting ability in the SP.
-- -EXEC [Gl_nbrsView]   
-- ==========================================================================================    
CREATE PROC [dbo].[Gl_nbrsView]     
	@userId uniqueidentifier = NULL, 
	@filter NVARCHAR(1000) = NULL,  
	@sortExpression NVARCHAR(1000) = NULL  
AS    
BEGIN  
	DECLARE @sqlQuery NVARCHAR(MAX),@qryMain NVARCHAR(MAX);         
	DECLARE @rowCount INT  
  
	--SELECT Gl_nbrs.gl_nbr,Gl_nbrs.gl_class,Gl_nbrs.gl_descr,    
	--Gl_nbrs.long_descr,Gl_nbrs.gltype,Gl_nbrs.stmt,Gl_nbrs.status,    
	--Gl_nbrs.gl_note,Gl_nbrs.tot_start,    
	--Gl_nbrs.tot_end, Gl_nbrs.curr_bal, Gl_nbrs.mtd_bal,Gl_nbrs.glis_post,    
	--Gltypes.glTypeDesc,GlTypes.lo_limit,Gltypes.Hi_limit    
	SELECT Gltypes.glTypeDesc,Gl_nbrs.gltype,Gl_nbrs.gl_nbr,Gl_nbrs.long_descr,Gl_nbrs.stmt,
		Gl_nbrs.gl_class,Gl_nbrs.[status],Gl_nbrs.gl_note,Gl_nbrs.gl_descr,Gl_nbrs.tot_start,
		Gl_nbrs.tot_end, Gl_nbrs.curr_bal,Gl_nbrs.mtd_bal,Gl_nbrs.glis_post,GlTypes.lo_limit,
		Gltypes.Hi_limit  
	INTO #GLNumbersView    
	FROM gl_nbrs   
	INNER JOIN gltypes ON Gl_nbrs.gltype=gltypes.gltype   
	ORDER BY gl_nbr;  

	-- 06/05/2020 Satyawan added filter and sorting ability in the SP.
	IF TRIM(ISNULL(@filter,'')) <> '' AND TRIM(ISNULL(@sortExpression,'')) <> ''    
	BEGIN    
		SET @qryMain='SELECT * FROM(SELECT * FROM #GLNumbersView)a  WHERE ' + @filter + ' ORDER BY '+ @sortExpression    
	END    
	ELSE IF TRIM(ISNULL(@filter,'')) = '' AND TRIM(ISNULL(@sortExpression,'')) <> ''    
	BEGIN    
		SET @qryMain='SELECT * FROM(SELECT * FROM #GLNumbersView)a  ORDER BY '+ @sortExpression  
	END    
	ELSE IF TRIM(ISNULL(@filter,'')) <> '' AND TRIM(ISNULL(@sortExpression,'')) = ''    
	BEGIN   
		SET @qryMain='SELECT * FROM(SELECT * FROM #GLNumbersView)a WHERE ' +@filter  
	END    
	ELSE    
	BEGIN  
		SET @qryMain='SELECT * FROM(SELECT * FROM #GLNumbersView)a'  
	END    

	EXEC sp_executesql @qryMain  
END