CREATE TABLE [dbo].[ECOUpdate] (
    [EcoUpdateUniq]  CHAR (10)      CONSTRAINT [DF__ECOUpdate__EcoUp__3EAC0DD0] DEFAULT ([dbo].[fn_GenerateUniqueNumber]()) NOT NULL,
    [UniqeECNo]      CHAR (10)      NOT NULL,
    [UpdateCriteria] NVARCHAR (100) NOT NULL,
    [NewValue]       VARCHAR (100)  CONSTRAINT [DF__ECOUpdate__NewVa__3FA03209] DEFAULT ('') NOT NULL,
    [CurrentValue]   VARCHAR (100)  CONSTRAINT [DF__ECOUpdate__Curre__40945642] DEFAULT ('') NOT NULL,
    [IsChanged]      BIT            CONSTRAINT [DF__ECOUpdate__IsCha__41887A7B] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ECOUpdate] PRIMARY KEY CLUSTERED ([EcoUpdateUniq] ASC)
);

