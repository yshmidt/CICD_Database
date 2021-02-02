-- =============================================
-- Author:		Yelena Shmidt	
-- Create date: <01/10/2011>
-- Description:	<porejlocview>
-- Modified: 05/15/14 YS added sourcedev column to porecdtl = 'D' when updated from desktop
-- =============================================
CREATE PROCEDURE [dbo].[porejlocview]
	-- Add the parameters for the stored procedure here
	@lcuniqrecdtl char(10) =' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT DISTINCT Porecloc.accptqty, Porecloc.uniqdetno,
		Porecloc.loc_uniq, Porecloc.receiverno, Porecloc.sdet_uniq,
		Porecloc.sinv_uniq, Porecloc.rejqty, Porecloc.fk_uniqrecdtl,
		Poitschd.schd_date, Poitschd.req_date, Poitschd.balance, Poitschd.gl_nbr,
		Poitschd.requesttp, Poitschd.requestor,
		Porecloc.accptqty-0 AS old_accptqty,
		Porecloc.accptqty-Porecloc.accptqty AS retlocqty,Porecloc.uniqwh,
		ISNULL(Warehous.whno,'   ') AS whno, SPACE(10) AS w_key,
		ISNULL(Warehous.warehouse,SPACE(6)) AS warehouse, Porecloc.location,Porecloc.sourceDev,
		CAST(1 as bit) AS lFilter
	FROM poitschd INNER JOIN porecloc 
    LEFT OUTER JOIN warehous 
	ON  Porecloc.uniqwh = Warehous.uniqwh 
	ON  Poitschd.uniqdetno = Porecloc.uniqdetno
	WHERE  Porecloc.fk_uniqrecdtl = ( @lcuniqrecdtl )
	ORDER BY Poitschd.schd_date
END