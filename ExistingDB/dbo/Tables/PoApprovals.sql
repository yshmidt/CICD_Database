CREATE TABLE [dbo].[PoApprovals] (
    [nPOAPPRID]     INT       IDENTITY (1, 1) NOT NULL,
    [uniq_user]     CHAR (10) CONSTRAINT [DF_PoApprovals_uniq_user] DEFAULT ('') NOT NULL,
    [cFinalInvtAmt] CHAR (20) CONSTRAINT [DF_PoApprovals_cFinalInvtAmt] DEFAULT ('') NOT NULL,
    [cFinalMROAmt]  CHAR (20) CONSTRAINT [DF_PoApprovals_cFinalMROAmt] DEFAULT ('') NOT NULL,
    [cInvtAmt]      CHAR (20) CONSTRAINT [DF_PoApprovals_cInvtAmt] DEFAULT ('') NOT NULL,
    [cMROAmt]       CHAR (20) CONSTRAINT [DF_PoApprovals_cMROAmt] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_PoApprovals] PRIMARY KEY CLUSTERED ([nPOAPPRID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [uniq_user]
    ON [dbo].[PoApprovals]([uniq_user] ASC) WITH (ALLOW_PAGE_LOCKS = OFF);

