CREATE TABLE [dbo].[AgingRangeSetup] (
    [AgingRangeSetupUk] INT      IDENTITY (1, 1) NOT NULL,
    [cType]             CHAR (2) CONSTRAINT [DF_AgingRangeSetupUk_cType] DEFAULT ('') NOT NULL,
    [nRange]            INT      NOT NULL,
    [nStart]            INT      NOT NULL,
    [nEnd]              INT      NOT NULL,
    CONSTRAINT [PK_AgingRangeSetup] PRIMARY KEY CLUSTERED ([AgingRangeSetupUk] ASC),
    CONSTRAINT [CK_AgingRangeSetup_cType] CHECK ([CType]='AP' OR [CType]='AR'),
    CONSTRAINT [CK_AgingRangeSetup_nRange] CHECK ([nRange]=(5) OR [nRange]=(4) OR [nRange]=(3) OR [nRange]=(2) OR [nRange]=(1))
);


GO
CREATE NONCLUSTERED INDEX [cType]
    ON [dbo].[AgingRangeSetup]([cType] ASC);


GO
CREATE NONCLUSTERED INDEX [nRange]
    ON [dbo].[AgingRangeSetup]([nRange] ASC);

