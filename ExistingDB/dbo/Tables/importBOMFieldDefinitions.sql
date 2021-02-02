CREATE TABLE [dbo].[importBOMFieldDefinitions] (
    [fieldDefId]      UNIQUEIDENTIFIER CONSTRAINT [DF_importBOMFieldDefinitions_fieldDefId] DEFAULT (newsequentialid()) NOT NULL,
    [fieldName]       VARCHAR (50)     CONSTRAINT [DF_importBOMFieldDefinitions_fieldName] DEFAULT ('') NOT NULL,
    [valueSP]         VARCHAR (50)     CONSTRAINT [DF_importBOMFieldDefinitions_valueSP] DEFAULT ('') NOT NULL,
    [validationSP]    VARCHAR (50)     CONSTRAINT [DF_importBOMFieldDefinitions_validationSP] DEFAULT ('') NOT NULL,
    [spParameters]    VARCHAR (50)     CONSTRAINT [DF_importBOMFieldDefinitions_spParameters] DEFAULT ('') NOT NULL,
    [dataType]        VARCHAR (10)     CONSTRAINT [DF_importBOMFieldDefinitions_dataType] DEFAULT ('string') NOT NULL,
    [required]        BIT              CONSTRAINT [DF_importBOMFieldDefinitions_required] DEFAULT ((0)) NOT NULL,
    [fixMatches]      BIT              CONSTRAINT [DF_importBOMFieldDefinitions_fixMatches] DEFAULT ((0)) NOT NULL,
    [existLock]       BIT              CONSTRAINT [DF_importBOMFieldDefinitions_existLock] DEFAULT ((0)) NOT NULL,
    [validated]       BIT              CONSTRAINT [DF_importBOMFieldDefinitions_validated] DEFAULT ((1)) NOT NULL,
    [table]           VARCHAR (50)     CONSTRAINT [DF_importBOMFieldDefinitions_table] DEFAULT ('importBOMFields') NOT NULL,
    [hide]            BIT              CONSTRAINT [DF_importBOMFieldDefinitions_hide] DEFAULT ((0)) NULL,
    [default]         VARCHAR (50)     CONSTRAINT [DF_importBOMFieldDefinitions_default] DEFAULT ('') NOT NULL,
    [valueSQL]        VARCHAR (200)    CONSTRAINT [DF_importBOMFieldDefinitions_valueSQL] DEFAULT ('') NOT NULL,
    [errMsg]          VARCHAR (200)    CONSTRAINT [DF_importBOMFieldDefinitions_errMsg] DEFAULT ('') NOT NULL,
    [sourceTableName] VARCHAR (50)     CONSTRAINT [DF_importBOMFieldDefinitions_sourceTableName] DEFAULT ('') NOT NULL,
    [sourceFieldName] VARCHAR (50)     CONSTRAINT [DF_importBOMFieldDefinitions_sourceFieldName] DEFAULT ('') NOT NULL,
    [fieldLength]     INT              NULL,
    [ColumnOrder]     INT              NULL,
    CONSTRAINT [PK_importBOMFieldDefinitions] PRIMARY KEY CLUSTERED ([fieldDefId] ASC)
);

