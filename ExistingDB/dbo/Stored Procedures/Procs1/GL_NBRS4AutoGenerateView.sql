-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <11/05/2009>
-- Description:	<Procedure will accept low and high range for the first 7 digits of the gl number and
-- produce a set of records with all the values for the selected GL_nbr
-- the chanlange is to select only first gl_nbr that matches first seven digits
-- for example if we have records with the following numbers 
-- '4400000-00-00', '4400000-01-01', '4400000-02-01'
-- only records for the '4400000-00-00' is included  
-- =============================================
CREATE PROCEDURE dbo.GL_NBRS4AutoGenerateView 
	-- Add the parameters for the stored procedure here
	@pLow char(7),@pHigh char(7)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT gl_nbr,gl_class,gl_descr,Long_descr,Tot_start,Tot_end 
		FROM gl_nbrs gn1 
		WHERE LEFT(gn1.Gl_nbr, 7) BETWEEN @pLow AND @pHigh 
		AND gn1.gl_nbr IN 
			(SELECT TOP 1 gn2.gl_nbr FROM gl_nbrs gn2 
				WHERE  LEFT(gn2.Gl_nbr, 7)=LEFT(Gn1.Gl_nbr,7) order by gn2.gl_nbr)

	--SELECT <@Param1, sysname, @p1>, <@Param2, sysname, @p2>
END
