CREATE TABLE [dbo].[UdfFields] (
    [FieldListId]     UNIQUEIDENTIFIER CONSTRAINT [DF_UdfFields_FieldListId] DEFAULT (newid()) NOT NULL,
    [FK_ModuleListId] UNIQUEIDENTIFIER NOT NULL,
    [FIELDNAME]       VARCHAR (50)     CONSTRAINT [DF__UDFSETUP__FIELDN__363DB7A5] DEFAULT ('') NOT NULL,
    [FieldType]       VARCHAR (50)     CONSTRAINT [DF__UDFSETUP__DATATY__3731DBDE] DEFAULT ('') NOT NULL,
    [FieldRequired]   BIT              CONSTRAINT [DF_UdfFields_FieldRequired] DEFAULT ((1)) NOT NULL,
    [FieldLength]     INT              CONSTRAINT [DF__UDFSETUP__DATAWI__38260017] DEFAULT ((0)) NOT NULL,
    [FieldDecimal]    INT              CONSTRAINT [DF__UDFSETUP__DECIMA__391A2450] DEFAULT ((0)) NOT NULL,
    [COLUMNNO]        INT              CONSTRAINT [DF__UDFSETUP__COLUMN__3A0E4889] DEFAULT ((0)) NOT NULL,
    [CAPTION]         VARCHAR (50)     CONSTRAINT [DF__UDFSETUP__CAPTIO__3B026CC2] DEFAULT ('') NOT NULL,
    [ListType]        VARCHAR (10)     CONSTRAINT [DF_UdfFields_LisType] DEFAULT ('') NOT NULL,
    [CalcSum]         BIT              CONSTRAINT [DF_UdfFields_CalcSum] DEFAULT ((0)) NOT NULL,
    [ExcludeWhen]     VARCHAR (MAX)    CONSTRAINT [DF_UdfFields_ConditionOn] DEFAULT ('') NOT NULL,
    [MinValue]        NUMERIC (18, 5)  NULL,
    [MaxValue]        NUMERIC (18, 5)  NULL,
    [DefaultValue]    VARCHAR (50)     CONSTRAINT [DF_UdfFields_DefaultValue] DEFAULT ('') NOT NULL,
    CONSTRAINT [UDFSETUP_PK] PRIMARY KEY CLUSTERED ([FieldListId] ASC)
);

