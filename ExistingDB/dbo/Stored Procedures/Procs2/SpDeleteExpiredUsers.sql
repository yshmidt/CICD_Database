-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 06/19/13 
-- Description:	Remove Expired users
-- 07/10/13 YS use left outer join in case A.fkuserid is not connected to profile. That is probably a desktop user. Will give this user 3 hours till timeout
-- =============================================
CREATE PROCEDURE [dbo].[SpDeleteExpiredUsers]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION
	BEGIN TRY
		;WITH tDel
		AS
		-- select all expired sessions
		-- 07/10/13 YS use left outer join in case A.fkuserid is not connected to profile and give a user 3 hours
		(SELECT A.sessionId,A.fkuserId,A.lastActivityDate,ISNULL(p.minutelimit,180) as minutelimit FROM aspmnx_ActiveUsers A LEFT OUTER JOIN aspnet_Profile P 
				on A.fkuserid=P.UserId WHERE 
				1=CASE WHEN ISNULL(p.minutelimit,180)=0 OR GETDATE()<DateAdd(mi,ISNULL(p.minutelimit,180),A.lastActivityDate) THEN 0 ELSE 1 END
		)
		DELETE FROM aspmnx_ActiveUsers where sessionId+cast(fkuserId as varchar(36)) IN (SELECT sessionId+cast(fkuserId as varchar(36)) from tDel)
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT>0
			ROLLBACK
	END CATCH
	IF @@TRANCOUNT>0
		COMMIT
	
END