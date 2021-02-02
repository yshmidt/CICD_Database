CREATE TABLE [dbo].[GLRELEASED] (
    [GLRELUNIQUE]     CHAR (10)        CONSTRAINT [DF__GLRELEASE__GLUNI__683E5C36] DEFAULT ('') NOT NULL,
    [TRANS_DT]        SMALLDATETIME    NULL,
    [PERIOD]          NUMERIC (2)      CONSTRAINT [DF__GLRELEASE__PERIO__6932806F] DEFAULT ((0)) NOT NULL,
    [FY]              CHAR (4)         CONSTRAINT [DF__GLRELEASED__FY__6A26A4A8] DEFAULT ('') NOT NULL,
    [GL_NBR]          CHAR (13)        CONSTRAINT [DF__GLRELEASE__GL_NB__6C0EED1A] DEFAULT ('') NOT NULL,
    [DEBIT]           NUMERIC (14, 2)  CONSTRAINT [DF__GLRELEASE__DEBIT__6D031153] DEFAULT ((0)) NOT NULL,
    [CREDIT]          NUMERIC (14, 2)  CONSTRAINT [DF__GLRELEASE__CREDI__6DF7358C] DEFAULT ((0)) NOT NULL,
    [SAVEINIT]        CHAR (8)         CONSTRAINT [DF__GLRELEASE__SAVEI__6EEB59C5] DEFAULT ('') NULL,
    [CIDENTIFIER]     CHAR (30)        CONSTRAINT [DF__GLRELEASE__CIDEN__70D3A237] DEFAULT ('') NOT NULL,
    [LPOSTEDTOGL]     BIT              CONSTRAINT [DF__GLRELEASE__LPOST__71C7C670] DEFAULT ((0)) NOT NULL,
    [CDRILL]          VARCHAR (50)     CONSTRAINT [DF__GLRELEASE__CDRIL__72BBEAA9] DEFAULT ('') NOT NULL,
    [TransactionType] VARCHAR (50)     CONSTRAINT [DF__GLRELEASE__SOURC__6B1AC8E1] DEFAULT ('') NOT NULL,
    [SourceTable]     VARCHAR (25)     CONSTRAINT [DF__GLRELEASE__CTRAN__6FDF7DFE] DEFAULT ('') NOT NULL,
    [SourceSubTable]  VARCHAR (25)     CONSTRAINT [DF_GLRELEASED_SourceSubTable] DEFAULT ('') NOT NULL,
    [cSubIdentifier]  CHAR (30)        CONSTRAINT [DF_GLRELEASED_cSubIdentifier] DEFAULT ('') NOT NULL,
    [cSubDrill]       VARCHAR (50)     CONSTRAINT [DF_GLRELEASED_cSubDrill] DEFAULT ('') NOT NULL,
    [fk_fydtluniq]    UNIQUEIDENTIFIER NULL,
    [GroupIdNumber]   INT              CONSTRAINT [DF_GLRELEASED_GroupIdNumber] DEFAULT ((0)) NOT NULL,
    [ReleaseDate]     SMALLDATETIME    CONSTRAINT [DF_GLRELEASED_ReleasedDate] DEFAULT (getdate()) NULL,
    [ATDUNIQ_KEY]     CHAR (10)        CONSTRAINT [DF__GLRELEASE__ATDUN__0547113D] DEFAULT ('') NOT NULL,
    [DebitPR]         NUMERIC (14, 2)  CONSTRAINT [DF_GLRELEASED_DebitPR] DEFAULT ((0.00)) NOT NULL,
    [CreditPR]        NUMERIC (14, 2)  CONSTRAINT [DF_GLRELEASED_CreditPR] DEFAULT ((0.00)) NOT NULL,
    [FuncFCUsed_uniq] CHAR (10)        CONSTRAINT [DF_GLRELEASED_FuncFCUsed_uniq] DEFAULT ('') NOT NULL,
    [PRFCUsed_uniq]   CHAR (10)        CONSTRAINT [DF_GLRELEASED_PRFCUsed_uniq] DEFAULT ('') NOT NULL,
    CONSTRAINT [GLRELEASED_PK] PRIMARY KEY CLUSTERED ([GLRELUNIQUE] ASC)
);


GO
CREATE NONCLUSTERED INDEX [CTRANSTYPE]
    ON [dbo].[GLRELEASED]([SourceTable] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 11/09/11
-- Description:	Insert Trigger 
-- 05/28/13 YS prevent dynamic @SqlCmd from outputing record set to the output window, using OUT parameter 
-- =============================================
CREATE TRIGGER [dbo].[GlReleased_Insert]
   ON  [dbo].[GLRELEASED] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    DECLARE @TransactionType as varchar(50),@SourceTable as varchar(25),@cIdentifier char(30),@cDrill as varchar(50),@GroupidNumber as integer,
			@SourceSubTable as varchar(25),@cSubIdentifier as char(30),@cSubDrill as varchar(50)
   
    
    DECLARE @SqlCmd as nvarchar(max)
    SELECT @TransactionType=TransactionType,
		   @cIdentifier =CASE WHEN SourceTable<>'GLJEHDR' THEN cIdentifier ELSE 'JEOHKEY' END,
		   @SourceTable=CASE WHEN SourceTable<>'GLJEHDR' THEN SourceTable ELSE 'GLJEHDRO' END,
		   @cDrill=cDrill, 
		   @GroupidNumber = GroupidNumber,
		   @SourceSubTable=CASE WHEN SourceSubTable<>'GLJEHDR' THEN SourceSubTable ELSE 'GLJEHDRO' END,
		   @cSubIdentifier = CASE WHEN SourceTable<>'GLJEHDR' THEN cSubIdentifier ELSE 'JEODKEY' END,
		   @cSubDrill = cSubDrill 
		   FROM Inserted
	
	
   -- build SqlCmd here. All the tables that have to be updated for the GL release flag will have the same name is_rel_gl.
   BEGIN TRANSACTION
   IF (@GroupidNumber=1)
   BEGIN
		-- build a command to check if already released
		DECLARE @nCount int=0
 
			
		
		--SET @SqlCmd=N'SELECT '+@cIdentifier +' FROM '+@SourceTable +' where '+@cIdentifier+'='''+LTRIM(RTRIM(@CDRILL))+''' and '+LTRIM(rtrim(@SourceTable))+'.is_rel_gl=0'
		SET @SqlCmd=N'SELECT @nCount=COUNT(*) FROM '+@SourceTable +' where '+@cIdentifier+'='''+LTRIM(RTRIM(@CDRILL))+''' and '+LTRIM(rtrim(@SourceTable))+'.is_rel_gl=0'
		--execute sp_executesql @SqlCmd
		execute sp_executesql @SqlCmd,N'@nCount int out',@nCount out
		
		--IF @@ROWCOUNT =0
		IF @nCount=0
		BEGIN
			RAISERROR('Some of the records were already released. The trnasaction is cancelled',1,1)
			ROLLBACK TRANSACTION
		END
		ELSE
		BEGIN
			-- build a command to update released flag
			SET @SqlCmd='Update '+@SourceTable+' SET IS_REL_GL = 1'+CASE WHEN @TransactionType ='PURCH' 
																	THEN ',ApStatus = CASE WHEN Apmaster.Paid=''Y'' THEN  ''Paid/Rel to GL'' ELSE ''Released to GL'' END' 
																	ELSE '' END +' WHERE '+LTRIM(rtrim(@SourceTable))+'.'+@cIdentifier+'='''+@CDRILL +''''  
			execute sp_executesql @SqlCmd
				
		END
	END	--IF (SELECT GroupidNumber from inserted)=1
	IF (@GroupidNumber<>1 AND @TransactionType='SALES' and @SourceSubTable='Invt_isu')
	BEGIN	
		-- for the sales need to update Invt_isu table's flag
		SET @SqlCmd='Update '+@SourceSubTable+' SET IS_REL_GL = 1 WHERE '+LTRIM(rtrim(@SourceSubTable))+'.'+@cSubIdentifier+'='''+@CSUBDRILL +''''  
		execute sp_executesql @SqlCmd
	END
	IF (@TransactionType='DM' and @SourceSubTable='APMASTER')  -- manaul DM need to update flag in apmaster table
	BEGIN	
		-- for the sales need to update Invt_isu table's flag
		SET @SqlCmd='Update '+@SourceSubTable+' SET IS_REL_GL = 1 WHERE '+LTRIM(rtrim(@SourceSubTable))+'.'+@cSubIdentifier+'='''+@CSUBDRILL +''''  
		execute sp_executesql @SqlCmd
	END
	
	COMMIT
	END
	
 
