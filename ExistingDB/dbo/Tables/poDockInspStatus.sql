CREATE TABLE [dbo].[poDockInspStatus] (
    [dock_uniq]        CHAR (10)        CONSTRAINT [DF_poDockInspStatus_dock_uniq] DEFAULT ('') NOT NULL,
    [RequirementName]  VARCHAR (50)     CONSTRAINT [DF_poDockInspStatus_RequirementName] DEFAULT ('') NOT NULL,
    [ReqComplete]      BIT              CONSTRAINT [DF_poDockInspStatus_ReqComplete] DEFAULT ((0)) NOT NULL,
    [DateComplete]     SMALLDATETIME    NULL,
    [userid]           UNIQUEIDENTIFIER NULL,
    [UniqueInspStatus] CHAR (10)        CONSTRAINT [DF_poDockInspStatus_UniqueInspStatus] DEFAULT ([dbo].[fn_GenerateUniqueNumber]()) NOT NULL
);

