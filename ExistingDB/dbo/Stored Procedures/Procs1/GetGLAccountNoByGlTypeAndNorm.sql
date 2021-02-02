-- =============================================    
-- Author:  Sachin B    
-- Create date: 09/18/2019    
-- Description: Getting  Revenue GL Account Number on gl type and Norm selection 
-- Satyawan H 04/16/2020 : Selected two more fields Type and Status 
-- Satyawan H 04/16/2020 : Modified @glType to get all records enven if it is not provided i.e. empty or null 
-- GetGLAccountNoByGlTypeAndNorm 'SAL','CR', '4010020-00' 
--======================================================  
CREATE PROC [dbo].[GetGLAccountNoByGlTypeAndNorm]    
	@glType AS CHAR(10) = '',
	@balNorm AS CHAR(2) = '',
	@revenueOrCostGLNoFltr AS nVarchar(MAX) = NULL
AS    
BEGIN  
	SET NOCOUNT ON;  
  
	SELECT CONCAT(g.Gl_nbr, ' (',TRIM(GL_DESCR),')') AS Value
	-- Satyawan H 04/16/2020 : Selected two more fields Type and Status 
	,g.Gl_nbr AS Id, t.GLTYPE AS [Type], [Status] AS Status  
	FROM Gl_nbrs G
		INNER JOIN Gltypes T ON g.gl_nbr BETWEEN t.LO_LIMIT AND t.HI_LIMIT AND g.GLTYPE=t.GLTYPE
		WHERE gl_class = 'Posting' 
		AND [Status] = 'Active' AND t.Stmt = 'INC' AND t.NORM_BAL=@balNorm 
		-- Satyawan H 04/16/2020 : Modified @glType to get all records enven if it is not provided i.e. empty or null 
		--AND t.GLTYPE=@glType 
		AND (t.GLTYPE=@glType  OR ISNULL(TRIM(@glType),'')='')
		AND [Gl_nbr] LIKE  CASE WHEN (@revenueOrCostGLNoFltr IS NOT NULL) 
							THEN  '%'+@revenueOrCostGLNoFltr+'%'
							ELSE Gl_nbr END
	ORDER BY Gl_nbr
END