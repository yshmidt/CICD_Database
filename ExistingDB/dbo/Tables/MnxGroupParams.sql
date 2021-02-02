CREATE TABLE [dbo].[MnxGroupParams] (
    [groupParamId]    INT              IDENTITY (1, 1) NOT NULL,
    [fkParamId]       UNIQUEIDENTIFIER CONSTRAINT [DF_reportParams_rptParamId] DEFAULT (newid()) NOT NULL,
    [paramGroup]      VARCHAR (50)     NOT NULL,
    [sequence]        INT              NOT NULL,
    [columnNum]       INT              CONSTRAINT [DF_reportParams_columnCount] DEFAULT ((1)) NOT NULL,
    [defaultValue]    VARCHAR (100)    CONSTRAINT [DF_reportParams_defaultValue] DEFAULT ('') NOT NULL,
    [selectParam]     CHAR (1)         CONSTRAINT [DF_reportParams_selectParam] DEFAULT ((1)) NOT NULL,
    [hideFirst]       BIT              CONSTRAINT [DF_rptGroupParams_hideFirst] DEFAULT ((0)) NOT NULL,
    [onchange]        VARCHAR (MAX)    CONSTRAINT [DF_rptGroupParams_onchange] DEFAULT ('') NOT NULL,
    [addressSp]       VARCHAR (MAX)    CONSTRAINT [DF_rptGroupParams_addressSp] DEFAULT ('') NOT NULL,
    [defaultValueSql] BIT              CONSTRAINT [DF_rptGroupParams_defaultValueSql] DEFAULT ((0)) NOT NULL,
    [isFixed]         BIT              CONSTRAINT [DF_rptGroupParams_isFixed] DEFAULT ((0)) NOT NULL,
    [cascadeId]       UNIQUEIDENTIFIER NULL,
    [parentParam]     VARCHAR (50)     CONSTRAINT [DF_rptGroupParams_parentParam] DEFAULT ('') NOT NULL,
    [finalParam]      BIT              CONSTRAINT [DF_rptGroupParams_finalParam] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_reportParams] PRIMARY KEY CLUSTERED ([groupParamId] ASC)
);

