CREATE TABLE [dbo].[WmFileCabinet] (
    [FileId]         BIGINT           IDENTITY (1000, 1) NOT NULL,
    [FileName]       VARCHAR (200)    NOT NULL,
    [Path]           VARCHAR (MAX)    NOT NULL,
    [FileType]       INT              CONSTRAINT [DF_WmFileCabinet_FileType] DEFAULT ((5)) NOT NULL,
    [UploadDate]     SMALLDATETIME    NULL,
    [UploadBy]       UNIQUEIDENTIFIER NOT NULL,
    [InternalOnly]   BIT              CONSTRAINT [DF_WmFileCabinet_InternalOnly] DEFAULT ((0)) NOT NULL,
    [IsDeleted]      BIT              CONSTRAINT [DF_WmFileCabinet_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Alias]          VARCHAR (MAX)    NULL,
    [DeleteDate]     SMALLDATETIME    NULL,
    [DocNameAndNo]   VARCHAR (200)    CONSTRAINT [DF__WmFileCab__DocNa__76BB5CC9] DEFAULT ('') NOT NULL,
    [Description]    VARCHAR (200)    CONSTRAINT [DF__WmFileCab__Descr__77AF8102] DEFAULT ('') NOT NULL,
    [Revision]       VARCHAR (50)     CONSTRAINT [DF__WmFileCab__Revis__78A3A53B] DEFAULT ('') NOT NULL,
    [DocModule]      VARCHAR (50)     CONSTRAINT [DF__WmFileCab__DocMo__7997C974] DEFAULT ('') NOT NULL,
    [DeletedBy]      UNIQUEIDENTIFIER CONSTRAINT [DF__WmFileCab__Delet__7A8BEDAD] DEFAULT (NULL) NULL,
    [ExpirationDate] DATETIME         CONSTRAINT [DF__WmFileCab__Expir__7B8011E6] DEFAULT (NULL) NULL,
    CONSTRAINT [PK_WmFileCabinet] PRIMARY KEY CLUSTERED ([FileId] ASC)
);


GO
CREATE TRIGGER [dbo].[WmFileCabinet_Delete] 
   ON  [dbo].[WmFileCabinet]
   AFTER DELETE
AS 
BEGIN
	SET NOCOUNT ON;    
	-- 05/03/16 Nitesh B Modified the trigger to use multiple row delete
	--Declare @fileId int
	--set @fileId=(SELECT Deleted.FileId from Deleted)
	BEGIN TRANSACTION	
	      -- 05/03/16 Nitesh B Modified the trigger to use multiple row delete		
		  -- Delete from WmFileTree Where ChildId =@fileId
		  Delete from WmFileTree Where  exists (select 1 from Deleted where deleted.FileId  =WmFileTree.ChildId) 
	COMMIT
END