CREATE TABLE [dbo].[importRoutingAssemblyInfo] (
    [ImportTemplateId]  UNIQUEIDENTIFIER NOT NULL,
    [FkImportId]        UNIQUEIDENTIFIER NOT NULL,
    [partNo]            NVARCHAR (MAX)   NOT NULL,
    [revision]          NVARCHAR (MAX)   NOT NULL,
    [uniq_Key]          NVARCHAR (MAX)   NOT NULL,
    [templateName]      NVARCHAR (MAX)   NOT NULL,
    [templateType]      NVARCHAR (MAX)   NOT NULL,
    [validationMessage] NVARCHAR (MAX)   CONSTRAINT [DF__importRou__valid__6D91E542] DEFAULT ('') NOT NULL,
    [Status]            NVARCHAR (50)    CONSTRAINT [DF__importRou__Statu__6E86097B] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK__importRo__AEC13D2C4F57B46D] PRIMARY KEY CLUSTERED ([ImportTemplateId] ASC)
);

