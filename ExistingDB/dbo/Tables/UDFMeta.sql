CREATE TABLE [dbo].[UDFMeta] (
    [metaId]     UNIQUEIDENTIFIER CONSTRAINT [DF_UDFMeta_metId] DEFAULT (newsequentialid()) NOT NULL,
    [udfTable]   VARCHAR (200)    NOT NULL,
    [udfField]   VARCHAR (MAX)    NOT NULL,
    [listString] VARCHAR (MAX)    NULL,
    [dynamicSQL] VARCHAR (MAX)    NULL,
    CONSTRAINT [PK_UDFMeta] PRIMARY KEY CLUSTERED ([metaId] ASC)
);


GO
-- =============================================
-- Author:		Sachin s
-- Create date: 10-19-2015
-- Description:	Force replace for '_' over empty space UDF Field for generic list can not load
-- =============================================
CREATE TRIGGER [dbo].[UDFMeta_Insert]
   ON [dbo].[UDFMeta] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--04/06/15 YS declare variables for the error to raise
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
BEGIN TRANSACTION
BEGIN TRY
		
	UPDATE UDFMeta SET udfField=REPLACE(I.udfField,' ','_')
			FROM inserted I where I.metaId =UDFMeta.metaId  
END TRY
BEGIN CATCH
	SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();
		RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
		IF @@TRANCOUNT <>0
			ROLLBACK TRAN ;
			
END CATCH
	
IF @@TRANCOUNT>0
	COMMIT
		
END
