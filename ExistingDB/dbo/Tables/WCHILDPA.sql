﻿CREATE TABLE [dbo].[WCHILDPA] (
    [CHILDWO]    CHAR (10) CONSTRAINT [DF__WCHILDPA__CHILDW__3BC186D1] DEFAULT ('') NOT NULL,
    [PARENTWO]   CHAR (10) CONSTRAINT [DF__WCHILDPA__PARENT__3CB5AB0A] DEFAULT ('') NOT NULL,
    [WCHILDPAUK] CHAR (10) CONSTRAINT [DF__WCHILDPA__WCHILD__3DA9CF43] DEFAULT ('') NOT NULL,
    CONSTRAINT [WCHILDPA_PK] PRIMARY KEY CLUSTERED ([WCHILDPAUK] ASC)
);

