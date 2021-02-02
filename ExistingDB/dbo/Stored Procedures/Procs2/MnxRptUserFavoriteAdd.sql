		-- =============================================
		-- Author:		David Sharp
		-- Create date: 5/3/2013
		-- Description:	Adds a report to User Favorites
		-- =============================================
		CREATE PROCEDURE [dbo].[MnxRptUserFavoriteAdd] 
			-- Add the parameters for the stored procedure here
			@rptId char(10), 
			@userId uniqueidentifier
		AS
		BEGIN
			-- SET NOCOUNT ON added to prevent extra result sets from
			-- interfering with SELECT statements.
			SET NOCOUNT ON;

			-- Insert statements for procedure here
			INSERT INTO wmReportsUserFavorites (fkRptId,fkUserId)
			VALUES(@rptId, @userId)
		END