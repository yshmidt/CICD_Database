-- =============================================
-- Author:		Anuj Kumar
-- Create date: 5/7/2012
-- Description:	add error information
-- 05/15/15 YS added begin/commit transaction
--05/15/15 YS added import id column to the table
-- =============================================
CREATE PROCEDURE [dbo].[importSupplierMpnErrorAdd] 
	-- Add the parameters for the stored procedure here
--05/15/15 YS added import id column to the table
	@errNumber int,@errSeverity int,@errProc VARCHAR(MAX),@errLine int,@errMsg VARCHAR(MAX),@importid uniqueidentifier 
AS
BEGIN
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	BEGIN TRANSACTION
	--05/15/15 YS added importid column
	INSERT INTO [dbo].[importSupplierMpnLinkerror]
           ([erroId]
           ,[errNumber]
           ,[errSeverity]
           ,[errProc]
           ,[errLine]
           ,[errMsg]
           ,[errDate]
		   ,importid
		   )
		VALUES
           (
		    NEWID()
           ,@errNumber
		   ,@errSeverity
		   ,@errProc
		   ,@errLine
		   ,@errMsg
		   ,GETDATE()
		   ,@importid)
	IF @@TRANCOUNT>0
	COMMIT
END