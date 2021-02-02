-- =============================================
-- Author:		Nitesh B	
-- Create date: <31/07/2018>
-- Description:	Get Employee Logging summary 
-- exec GetEmployeeLogSummary '681f01dc-4459-4586-b5dd-0067c6070aa2',GETDATE(),GETDATE()
CREATE PROCEDURE [GetEmployeeLogSummary]
(
@userId UNIQUEIDENTIFIER=NULL,
@fromDateTime AS SMALLDATETIME =NULL,
@toDateTime AS SMALLDATETIME = NULL
)
AS 
BEGIN
	SET NOCOUNT ON
	SET @fromDateTime = '2017-10-09'
	SET @toDateTime = '2018-04-26'
	DECLARE @shiftRegularTime INT
	SELECT @shiftRegularTime = TOT_MIN - BREAK_MIN FROM aspnet_Profile AP LEFT JOIN WRKSHIFT W ON AP.shift_no = W.SHIFT_NO WHERE AP.UserId = @userId
	DECLARE @tempLogTable AS TABLE
		(
		 ShiftDate NVARCHAR(10)
		,TotalTime INT
		) 
		Insert into @tempLogTable 
		EXEC GetEmpLogTime @userId,@fromDateTime,@toDateTime

		SELECT DISTINCT ROW_NUMBER() OVER(ORDER BY MIN(DATE_IN) DESC) AS RowNumber 
					   ,AP.Userid
			 		   ,MIN(DATE_IN) AS DateIn
					   ,MAX(DATE_OUT) AS DateOut
					   ,FORMAT(MIN(DATE_IN),'MM/dd/yyyy hh:mm tt') AS InDate
					   ,FORMAT(MAX(DATE_OUT),'MM/dd/yyyy hh:mm tt') AS OutDate
					   ,CASE WHEN TLT.TotalTime <= @shiftRegularTime THEN CAST(TLT.TotalTime/60 AS VARCHAR(5)) + ':' +  CAST(TLT.TotalTime%60 AS VARCHAR(2))  
					    ELSE  CAST(@shiftRegularTime/60 AS VARCHAR(5)) + ':' +  CAST(@shiftRegularTime%60 AS VARCHAR(2))   END AS RegulerTime
					   ,CASE WHEN TLT.TotalTime > @shiftRegularTime THEN  CAST((TLT.TotalTime - @shiftRegularTime)/60 AS VARCHAR(5)) + ':' +  
					    CAST((TLT.TotalTime - @shiftRegularTime)%60 AS VARCHAR(2)) ELSE '0:0' END AS OverTime
					   ,CAST((DATEDIFF(Minute,MIN(DATE_IN),MAX(DATE_OUT)) - TLT.TotalTime)/60 AS VARCHAR(5)) + ':' +  
					    CAST((DATEDIFF(Minute,MIN(DATE_IN),MAX(DATE_OUT)) - TLT.TotalTime)%60 AS VARCHAR(2)) AS BreakTime
					   ,CAST((DATEDIFF(Minute,MIN(DATE_IN),MAX(DATE_OUT)))/60 AS VARCHAR(5))+ ':'+ 
					    RIGHT('0' + CAST( (DATEDIFF(Minute,MIN(DATE_IN),MAX(DATE_OUT)))%60 AS VARCHAR(2)), 2) AS TotalTime
					   ,DL.uDeleted AS IsDeleted
		FROM DEPT_LGT DL  INNER JOIN aspnet_Profile AP ON  DL.inUserId = AP.UserId
						  LEFT JOIN TMLOGTP TG ON DL.TMLOGTPUK = TG.TMLOGTPUK
						  LEFT JOIN aspnet_Profile APL ON DL.LastUpdatedBy = APL.UserId
						  INNER JOIN @tempLogTable TLT ON FORMAT(DATE_IN,'MM/dd/yyyy') = TLT.ShiftDate
	    WHERE DL.InUserId = @userId 
				AND (FORMAT(DATE_IN,'MM/dd/yyyy') >= FORMAT(@fromDateTime,'MM/dd/yyyy') OR DATE_IN >= @fromDateTime)
		        AND (FORMAT(DATE_OUT,'MM/dd/yyyy') <= FORMAT(@toDateTime,'MM/dd/yyyy')  OR DATE_OUT <= @toDateTime) 
			    AND WONO = ''
        GROUP BY AP.Userid
			    ,FORMAT(DATE_IN,'MM/dd/yyyy')
				,DL.uDeleted,TLT.TotalTime
		ORDER BY RowNumber 
END