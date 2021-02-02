-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 04/29/2013
-- Description:	Maintenance Script to run after update script when manex version number has to be changed
-- all maintenance scripts will start with spMNT 
-- =============================================
CREATE PROCEDURE dbo.spMntManexVersionChange
	-- Add the parameters for the stored procedure here
	@manexverno varchar(20) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	IF @manexverno IS NULL
		print 'Need to update manexverno'
	else --@manexverno IS NULL
	begin	
		-- Insert statements for procedure here
		BEGIN TRANSACTION
		UPDATE MICSSYS set MANEXVERNO = @manexverno 
		COMMIT
	end	--- @manexverno IS NULL
END
