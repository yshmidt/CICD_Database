CREATE TABLE [dbo].[MpnAutoComplete] (
    [Source]  VARCHAR (20)  CONSTRAINT [DF_MpnAutoComplete_Source] DEFAULT ('') NOT NULL,
    [Data]    VARCHAR (254) CONSTRAINT [DF_MpnAutoComplete_Data] DEFAULT ('') NOT NULL,
    [count]   INT           CONSTRAINT [DF_MpnAutoComplete_count] DEFAULT ((0)) NOT NULL,
    [weight]  INT           CONSTRAINT [DF_MpnAutoComplete_weight] DEFAULT ((0)) NOT NULL,
    [created] DATETIME      NULL,
    [updated] DATETIME      NULL,
    [user]    VARCHAR (MAX) CONSTRAINT [DF_MpnAutoComplete_user] DEFAULT ('') NOT NULL
);

