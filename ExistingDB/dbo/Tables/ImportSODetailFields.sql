﻿CREATE TABLE [dbo].[ImportSODetailFields] (
    [SODetailId]   UNIQUEIDENTIFIER NOT NULL,
    [SOMainRowId]  UNIQUEIDENTIFIER NOT NULL,
    [RowId]        UNIQUEIDENTIFIER NOT NULL,
    [FKFieldDefId] UNIQUEIDENTIFIER NOT NULL,
    [Original]     NVARCHAR (MAX)   NULL,
    [Adjusted]     NVARCHAR (MAX)   NULL,
    [Status]       NVARCHAR (50)    NULL,
    [Message]      NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK__ImportSO__E30429B1C069C81E] PRIMARY KEY CLUSTERED ([SODetailId] ASC)
);

