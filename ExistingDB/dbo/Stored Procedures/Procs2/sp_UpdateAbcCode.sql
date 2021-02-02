-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/05/2009
-- Description:	This procedure will take ABC code precalculated and saved in the TempAbc Table
-- and populate Inventor.Abc field with it.
-- =============================================
CREATE PROCEDURE [dbo].[sp_UpdateAbcCode]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRAN
		UPDATE Inventor SET ABC=TempAbc.Abc FROM TempAbc WHERE TempAbc.Uniq_key=Inventor.Uniq_key
		DELETE FROM TempAbc WHERE 1=1
	COMMIT TRAN
  END TRY
  BEGIN CATCH
	ROLLBACK TRAN
  END CATCH		
END