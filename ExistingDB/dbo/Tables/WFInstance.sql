CREATE TABLE [dbo].[WFInstance] (
    [WFInstanceId] CHAR (10)        NOT NULL,
    [WFRequestId]  CHAR (10)        NOT NULL,
    [IsApproved]   BIT              NULL,
    [Comments]     VARCHAR (MAX)    NULL,
    [ActionDate]   SMALLDATETIME    NULL,
    [Approver]     UNIQUEIDENTIFIER NULL,
    [RejectToStep] INT              NULL,
    [WFConfigId]   CHAR (10)        NOT NULL,
    CONSTRAINT [PK_WFInstance] PRIMARY KEY CLUSTERED ([WFInstanceId] ASC)
);

