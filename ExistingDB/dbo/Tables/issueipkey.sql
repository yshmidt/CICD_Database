CREATE TABLE [dbo].[issueipkey] (
    [issueIpKeyUnique] CHAR (10)       CONSTRAINT [DF_issueipkey_issueIpKeyUnique] DEFAULT ('') NOT NULL,
    [invtisu_no]       CHAR (10)       CONSTRAINT [DF_issueipkey_invtisu_no] DEFAULT ('') NOT NULL,
    [qtyissued]        NUMERIC (12, 2) CONSTRAINT [DF_issueipkey_qtyissued] DEFAULT ((0)) NOT NULL,
    [ipkeyunique]      CHAR (10)       CONSTRAINT [DF_issueipkey_ipkeyunique] DEFAULT ('') NOT NULL,
    [kaseqnum]         CHAR (10)       CONSTRAINT [DF_issueipkey_kaseqnum] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_issueipkey] PRIMARY KEY CLUSTERED ([issueIpKeyUnique] ASC)
);


GO
CREATE NONCLUSTERED INDEX [issueipkey]
    ON [dbo].[issueipkey]([ipkeyunique] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_invtisu_no]
    ON [dbo].[issueipkey]([invtisu_no] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_issueipkeykit]
    ON [dbo].[issueipkey]([kaseqnum] ASC);


GO

-- =============================================
-- Author:		Yelena Shmist
-- Create date: 08/13/2014
-- Description:	inserrt trigger for IssueIpKey
-- 03/17/2016 YS revised for the new structure
-- =============================================
CREATE TRIGGER [dbo].[IssueIpKey_Insert] ON [dbo].[issueipkey] 
	AFTER INSERT
AS

BEGIN

	SET NOCOUNT ON;
	-- 03/17/16 YS added error trap
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	BEGIN TRY
	BEGIN TRANSACTION
		--- need to check if can find ipkey and if balance qty > than issued 
		SELECT Inserted.ipkeyunique FROM Inserted  where ipkeyunique NOT IN (SELECT IPKEYUNIQUE from IpKey)
		
		IF (@@ROWCOUNT<>0)
			BEGIN
				RAISERROR('Cannot find IpKey to issue. This operation will be cancelled.', -- Message text.
					16, -- Severity.
					1 -- State.
				);
				
			END  -- IF (@@ROWCOUNT<>0)
		-- check if balance
		SELECT i.ipkeyunique 
		FROM Inserted I INNER JOIN IpKey on I.ipkeyunique=IpKey.IPKEYUNIQUE
		WHERE IpKey.pkgBalance < I.qtyissued
		IF (@@ROWCOUNT<>0)
			BEGIN
				RAISERROR('Not enough quantities to issue. This operation will be cancelled.', -- Message text.
					16, -- Severity.
					1 -- State.
				);
				
			END  -- IF (@@ROWCOUNT<>0)
		

		UPDATE IpKey SET pkgBalance=pkgBalance-i.qtyissued
		FROM Inserted I where I.ipkeyunique=IpKey.IPKEYUNIQUE
		
	
	END TRY	
	BEGIN CATCH
		IF @@TRANCOUNT <>0
			ROLLBACK TRAN ;
			SELECT @ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();
			RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
			RETURN
	END CATCH
	IF @@TRANCOUNT <>0
	COMMIT TRANSACTION
END -- end of the trigger code	