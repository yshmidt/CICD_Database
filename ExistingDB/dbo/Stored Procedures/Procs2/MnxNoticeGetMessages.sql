-- =============================================
-- Author:		David Sharp
-- Create date: 3/19/2012
-- Description:	Gets a list of Messages to send
-- 09/24/13 DS Changed result method from OUTPUT to SELECT
-- 09/25/14 DS created separate method for triggers without a sp or select table.
-- =============================================
CREATE PROCEDURE [dbo].[MnxNoticeGetMessages] 
	-- Add the parameters for the stored procedure here
	@sessionId uniqueidentifier = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    --@tSelect should be a select string with the following standard codes:
	--{ds} = data start - indicates the start of a data cell
	--{de} = data end - indicates the end of a data cell
	--{rj} = right justified text in the cell
	--{cj} = center justified text in the cell
	--{lj} = left justified text in the cell
	--{pl} = add 20px padding to the left of the contents
	--{pr} = add 20px padding to the right of the contents
	--{ae} = close a hyper link
    --07/30/13 Check In web service to indicate that it is running 
	UPDATE GENERALSETUP SET LastWebServiceCheckIn = GETDATE() 
				
	DECLARE @tFooterTbl TABLE(selValue varchar(MAX))
	DECLARE @emailTo TABLE(emailAdd varchar(MAX))
    DECLARE @tbody varchar(MAX),@table varchar(MAX),@htmlTable varchar(MAX),@thead varchar(MAX),@id int,@select selectToHtmlType
    
	-- Get a list of trigger SP to be run
	--Values set with each trigger
	


	--07/30/13 YS add table variable to save all the triggers that were pulled forward and for which the dateLustRun was updated
	DECLARE @Triggers TABLE 
	(
	[triggerId] [uniqueidentifier] NOT NULL,
	[triggerName] [varchar](50) NOT NULL,
	[trigType] [varchar](50) NOT NULL,
	[dateLastRun] [datetime2](0) NULL,
	[startDate] [datetime2](0) NOT NULL,
	[repeatInterval] [varchar](50) NOT NULL,
	[repeatValue] [int] NOT NULL,
	[intervalDesc] [varchar](50) NOT NULL,
	[active] [bit] NOT NULL,
	[toString] [varchar](max) NOT NULL,
	[ccString] [varchar](max) NOT NULL,
	[bccString] [varchar](max) NOT NULL,
	[emailSubject] [varchar](max) NOT NULL,
	[emailBody] [varchar](max) NOT NULL,
	[headerBackgroundColor] [varchar](50) NOT NULL,
	[headerColor] [varchar](50) NOT NULL,
	[evenRowBackgroundColor] [varchar](50) NOT NULL,
	[oddRowBackgroundColor] [varchar](50) NOT NULL,
	[tableSelect] [varchar](max) NOT NULL,
	[footerSelect] [varchar](max) NOT NULL,
	[stopIfTableNull] [bit] NOT NULL,
	[triggerSp] [varchar](50) NOT NULL,
	[formSelect] [varchar](max) NOT NULL,
	[successNotify] [bit] NOT NULL,
	[endDate] [datetime2](7) NULL)
--07/30/13 YS change @tsp to be nvarchar type to use with sp_executesql
    DECLARE @trigName varchar(50),@trigId uniqueidentifier, @tSP nvarchar(MAX),@tSelect varchar(MAX),@tFootSel varchar(MAX)='',@tblNullStop bit,
			@tFooter varchar(MAX),@hColor varchar(10),@hBcolor varchar(10),@eRowColor varchar(10),@oRowColor varchar(10),@notify bit,
			@eBody varchar(MAX)='',@eSubject varchar(MAX),@eTo varchar(MAX),@ecTo varchar(max),@ebcTo varchar(MAX)	,
			--07/30/13 YS added a vriable to indicate if @tSP failed to run
			@tryFailed bit 
		
		
	--07/30/13 YS pulle forward all the triggers for review and update dateLustRun with todays date to prevent from pulling into the list of triggers to run when timer will run this procedure in 30 seconds 
	-- and not all the triggers are processed
	UPDATE wmTriggers Set dateLastRun=GETDATE() OUTPUT Inserted.* INTO @Triggers 
			WHERE CASE
			WHEN repeatInterval = 'year' THEN DATEADD(year,DATEDIFF(year,startdate,dateLastRun)+1,startDate)
			WHEN repeatInterval = 'month' THEN DATEADD(month,DATEDIFF(month,startdate,dateLastRun)+1,startDate)
			WHEN repeatInterval = 'eom' THEN DATEADD(ss,-DATEDIFF(s,startdate,DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,startDate)+1,0))),DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,dateLastRun)+2,0)))
			WHEN repeatInterval = 'week' THEN DATEADD(week,DATEDIFF(week,startdate,dateLastRun)+1,startDate)
			WHEN repeatInterval = 'day' THEN DATEADD(day,DATEDIFF(day,startdate,dateLastRun)+1,startDate)
			WHEN repeatInterval = 'hour' THEN DATEADD(hour,DATEDIFF(hour,startdate,dateLastRun)+1,startDate)
			ELSE DATEADD(minute,DATEDIFF(minute,startdate,dateLastRun)+1,startDate)END < GETDATE() AND active=1;	


	--	BEGIN    
	--	DECLARE rt_cursor CURSOR LOCAL FAST_FORWARD
	--	FOR
	--		SELECT triggerName,triggerId,triggerSp,tableSelect,footerSelect,headerColor,headerBackgroundColor,evenRowBackgroundColor,oddRowBackgroundColor,emailBody,emailSubject,toString,stopIfTableNull,ccString,bccString,successNotify
	--			FROM [MnxTriggers]
	--			WHERE CASE
	--				--CASE statement calculates and filters by the next run date to reduce the number of sp to cycle through.
	--				WHEN repeatInterval = 'year' THEN DATEADD(year,DATEDIFF(year,startdate,dateLastRun)+1,startDate)
	--				WHEN repeatInterval = 'month' THEN DATEADD(month,DATEDIFF(month,startdate,dateLastRun)+1,startDate)
	--				WHEN repeatInterval = 'eom' THEN DATEADD(ss,-DATEDIFF(s,startdate,DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,startDate)+1,0))),DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,dateLastRun)+2,0)))
	--				WHEN repeatInterval = 'week' THEN DATEADD(week,DATEDIFF(week,startdate,dateLastRun)+1,startDate)
	--				WHEN repeatInterval = 'day' THEN DATEADD(day,DATEDIFF(day,startdate,dateLastRun)+1,startDate)
	--				WHEN repeatInterval = 'hour' THEN DATEADD(hour,DATEDIFF(hour,startdate,dateLastRun)+1,startDate)
	--				ELSE DATEADD(minute,DATEDIFF(minute,startdate,dateLastRun)+1,startDate)END < GETDATE() AND active=1
	--	OPEN		rt_cursor;
	--END
--07/30/13 YS create cursor from @trigger table varibale
	BEGIN    
	DECLARE rt_cursor CURSOR LOCAL FAST_FORWARD
	FOR
		SELECT triggerName,triggerId,triggerSp,tableSelect,footerSelect,headerColor,headerBackgroundColor,evenRowBackgroundColor,oddRowBackgroundColor,emailBody,emailSubject,toString,stopIfTableNull,ccString,bccString,successNotify
			FROM @Triggers 
		OPEN		rt_cursor;
	END

    FETCH NEXT FROM rt_cursor INTO @trigName,@trigId,@tSp,@tSelect,@tFootSel,@hColor,@hBcolor,@eRowColor,@oRowColor,@eBody,@eSubject,@eTo,@tblNullStop,@ecTo,@ebcTo,@notify

    WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @tSP<>''
		BEGIN	
			--07/30/13 Check In web service to indicate that it is running 
			UPDATE GENERALSETUP SET LastWebServiceCheckIn = GETDATE() 
			--07/30/13 YS added a vriable to indicate if @tSP failed to run
			SET @tryFailed = 0
			--07/30/13 YS use sp_executesql and add try/catch
			BEGIN TRY
				EXEC sp_executesql @tSP
				
			END TRY
			BEGIN CATCH
				-- !!!! 07/30/13 YS we can log an error similar to importbomerror or we can save the error information and e-mail as the reasone
				SET @tryFailed = 1
			END CATCH
			-- 07/30/13 YS if @tSp failed for any reason replace dateLastRun with 19991231
			IF (@tryFailed = 1) 
				UPDATE wmTriggers SET dateLastRun= '19991231' WHERE triggerId = @trigId
			
			IF (@notify=1 AND @eTo<>'')
			BEGIN
				INSERT INTO @emailTo
					SELECT id FROM dbo.fn_simpleVarcharlistToTable(@eTo,',')
					
				--Create 1 listing per address
				-- 07/30/13 YS check if failed send "fail" message  
				INSERT INTO dbo.wmTriggerEmails (toEmail,subject,body,isHtml,dateAdded,tocc,tobcc)
				SELECT emailAdd,@trigName+
				CASE WHEN @tryFailed= 0 THEN
				' ran successfully' ELSE ' failed' END,
				'This notice is to let you know that ' + @trigName + 
				CASE WHEN @tryFailed= 0 THEN
				' ran successfully.' ELSE' failed' END,
				1,GETDATE(),@ecTo,@ebcTo FROM @emailTo
			END
		END
		ELSE IF @tSelect <> ''
		BEGIN
		
			--INSERT INTO @select
			--EXEC(@tSelect)
			INSERT INTO @tFooterTbl 
			EXEC(@tFootSel)
			SELECT @tFooter = selValue FROM @tFooterTbl
			
			DECLARE @rCount int
			DECLARE @thisSelect nvarchar(MAX)='SELECT @rc=CASE WHEN EXISTS(' + @tSelect + ') THEN 1 ELSE 0 END'
			EXEC SP_EXECUTESQL @thisSelect,N'@rc int OUTPUT',@rCount OUTPUT
			IF @rCount>0 OR @tblNullStop=0 
			BEGIN
				--DECLARE @ht varchar(MAX)
				EXEC dbo.MnxFuncSelectToHtml @tSelect,@tFooter,null,@htmlTable OUTPUT
				--SET @htmlTable = CRM.dbo.fn_selectToHtmlTable(@colNames,@select,@tFooter)
			
				--Replace standard place holders to be set by individual sp
				SET @htmlTable = REPLACE(@htmlTable,'{hbc}','background-color:' + @hBcolor + ';') --header background color
				SET @htmlTable = REPLACE(@htmlTable,'{hc}','color:' + @hcolor + ';')-- header font color
				SET @htmlTable = REPLACE(@htmlTable,'{rbc1}',@oRowColor) --odd row background color
				SET @htmlTable = REPLACE(@htmlTable,'{rbc2}',@eRowColor) --even row background color
				SET @htmlTable = REPLACE(@htmlTable,'{le}','">') --drop custom color used for custom sp
				
				SET @eBody = REPLACE(@eBody,'{TABLE}',@htmlTable)
				SET @eBody = REPLACE(@eBody,'{DATE}',CONVERT(varchar(MAX),GETDATE(),101))
				SET @eSubject = REPLACE(@eSubject,'{DATE}',CONVERT(varchar(MAX),GETDATE(),102))
				
				--Convert @eTo to table to check to see if there is more than one email address listed (addresses MUST be comma separated)
				INSERT INTO @emailTo
				SELECT id FROM dbo.fn_simpleVarcharlistToTable(@eTo,',')
				
				--Create 1 listing per address
				INSERT INTO dbo.wmTriggerEmails (toEmail,subject,body,isHtml,dateAdded,tocc,tobcc)
				SELECT emailAdd,@eSubject,@eBody,1,GETDATE(),@ecTo,@ebcTo FROM @emailTo
				
				UPDATE wmTriggers SET dateLastRun=GETDATE() WHERE triggerId = @trigId
			END
		END
		ELSE
		-- 09/25/14 DS added catch for non-select and non-procedure triggers
		BEGIN
				INSERT INTO @emailTo
				SELECT id FROM dbo.fn_simpleVarcharlistToTable(@eTo,',')
					
				--Create 1 listing per address
				INSERT INTO dbo.wmTriggerEmails (toEmail,subject,body,isHtml,dateAdded,tocc,tobcc)
				SELECT emailAdd,@eSubject,@eBody,1,GETDATE(),@ecTo,@ebcTo FROM @emailTo
				
				UPDATE wmTriggers SET dateLastRun=GETDATE() WHERE triggerId = @trigId
		END
		
		FETCH NEXT FROM rt_cursor INTO @trigName,@trigId,@tSp,@tSelect,@tFooter,@hColor,@hBcolor,@eRowColor,@oRowColor,@eBody,@eSubject,@eTo,@tblNullStop,@ecTo,@ebcTo,@notify
	END
	CLOSE rt_cursor
	DEALLOCATE rt_cursor
	--07/30/13 Check In web service to indicate that it is running 
	UPDATE GENERALSETUP SET LastWebServiceCheckIn = GETDATE() 
    ---07/30/13 YS update dateSent so next timer event in 30 seconds will not pickup the same e-mails
    
	UPDATE wmTriggerEmails SET dateSent=GETDATE()
		OUTPUT INSERTED.*
		WHERE dateSent is null
    -- 09/24/13 DS changed method so results are returned via SELECT instead of OUTPUT as C# did not recognize the OUTPUT values.
    
    
	--DECLARE @Output TABLE (messageid uniqueidentifier)
	
	--INSERT INTO @Output
	--SELECT messageid FROM MnxTriggerEmails WHERE dateSent is null 
		
	--UPDATE MnxTriggerEmails SET dateSent=GETDATE() 
	--	WHERE messageid IN (SELECT messageId FROM @Output)
		
	--SELECT * FROM MnxTriggerEmails WHERE messageid IN (SELECT messageid FROM @Output)
	
	
	--SELECT * FROM MnxTriggerEmails
	--WHERE dateSent is null --OR dateSent = ''
END