CREATE TABLE [dbo].[WOActiveSID] (
    [WOSIDUniqKey]  CHAR (10)        NOT NULL,
    [WONO]          CHAR (10)        NOT NULL,
    [IPKEYUNIQUE]   CHAR (10)        NOT NULL,
    [DeptKey]       CHAR (10)        NOT NULL,
    [SIDSequenceNo] INT              NOT NULL,
    [QtyEach]       NUMERIC (12, 2)  NOT NULL,
    [IsSIDDone]     BIT              NOT NULL,
    [Date]          SMALLDATETIME    NOT NULL,
    [fk_userid]     UNIQUEIDENTIFIER NOT NULL,
    [DeptID]        CHAR (4)         CONSTRAINT [DF__WOActiveS__DeptI__03756E12] DEFAULT ('') NOT NULL,
    [IsReserve]     BIT              CONSTRAINT [DF__WOActiveS__IsRes__0469924B] DEFAULT ((0)) NOT NULL,
    [KaSeqNum]      CHAR (10)        CONSTRAINT [DF__WOActiveS__KaSeq__055DB684] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_WOActiveSID] PRIMARY KEY CLUSTERED ([WOSIDUniqKey] ASC)
);

