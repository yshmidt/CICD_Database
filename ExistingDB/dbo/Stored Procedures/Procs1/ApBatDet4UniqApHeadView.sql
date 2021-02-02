-- =============================================
-- Author:		Bill Blake
-- Create date: <Create Date,,>
-- Description:	Check if invoice is part of the existsing batch
-- Modified:	04/04/14 YS include only if batch is open 
-- =============================================
CREATE PROCEDURE [dbo].[ApBatDet4UniqApHeadView]
	-- Add the parameters for the stored procedure here
	@lcUniqApHead as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 04/04/14 YS select only if batch is not closed

	SELECT D.BatchUniq, D.AprPay 
		from APBATDET D inner join Apbatch H On d.BATCHUNIQ =H.BATCHUNIQ  where FK_UNIQAPHEAD = @lcUniqAphead
			and H.IS_CLOSED = 0
END