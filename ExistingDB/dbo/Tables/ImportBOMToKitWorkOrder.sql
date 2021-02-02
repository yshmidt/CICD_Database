CREATE TABLE [dbo].[ImportBOMToKitWorkOrder] (
    [WorkOrderId]     UNIQUEIDENTIFIER NOT NULL,
    [FKAssemblyRowId] UNIQUEIDENTIFIER NOT NULL,
    [FKFieldDefId]    UNIQUEIDENTIFIER NOT NULL,
    [WORowId]         UNIQUEIDENTIFIER NOT NULL,
    [Original]        NVARCHAR (MAX)   NULL,
    [Adjusted]        NVARCHAR (MAX)   NULL,
    [Status]          NVARCHAR (50)    NULL,
    [Message]         NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK__ImportBO__AE755115AC1E299E] PRIMARY KEY CLUSTERED ([WorkOrderId] ASC)
);

