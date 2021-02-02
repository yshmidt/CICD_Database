		-- =============================================
		-- Author:		David Sharp
		-- Create date: 5/3/2013
		-- Description:	Delete a report from User Favorites
		-- =============================================
		CREATE PROCEDURE [dbo].[MnxRptUserFavoriteDelete]
			-- Add the parameters for the stored procedure here
			@rptId char(10), 
			@userId uniqueidentifier
		AS
		BEGIN
			-- SET NOCOUNT ON added to prevent extra result sets from
			-- interfering with SELECT statements.
			SET NOCOUNT ON;

			-- Insert statements for procedure here
			DELETE FROM wmReportsUserFavorites WHERE fkRptId = @rptId AND fkUserId = @userId
		END