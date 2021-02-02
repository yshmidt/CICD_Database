-- =============================================
-- Author:		yelena Shmidt
-- Create date: 08/06/2013
-- Description:	procedure for the MRP Horizontal Planning Summary report
-- Modified:  01/15/2014 DRP:  added the @userid parameter for WebManex
--			  05/01/2014 YS  fixed date ranges, was skipping weeks by multiplying 7*sequence	
--			03/25/2015 DRP:  needed to make a couple changes so that the Out and Over headers were replaced by the Before and After.  The prior headers were confusing to the end users.  Before will be any records before the @dStartMonday.  After will be any record after the @dEndMonday.
-- =============================================
CREATE PROCEDURE [dbo].[rptMrpHorizontalPlanningSum]
	-- Add the parameters for the stored procedure here
	--declare
	@userId uniqueidentifier=null
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- set first date of the week to Monday
	DECLARE @liDateFirst as Int;
	-- save current @@DATEFIRST
	SET @liDateFirst = @@DATEFIRST;
	SET DATEFIRST 1;
	DECLARE @t as tMrpHorizontal -- UDTT 
	DECLARE @dbaseMonday datetime2 , ---  monday a week from now 
		@dSTartMonday date, --- start range
		@dEndMonday date , --- monday of the 12th range
		@cols nvarchar(max), -- create dynamic column names based on the dates
		@sql nvarchar(max)  -- for dynamic SQl
		
	SET @dBaseMonday = DATEADD(day,-7-(DATEPART(w, GETDATE())-1),GETDATE())
	SET @dSTartMonday = DATEADD(day,7,@dBaseMonday)

	DECLARE @DateRanges Table (nRangeStart date,nSeqNumber int)
	;WITH dateranges 
		as (
	SELECT @dSTartMonday as [nRangeStart],CAST(1 as int) as nSeqNumber
		UNION ALL
---	  05/01/2014 YS  fixed date ranges, was skipping weeks by multiplying 7*sequence	
	--SELECT DATEADD(Day,nSeqNumber*7,nRangeStart),nSeqNumber+1 
	SELECT DATEADD(Day,7,nRangeStart),nSeqNumber+1 
	FROM dateranges		
	WHERE dateranges.nSeqNumber+1<=12)
	
	INSERT INTO @DateRanges 
		select * from dateranges


	SELECT @dEndMonday=nRangeStart from @DateRanges where nSeqNumber=12
	 
	
    -- create column list to use for pivoting table
	select @cols = STUFF((
	SELECT ',' + C.Name
		from (select nSeqNumber, '['+cast(nRangeStart as varchar(10))+']' as name from @DateRanges ) C
	ORDER BY C.nSeqNumber
	FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,1,'');
	
	--SELECT @cols='[Out],'+@cols+',[Over]'		--03/25/2015 DRP:  Replaced with the below because the other terms were confusing to the users. 
	SELECT @cols='[Before],'+@cols+',[After]'
	
	--	select @cols
	--SELECT * FROM @DateRanges
	-- [type] starting with 'S' - for Supply and with 'D' - demands
	;WITH AllRecords
	AS(
	SELECT CAST(ISNULL(D.nSeqNumber,0) as integer) as nSeqnumber, Uniq_Key, 
		DATEADD(Day,DATEPART(w, Reqdate)-1,Reqdate) as Due_Dts,Reqdate,ReqQty, 
		  CASE WHEN D.nSeqNumber IS NOT NULL THEN 'S    '
			 WHEN D.nSeqNumber IS NULL and DATEDIFF(Day,DATEADD(DAY,6,@dEndMonday),ReqDate)>0 THEN 'Sout'
			 WHEN D.nSeqNumber IS NULL and DATEDIFF(Day,@dSTartMonday,ReqDate)<0 THEN 'Sover'
			 ELSE 'Unknw' END as [type]
	--FROM MrpSch2 LEFT OUTER JOIN @DateRanges D ON DATEADD(Day,DATEPART(w, Reqdate)-1,Reqdate)=D.nRangeStart	--03/25/2015 DRP:  needed to change to the following to get the correct buckets
	FROM MrpSch2 LEFT OUTER JOIN @DateRanges D ON DATEADD(Day,-(DATEPART(w, Reqdate)-1),Reqdate)=D.nRangeStart
	WHERE ReqQty > 0 
	AND ReqDate IS NOT NULL
    AND CHARINDEX('Inv', Ref)=0
    UNION
    SELECT CAST(ISNULL(D.nSeqNumber,0) as integer) as nSeqnumber, Uniq_Key, 
		DATEADD(Day,DATEPART(w, Reqdate)-1,Reqdate) as Due_Dts,Reqdate,ReqQty,
		  CASE WHEN D.nSeqNumber IS NOT NULL THEN 'D    '
		 WHEN D.nSeqNumber IS NULL and DATEDIFF(Day,DATEADD(DAY,6,@dEndMonday),ReqDate)>0 THEN 'Dout'
			 WHEN D.nSeqNumber IS NULL and DATEDIFF(Day,@dSTartMonday,ReqDate)<0 THEN 'Dover'
			 ELSE 'Unknw' END as [type]
	--FROM MrpSch2 LEFT OUTER JOIN @DateRanges D ON DATEADD(Day,DATEPART(w, Reqdate)-1,Reqdate)=D.nRangeStart	--03/25/2015 DRP:  needed to change to the following to get the correct buckets
	FROM MrpSch2 LEFT OUTER JOIN @DateRanges D ON DATEADD(Day,-(DATEPART(w, Reqdate)-1),Reqdate)=D.nRangeStart
	WHERE ReqQty < 0 
	AND ReqDate IS NOT NULL
    AND CHARINDEX('Inv', Ref)=0 )
   
    --select * from AllRecords
   -- get data to pivot
   INSERT INTO @t
       SELECT Uniq_key,AllRecords.nSeqNumber,[TYPE],
   --    CASE WHEN D.nRangeStart IS NOT NULL THEN CAST(D.nRangeStart as CHAR(10)) 
			--WHEN  D.nRangeStart IS NULL AND CHARINDEX('Out',[TYPE])<>0 THEN cast('Out' as CHAR(10))
			--WHEN D.nRangeStart IS NULL AND CHARINDEX('Over',[TYPE])<>0 THEN cast('Over' as CHAR(10))
			--ELSE CAST('Unknw' as CHAR(10)) END AS FieldName,		--03/25/2015 DRP:  replaced by the below because out and over were confusing. 
		CASE WHEN D.nRangeStart IS NOT NULL THEN CAST(D.nRangeStart as CHAR(10)) 
			WHEN  D.nRangeStart IS NULL AND CHARINDEX('Out',[TYPE])<>0 THEN cast('After' as CHAR(10))
			WHEN D.nRangeStart IS NULL AND CHARINDEX('Over',[TYPE])<>0 THEN cast('Before' as CHAR(10))
			ELSE CAST('Unknw' as CHAR(10)) END AS FieldName,
       SUM(ReqQty)
		FROM AllRecords LEFT OUTER JOIN @DateRanges D on AllRecords.nSeqnumber =D.nSeqNumber   
	GROUP BY UNIQ_KEY,AllRecords.nSeqNumber,[TYPE],D.nRangeStart
	ORDER BY AllRecords.nSeqNumber desc   


	-- select * from @t	
  
	select @sql=N'
	SELECT * 
		FROM  (SELECT t.Uniq_key,LEFT(t.[Type],1) as Type,t.ReqQty,t.FieldName,M.Part_class,M.Part_Type, M.Part_no, M.Revision, M.Descript, M.Buyer_type as Buyer,
		cast(ISNULL(Wh.[Netable Qty],0.00) as numeric(14,2)) as [Netable Qty],   
		Cast(ISNULL(Wh.[Not Netable Qty],0.00) as numeric(14,2)) as [Not Netable Qty]    
		FROM @t t  INNER JOIN MrpInvt M ON t.uniq_key=M.Uniq_key    
		LEFT OUTER JOIN 
		(SELECT UNIQ_KEY,[Netable Qty],[Not Netable Qty]
		FROM
		(SELECT Uniq_key,CASE WHEN netable=1 THEN ''Netable Qty'' ELSE ''Not Netable Qty'' END as Fieldname,qty_oh
			FROM MrpWh
			)st
		PIVOT
		(
		SUM(qty_oh)
		FOR Fieldname IN 
		([Netable Qty],[Not Netable Qty])
		) subpv		
		)WH ON t.uniq_key=Wh.Uniq_key) PVT
		 PIVOT     (SUM(ReqQty) FOR FieldName IN ('+@cols+')) AS PVT
		 ORDER BY PVT.Part_no,PVT.Revision,PVT.[Type]'

  
	--select @sql
	--08/06/13 YS sp_executesql procedure will take second parameter as User defined table type (UDTT) and we will pass @result table variable 
	execute sp_executesql @sql,N'@t tMrpHorizontal READONLY',@t

	-- re-set to default
	SET @liDateFirst = @liDateFirst
END