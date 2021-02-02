

CREATE PROCEDURE [dbo].[BkAdDetlView]
	-- Add the parameters for the stored procedure here
	@gcUniqBkAdmn as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- 07/13/15 VL added FC fields
	-- 02/15/17 VL added functinal currency code
    -- Insert statements for procedure here
	SELECT Bkaddetl.fk_uniqbkadmn, Bkaddetl.uniqbkaddt, Bkaddetl.item_no,
  Bkaddetl.item_desc, Bkaddetl.item_total, Bkaddetl.gl_nbr,
  GL_NBRS.Gl_Descr, Bkaddetl.item_totalFC, Bkaddetl.item_totalPR
 FROM 
     bkaddetl 
    LEFT OUTER JOIN GL_NBRS 
   ON  Bkaddetl.Gl_nbr = GL_NBRS.gl_Nbr
 WHERE  Bkaddetl.fk_uniqbkadmn = @gcUniqBkAdmn
END