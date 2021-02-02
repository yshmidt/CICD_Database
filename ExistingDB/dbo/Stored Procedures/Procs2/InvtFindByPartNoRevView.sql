
CREATE PROCEDURE [dbo].[InvtFindByPartNoRevView]
	-- Add the parameters for the stored procedure here
	--- 03/28/17 YS changed length of the part_no column from 25 to 35, revision 8
	@gcPart_no as char(35) = ' ', @gcRevision as char(8) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Part_no
		from Inventor
		where part_no = @gcPart_no 
			and Revision = @gcRevision
END