-- =============================================
-- Author:	Sachin b
-- Create date: 03/06/2017
-- Description:	this procedure will be called from the SF module and set ISSID Done for the Components 
-- 03/20/2017 Sachin B Add SID Done condition if/ELSE set all sid Done in case of return/replace and in case of transfer set SID done only for those which have pkgbalance =0
-- =============================================
CREATE PROCEDURE [dbo].[SetSIDDoneForComponentReturn]
	-- Add the parameters for the stored procedure here
	@tSerailIssue tSerialsIssue2Kit READONLY,
	@tIpkeyIssue tIpkeyIssue2Kit READONLY,
	@wono char(10) = '',
	@userid uniqueidentifier= null,
	@fromDeptKey varchar(10),
	@IsAllSIDDone bit

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	
	BEGIN TRY
	BEGIN TRANSACTION

	    -- 03/20/2017 Sachin B Add SID Done condition if/ELSE set all sid Done in case of return/replace and in case of transfer set SID done only for those which have pkgbalance =0
	    IF(@IsAllSIDDone =1)
			BEGIN
				IF (Exists (select 1 from @tSerailIssue))
					BEGIN
						UPDATE im SET im.IsSIDDone = 1, im.Date =GETDATE(),im.fk_userid =@userid FROM WOActiveSID im
						WHERE im.IPKEYUNIQUE in (SELECT IPKEYUNIQUE FROM @tSerailIssue) AND WONO =@wono AND DeptKey =@fromDeptKey
					END

				IF (Exists (select 1 from @tIpkeyIssue))
					BEGIN
						UPDATE im SET im.IsSIDDone = 1, im.Date =GETDATE(),im.fk_userid =@userid FROM WOActiveSID im
						WHERE im.IPKEYUNIQUE in (SELECT IPKEYUNIQUE FROM @tIpkeyIssue) AND WONO =@wono AND DeptKey =@fromDeptKey
					END
			END
		ELSE
		   BEGIN
		        IF (Exists (select 1 from @tSerailIssue))
					BEGIN
							UPDATE im
							SET im.IsSIDDone = 1, im.Date =GETDATE(),im.fk_userid =@userid FROM WOActiveSID im
							Inner JOIN IPKEY ip on im.IPKEYUNIQUE = ip.IPKEYUNIQUE
							WHERE im.IPKEYUNIQUE in (SELECT IPKEYUNIQUE FROM @tSerailIssue) AND WONO =@wono AND DeptKey =@fromDeptKey and ip.pkgBalance = 0
					END

				IF (Exists (select 1 from @tIpkeyIssue))
					BEGIN
							UPDATE im
							SET im.IsSIDDone = 1, im.Date =GETDATE(),im.fk_userid =@userid FROM WOActiveSID im
							Inner JOIN IPKEY ip on im.IPKEYUNIQUE = ip.IPKEYUNIQUE
							WHERE im.IPKEYUNIQUE in (SELECT IPKEYUNIQUE FROM @tIpkeyIssue) AND WONO =@wono AND DeptKey =@fromDeptKey and ip.pkgBalance = 0
					END
		   END		
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