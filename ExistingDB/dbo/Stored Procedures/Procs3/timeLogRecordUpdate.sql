-- =============================================
-- Author:		David Sharp
-- Create date: 6/22/2012
-- Description:	update a time record
-- 11/18/15 YS make sure that work order has leading zeros
-- 04/20/16 YS allow update record only if the user has edit rights, even if the @userId<>inUserId
-- 12/20/16 Raviraj P Update the number while updating the job
-- =============================================
CREATE PROCEDURE [dbo].[timeLogRecordUpdate]
	-- Add the parameters for the stored procedure here
	@userId uniqueidentifier,
	@comment varchar(MAX),
	@dateIn smalldatetime,
	@dateOut smalldatetime,
	@timeType varchar(10),
	@deptId varchar(8),
	@record varchar(10),
	@deleted bit=0,
	@uniqlogin varchar(10),
	@number int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--04/20/16 first check if the user has rights
	declare @roleid uniqueidentifier ,@isinrole bit=0,@username nvarchar(200) = null,@useridError nvarchar(50)

	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	BEGIN TRY
		set @useridError = cast(@userid as nvarchar(50))
		select @roleid = roleid from  aspnet_Roles where rolename='TIMELOG_Edit'
		select @username= rtrim(p.firstname)+' '+rtrim(p.lastName) from aspnet_profile P where userid=@userId
		if @username is null
			RAISERROR('Cannot find User with ID: %s doesn''t exists in the system. This operation will be cancelled.',11,1,@useridError )
		
		exec @isinrole=dbo.aspmnxIsUserInRole @userid,@roleid,1
		if @isinrole=0
			RAISERROR('User %s has no rights to adjust the time log. This operation will be cancelled.',11,1,@username)
			

	
	
		BEGIN TRANSACTION

	
		-- Insert statements for procedure here
		UPDATE DEPT_LGT
		-- 11/18/15 YS make sure that work order has leading zeros
		SET
			WONO=CASE WHEN @record=' ' then @record else dbo.padl(ltrim(rtrim(@record)),10,'0') end,
			DATE_IN=@dateIn,
			DATE_OUT=@dateOut,
			TIME_USED=DATEDIFF(minute,@dateIn,@dateOut),
			TMLOGTPUK=@timeType,
			DEPT_ID=@deptId,
			[comment]=@comment,
			uDeleted=@deleted,
			number = @number -- 12/20/16 Raviraj P Update the number while updating the job
		WHERE UNIQLOGIN=@uniqlogin 
		--04/20/16 remove check for the in user matching current user
		--AND inUserId=@userId
	
		--Cannot set time out while editing a current record, must first logout
		UPDATE DEPT_CUR
		-- 11/18/15 YS make sure that work order has leading zeros
		SET
			WONO=CASE WHEN @record=' ' then @record else dbo.padl(ltrim(rtrim(@record)),10,'0') end,
			DATE_IN=@dateIn,
			TMLOGTPUK=@timeType,
			DEPT_ID=@deptId,
			[comment]=@comment,
			uDeleted=@deleted,
			number = @number -- 12/20/16 Raviraj P Update the number while updating the job
		WHERE UNIQLOGIN=@uniqlogin 
		--04/20/16 remove check for the in user matching current user
		--AND inUserId=@userId
		--AND inUserId=@userId
	end try
	begin catch
		IF @@TRANCOUNT>0
		ROLLBACK
		SELECT @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();
		RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );

	end catch
	IF @@TRANCOUNT>0
	COMMIT
END