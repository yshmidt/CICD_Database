CREATE TABLE [dbo].[ECAlternateParts] (
    [ECAltPartUniq]      CHAR (10) NOT NULL,
    [BOMPARENT]          CHAR (10) NOT NULL,
    [ALT_FOR]            CHAR (10) NOT NULL,
    [UNIQ_KEY]           CHAR (10) NOT NULL,
    [IsSynchronizedFlag] BIT       NOT NULL,
    [UNIQECDET]          CHAR (10) CONSTRAINT [DF__ECAlterna__UNIQE__37FF1041] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_ECAlternateParts] PRIMARY KEY CLUSTERED ([ECAltPartUniq] ASC)
);

