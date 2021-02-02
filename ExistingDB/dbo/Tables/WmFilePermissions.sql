CREATE TABLE [dbo].[WmFilePermissions] (
    [fmPermissionId] BIGINT       IDENTITY (1, 1) NOT NULL,
    [permittedId]    VARCHAR (36) NOT NULL,
    [fileId]         BIGINT       NOT NULL,
    [IsApprover]     BIT          CONSTRAINT [DF_WmFileManagerGroupRelationship_IsApprover] DEFAULT ((0)) NOT NULL,
    [IsViewer]       BIT          CONSTRAINT [DF_WmFileManagerGroupRelationship_IsViewer] DEFAULT ((0)) NOT NULL,
    [IsEditor]       BIT          CONSTRAINT [DF_WmFileManagerGroupRelationship_IsEditor] DEFAULT ((0)) NOT NULL,
    [permittedType]  VARCHAR (10) NOT NULL,
    [viewOnly]       BIT          CONSTRAINT [DF_WmFileManagerGroupRelationship_viewOnly] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WmFileManagerGroupRelationship] PRIMARY KEY CLUSTERED ([fmPermissionId] ASC)
);

