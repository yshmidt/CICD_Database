-- =============================================
-- Author:		Debbie	
-- Create date:	02/20/2015
-- Description:	procedure to compile list of  GL Numbers for the report's parameters
-- Modified:		
-- =============================================
create PROCEDURE [dbo].[getParamsAllGlNbrs] 
--declare
	@paramFilter varchar(200) = '',		--- first 3+ characters entered by the user
	@top int = null,							-- if not null return number of rows indicated
	@showrevision bit =1,
	@userId uniqueidentifier = null

AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
   	if (@top is not null)
		select distinct  top(@top) gl_nbr as Value, cast(gl_nbr+'     '+rtrim(gltype)+'   '+rtrim(gl_descr) as varchar(50))  AS Text 
		from	GL_NBRS
		WHERE	1 = case when @paramFilter is null then 1 else case when GL_NBR like @paramFilter+ '%' then 1 else 0 end end
		
	else
		select distinct	gl_nbr as Value, cast(gl_nbr+'     '+rtrim(gltype)+'   '+rtrim(gl_descr) as varchar(50)) as text
		from	GL_NBRS
		WHERE	1 = case when @paramFilter is null then 1 else case when GL_NBR like @paramFilter+ '%' then 1 else 0 end end

		
END