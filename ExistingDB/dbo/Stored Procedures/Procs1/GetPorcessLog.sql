-- =============================================
-- Author:		Nitesh B	
-- Create date: 05/08/2018
-- Description:	Get Payroll Porcess Log
-- Modification 
   -- 05/29/2018 Nitesh B:Complete rewrite 
-- =============================================
CREATE PROCEDURE [dbo].[GetPorcessLog]
AS
BEGIN
SET NOCOUNT ON
    --Declarre temp table to hold start dates and end dates
	CREATE TABLE #payPeriod
	   (
	   StartDate SMALLDATETIME,
	   EndDate SMALLDATETIME,
	   ProcessedBy UNIQUEIDENTIFIER
	   )

	--Delcare and Set LastProcessedDate
	DECLARE @lastProcessedDate SMALLDATETIME  =(SELECT TOP(1)ToDate AS LastProcessedDate FROM PaymentProcessDate ORDER BY ToDate DESC)
	
	--Declare and set dateTimeDuration
    DECLARE @dateTimeDuration SMALLDATETIME = CASE  WHEN @lastProcessedDate IS NULL THEN DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) 
												  ELSE DATEADD(MONTH, DATEDIFF(MONTH, 0, @lastProcessedDate), 0) END;	

    --Delcare and set Period type(from PayrollSettings table)
	DECLARE @periodType VARCHAR(13)= (SELECT RTRIM(PeriodType) FROM PayrollSettings)

	--Delclare and set current date
	DECLARE @currentDate DATETIME = GETDATE() 

	--Declare @startDayNumber and @endDayNumber  for Monthly and Semi-Monthly PeriodType
	DECLARE @startDayNumber INT,@endDayNumber INT

	--Declare @recordsSelected and @recordsCount used in while loop 
	DECLARE @recordsSelected INT = 0,@recordsCount INT=0
	
	--Declare PaymentRecords
	DECLARE @paymentRecords INT

	--Get Records for Monthly Priod Type
    IF(@periodType='Monthly')
    BEGIN    
	    --Set Start day number and end day number
    	SELECT @startDayNumber = p.StartValue
    		  ,@endDayNumber = p.StartValue + 30
    	FROM PayrollSettings p
    	
        --Declare and set Start day and End day for Monthly payroll cycle												  	
    	DECLARE @monthStartDay SMALLDATETIME = DATEADD(DAY, @startDayNumber-1, @dateTimeDuration)
		DECLARE @monthEndDay SMALLDATETIME = DATEADD(DAY, @endDayNumber-1, @dateTimeDuration)
		
		--Declare and set current time duration 
		DECLARE @currentTimeDuration SMALLDATETIME =  DATEADD(MONTH, DATEDIFF(MONTH, 0, GetDate()), 0);

		-- Get records from last Payroll duration to current Payroll duration If records available in PaymentProcess table
	    IF(@lastProcessedDate IS NOT NULL)
		BEGIN
		    --Insert records into temp table #payPeriod
			WHILE(@recordsSelected=0)
    			BEGIN
    			INSERT INTO #payPeriod
    			SELECT DATEADD(MONTH,@recordsCount+1,@monthStartDay)
    				  ,DATEADD(MONTH,@recordsCount+1,@monthEndDay)
    			      ,NULL AS ProcessedBy
				SET @recordsCount = @recordsCount + 1
			
    			IF (@currentTimeDuration=DATEADD(MONTH,@recordsCount,@monthStartDay))
    			BEGIN
    				 SET @recordsSelected = 1
    			END
    		END
		 
		 --Get records from PaymentProcess table
		 SET @paymentRecords = (SELECT COUNT(1) FROM #payPeriod)
			IF (@paymentRecords<9)
			BEGIN
				INSERT INTO #payPeriod
    			SELECT TOP(10-@paymentRecords) FromDate,ToDate,ProcessedBy FROM PaymentProcessDate  
			END
		END
		ELSE
		BEGIN
		--If records not available in PaymentProcess table then get records from current Payroll duration to last 10 Payroll duration
    	WHILE(@recordsSelected=0)
    		BEGIN
			 --Insert records into temp table #payPeriod
    			INSERT INTO #payPeriod
    			SELECT DATEADD(MONTH,-@recordsCount,@monthStartDay)
    				  ,DATEADD(MONTH,-@recordsCount,@monthEndDay)
    				  ,NULL
    			SET @recordsCount = @recordsCount + 1
    			IF (@recordsCount=10)
    			BEGIN
    				SET @recordsSelected = 1
    			END
    		END  
		END 
    END

   --Get Records for SemiMonthly Priod Type
    IF(@periodType='Semi-Monthly')
    BEGIN
		--Set Start day number and end day number
    	SELECT @startDayNumber = p.StartValue
    		  ,@endDayNumber = p.StartValue + 15
    	FROM PayrollSettings p   

		--Declare and set Start Days and End Days for first and second half of month
    	DECLARE @monthlyStartDay SMALLDATETIME = DATEADD(DAY, @startDayNumber-1, @dateTimeDuration)
    	DECLARE @monthlyEndDay SMALLDATETIME = DATEADD(DAY, @startDayNumber + 14, @dateTimeDuration)
    	DECLARE @monthlyStartDate SMALLDATETIME = DATEADD(DAY,@endDayNumber-1, @dateTimeDuration)
    	DECLARE @monthlyEndDate SMALLDATETIME = DATEADD(DAY, @endDayNumber + 14, @dateTimeDuration)
    
	    --Declare and set current time duration
	    DECLARE @semiCurrentTimeDuration SMALLDATETIME =  DATEADD(DAY,@endDayNumber-1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0))
		--If records available in PaymentProcess table get records from last payroll duration to current payroll duration
	     IF(@lastProcessedDate IS NOT NULL)
		 BEGIN
		 WHILE(@recordsSelected=0)
    	 	BEGIN
			--Insert records into temp table #payPeriod
    	 	INSERT INTO #payPeriod
			--Get payroll duration from first half of month
    	 	SELECT DATEADD(MONTH,@recordsCount+1,@monthlyStartDay)
    			  ,DATEADD(MONTH,@recordsCount+1,@monthlyEndDay)
				  ,NULL
    		UNION
			--Get payroll duration from second half of month
    		SELECT DATEADD(MONTH,@recordsCount+1,@monthlyStartDate)
    			  ,DATEADD(MONTH,@recordsCount+1,@monthlyEndDate)
				  ,NULL
		 	SET @recordsCount = @recordsCount + 1
			IF(@semiCurrentTimeDuration=DATEADD(MONTH,@recordsCount,@monthlyStartDay) OR (@semiCurrentTimeDuration=DATEADD(MONTH,@recordsCount,@monthlyStartDate)))
			BEGIN
    	 		 SET @recordsSelected = 1
    	 	END
    	 END 
		 --Get records from PaymentProcess table
		 SET @paymentRecords = (SELECT COUNT(1) FROM #payPeriod)
		 IF (@paymentRecords<9)
		 BEGIN
		 INSERT INTO #payPeriod
    	 SELECT TOP(10-@paymentRecords) FromDate,ToDate,ProcessedBy FROM PaymentProcessDate  
		 END
		END
		ELSE
		BEGIN
		--If records not available in PaymentProcess table then get records from current payroll duration to last 10 payroll duration
		WHILE(@recordsSelected=0)
    	BEGIN
    		INSERT INTO #payPeriod
    		SELECT DATEADD(MONTH,-@recordsCount,@monthlyStartDay)
    			  ,DATEADD(MONTH,-@recordsCount,@monthlyEndDay)
				  ,NULL
    		UNION
    		SELECT DATEADD(MONTH,-@recordsCount,@monthlyStartDate)
    			  ,DATEADD(MONTH,-@recordsCount,@monthlyEndDate)
				  ,NULL
    		SET @recordsCount = @recordsCount + 1
    		IF (@recordsCount=5)
    		BEGIN
    			SET @recordsSelected = 1
    		END
		END
		END
    END

    ELSE
    BEGIN
	    --Declare temp table @tempDayNumber to get day number in week from day name
		DECLARE @tempDayNumber TABLE (WeekayNumber INT)
				INSERT INTO @tempDayNumber VALUES (1),(2),(3),(4),(5),(6),(7)	
		DECLARE @startDay INT,@endDay INT
		
		CREATE TABLE #tempDayOrder 
			   (
			   DayNumber INT,
			   DayName VARCHAR(9)
			   )
		
		--Get day number in week from day name
		INSERT INTO #tempDayOrder
		SELECT WeekayNumber AS DayNumber
			  ,DateName(WEEKDAY,Dateadd(WEEKDAY,WeekayNumber-1,0)) AS DayName
		FROM @tempDayNumber
		
		--Set @startDay and @endDay
		SELECT @startDay = T.DayNumber
			   ,@endDay = T.DayNumber + 6
		FROM PayrollSettings p 
		INNER JOIN #tempDayOrder T On RTRIM(p.StartValue) = T.DayName 
        --Get Records for Weekly Priod Type
    		IF(@periodType='Weekly')
    	BEGIN  
		--Declare and set Start Days and End Days for first and second half of month
    		DECLARE @currentStartDate SMALLDATETIME = DATEADD(DD, (@startDay + 1) - DATEPART(DW, @currentDate), @currentDate)
    		DECLARE @currentEndDate SMALLDATETIME =  DATEADD(DD, (@endDay+1) - DATEPART(DW, @currentDate), @currentDate)
			--Declare @currentPeriod and set current period's value from @currentStartDate
			DECLARE @currentPeriod SMALLDATETIME = FORMAT(@currentStartDate,'MM/dd/yyyy')
			IF(@lastProcessedDate IS NOT NULL)
			BEGIN
			    --Change @currentStartDate and @currentEndDate values by @lastProcessedDate
				SET @currentStartDate = DATEADD(DD, (@startDay + 1) - DATEPART(DW, @lastProcessedDate), @lastProcessedDate)
				SET @currentEndDate =  DATEADD(DD, (@endDay+1) - DATEPART(DW, @lastProcessedDate), @lastProcessedDate)
		
				WHILE(@recordsSelected=0)
    			BEGIN
					INSERT INTO #payPeriod
    				SELECT DATEADD(DAY,@recordsCount * 7 ,@currentStartDate)
    					  ,DATEADD(DAY,@recordsCount * 7,@currentEndDate)
						  ,NULL
					SET @recordsCount = @recordsCount + 1
    				IF (@currentPeriod=DATEADD(DAY,@recordsCount * 7 ,@currentStartDate))
    				BEGIN
    					SET @recordsSelected = 1
    				END
				END
			 --Get records from PaymentProcess table
				SET @paymentRecords = (SELECT COUNT(1) FROM #payPeriod)
				IF (@paymentRecords<9)
				BEGIN
					INSERT INTO #payPeriod
    				SELECT TOP(10-@paymentRecords) FromDate,ToDate,ProcessedBy FROM PaymentProcessDate  
				END
		    END
    		ELSE
			--If records not available in PaymentProcess table then get records from current payroll duration to last 10 payroll duration
			 WHILE(@recordsSelected = 0)
    		 BEGIN
    			INSERT INTO #payPeriod
    			SELECT DATEADD(DAY,-@recordsCount * 7 ,@currentStartDate)
    				  ,DATEADD(DAY,-@recordsCount * 7,@currentEndDate)
					  ,NULL					 
				SET @recordsCount = @recordsCount + 1
    			IF (@recordsCount=10)
    			BEGIN
    				SET @recordsSelected = 1
    			END
    		END
		END
		--Get Records for Bi-Weekly Priod Type
		ELSE IF(@periodType='Bi-Weekly')
		BEGIN
			DECLARE @currentStartDay  SMALLDATETIME = DATEADD(DD, (@startDay+1) - DATEPART(DW, @currentDate), @currentDate)
			DECLARE @currentEndDay  SMALLDATETIME = DATEADD(DD, (@startDay+14) - DATEPART(DW, @currentDate), @currentDate)
			--Set current period's value from @currentStartDay
			SET @currentPeriod = FORMAT(@currentStartDay,'MM/dd/yyyy')
			IF(@lastProcessedDate IS NOT NULL)
			 BEGIN
				SET @currentStartDay = DATEADD(DD, (@startDay+1) - DATEPART(DW, @lastProcessedDate), @lastProcessedDate)
				SET @currentEndDay   = DATEADD(DD, (@startDay+14) - DATEPART(DW, @lastProcessedDate), @lastProcessedDate)
				WHILE(@recordsSelected=0)
    			BEGIN
					INSERT INTO #payPeriod
    				SELECT DATEADD(DAY, (@recordsCount)*14, @currentStartDay)
						  ,DATEADD(DAY, (@recordsCount)*14, @currentEndDay)
						  ,NULL
					SET @recordsCount = @recordsCount + 1
    				IF (@currentPeriod=DATEADD(DAY, (@recordsCount-1)*14, @currentStartDay))
    				BEGIN
    					SET @recordsSelected = 1
    				END
				END
				--Get records from PaymentProcess table
				SET @paymentRecords = (SELECT COUNT(1) FROM #payPeriod)
				 IF (@paymentRecords<9)
				 BEGIN
				 INSERT INTO #payPeriod
    			 SELECT TOP(10-@paymentRecords) FromDate,ToDate,ProcessedBy FROM PaymentProcessDate  
				 END
			END
			ELSE 
			--If records not available in PaymentProcess table then get records from current payroll duration to last 10 payroll duration
			WHILE(@recordsSelected=0)
			BEGIN
				INSERT INTO #payPeriod				
				SELECT DATEADD(DAY, -@recordsCount*14, @currentStartDay)
					  ,DATEADD(DAY, -@recordsCount*14, @currentEndDay)
					  ,NULL
				SET @recordsCount = @recordsCount + 1
				IF (@recordsCount=10)
				BEGIN
					SET @recordsSelected = 1
			END
			END
    END
	DROP TABLE #tempDayOrder
    END
    	SELECT DISTINCT 
    	       FORMAT(P.StartDate,'MM/dd/yyyy') AS FromDate
    		  ,FORMAT(EndDate,'MM/dd/yyyy') AS ToDate
    		  ,FORMAT(EndDate,'MM/dd/yyyy') AS ProcessedDate 
    		  ,ISNULL(AP.Initials,'') AS ProcessedBy
    		  ,(CAST(CASE WHEN AP.Initials IS NULL THEN 0 ELSE 1 END AS BIT)) AS Status
			  ,P.StartDate
    	FROM #payPeriod P LEFT JOIN Aspnet_Profile AP ON P.ProcessedBy = AP.UserId
    	ORDER BY StartDate DESC
    DROP TABLE #payPeriod
END