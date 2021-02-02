-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/02/14
-- Description:	Save all wono that were used in the last MRP and update woentry  table
-- =============================================
CREATE PROCEDURE mrpWoentry
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT wono,inLastMrp  from woentry where 1=0
END