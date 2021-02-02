-- =============================================
-- Author:		David Sharp
-- Create date: 8/27/2012
-- Description:	gets the UDF sections and tables
-- =============================================
CREATE PROCEDURE [dbo].[UDFSectionGet] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT * FROM MnxUdfSections
END