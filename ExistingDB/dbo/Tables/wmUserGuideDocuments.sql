﻿CREATE TABLE [dbo].[wmUserGuideDocuments] (
    [DocumentId]       BIGINT           IDENTITY (1000, 1) NOT NULL,
    [DocumentNumber]   VARCHAR (100)    NULL,
    [DocumentRev]      VARCHAR (16)     NULL,
    [Title]            VARCHAR (255)    NOT NULL,
    [CreatedDate]      SMALLDATETIME    NULL,
    [LastModifiedDate] SMALLDATETIME    NULL,
    [Author]           UNIQUEIDENTIFIER NULL,
    [Approver]         UNIQUEIDENTIFIER NULL,
    [ReleaseDate]      SMALLDATETIME    NULL,
    [EditExplanation]  VARCHAR (MAX)    NULL,
    [Content]          VARCHAR (MAX)    NULL,
    [Summary]          VARCHAR (200)    NULL,
    [Status]           VARCHAR (50)     NOT NULL,
    [Template]         VARCHAR (100)    NULL,
    [TemplateValues]   VARCHAR (MAX)    NULL,
    [Display]          BIT              CONSTRAINT [DF_wmUserGuideDocument_Display] DEFAULT ((0)) NOT NULL,
    [ViewCount]        INT              CONSTRAINT [DF_wmUserGuideDocument_ViewCount] DEFAULT ((0)) NOT NULL,
    [InternalOnly]     BIT              CONSTRAINT [DF_wmUserGuideDocument_InternalOnly] DEFAULT ((0)) NOT NULL,
    [DocumentLevel]    INT              NOT NULL,
    CONSTRAINT [PK_wmUserGuideDocument] PRIMARY KEY CLUSTERED ([DocumentId] ASC),
    CONSTRAINT [FK_wmUserGuideDocuments_aspnet_Profile] FOREIGN KEY ([Approver]) REFERENCES [dbo].[aspnet_Profile] ([UserId]),
    CONSTRAINT [FK_wmUserGuideDocuments_aspnet_Profile1] FOREIGN KEY ([Author]) REFERENCES [dbo].[aspnet_Profile] ([UserId])
);
