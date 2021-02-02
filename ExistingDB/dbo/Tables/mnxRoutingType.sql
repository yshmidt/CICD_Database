CREATE TABLE [dbo].[mnxRoutingType] (
    [routingType] NVARCHAR (30) CONSTRAINT [DF_mnxRoutingType_routingType] DEFAULT ('') NOT NULL,
    [rtypeid]     INT           IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_mnxRoutingType] PRIMARY KEY CLUSTERED ([rtypeid] ASC)
);

