CREATE TABLE [dbo].[WmResourceTranslation] (
    [TranslationId] INT             IDENTITY (1, 1) NOT NULL,
    [Translation]   NVARCHAR (1000) NULL,
    [ResourceKeyId] INT             NULL,
    [LanguageId]    INT             NULL,
    CONSTRAINT [PK_WmResourceTranslation] PRIMARY KEY CLUSTERED ([TranslationId] ASC)
);

