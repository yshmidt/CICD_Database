CREATE PROCEDURE [dbo].[SupplierDetailView]
       -- Add the parameters for the stored procedure here
       @gcUniqSupNo as Char(10)=''
AS
-- 01/19/15 VL added Ad_link, Tax_id and Fcused_uniq
BEGIN
       -- SET NOCOUNT ON added to prevent extra result sets from
       -- interfering with SELECT statements.
       SET NOCOUNT ON;

   -- Insert statements for procedure here
       SELECT Terms, R_Link, C_link, Acctno, Status, Ad_link, Tax_id, Fcused_uniq
       from SupInfo
       where UniqSupno = @gcUniqSupNo
END