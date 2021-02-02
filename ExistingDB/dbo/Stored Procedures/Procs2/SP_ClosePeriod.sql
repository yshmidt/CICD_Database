-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 01/24/2012
-- Description:	Close 
-- Modified: 06/22/15 YS use SequenceNumber in fiscalYrs table to find next prior year instead of the FiscalYr field
--07/20/15 YS need cNextFy to popuate glsys table
--11/23/15 VL added code to update Cashbook records for FC
--04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- =============================================
CREATE PROCEDURE [dbo].[SP_ClosePeriod]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- check if current end and yeqar end are the same
	-- 11/23/15 VL added to check if FC is installed or not
	DECLARE @fy_end as Date,@Cur_End as Date,@nCurrentPeriod int,@cCurrenFy char(4),@cNextFy char(4),@Next_fy_end as Date,
	--06/22/15 YS use SequenceNumber in fiscalYrs table
	@currentSequenceNumber int,@nextSequenceNumber int, @lFCInstalled bit
	-- 04/08/16 VL changed to get FC installed from function
	SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

	--06/22/15 YS updated AllFYPeriods UDT type
	Declare @T as dbo.AllFYPeriods
    
	
	
	SELECT @fy_end=CAST(GlSys.Fy_End_Dt as DATE),
			@Cur_End=CAST(Cur_End_Dt as date),
			@nCurrentPeriod=glsys.CUR_PERIOD,
			@cCurrenFy = glsys.CUR_FY,
			@Next_fy_end=CAST(GlSys.Fy_End_Dt as DATE),
			@cNextFy=glsys.CUR_FY FROM GLSYS   -- assign  @cNextFy same as current, will change if end of fy

			
	-- will find all the records starting with current fy
	insert into @T EXEC GlFyrstartEndView @cCurrenFy	;
	select @currentSequenceNumber=t.sequenceNumber from @T T where t.fiscalyr=@cCurrenFy
	-- set to current in case closing period not the year
	set @nextSequenceNumber=@currentSequenceNumber

	-- recalculate TB
	EXEC sp_RecalculateTB	
			
	BEGIN TRANSACTION
	
	-- {11/23/15 VL added code to update Cashbook records for FC
	IF @lFCInstalled = 1
		BEGIN
		EXEC sp_UpdCashBook 
	END
	-- 11/23/15 VL End}

	IF (@fy_end=@Cur_End)
	BEGIN
		-- end of the year
		-- check if the next year exists
		--06/22/15 YS use SequenceNumber in fiscalYrs table
		--07/20/15 YS need cNextFy to popuate glsys table
		--SELECT @cNextFy=t.FiscalYr FROM @T t WHERE CAST(t.FiscalYr as int)=CAST(@cCurrenFy as int)+1
		SELECT @nextSequenceNumber =t.sequenceNumber, 
			 @cNextFy=t.FiscalYr
			FROM @T t WHERE t.sequenceNumber=@CurrentsequenceNumber+1
					
		IF @@ROWCOUNT =0
		BEGIN
		-- raise an error
		RAISERROR ('This is a Fiscal Year Close and the next fiscal year has not been set up in the system manager. This must be done before the last period of the current fiscal year can be closed.
			Cannot close current Fiscal Year %s'
            ,16 -- Severity.
            ,1 -- State 
            ,@cCurrenFy) -- current fy 
		ROLLBACK
		RETURN 
		END -- IF @@ROWCOUNT =0
		-- if pass this code no problem with the next FY
		--06/22/15 YS use SequenceNumber in fiscalYrs table
		--select @Next_fy_end=CAST(GLFISCALYRS.dEndDate as DATE) FROM GLFISCALYRS WHERE FISCALYR =@cNextFy
		select @Next_fy_end=CAST(GLFISCALYRS.dEndDate as DATE) FROM GLFISCALYRS WHERE sequenceNumber =@nextSequenceNumber
		UPDATE GLFISCALYRS SET lCurrent = 0
		--UPDATE GLFISCALYRS SET lClosed=1 WHERE FiscalYr =@cCurrenFy 
		--UPDATE GLFISCALYRS SET lCurrent = 1 WHERE FiscalYr =@cNextFy
		UPDATE GLFISCALYRS SET lClosed=1 WHERE sequenceNumber =@CurrentsequenceNumber 
		UPDATE GLFISCALYRS SET lCurrent = 1 WHERE sequenceNumber=@nextSequenceNumber

	END -- (@fy_end=@Cur_End)
	-- next code is common for both end of period and end of fy, notice that @cNextFy=@cCurrenFy if only period has to be changed
	-- find new period and replace values in GlSys
	--06/22/15 YS use SequenceNumber in fiscalYrs table
	--UPDATE GLSYS SET CUR_PERIOD=CASE WHEN (@fy_end=@Cur_End) THEN 1 ELSE @nCurrentPeriod+1 END ,
	--				 CUR_FY = @cNextFy,
	--				 FY_UNIQ = T.fk_fy_uniq,
	--				 FY_END_DT = @Next_fy_end ,
	--				 CUR_END_DT = t.EndDate from @T T 
	--				 where t.FiscalYr =@cNextFy and t.Period =CASE WHEN (@fy_end=@Cur_End) THEN 1 ELSE @nCurrentPeriod+1 END
	UPDATE GLSYS SET CUR_PERIOD=CASE WHEN (@fy_end=@Cur_End) THEN 1 ELSE @nCurrentPeriod+1 END ,
					 CUR_FY = @cNextFy,
					 FY_UNIQ = T.fk_fy_uniq,
					 FY_END_DT = @Next_fy_end ,
					 CUR_END_DT = t.EndDate from @T T 
					 where t.sequenceNumber =@nextSequenceNumber and t.Period =CASE WHEN (@fy_end=@Cur_End) THEN 1 ELSE @nCurrentPeriod+1 END
					 
	UPDATE GLFYRSDETL SET lCurrent = 0
	--UPDATE GLFYRSDETL SET lClosed=1 
	--		FROM @T T 
	--		WHERE t.FiscalYr =@cCurrenFy 
	--		AND t.Period =@nCurrentPeriod AND t.fyDtlUniq=GLFYRSDETL.FYDTLUNIQ
	--UPDATE GLFYRSDETL SET lCurrent = 1 
	--		FROM @T T 
	--		WHERE t.FiscalYr =@cNextFy 
	--		AND t.Period =CASE WHEN (@fy_end=@Cur_End) THEN 1 ELSE @nCurrentPeriod+1 END 
	--		AND GLFYRSDETL.FYDTLUNIQ = T.fyDtlUniq  
	--06/22/15 YS use SequenceNumber in fiscalYrs table
	UPDATE GLFYRSDETL SET lClosed=1 
			FROM @T T 
			WHERE t.sequenceNumber =@CurrentsequenceNumber 
			AND t.Period =@nCurrentPeriod AND t.fyDtlUniq=GLFYRSDETL.FYDTLUNIQ
	UPDATE GLFYRSDETL SET lCurrent = 1 
			FROM @T T 
			WHERE t.SequenceNumber =@nextSequenceNumber 
			AND t.Period =CASE WHEN (@fy_end=@Cur_End) THEN 1 ELSE @nCurrentPeriod+1 END 
			AND GLFYRSDETL.FYDTLUNIQ = T.fyDtlUniq  

   COMMIT	
  		
	
END