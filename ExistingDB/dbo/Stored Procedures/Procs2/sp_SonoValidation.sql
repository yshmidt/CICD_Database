		-- =============================================
		-- Author:		Vicky Lu
		-- Create date: 04/18/13 
		-- Description:	This procedure will return the Sono from @ltSono that already exist in Somain table
		-- =============================================
		CREATE PROCEDURE [dbo].[sp_SonoValidation] 
			@ltSono AS tSono READONLY
		AS
		BEGIN
		-- SET NOCOUNT ON added to prevent extra result sets from
		-- interfering with SELECT statements.
		SET NOCOUNT ON;
			SELECT Sono 
				FROM @ltSono
				WHERE Sono IN 
					(SELECT Sono 
						FROM SOMAIN)
		END