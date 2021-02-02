CREATE TABLE [dbo].[HolidayList] (
    [cHolidayName]         NCHAR (50) CONSTRAINT [DF_Table_1_HolidayName] DEFAULT ('') NOT NULL,
    [lFixedDate]           BIT        CONSTRAINT [DF_HolidayList_lFixedDate] DEFAULT ((0)) NOT NULL,
    [nFixedDate]           SMALLINT   CONSTRAINT [DF_HolidayList_cFixedDate] DEFAULT ((0)) NOT NULL,
    [nMonth]               INT        CONSTRAINT [DF_HolidayList_cMonth] DEFAULT ((0)) NOT NULL,
    [nDayOfWeek]           INT        CONSTRAINT [DF_HolidayList_cDayofWeek] DEFAULT ((0)) NOT NULL,
    [cDayOccurrence]       NCHAR (10) CONSTRAINT [DF_HolidayList_cDayOccurance] DEFAULT ('') NOT NULL,
    [lCompObserve]         BIT        CONSTRAINT [DF_HolidayList_lCompObserve] DEFAULT ((1)) NOT NULL,
    [lRepeat]              BIT        CONSTRAINT [DF_HolidayList_lRepeat] DEFAULT ((0)) NOT NULL,
    [lSelectedyear]        BIT        CONSTRAINT [DF_HolidayList_lSelectedyear] DEFAULT ((0)) NOT NULL,
    [nStartYear]           SMALLINT   CONSTRAINT [DF_HolidayList_nStartYear] DEFAULT ((0)) NOT NULL,
    [nEndYear]             SMALLINT   CONSTRAINT [DF_HolidayList_nEndYear] DEFAULT ((0)) NOT NULL,
    [nOffsetFromDayOfWeek] SMALLINT   CONSTRAINT [DF_HolidayList_nOffsetFromDayOfWeek] DEFAULT ((0)) NOT NULL,
    [iHolidayListUK]       INT        IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_HolidayList] PRIMARY KEY CLUSTERED ([iHolidayListUK] ASC),
    CONSTRAINT [CK_EndYear] CHECK ([nEndYear]>=[nStartYear])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [HolidayName]
    ON [dbo].[HolidayList]([cHolidayName] ASC);

