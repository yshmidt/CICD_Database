CREATE TYPE [dbo].[tCalendar] AS TABLE (
    [dDate]        SMALLDATETIME NOT NULL,
    [WorkingDay]   BIT           DEFAULT ((0)) NULL,
    [WorkDayCount] INT           NULL,
    PRIMARY KEY CLUSTERED ([dDate] ASC));

