CREATE TABLE [dbo].[UDFSearchSetupDetail] (
    [DetailId]      INT           IDENTITY (1, 1) NOT NULL,
    [FkFilterId]    INT           NULL,
    [FieldName]     VARCHAR (100) NULL,
    [FieldDataType] VARCHAR (50)  NULL,
    [FieldValue]    VARCHAR (MAX) NULL,
    [UdfColumn]     VARCHAR (MAX) NULL,
    CONSTRAINT [PK_UDFSearchSetupDetail] PRIMARY KEY CLUSTERED ([DetailId] ASC),
    CONSTRAINT [FK_UDFSearchSetupDetail_UDFSearchSetup] FOREIGN KEY ([FkFilterId]) REFERENCES [dbo].[UDFSearchSetup] ([FilterId])
);

