CREATE TABLE [dbo].[MnxResourceLanguages] (
    [LanguageId]   INT           IDENTITY (1, 1) NOT NULL,
    [Language]     VARCHAR (100) NULL,
    [Abbreviation] NVARCHAR (50) NULL,
    [IsSelected]   BIT           CONSTRAINT [DF__MnxResour__IsSel__104624A2] DEFAULT ((0)) NOT NULL,
    [IsDefault]    BIT           CONSTRAINT [DF__MnxResour__IsDef__113A48DB] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WmResourceLanguages] PRIMARY KEY CLUSTERED ([LanguageId] ASC)
);

