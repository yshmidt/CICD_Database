CREATE TABLE [dbo].[CalcuQuoteConfig] (
    [ConfigId]           INT            IDENTITY (1, 1) NOT NULL,
    [FkCalcuQuoteUserId] INT            NULL,
    [AuthenticationType] VARCHAR (100)  NOT NULL,
    [ModelAPIName]       VARCHAR (200)  NOT NULL,
    [AccessTokenURL]     NVARCHAR (250) NULL,
    [InitiateRequstURL]  NVARCHAR (250) NULL,
    [DataAccessURL]      NVARCHAR (MAX) NULL,
    [SessionId]          VARCHAR (50)   NULL,
    [ModifiedDt]         DATETIME       CONSTRAINT [DF__CalcuQuot__Modif__1555BDD9] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK__CalcuQuo__C3BC335C8A6B9282] PRIMARY KEY CLUSTERED ([ConfigId] ASC),
    CONSTRAINT [FK__CalcuQuot__FkCal__146199A0] FOREIGN KEY ([FkCalcuQuoteUserId]) REFERENCES [dbo].[CalcuQuoteUser] ([CalcuQuoteId])
);

