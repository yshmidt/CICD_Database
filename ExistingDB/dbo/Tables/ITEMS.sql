CREATE TABLE [dbo].[ITEMS] (
    [SCREENNAME] CHAR (8)       CONSTRAINT [DF_ITEMS_SCREENNAME] DEFAULT ('') NOT NULL,
    [SCREENDESC] CHAR (100)     CONSTRAINT [DF_ITEMS_SCREENDESC] DEFAULT ('') NOT NULL,
    [Installed]  BIT            CONSTRAINT [DF_ITEMS_INSTALLED] DEFAULT ((0)) NOT NULL,
    [DEPTS]      CHAR (4)       CONSTRAINT [DF_ITEMS_DEPTS] DEFAULT ('') NOT NULL,
    [NUMBER]     NUMERIC (4)    CONSTRAINT [DF_ITEMS_NUMBER] DEFAULT ((0)) NOT NULL,
    [APP]        CHAR (20)      CONSTRAINT [DF_ITEMS_APP] DEFAULT ('') NOT NULL,
    [UNIQUENUM]  INT            IDENTITY (1, 1) NOT NULL,
    [SqlAddress] VARBINARY (64) CONSTRAINT [DF_ITEMS_Modaddress] DEFAULT (CONVERT([varbinary](64),'',(0))) NOT NULL,
    [WebAddress] VARCHAR (MAX)  CONSTRAINT [DF_ITEMS_WebAddress] DEFAULT ('') NOT NULL,
    [hasModule]  BIT            CONSTRAINT [DF_ITEMS_hasModule] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [ITEMS_PK] PRIMARY KEY CLUSTERED ([UNIQUENUM] ASC)
);


GO
CREATE NONCLUSTERED INDEX [BYDEPT]
    ON [dbo].[ITEMS]([DEPTS] ASC);


GO
CREATE NONCLUSTERED INDEX [BYSCRN]
    ON [dbo].[ITEMS]([SCREENNAME] ASC);


GO
CREATE NONCLUSTERED INDEX [NUMBER]
    ON [dbo].[ITEMS]([NUMBER] ASC);


GO

-- =============================================
-- Author:		Yelena Shmidt	
-- Create date: 04/28/2015 (Happy BD Glynn)
-- Description:	Auto update mnxFileCabinet when new record is inserted
-- =============================================
CREATE TRIGGER [dbo].[Items_insert]
   ON [dbo].[ITEMS]
   AFTER  INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for trigger here
	INSERT INTO [dbo].[mnxFileCabinet]
           ([FileName]
           ,[FileType]
           ,[UploadDate]
           ,[InternalOnly]
           ,[moduleid]
           ,[sequence])
     SELECT
           Inserted.SCREENDESC
           ,1
           ,getdate()
           ,0
           ,Inserted.UNIQUENUM
           ,Inserted.NUMBER
		   FROM Inserted

END
