-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 01/11/2018
-- Description:	Procedure to auto-reconcile PI
-- =============================================
CREATE PROCEDURE [dbo].[AutoReconcilePI] 
	-- Add the parameters for the stored procedure here
	@UNIQPIHEAD char(10) = '' ,@reason varchar (20)='Physical Inventory'
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	 -- Insert statements for procedure here
	DECLARE @ErrorMessage NVARCHAR(max);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	BEGIN TRY

    -- Insert statements for procedure here
	if (@UNIQPIHEAD='') and (select count(*)  from PHYINVTH where PISTATUS='In Process')>1
		RAISERROR('More than one active PI. Cannot continue. Please provide UNIQPIHEAD as a first parameter.',-- Message text.
		      16, -- Severity.
               1 -- State.
               );
		
	if (@UNIQPIHEAD='') and (select count(*)  from PHYINVTH where PISTATUS='In Process')=0
		RAISERROR('No current PI with status ''In Process'' was found.',-- Message text.
		      16, -- Severity.
               1 -- State.
               );
		

	IF @UNIQPIHEAD=''
		select @UNIQPIHEAD=UNIQPIHEAD from PHYINVTH where PISTATUS='In Process'
	BEGIN TRANSACTION
	UPDATE PHYINVT set INVREASON=@reason,INVRECNCL=1 where UNIQPIHEAD=@UNIQPIHEAD and PHYDATE is not null 
	IF @@TRANCOUNT>0
		COMMIT
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
END