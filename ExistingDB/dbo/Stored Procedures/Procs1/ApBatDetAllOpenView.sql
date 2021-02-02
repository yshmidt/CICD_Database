CREATE PROCEDURE dbo.ApBatDetAllOpenView 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT APBATDET.* 
		from APBATCH, APBATDET 
		where APBATDET.BATCHUNIQ = APBATCH.BATCHUNIQ
		and APBATCH.IS_CLOSED = 0
END