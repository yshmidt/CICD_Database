-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 01/24/2012
-- Description:	Generate records for closing JE
-- Modified: 10/16/2013 YS assign last date of closing period to the transaction date
--06/23/15 YS GlFyrstartEndView will generate records starting with current fy-1 (no changes to this procedure)
-- =============================================
CREATE PROCEDURE [dbo].[SP_GenerateClosingJE]
	-- Add the parameters for the stored procedure here
	@nPeriod int=0,@cFy char(4)=' ',@cSaveinit char(8)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- 10/16/13 YS assign end of the closing period to the transaction date
	
	DECLARE @Jeno [numeric](6,0),
			@JEOHKEY char(10)=' ',
			@RET_EARN_GL char(13),
			@nEarnValue numeric(14,2),
			@nRecordGenerated integer,
			@dTransaction as smalldatetime
   
    -- Insert statements for procedure here
	-- if no parameters sent use current fy
	
	
	SELECT @nPeriod = CASE WHEN @nPeriod=0 THEN Glsys.CUR_PERIOD ELSE @nPeriod  END ,
		   @cFy = CASE WHEN @cFy=' ' THEN Glsys.CUR_FY  ELSE @cFy END,
		   @RET_EARN_GL=Glsys.RET_EARN 
		   FROM GLSYS 
     Declare @T as dbo.AllFYPeriods
     --06/23/15 YS GlFyrstartEndView will generate records starting with current fy-1
	 -- will find all the records starting with current fy
	insert into @T EXEC GlFyrstartEndView @cFy	;
-- 10/16/13 YS assign end of the closing period to the transaction date
     select @dTransaction =fy.EndDate  from @t fy where fy.FISCALYR=@cFy and fy.Period =@nPeriod
		   
	-- recalculate TB
	EXEC sp_RecalculateTB	   
	DECLARE @JeClosing Table (gl_nbr char(13),Debit numeric(14,2),Credit numeric(14,2),nEarnValue numeric(14,2))
	
	INSERT INTO @JeClosing SELECT Gltrans.Gl_nbr,
		CASE WHEN SUM(Debit-Credit) >0 THEN 0.00 ELSE ABS(SUM(Debit-Credit)) END AS Debit,
		CASE WHEN SUM(Debit-Credit) >0 THEN SUM(Debit-Credit) ELSE 0.00 END AS Credit, SUM(Debit-Credit) as nEarnValue
	FROM Gltrans INNER JOIN Gl_nbrs ON Gltrans.GL_NBR =Gl_nbrs.GL_NBR 
	INNER JOIN GLTRANSHEADER ON Gltrans.Fk_GLTRansUnique =GLTRANSHEADER.GLTRANSUNIQUE   
	WHERE Gl_nbrs.Gl_class = 'Posting' AND Stmt = 'INC'
		AND Gltransheader.Fy = @cfy
	GROUP BY Gltrans.Gl_nbr,Gltransheader.Fy,Gl_nbrs.Gl_descr
	HAVING  SUM(Debit-Credit)<> 0 
	SET @nRecordGenerated= @@ROWCOUNT 
	IF @nRecordGenerated<>0
	BEGIN
		-- find total earning
		SELECT @nEarnValue = SUM(nEarnValue) FROM @JeClosing
          
		-- populate JE table
		
		BEGIN TRANSACTION
		-- 10/16/13 YS assign end of the closing period to the transaction date
		EXEC GetNextJeno @Jeno OUTPUT 
		SET @JEOHKEY=dbo.fn_GenerateUniqueNumber()
		INSERT INTO [GLJEHDRO]
           ([JE_NO]
           ,[TRANSDATE]
           ,[SAVEINIT]
           ,[REASON]
           ,[STATUS]
           ,[JETYPE]
           ,[PERIOD]
           ,[FY]
           ,[JEOHKEY])
		VALUES
           (@Jeno
           ,@dTransaction 
           ,@cSaveinit
           ,'Closing Entry'
           ,'NOT APPROVED'
           ,'CLOSE'
           ,@nPeriod
           ,@cFY
           ,@JEOHKEY)
           
		INSERT INTO [GLJEDETO]
           ([GL_NBR]
           ,[DEBIT]
           ,[CREDIT]
           ,[JEODKEY]
           ,[FKJEOH])
		SELECT GL_NBR 
		    ,DEBIT
			,CREDIT
           ,dbo.fn_GenerateUniqueNumber()
           ,@JEOHKEY FROM @JeClosing 
          --- create trnasaction into return earning gl 
          INSERT INTO [GLJEDETO]
           ([GL_NBR]
           ,[DEBIT]
           ,[CREDIT]
           ,[JEODKEY]
           ,[FKJEOH])
		SELECT @RET_EARN_GL
           ,CASE WHEN @nEarnValue<0 THEN 0.00 ELSE @nEarnValue END 
           ,CASE WHEN @nEarnValue<0 THEN ABS(@nEarnValue) ELSE 0.00 END
           ,dbo.fn_GenerateUniqueNumber()
           ,@JEOHKEY
           
        COMMIT   
		SELECT JEOHKEY,Je_no FROM GlJehdro where JEOHKEY=@JEOHKEY
	END -- @nRecordGenerated<>0
	
END