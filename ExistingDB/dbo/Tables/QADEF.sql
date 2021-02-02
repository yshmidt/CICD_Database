CREATE TABLE [dbo].[QADEF] (
    [WONO]       CHAR (10)     CONSTRAINT [DF__QADEF__WONO__3BB699D9] DEFAULT ('') NOT NULL,
    [QASEQMAIN]  CHAR (10)     CONSTRAINT [DF__QADEF__QASEQMAIN__3CAABE12] DEFAULT ('') NOT NULL,
    [DEFDATE]    SMALLDATETIME NULL,
    [LOCSEQNO]   CHAR (10)     CONSTRAINT [DF__QADEF__LOCSEQNO__3D9EE24B] DEFAULT ('') NOT NULL,
    [SERIALNO]   CHAR (30)     CONSTRAINT [DF__QADEF__SERIALNO__3E930684] DEFAULT ('') NOT NULL,
    [DIAGNOSIS]  TEXT          CONSTRAINT [DF__QADEF__DIAGNOSIS__3F872ABD] DEFAULT ('') NOT NULL,
    [ROOTCAUSE]  TEXT          CONSTRAINT [DF__QADEF__ROOTCAUSE__407B4EF6] DEFAULT ('') NOT NULL,
    [REWORKNOTE] TEXT          CONSTRAINT [DF__QADEF__REWORKNOT__416F732F] DEFAULT ('') NOT NULL,
    [SERIALUNIQ] CHAR (10)     CONSTRAINT [DF__QADEF__SERIALUNI__42639768] DEFAULT ('') NOT NULL,
    [PASSNUM]    NUMERIC (2)   CONSTRAINT [DF__QADEF__PASSNUM__4357BBA1] DEFAULT ((0)) NOT NULL,
    [DEPT_ID]    CHAR (4)      CONSTRAINT [DF__QADEF__DEPT_ID__444BDFDA] DEFAULT ('') NOT NULL,
    [IS_PASSED]  BIT           CONSTRAINT [DF__QADEF__IS_PASSED__45400413] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [QADEF_PK] PRIMARY KEY CLUSTERED ([LOCSEQNO] ASC)
);


GO
CREATE NONCLUSTERED INDEX [QASEQMAIN]
    ON [dbo].[QADEF]([QASEQMAIN] ASC);


GO
CREATE NONCLUSTERED INDEX [WoQaseqLocseqSn]
    ON [dbo].[QADEF]([DEFDATE] ASC)
    INCLUDE([WONO], [QASEQMAIN], [LOCSEQNO], [SERIALNO]);


GO
CREATE NONCLUSTERED INDEX [LocseqQaseqDeptid]
    ON [dbo].[QADEF]([LOCSEQNO] ASC)
    INCLUDE([QASEQMAIN], [DEPT_ID]);


GO
CREATE NONCLUSTERED INDEX [serialno]
    ON [dbo].[QADEF]([SERIALNO] ASC);


GO
-- =============================================
-- Author:		Vicky Lu
-- Create date: 09/18/15
-- Description:	Insert trigger for Qadef.  Need to update QaMaxPas and Qadef.PassNum
-- Modification:
-- =============================================
CREATE TRIGGER [dbo].[Qadef_Insert]
   ON  [dbo].[Qadef]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT, 
			@Wono char(10), @Dept_id char(4), @Serialno char(30), @SerialUniq char(10), @MaxPassNum numeric(2,0), 
			@UqQaMaxPas char(10), @NewMaxPassNum numeric(10), @LocSeqno char(10)

	BEGIN TRANSACTION
	BEGIN TRY

	SELECT @Wono = Inserted.Wono, @Dept_id = Qainsp.Dept_id, @Serialno = Serialno, @SerialUniq = SerialUniq, @LocSeqno = LocSeqno
		FROM Inserted, Qainsp
		WHERE Inserted.Qaseqmain = Qainsp.Qaseqmain 

	SELECT @MaxPassNum = ISNULL(MaxPassNum,0), @UqQaMaxPas = UqQaMaxPas 
		FROM QaMaxPas
		WHERE Wono = @Wono 
		AND Dept_id = @Dept_id
		AND Serialno = @Serialno

	IF @@ROWCOUNT =	0	-- no record is found in QaMaxPas
		BEGIN
			INSERT INTO QaMaxPas (UqQaMaxPas, Wono, Dept_id, Serialno, SerialUniq, MaxPassNum)
				VALUES (dbo.fn_GenerateUniqueNumber(), @Wono, @Dept_id, @Serialno, @SerialUniq, 1)
			SET @NewMaxPassNum = 1
		END	
	ELSE
		-- Found, just update QaMaxPas.MaxPassNum
		BEGIN
		UPDATE QaMaxPas SET MaxPassNum = @MaxPassNum + 1
			WHERE UqQaMaxPas = @UqQaMaxPas
		SET @NewMaxPassNum = @MaxPassNum + 1
	END
	
	-- Now update Qadef.PassNum by QaMaxPas.MaxPassNum
	UPDATE Qadef SET PassNum = @NewMaxPassNum WHERE LocSeqno = @LocSeqno

	END TRY
	BEGIN CATCH
		SELECT 
			@ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();
			RAISERROR (@ErrorMessage, -- Message text.
				   @ErrorSeverity, -- Severity.
				   @ErrorState -- State.
				   );
			IF @@TRANCOUNT <>0
				ROLLBACK TRAN ;
			
	END CATCH
	
IF @@TRANCOUNT>0
	COMMIT
END