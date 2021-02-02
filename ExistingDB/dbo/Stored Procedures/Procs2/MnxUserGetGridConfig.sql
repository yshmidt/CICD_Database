-- =============================================
-- Author:		David Sharp
-- Create date: 2/8/2012
-- Description:	returns grid personalization if it exists
-- =============================================
CREATE PROCEDURE [dbo].[MnxUserGetGridConfig]
	@userId uniqueidentifier = null, @gridId varchar(50) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF @userId = NULL OR @gridId = NULL
		SELECT '' AS gridConfig 
	ELSE
		SELECT colModel, colNames, groupedCol FROM wmUserGridConfig WHERE userId = @userId AND gridId = @gridId
END
