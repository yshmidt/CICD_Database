CREATE TABLE [dbo].[wmGroupParams] (
    [groupParamId]    INT              IDENTITY (1, 1) NOT NULL,
    [fkParamId]       UNIQUEIDENTIFIER CONSTRAINT [DF_wmGroupParams_fkParamId] DEFAULT (newid()) NOT NULL,
    [paramGroup]      VARCHAR (50)     NOT NULL,
    [sequence]        INT              CONSTRAINT [DF_wmGroupParams_sequence] DEFAULT ((0)) NOT NULL,
    [columnNum]       INT              CONSTRAINT [DF_wmGroupParams_columnNum] DEFAULT ((1)) NOT NULL,
    [defaultValue]    VARCHAR (100)    CONSTRAINT [DF_wmGroupParams_defaultValue] DEFAULT ('') NOT NULL,
    [selectParam]     CHAR (1)         CONSTRAINT [DF_wmGroupParams_selectParam] DEFAULT ('y') NOT NULL,
    [hideFirst]       BIT              CONSTRAINT [DF_wmGroupParams_hideFirst] DEFAULT ((0)) NOT NULL,
    [onchange]        VARCHAR (MAX)    CONSTRAINT [DF_wmGroupParams_onchange] DEFAULT ('') NOT NULL,
    [addressSp]       VARCHAR (MAX)    CONSTRAINT [DF_wmGroupParams_addressSp] DEFAULT ('') NOT NULL,
    [defaultValueSql] BIT              CONSTRAINT [DF_wmGroupParams_defaultValueSql] DEFAULT ((0)) NOT NULL,
    [isFixed]         BIT              CONSTRAINT [DF_wmGroupParams_isFixed] DEFAULT ((0)) NOT NULL,
    [cascadeId]       UNIQUEIDENTIFIER NULL,
    [parentParam]     VARCHAR (50)     CONSTRAINT [DF_wmGroupParams_parentParam] DEFAULT ('') NOT NULL,
    [finalParam]      BIT              CONSTRAINT [DF_wmGroupParams_finalParam] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_wmGroupParams] PRIMARY KEY CLUSTERED ([groupParamId] ASC)
);

