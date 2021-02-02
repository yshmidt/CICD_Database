CREATE TABLE [dbo].[InvtMpnClean] (
    [partMfgr]   VARCHAR (8)      NOT NULL,
    [mfgr_pt_no] VARCHAR (30)     NOT NULL,
    [cleanmpn]   VARCHAR (30)     NULL,
    [mpnId]      UNIQUEIDENTIFIER CONSTRAINT [DF_InvtMpnClean_mpnId] DEFAULT (newid()) NOT NULL,
    CONSTRAINT [PK_InvtMpnClean_1] PRIMARY KEY CLUSTERED ([mpnId] ASC)
);

