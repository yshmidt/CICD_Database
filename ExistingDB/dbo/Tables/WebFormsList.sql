CREATE TABLE [dbo].[WebFormsList] (
    [WebFormID]   INT           IDENTITY (1, 1) NOT NULL,
    [WebFormName] VARCHAR (50)  CONSTRAINT [DF_WebFormsList_WebFormName] DEFAULT ('') NOT NULL,
    [WebFormURL]  VARCHAR (100) CONSTRAINT [DF_WebFormsList_WebFormURL] DEFAULT ('') NOT NULL,
    [FK_uniqApp]  INT           CONSTRAINT [DF_WebFormsList_FK_uniqApp] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_WebFormsList] PRIMARY KEY CLUSTERED ([WebFormID] ASC)
);

