-- =============================================
-- Author:	Shivshankar P
-- Create date: 02/20/2012
-- Description:	checks the standard values for import record
-- EXEC ImportInvtCheckValues @importId ='31CF49DD-CF02-4190-BDE5-970AA8D6059F'
-- =============================================
CREATE PROCEDURE [dbo].[ImportInvtSerialCheck] 
	-- Add the parameters for the stored procedure here
	@importId UNIQUEIDENTIFIER = null,
	@fkRowId UNIQUEIDENTIFIER
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    DECLARE @headerErrs VARCHAR(MAX)
    
    DECLARE @white VARCHAR(20)='i00white',@green VARCHAR(20)='i01green',@blue VARCHAR(20)='i03blue',
	        @orange VARCHAR(20)='i04orange',@red VARCHAR(20)='i05red',
			@sys VARCHAR(20)='01system',@usr VARCHAR(20)='03user'

    	
	DECLARE @ErrTable TABLE (ErrNumber INT,ErrSeverity INT,ErrProc VARCHAR(MAX),ErrLine INT,ErrMsg VARCHAR(MAX))
  

    /* Length Check - Warn for any field with a length longer than the definition length */
	 --Added filter by importid
		BEGIN TRY -- inside begin try
		UPDATE f
			SET [message]='Field will be truncated to ' + CAST(fd.fieldLength AS varchar(50)) + ' characters.',[status]=@orange,[validation]=@sys
			FROM  ImportInvtSerialFields f JOIN  ImportInvtFields  ON FkRowId = ImportInvtFields.RowId
			INNER JOIN importFieldDefinitions fd ON f.fkFieldDefId=fd.fieldDefId AND fd.fieldLength>0
			WHERE  fkImportId=@importId
			AND LEN(f.adjusted)>fd.fieldLength  
	END TRY
	BEGIN CATCH	
		INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)
		SELECT
			ERROR_NUMBER() AS ErrorNumber
			,ERROR_SEVERITY() AS ErrorSeverity
			,ERROR_PROCEDURE() AS ErrorProcedure
			,ERROR_LINE() AS ErrorLine
			,ERROR_MESSAGE() AS ErrorMessage;
		SET @headerErrs = 'There are issues in the fields to be truncated (starting on line:44)'
	END CATCH

	--Added filter by importid
	BEGIN TRY -- inside begin try
		UPDATE f
			SET [message] = '',[status]=@white,[validation]=@sys
			FROM ImportInvtSerialFields f JOIN  ImportInvtFields  ON FkRowId = ImportInvtFields.RowId
			INNER JOIN importFieldDefinitions fd ON f.fkFieldDefId=fd.fieldDefId AND fd.fieldLength>0
			WHERE fkimportid = @importId
			AND LEN(f.adjusted)<fd.fieldLength AND f.original=f.adjusted AND f.[Status] NOT IN (@blue ,@green)
		
		UPDATE f
			SET [message] = '',[status]=@green,[validation]=@usr
			FROM ImportInvtSerialFields f JOIN  ImportInvtFields  ON FkRowId = ImportInvtFields.RowId
			INNER JOIN importFieldDefinitions fd ON f.fkFieldDefId=fd.fieldDefId AND fd.fieldLength>0
			WHERE fkImportId=@importId
			and LEN(f.adjusted)<fd.fieldLength AND f.original<>f.adjusted AND f.[status]<>@blue
  	END TRY
	BEGIN CATCH	
		INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)
		SELECT
			ERROR_NUMBER() AS ErrorNumber
			,ERROR_SEVERITY() AS ErrorSeverity
			,ERROR_PROCEDURE() AS ErrorProcedure
			,ERROR_LINE() AS ErrorLine
			,ERROR_MESSAGE() AS ErrorMessage;
		SET @headerErrs = 'There are issues resetting the status to white to start fresh (starting on line:67)'
	END CATCH
	
		/*verfify all required fields are not empty*/
	BEGIN TRY -- inside begin try
		UPDATE ImportInvtFields 
			SET [message]='Field Cannot Be Blank',[status]=@red,[validation]=@sys
			FROM ImportInvtSerialFields f JOIN  ImportInvtFields  ON FkRowId = ImportInvtFields.RowId JOIN
			importFieldDefinitions fd  ON fd.FieldDefId=f.FkFieldDefId 
			WHERE fd.[required] = 1 
				AND f.adjusted=''
				AND fkImportId=@importId  
	END TRY
	BEGIN CATCH	
		INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)
		SELECT
			ERROR_NUMBER() AS ErrorNumber
			,ERROR_SEVERITY() AS ErrorSeverity
			,ERROR_PROCEDURE() AS ErrorProcedure
			,ERROR_LINE() AS ErrorLine
			,ERROR_MESSAGE() AS ErrorMessage;
		SET @headerErrs = 'There are issues verifying required fields contain a value (starting on line:561)'
	END CATCH

 -- /****** Used to validate Serial number Column Data ******/
	BEGIN TRY
		;WITH SerialData AS (
				SELECT DISTINCT invt.RowId,f.Adjusted,f.SerialDetailId FROM ImportInvtSerialFields f
				JOIN importFieldDefinitions ON f.FkFieldDefId = importFieldDefinitions.FieldDefId
				JOIN ImportInvtFields invt ON  invt.RowId =  f.FkRowId
				--JOIN InvtImportHeader ON invt.FkImportId =  InvtImportId
				where FkRowId=@fkRowId  and FieldName = 'Serialno')

				UPDATE f SET   f.[original]  = CASE WHEN  len (f.[original]) !=30 AND  f.[original]   <>''
		                                     THEN  RIGHT(replicate('0', 30) + ltrim(f.Original), 30) ELSE f.Original  END,
		                       f.[Adjusted]  = CASE WHEN  len (f.Adjusted) !=30  AND f.Adjusted   <>''
						                     THEN  RIGHT(replicate('0', 30) + ltrim(f.Adjusted), 30)  ELSE f.Adjusted END,
				
								f.[Message]= 
												CASE WHEN   ISNULL(invtSe.SERIALUNIQ,'') = ''
															THEN   ''
													ELSE 'Serial number already exists in the system.  Can not add it again.'
												END,
								f.[status]=   CASE WHEN   ISNULL(invtSe.SERIALUNIQ,'') = ''
													THEN  CASE WHEN  f.Adjusted =f.Original THEN  @white WHEN 
													ISNULL(f.Adjusted,'')='' OR f.Adjusted <> f.Original THEN @green
													ELSE  @red END ELSE  @red END,
								f.[validation]= 
										CASE WHEN   ISNULL(invtSe.SERIALUNIQ,'') = ''  THEN  @sys 
											ELSE '' END								
		         
				               FROM  ImportInvtSerialFields f 
							         JOIN SerialData invt ON  invt.SerialDetailId= f.SerialDetailId
				                     OUTER APPLY (SELECT top 1 SERIALUNIQ from INVTSER where SERIALNO =RIGHT(REPLICATE('0', 30) + ltrim(f.Adjusted), 30)) invtSe

      END TRY
		BEGIN CATCH	
			INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)
			SELECT
				ERROR_NUMBER() AS ErrorNumber
				,ERROR_SEVERITY() AS ErrorSeverity
				,ERROR_PROCEDURE() AS ErrorProcedure
				,ERROR_LINE() AS ErrorLine
				,ERROR_MESSAGE() AS ErrorMessage;
			SET @headerErrs = 'There are issues validating the non-string fields (starting on line:310)'
	 END CATCH	
 
END



