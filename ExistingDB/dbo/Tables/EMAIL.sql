﻿CREATE TABLE [dbo].[EMAIL] (
    [UNIQEMAIL] CHAR (10) CONSTRAINT [DF__EMAIL__UNIQEMAIL__477C86E9] DEFAULT ('') NOT NULL,
    [NAME]      CHAR (25) CONSTRAINT [DF__EMAIL__NAME__4870AB22] DEFAULT ('') NOT NULL,
    [EMAIL]     CHAR (60) CONSTRAINT [DF__EMAIL__EMAIL__4964CF5B] DEFAULT ('') NOT NULL,
    [INTER_OUT] CHAR (1)  CONSTRAINT [DF__EMAIL__INTER_OUT__4A58F394] DEFAULT ('') NOT NULL,
    [DEPT_CO]   CHAR (20) CONSTRAINT [DF__EMAIL__DEPT_CO__4B4D17CD] DEFAULT ('') NOT NULL,
    CONSTRAINT [EMAIL_PK] PRIMARY KEY CLUSTERED ([UNIQEMAIL] ASC)
);

