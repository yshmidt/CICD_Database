CREATE TABLE [dbo].[udfInspection] (
    [udfId]          UNIQUEIDENTIFIER CONSTRAINT [DF_udfInspection_udfId] DEFAULT (newid()) NOT NULL,
    [fkinspHeaderId] CHAR (10)        CONSTRAINT [DF_udfInspection_fkinspHeaderId] DEFAULT ('') NOT NULL,
    [Casing_Status]  VARCHAR (50)     CONSTRAINT [DF_udfInspection_Casing_Status] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_udfInspection] PRIMARY KEY CLUSTERED ([udfId] ASC)
);

