CREATE TABLE [dbo].[ImportTargetPrice] (
    [Part_no]     CHAR (25)       CONSTRAINT [DF__ImportTar__Part___6A33F3A5] DEFAULT ('') NOT NULL,
    [Revision]    CHAR (8)        CONSTRAINT [DF__ImportTar__Revis__6B2817DE] DEFAULT ('') NOT NULL,
    [TargetPrice] NUMERIC (13, 5) CONSTRAINT [DF__ImportTar__Targe__6C1C3C17] DEFAULT ((0)) NOT NULL
);

