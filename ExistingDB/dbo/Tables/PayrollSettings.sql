CREATE TABLE [dbo].[PayrollSettings] (
    [PayrollSettingUniq] CHAR (10)        CONSTRAINT [DF__PayrollSe__Payro__2773A2BD] DEFAULT ([dbo].[fn_GenerateUniqueNumber]()) NOT NULL,
    [PeriodType]         CHAR (15)        CONSTRAINT [DF__PayrollSe__Perio__2867C6F6] DEFAULT ('') NOT NULL,
    [StartValue]         CHAR (10)        CONSTRAINT [DF__PayrollSe__Start__295BEB2F] DEFAULT ('') NOT NULL,
    [PayValue]           CHAR (10)        CONSTRAINT [DF__PayrollSe__PayVa__2A500F68] DEFAULT ('') NOT NULL,
    [ModifiedBy]         UNIQUEIDENTIFIER CONSTRAINT [DF__PayrollSe__Modif__2B4433A1] DEFAULT ('00000000-0000-0000-0000-000000000000') NULL,
    [ModifiedDate]       DATETIME         NULL
);

