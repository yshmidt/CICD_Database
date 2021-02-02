-- =============================================
-- Author:	Nilesh Sa
-- Create date: 12/20/2016
-- Description:	this procedure will used to generate Recurring Journal Entries.
-- Nilesh Sa: 09/13 Changed status "NOT APPROVED" to lower case "Not Approved" 
-- Shivshnakar P : 05/29/2020 Update the tRecurringJE user data table and Chnage the Datatype of nextDate form DATETIME to SmallDateTime and Reason VARCHAR(max) 
-- =============================================
CREATE PROCEDURE [dbo].[GenerateRecurringEntries]
	-- Add the parameters for the stored procedure here
	@recurringDetails tRecurringJE READONLY,
	@initials varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- get ready to handle any errors
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	-- Shivshnakar P : 05/29/2020 Update the tRecurringJE user data table and Chnage the Datatype of nextDate form DATETIME to SmallDateTime and Reason VARCHAR(max) 
	DECLARE @glrhdrkey CHAR(10),@frequency CHAR(12), @fy CHAR(10), @nextDate SmallDateTime, @period NVARCHAR(200), @Recdescr CHAR(30), @recref CHAR(10), @saveInit CHAR(8), 
	@UniqeId VARCHAR(10),@UniqeHrdId VARCHAR(10), @UniqeDetId VARCHAR(10), @Reason VARCHAR(max)


	DECLARE cRecurringJE CURSOR FORWARD_ONLY FOR
			SELECT  r.Glrhdrkey,r.Frequency, r.FY,r.NextDate,r.Period,r.Recdescr,r.Recref,r.SaveInit,r.UniqeId,r.Reason
				FROM @recurringDetails r
	OPEN cRecurringJE
	FETCH cRecurringJE INTO @glrhdrkey,@frequency,@fy,@nextDate,@period,@Recdescr,@recref,@saveInit,@UniqeId, @Reason
		WHILE (@@fetch_status = 0)
		BEGIN
			BEGIN TRY
			BEGIN TRANSACTION
			DECLARE @JENextNumber NUMERIC(6,0)=0
			EXEC GetNextJeNo @JENextNumber OUT
			SET @UniqeHrdId =dbo.fn_GenerateUniqueNumber()
				INSERT INTO GLJEHdrO(JEOHKEY,JE_NO,TRANSDATE,SAVEINIT,REASON,STATUS,JETYPE,PERIOD,FY) 
				SELECT @UniqeHrdId,@JENextNumber,@nextDate,@initials,@Reason,'Not Approved','RECURRING',@period,@fy
				--Nilesh Sa: 09/13 Changed status "NOT APPROVED" to lower case "Not Approved"  
			    -- Shivshnakar P : 05/29/2020 Update the tRecurringJE user data table and Chnage the Datatype of nextDate form DATETIME to SmallDateTime and Reason VARCHAR(max) 
				INSERT INTO GLJEDETO(GL_NBR,DEBIT,CREDIT,JEODKEY,FKJEOH) 
				SELECT gl_nbr,debit,credit,dbo.fn_GenerateUniqueNumber() as JEODKEY,@UniqeHrdId 
					FROM [GlRjDet] 
				WHERE fkglrhdr = @glrhdrkey
			
				 UPDATE Glrjhdr SET LASTGEN_DT=@nextDate,LASTPERIOD= @period,LAST_FY=@fy WHERE GlRHdrKey=@glrhdrkey

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
			FETCH NEXT FROM cRecurringJE INTO @glrhdrkey,@frequency,@fy,@nextDate,@period,@Recdescr,@recref,@saveInit,@UniqeId,@Reason
			END
	CLOSE cRecurringJE
	DEALLOCATE cRecurringJE
END


