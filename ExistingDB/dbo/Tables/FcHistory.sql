CREATE TABLE [dbo].[FcHistory] (
    [Fchist_key]      CHAR (10)       CONSTRAINT [DF__FcHistory__Fchis__6C1C3C17] DEFAULT ([dbo].[fn_GenerateUniqueNumber]()) NOT NULL,
    [Fcused_Uniq]     CHAR (10)       CONSTRAINT [DF__FcHistory__Fcuse__6D106050] DEFAULT ('') NOT NULL,
    [FcDateTime]      SMALLDATETIME   CONSTRAINT [DF__FcHistory__FcDat__6E048489] DEFAULT ('') NOT NULL,
    [Fgncncy]         CHAR (3)        CONSTRAINT [DF__FcHistory__Fgncn__6EF8A8C2] DEFAULT ('') NOT NULL,
    [Askprice]        NUMERIC (13, 5) CONSTRAINT [DF__FcHistory__Askpr__6FECCCFB] DEFAULT ((0)) NOT NULL,
    [AskpricePR]      NUMERIC (13, 5) CONSTRAINT [DF__FcHistory__Askpr__2B6363DB] DEFAULT ((0)) NOT NULL,
    [FuncFcused_uniq] CHAR (10)       CONSTRAINT [DF__FcHistory__FuncF__2C578814] DEFAULT ('') NOT NULL,
    [PRFcused_uniq]   CHAR (10)       CONSTRAINT [DF__FcHistory__PRFcu__2D4BAC4D] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK__FcHistor__2945DE006A33F3A5] PRIMARY KEY CLUSTERED ([Fchist_key] ASC)
);


GO
CREATE NONCLUSTERED INDEX [fcdate]
    ON [dbo].[FcHistory]([FcDateTime] ASC);


GO
CREATE NONCLUSTERED INDEX [fcused]
    ON [dbo].[FcHistory]([Fcused_Uniq] ASC);

