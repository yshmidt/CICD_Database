﻿CREATE TABLE [dbo].[ImportBOMToKitAvls] (
    [AvlId]        UNIQUEIDENTIFIER NOT NULL,
    [FKCompRowId]  UNIQUEIDENTIFIER NOT NULL,
    [AvlRowId]     UNIQUEIDENTIFIER NOT NULL,
    [FKFieldDefId] UNIQUEIDENTIFIER NOT NULL,
    [Original]     NVARCHAR (MAX)   NULL,
    [Adjusted]     NVARCHAR (MAX)   NULL,
    [Status]       NVARCHAR (50)    NULL,
    [Message]      NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK__ImportBO__FF2A427D23591961] PRIMARY KEY CLUSTERED ([AvlId] ASC)
);

