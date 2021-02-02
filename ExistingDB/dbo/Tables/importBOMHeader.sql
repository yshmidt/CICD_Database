CREATE TABLE [dbo].[importBOMHeader] (
    [importId]     UNIQUEIDENTIFIER CONSTRAINT [DF_importBOMHeader_importId] DEFAULT (newid()) NOT NULL,
    [startDate]    SMALLDATETIME    CONSTRAINT [DF_importBOMHeader_startDate] DEFAULT (getdate()) NOT NULL,
    [source]       VARCHAR (200)    CONSTRAINT [DF_importBOMHeader_source] DEFAULT ('') NOT NULL,
    [status]       VARCHAR (20)     CONSTRAINT [DF_importBOMHeader_status] DEFAULT ('started') NOT NULL,
    [completeDate] SMALLDATETIME    NULL,
    [custNo]       VARCHAR (10)     CONSTRAINT [DF_importBOMHeader_custNo] DEFAULT ('') NOT NULL,
    [assyNum]      VARCHAR (35)     CONSTRAINT [DF_importBOMHeader_assyNum] DEFAULT ('') NOT NULL,
    [assyRev]      VARCHAR (8)      CONSTRAINT [DF_importBOMHeader_assyRev] DEFAULT ('') NOT NULL,
    [assyDesc]     VARCHAR (45)     CONSTRAINT [DF_importBOMHeader_assyDesc] DEFAULT ('') NOT NULL,
    [partClass]    VARCHAR (8)      CONSTRAINT [DF_importBOMHeader_partClass] DEFAULT ('') NOT NULL,
    [partType]     VARCHAR (8)      CONSTRAINT [DF_importBOMHeader_partType] DEFAULT ('') NOT NULL,
    [uniq_key]     VARCHAR (10)     CONSTRAINT [DF_importBOMHeader_uniq_key] DEFAULT ('') NOT NULL,
    [message]      VARCHAR (MAX)    CONSTRAINT [DF_importBOMHeader_message] DEFAULT ('') NOT NULL,
    [isValidated]  BIT              CONSTRAINT [DF_importBOMHeader_isValidated] DEFAULT ((0)) NOT NULL,
    [useSetUp]     BIT              CONSTRAINT [DF__importBOM__useSe__16F18B83] DEFAULT ((0)) NOT NULL,
    [stdBldQty]    NUMERIC (8)      CONSTRAINT [DF__importBOM__stdBl__17E5AFBC] DEFAULT ((0)) NOT NULL,
    [startedBy]    UNIQUEIDENTIFIER NULL,
    [completedBy]  UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_importBOMHeader] PRIMARY KEY CLUSTERED ([importId] ASC)
);

