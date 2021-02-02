CREATE TABLE [dbo].[MnxGenericForm] (
    [GenericFormId] INT           IDENTITY (1, 1) NOT NULL,
    [FormName]      VARCHAR (150) NOT NULL,
    CONSTRAINT [PK_mnxGenericForm] PRIMARY KEY CLUSTERED ([GenericFormId] ASC)
);

