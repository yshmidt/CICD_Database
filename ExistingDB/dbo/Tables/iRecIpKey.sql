CREATE TABLE [dbo].[iRecIpKey] (
    [iRecIpKeyUnique] CHAR (10)       CONSTRAINT [DF_iRecIpKey_iRecIpKeyUnique] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL,
    [invtrec_no]      CHAR (10)       CONSTRAINT [DF_iRecIpKey_invtrec_no] DEFAULT ('') NOT NULL,
    [qtyPerPackage]   NUMERIC (12, 2) CONSTRAINT [DF_iRecIpKey_qtyPerPackage] DEFAULT ((0)) NOT NULL,
    [qtyReceived]     NUMERIC (12, 2) CONSTRAINT [DF_iRecIpKey_qtyReceived] DEFAULT ((0)) NOT NULL,
    [ipkeyunique]     CHAR (10)       NOT NULL,
    CONSTRAINT [PK_iRecIpKey] PRIMARY KEY CLUSTERED ([iRecIpKeyUnique] ASC)
);


GO
CREATE NONCLUSTERED INDEX [invtrec_no]
    ON [dbo].[iRecIpKey]([invtrec_no] ASC);


GO
CREATE NONCLUSTERED INDEX [ipkey]
    ON [dbo].[iRecIpKey]([ipkeyunique] ASC);


GO
-- =============================================
-- Author:		Yelena Shmist
-- Create date: 08/04/2014
-- Description:	inserrt trigger for iRecIpKey
-- Modified: 08/20/14 YS check if any parts with useIpKey=0 has Ipkey generated
-- 05/06/16 YS removed isallocated form the ipkey table
-- 12/08/2017 Rajendra K : Added logic for Update IPKEY PkgBalance if IpKey already exists else insert new record
-- 01/10/2018 Rajendra K : Added ElSE after IF Section
-- =============================================
CREATE TRIGGER [dbo].[iRecIpKey_Insert] ON [dbo].[iRecIpKey] 
	AFTER INSERT
AS

BEGIN

	SET NOCOUNT ON;
	--  08/20/14 YS added variable for the error. Want to see if I can raise an error in the CATCH blcok. 
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

	BEGIN TRANSACTION
	BEGIN TRY
		IF EXISTS(SELECT 1 from  Inserted I INNER JOIN Invt_rec R on I.invtrec_no=R.invtrec_no
			INNER JOIN Inventor P on r.UNIQ_KEY=p.uniq_key where p.useipkey=0)
			BEGIN
				-- 08/20/14 YS severity with 11-19 will move process to the catch block
				RAISERROR ('IP Key was entered for parts, that have IpKey turned off', -- Message text.
               16, -- Severity.
               1 -- State.
               );

		END -- IF EXISTS

		-- 12/08/2017 Rajendra K : Added for Update IPKEY PkgBalance if IpKey already exists else insert new record
		IF EXISTS(SELECT 1 FROM Inserted I INNER JOIN IPKEY IP ON I.ipkeyunique = IP.IPKEYUNIQUE)
		BEGIN 
			UPDATE IPKEY SET pkgBalance = IPKEY.pkgBalance + I.qtyReceived FROM Inserted I  INNER JOIN IPKEY ON I.ipkeyunique = IPKEY.IPKEYUNIQUE
		END
		ELSE -- 01/10/2018 Rajendra K : Added ElSE after IF Section
		BEGIN
		INSERT INTO [dbo].[IPKEY]
           ([IPKEYUNIQUE]
           ,[UNIQ_KEY]
           ,[UNIQMFGRHD]
           ,[LOTCODE]
           ,[REFERENCE]
           ,[EXPDATE]
           ,[RecordId]
           ,[TRANSTYPE]
           ,[originalPkgQty]
           ,[pkgBalance]
           ,[fk_userid]
           ,[recordCreated]
           ,[W_KEY]
           ,[originalIpkeyUnique])
		SELECT 
           I.ipkeyunique
           ,R.UNIQ_KEY
           ,R.UNIQMFGRHD
           ,R.LOTCODE
           ,R.REFERENCE
           ,R.EXPDATE
           ,R.INVTREC_NO as RecordId
		   ,'R' as TRANSTYPE
           ,I.qtyPerPackage
           ,I.qtyReceived
           ,R.fk_userid
           ,getdate() as recordCreated
           ,r.W_KEY
           ,' ' as originalIpkeyUnique FROM Inserted I INNER JOIN Invt_rec R on I.invtrec_no=R.INVTREC_NO
	    END
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
			RETURN
	END CATCH
	IF @@TRANCOUNT <>0
	COMMIT TRANSACTION
END -- end of the trigger code	