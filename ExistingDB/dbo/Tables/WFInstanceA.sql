CREATE TABLE [dbo].[WFInstanceA] (
    [WFInstanceAId] CHAR (10)        NOT NULL,
    [WFInstanceId]  CHAR (10)        NOT NULL,
    [WFRequestId]   CHAR (10)        NOT NULL,
    [IsApproved]    BIT              NULL,
    [Comments]      VARCHAR (MAX)    NULL,
    [ActionDate]    SMALLDATETIME    NULL,
    [Approver]      UNIQUEIDENTIFIER NULL,
    [RejectToStep]  INT              NULL,
    [WFConfigId]    CHAR (10)        NOT NULL,
    CONSTRAINT [PK_WFInstanceA] PRIMARY KEY CLUSTERED ([WFInstanceAId] ASC)
);

