CREATE TABLE [dbo].[WcEquipment] (
    [WcEquipmentId]     INT           IDENTITY (1, 1) NOT NULL,
    [DeptId]            CHAR (4)      NOT NULL,
    [Equipment]         NVARCHAR (50) NOT NULL,
    [EquipmentPriority] INT           CONSTRAINT [DF__WcEquipme__Equip__40FD9F3F] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WcEquipment] PRIMARY KEY CLUSTERED ([WcEquipmentId] ASC),
    CONSTRAINT [FK_WcEquipment_DEPTS] FOREIGN KEY ([DeptId]) REFERENCES [dbo].[DEPTS] ([DEPT_ID])
);


GO
-- =============================================
-- Author:		sachin B
-- Create date: 07/10/2017
-- Description:	update the equipment name for all work order in corresponding work Center
-- 09/06/2017 Sachinb Update Priority Also
-- =============================================
CREATE TRIGGER [dbo].[WcEquipment_Update]
   ON  [dbo].[WcEquipment]
   INSTEAD OF UPDATE
AS 
BEGIN
   SET NOCOUNT ON;
   -- Update statements for trigger here
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

	DECLARE @OldEquipment NVARCHAR(50)
	DECLARE @DeptId NVARCHAR(4)
	DECLARE @NewEquipment NVARCHAR(50)

    BEGIN TRY
	BEGIN TRANSACTION
	
	 SELECT @OldEquipment = w.Equipment,@NewEquipment=i.Equipment,@DeptId  = w.DeptId
	 FROM INSERTED I INNER JOIN WcEquipment w ON w.WcEquipmentId=I.WcEquipmentId

	 UPDATE DEPT_QTY SET equipment =@NewEquipment
	 WHERE DEPT_ID =@DeptId AND equipment =@OldEquipment

	 UPDATE w
	 SET w.Equipment = r.Equipment,
	     -- 09/06/2017 Sachinb Update Priority Also
	     w.EquipmentPriority = r.EquipmentPriority
	 FROM WcEquipment w
	 JOIN (SELECT WcEquipmentId,Equipment,EquipmentPriority FROM inserted I) r
	 ON w.WcEquipmentId = r.WcEquipmentId
	  
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

