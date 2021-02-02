-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/08/10
-- Description:	Insert record into the trigger 
-- =============================================
CREATE PROCEDURE dbo.Sp_TriggerInsert
	-- Add the parameters for the stored procedure here
	@lcUniqTrig char(10), @lcRef nvarchar(max)=' ' , @lnIsBatch bit=0, @lcAttachfile nvarchar(max)=' ',@lReturn char(10) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET @lReturn='Continue';
	DECLARE @lcSection char(10),@lcTrigType char(10),@lcDescript nvarchar(75),@lcScreenName nvarchar(15),@lcUniqOpen char(10);
	 
	 SELECT @lcSection=Section,@lcTrigType =TrigType,@lcDescript=descript
	 FROM Triggers 
	 WHERE UniqTrig =@lcUniqTrig and TRIGSTATUS=1;

	IF @@ROWCOUNT =0
		SET @lReturn=' ';
	ELSE -- @@ROWCOUNT =0
	BEGIN
		SET @lcScreenName = CASE 
			WHEN @lcSection='SALES' THEN 'SALETRGR'
			WHEN @lcSection='MATERIAL' THEN 'MATLTRGR'
			WHEN  @lcSection='PRODUCTION' THEN 'PRODTRGR' 
			WHEN  @lcSection='QUALITY' THEN 'QUALTRGR'
			ELSE ' ' END
			
		IF (@lcTrigType<>'REMINDER') and  @lcSection<>' '
		BEGIN
			-- check if installed
			SELECT Installed 
			FROM Items 
			WHERE ScreenName = @lcScreenName and INSTALLED=1
			IF @@ROWCOUNT =0
				SET @lReturn=' ';
						
		END -- (@lcTrigType<>'REMINDER')
	END --@@ROWCOUNT =0
	IF (@lReturn = 'Continue')
	BEGIN
		SET @lReturn =' '
		-- check if there is open trigger for the same item
		SELECT @lcUniqOpen=UniqOPen
			FROM TrigOpen 
		WHERE UniqTrig = @lcUniqTrig 
		AND Ref = @lcRef
		AND ClearDtTm IS NULL ;
		IF @@ROWCOUNT=0
		BEGIN
			EXEC sp_GenerateUniqueValue @lcUniqOpen OUTPUT
			INSERT INTO TrigOpen (UniqTrig, UniqOpen, TrigDtTm,Ref, AttachFile) 
				VALUES (@lcUniqTrig, @lcUniqOpen, GETDATE(), @lcRef, @lcAttachFile)
			SET @lReturn =@lcUniqOpen;
				
		END -- @@ROWCOUNT=0 in the trigopen
		ELSE -- @@ROWCOUNT=0 in the trigopen
		BEGIN -- @@ROWCOUNT=0 in the trigopen
			-- Open trigger for the item exists if trigger is batch and type is action update reference
			IF (@lnIsBatch = 2 and @lcTrigType ='Action')
				UPDATE TRIGOPEN SET REF=CASE WHEN REF<>' ' THEN REF+', '+@lcRef ELSE @lcRef END WHERE UniqOpen=@lcUniqOpen 
		END -- @@ROWCOUNT=0 in the trigopen
	END -- IF @lReturn='Continue'
END