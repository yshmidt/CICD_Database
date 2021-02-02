CREATE TABLE [dbo].[MnxUdfSections] (
    [uniqueNum]   INT           IDENTITY (1, 1) NOT NULL,
    [section]     VARCHAR (100) CONSTRAINT [DF_Table_1_SECTION] DEFAULT ('') NOT NULL,
    [mainTable]   VARCHAR (100) CONSTRAINT [DF_Table_1_TABLE] DEFAULT ('') NOT NULL,
    [role]        VARCHAR (100) CONSTRAINT [DF_udfSections_role] DEFAULT ('SYSSETUP_Edit') NOT NULL,
    [AddSeletion] VARCHAR (50)  CONSTRAINT [DF__MnxUdfSec__AddSe__7AC0F7D7] DEFAULT ('') NOT NULL,
    [Type]        VARCHAR (50)  CONSTRAINT [DF__MnxUdfSect__Type__7CA94049] DEFAULT ('') NOT NULL,
    [FieldName]   VARCHAR (50)  CONSTRAINT [DF__MnxUdfSec__Field__7D9D6482] DEFAULT ('') NOT NULL,
    [Source]      VARCHAR (MAX) CONSTRAINT [DF__MnxUdfSec__Sourc__0CDFA812] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_udfSections] PRIMARY KEY CLUSTERED ([uniqueNum] ASC)
);

