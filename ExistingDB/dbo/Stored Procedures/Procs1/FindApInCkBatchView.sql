CREATE PROCEDURE dbo.FindApInCkBatchView
 
	-- Add the parameters for the stored procedure here
@gcUniqApHead as char(10) = ''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


    -- Insert statements for procedure here
SELECT fk_uniqaphead,is_Closed
  	FROM apbatdet
	inner join  ApBatch 
    on ApBatDet.BatchUniq = ApBatch.BatchUniq
    where ApBatDet.fk_uniqaphead = @gcUniqApHead
		AND Is_Closed = 0 

END