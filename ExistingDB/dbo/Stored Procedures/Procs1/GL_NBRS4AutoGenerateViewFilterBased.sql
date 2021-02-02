-- =============================================
-- Author:		Nilesh Sa
-- Create date: 11/21/2017
-- Description: Fetch the GL_Nbrs details for which Account is not Auto Generated based on the division/dept and low and high range provided.
-- 11/22/2017 Nilesh Sa Added Column gl_class,gl_descr,Long_descr in select 
-- =============================================
CREATE PROCEDURE [dbo].[GL_NBRS4AutoGenerateViewFilterBased]
	-- Add the parameters for the stored procedure here
	@pLow char(10) = ' ',
	@pHigh char(10) = ' ',
	@status char(8)='Active',
	@subStringDivision char(2)='',
	@subStringDepartment char(2)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		 SELECT
	     DISTINCT  CONCAT (LEFT(GL_NBR,7),'-',@subStringDivision,'-',@subStringDepartment) AS gl_nbr,
		 -- 11/22/2017 Nilesh Sa Added Column gl_class,gl_descr,Long_descr in select 
		 gl_descr,gl_class,gl_descr,Long_descr
		 FROM GL_NBRS  
	     WHERE LEFT(GL_NBR, 7) BETWEEN @pLow AND @pHigh 
		 AND STATUS = @status 
		 AND LEFT(GL_NBR,7) NOT IN (SELECT  LEFT(GL_NBR,7)  
		 FROM GL_NBRS  WHERE SUBSTRING(GL_NBR,9,2) = @subStringDivision AND RIGHT(GL_NBR,2) = @subStringDepartment ) 
END