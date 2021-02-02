CREATE TABLE [dbo].[GLTRANSHEADER] (
    [GLTRANSUNIQUE]   CHAR (10)        CONSTRAINT [DF__GLTRANSHEADER__GLTRANSUNIQUE] DEFAULT ('') NOT NULL,
    [TransactionType] VARCHAR (50)     CONSTRAINT [DF_GLTRANSHEADER_TransactionType] DEFAULT ('') NOT NULL,
    [SourceTable]     VARCHAR (25)     CONSTRAINT [DF_GLTRANSHEADER_SourceTable] DEFAULT ('') NOT NULL,
    [cIdentifier]     CHAR (30)        CONSTRAINT [DF_GLTRANSHEADER_cIdentifier] DEFAULT ('') NOT NULL,
    [POST_DATE]       SMALLDATETIME    CONSTRAINT [DF_GLTRANSHEADER_POST_DATE] DEFAULT (getdate()) NULL,
    [TRANS_NO]        INT              CONSTRAINT [DF__GLTRANSHEADER__TRANS_NO] DEFAULT ((0)) NOT NULL,
    [TRANS_DT]        SMALLDATETIME    NULL,
    [PERIOD]          NUMERIC (2)      CONSTRAINT [DF__GLTRANSHEADER__PERIOD] DEFAULT ((0)) NOT NULL,
    [FY]              CHAR (4)         CONSTRAINT [DF__GLTRANSHEADER__FY] DEFAULT ('') NOT NULL,
    [SAVEINIT]        CHAR (8)         CONSTRAINT [DF__GLTRANSHEADER__SAVEINIT] DEFAULT ('') NOT NULL,
    [fk_fydtluniq]    UNIQUEIDENTIFIER NULL,
    [FuncFCUsed_uniq] CHAR (10)        CONSTRAINT [DF_GLTRANSHEADER_FuncFCUsed_uniq] DEFAULT ('') NOT NULL,
    [PRFCUsed_uniq]   CHAR (10)        CONSTRAINT [DF_GLTRANSHEADER_PRFCUsed_uniq] DEFAULT ('') NOT NULL,
    [saveUserId]      UNIQUEIDENTIFIER NULL,
    CONSTRAINT [GLTRANSHEADER_PK] PRIMARY KEY CLUSTERED ([GLTRANSUNIQUE] ASC)
);


GO
CREATE NONCLUSTERED INDEX [fk_fydtluniq]
    ON [dbo].[GLTRANSHEADER]([fk_fydtluniq] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 11/30/2011
-- Description:	Insert trigger for GltransHeader table will populate Trans_no here
-- Modification:
--	01/03/17 VL Added PrFcused_uniq and FuncFcused_uniq for functional currency project
-- 09/13/19 YS modify trigger to allow more than one record insert
-- =============================================
CREATE TRIGGER [dbo].[GltransHeader_Insert]
   ON  [dbo].[GLTRANSHEADER]
   INSTEAD OF INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    DECLARE @Trans_no as int,@GlTRansUnique as char(10),@nRowCount int,@nCounter int,@Jeno [numeric](6,0),
		@TransactionType as varchar(50),@SourceTable as varchar(25),@cIdentifier as char(30) ,
		--09/13/19 YS add userid as uniqueidentifier
		--09/13/19 YS added @GLTRANSUNIQUE
		@saveUserId uniqueidentifier
		--@SaveInit as char(8)
--09/13/19 YS add error handling
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;	
	
	
-- 09/13/19 YS use cursor to allow multiple records to be inserted at once
BEGIN TRY
BEGIN TRANSACTION
	DECLARE cTransHeader CURSOR LOCAL FAST_FORWARD
	FOR
	SELECT  TransactionType,
			SourceTable,
			cIdentifier , 
			SaveUserId ,
			GLTRANSUNIQUE
			FROM inserted

	OPEN cTransHeader;
	FETCH NEXT FROM cTransHeader INTO @TransactionType,@SourceTable,@cIdentifier,@saveUserId,@GLTRANSUNIQUE ;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		execute GetNextGLTransNumber @Trans_no OUTPUT
		INSERT INTO [GLTRANSHEADER]
           ([GLTRANSUNIQUE]
           ,[TransactionType]
           ,[SourceTable]
           ,[cIdentifier]
           ,[TRANS_NO]
           ,[TRANS_DT]
           ,[PERIOD]
           ,[FY]
           ,[SAVEINIT]
           ,[fk_fydtluniq]
		   ,[PrFcused_uniq]
		   ,[FuncFcused_uniq])
     SELECT
           GLTRANSUNIQUE 
           ,TransactionType
           ,inserted.SourceTable
           ,CASE WHEN inserted.SourceTable='GLJEHDR' THEN 'UNIQJEHEAD' ELSE Inserted.cIdentifier END
           ,@Trans_no
           ,TRANS_DT
           ,PERIOD
           ,FY
           ,SAVEINIT
           ,fk_fydtluniq
		   ,PrFcused_uniq
		   ,FuncFcused_uniq FROM INSERTED where inserted.GLTRANSUNIQUE= @GlTRansUnique;


		FETCH NEXT FROM cTransHeader INTO @TransactionType,@SourceTable,@cIdentifier,@saveUserId,@GLTRANSUNIQUE ;
	END --WHILE @@FETCH_STATUS = 0
	CLOSE cTransHeader;
	DEALLOCATE cTransHeader;
IF @@TRANCOUNT>0
COMMIT
END TRY
BEGIN CATCH
IF @@TRANCOUNT>0
		ROLLBACK
		SELECT @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();
		RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );

END CATCH
/* old code
SELECT @TransactionType = TransactionType,
			   @SourceTable=SourceTable,
			   @cIdentifier=cIdentifier , 
			   @SaveInit = SaveInit FROM inserted

    execute GetNextGLTransNumber @Trans_no OUTPUT
	INSERT INTO [GLTRANSHEADER]
           ([GLTRANSUNIQUE]
           ,[TransactionType]
           ,[SourceTable]
           ,[cIdentifier]
           ,[TRANS_NO]
           ,[TRANS_DT]
           ,[PERIOD]
           ,[FY]
           ,[SAVEINIT]
           ,[fk_fydtluniq]
		   ,[PrFcused_uniq]
		   ,[FuncFcused_uniq])
     SELECT
           GLTRANSUNIQUE 
           ,TransactionType
           ,inserted.SourceTable
           ,CASE WHEN inserted.SourceTable='GLJEHDR' THEN 'UNIQJEHEAD' ELSE Inserted.cIdentifier END
           ,@Trans_no
           ,TRANS_DT
           ,PERIOD
           ,FY
           ,SAVEINIT
           ,fk_fydtluniq
		   ,PrFcused_uniq
		   ,FuncFcused_uniq FROM INSERTED ;
    */       
   

	
END