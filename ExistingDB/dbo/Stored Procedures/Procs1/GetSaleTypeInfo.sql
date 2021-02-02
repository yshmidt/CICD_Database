-- =============================================    
-- Author:  Sachin B    
-- Create date: 09/18/2019    
-- Description: Getting Sale Type Information
-- GetSaleTypeInfo  
CREATE PROC [dbo].[GetSaleTypeInfo]      
AS    
BEGIN  

SET NOCOUNT ON;  
	SELECT s.SALETYPEID,CONCAT(glnbr1.GL_NBR,' (', TRIM(glnbr1.GL_DESCR),')') AS  GL_NBR, glnbr1.GL_NBR AS RevenueGLNo,
	 CONCAT(COG_GL_NBR,' (', TRIM(glnbr1.GL_DESCR),')') AS  COG_GL_NBR, COG_GL_NBR AS CostGLNo, UNIQUENUM,
	glnbr1.GLTYPE AS RevenueGLType,glnbr2.GLTYPE AS CostGlType  
	FROM SALETYPE s
	LEFT JOIN Gl_nbrs glnbr1 ON s.GL_NBR = glnbr1.GL_NBR
	LEFT JOIN Gl_nbrs glnbr2 ON  s.COG_GL_NBR = glnbr2.GL_NBR 
END