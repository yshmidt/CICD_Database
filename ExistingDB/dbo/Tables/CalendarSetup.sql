CREATE TABLE [dbo].[CalendarSetup] (
    [cDayOfWeek]       CHAR (10) CONSTRAINT [DF_Table_1_Admin_Mon] DEFAULT ('') NOT NULL,
    [lAdminWorkDay]    BIT       CONSTRAINT [DF_Table_1_Admin_Tue] DEFAULT ((1)) NOT NULL,
    [lProdWorkDay]     BIT       CONSTRAINT [DF_Table_1_Admin_Wed] DEFAULT ((1)) NOT NULL,
    [nCalendarSetupUK] INT       IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_CalendarSetup] PRIMARY KEY CLUSTERED ([nCalendarSetupUK] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [cDayOfWeek]
    ON [dbo].[CalendarSetup]([cDayOfWeek] ASC);

