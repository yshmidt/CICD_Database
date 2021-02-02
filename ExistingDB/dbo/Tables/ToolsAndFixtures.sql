CREATE TABLE [dbo].[ToolsAndFixtures] (
    [ToolsAndFixtureId]    CHAR (10)      CONSTRAINT [DF__ToolsAndF__Tools__6EC469EF] DEFAULT ([dbo].[fn_GenerateUniqueNumber]()) NOT NULL,
    [Description]          NVARCHAR (100) CONSTRAINT [DF__ToolsAndF__Descr__6FB88E28] DEFAULT ('') NOT NULL,
    [Location]             NVARCHAR (50)  CONSTRAINT [DF__ToolsAndF__Locat__70ACB261] DEFAULT ('') NOT NULL,
    [CalibrationDate]      SMALLDATETIME  NULL,
    [DEPT_ID]              CHAR (4)       NOT NULL,
    [ToolsFixturePriority] INT            CONSTRAINT [DF__ToolsAndF__Tools__71A0D69A] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ToolsAndFixtures] PRIMARY KEY CLUSTERED ([ToolsAndFixtureId] ASC)
);


GO
-- =============================================
-- Author:		sachin B
-- Create date: 07/10/2017
-- Description:	update the tools name for all work order in corresponding work Center
-- 09/06/2017 Sachinb Update Priority Also
-- =============================================
CREATE TRIGGER [dbo].[ToolsAndFixtures_Update]
   ON  [dbo].[ToolsAndFixtures]
   INSTEAD OF UPDATE
AS 
BEGIN
   SET NOCOUNT ON;
   -- Update statements for trigger here
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

	DECLARE @OldDescription NVARCHAR(50)
	DECLARE @DeptId NVARCHAR(4)
	DECLARE @NewDescription NVARCHAR(50)

    BEGIN TRY
	BEGIN TRANSACTION
	
	 SELECT @OldDescription = t.[Description],@NewDescription=i.[Description],@DeptId  = t.DEPT_ID
	 FROM INSERTED I INNER JOIN ToolsAndFixtures t ON t.ToolsAndFixtureId=I.ToolsAndFixtureId

	 UPDATE DEPT_QTY SET operator =@NewDescription
	 WHERE DEPT_ID =@DeptId AND operator =@NewDescription

	 UPDATE t
	 SET t.[Description] = r.[Description],
	 -- 09/06/2017 Sachinb Update Priority Also
	 t.[ToolsFixturePriority] = r.[ToolsFixturePriority]
	 FROM ToolsAndFixtures t
	 JOIN (SELECT ToolsAndFixtureId,Description,ToolsFixturePriority FROM inserted I) r
	 ON t.ToolsAndFixtureId = r.ToolsAndFixtureId
	  
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT>0
		ROLLBACK
		SELECT @ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();
			RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
	END CATCH
	IF @@TRANCOUNT>0
	COMMIT	
END

