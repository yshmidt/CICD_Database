-- =============================================
-- Author:		David Sharp
-- Create date: 12/7/2011
-- Description:	gets info about order status
-- 08/27/13 DS added filter for full results, or any result
-- 10/24/13 DS reworked the search process to reduce the results and improve overall performance and added @activeMonthLimit
-- 11/15/13 DS changed approach to return TOP 15 excluding previous results
-- 05/07/14 DS Added ExternalEmp param
-- 11/06/14 DS removed leading 0s from sono, changed the date format
--04/08/15 YS customer settings saved in wmsettings
-- =============================================
CREATE PROCEDURE [dbo].[MnxSearchViewCustomerOrders] 
	-- Add the parameters for the stored procedure here
	@searchTerm varchar(MAX),
	@searchType int,
	@userId uniqueidentifier,
	@tCustomers UserCompanyPermissions READONLY,
	@tSupplier UserCompanyPermissions READONLY,
	@fullResult bit = 0,
	@activeMonthLimit int = 0,
	@tSearchId tSearchId READONLY,
	@ExternalEmp bit = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		
    -- Insert statements for procedure here
	-- 15 = date
	IF @searchType = 15 OR @searchType = 25
		SET @searchTerm = cast(convert(date,@searchTerm) as varchar(10))
	
	-- If not specified, restrict the months to 6
    -- 10/25/13 DS Default Month Limit
    IF @activeMonthLimit = 0 
		--04/08/15 YS customer settings saved in wmsettings
		--SELECT @activeMonthLimit = settingValue FROM MnxSettingsManagement WHERE settingId='0c91389f-0559-410f-b5f8-12d8659a857f' --special limit for orders
		SELECT @activeMonthLimit = COALESCE(s.settingValue,w.settingvalue) 
				FROM MnxSettingsManagement s left outer join wmSettingsManagement w 
					ON s.settingid=w.settingid
				WHERE settingName='orderMonthLimit'
    
	DECLARE @thisTerm varchar(MAX) = '%' + SUBSTRING(RTRIM(@searchTerm),0,50) + '%'
    DECLARE @count int	
		/*colNames are the localizatoin keys for the column names returned in the results.*/
		--DECLARE @table TABLE(searchProc varchar(MAX),id varchar(50),[group] nvarchar(255),[table] nvarchar(255),[link] varchar(255),  
		--	SO_m nvarchar(255), customer_f nvarchar(255),PO_f nvarchar(255),partNumberRev_m nvarchar(255), orderDate datetime2)
		-- 10/24/13 DS reduced the results of an "ALL" search to the most likely desired results in order to improve performance.
		/* 40 = Universal All, 37 = Order Status All */
		--INSERT INTO @table
		SELECT DISTINCT TOP 15  'MnxSearchViewCustomerOrders'AS searchProc,sm.custno AS id,'SO_m' AS [group],'SO_m' AS [table]
				,'/Orders/' + CAST(sm.custno AS varchar(50)) + '/Details/' + CAST(sd.UNIQUELN AS varchar(50)) AS [link]
				,SUBSTRING(sm.sono,PATINDEX('%[^0]%',sm.sono+'.'),LEN(sm.sono)) AS SO_m, c.CUSTNAME AS customer_f, sm.pono AS PO_f
				,CAST(CASE WHEN sd.uniq_key=' ' THEN sd.[Sodet_Desc] ELSE RTRIM(i.part_no) END 
					+ CASE WHEN i.revision = ' ' THEN ' '  ELSE ' | ' + i.revision END AS varchar(MAX)) AS partNumRev_m
				,CONVERT(varchar(10),sm.ORDERDATE,101) AS orderDate
			from Somain sm  CROSS APPLY (SELECT TOP 1 * FROM sodetail where sm.sono=sono)sd 
			left outer join inventor i on sd.uniq_key = i.uniq_key INNER JOIN CUSTOMER c ON c.CUSTNO = sm.CUSTNO
			WHERE 1=CASE 
					WHEN (@searchType = 40 OR @searchType = 44) THEN
						CASE WHEN sm.ORDERDATE>DATEADD(MONTH,-@activeMonthLimit,GETDATE()) THEN 1 ELSE 0 END
					WHEN @searchType = 43 THEN 
						CASE WHEN  RTRIM(sm.ORD_TYPE) = 'OPEN' THEN 1 ELSE 0 END 
					WHEN @searchType = 45 THEN
						CASE WHEN RTRIM(sm.ORD_TYPE) = 'CLOSED' THEN 1 ELSE 0 END
					WHEN @searchType = 46 THEN
						CASE WHEN RTRIM(sm.ORD_TYPE) = 'CANCEL' THEN 1 ELSE 0 END
					WHEN @searchType <>0 THEN 1 
					ELSE 0 END
				AND(PATINDEX(@thisTerm,
					sm.SONO+'  '+
					sm.PONO+'  '+
					c.CUSTNAME)>0)
				OR CASE WHEN ISDATE(@searchTerm)=1 THEN 
						PATINDEX(cast(convert(date,@searchTerm) as varchar(10)),cast(convert(date,sm.ORDERDATE) as varchar(10)))
					ELSE 0 END >0
				AND (sm.CUSTNO IN (SELECT id FROM @tCustomers) OR 1 = CASE WHEN @ExternalEmp = 0 AND sm.CUSTNO = '' THEN 1 ELSE 0 END)
				AND NOT sm.CUSTNO IN (SELECT id FROM @tSearchId)
		
		SET @count = @@ROWCOUNT
		-- 10/25/13 DS Separate select for the more details search of parts on a Sales Order
		--INSERT INTO @table 
		SELECT DISTINCT TOP 15 'MnxSearchViewCustomerOrders'AS searchProc,sm.custno AS id,'SO_m' AS [group],'SO_m' AS [table]
				,'/Orders/' + CAST(sm.custno AS varchar(50)) + '/Details/' + CAST(sd.UNIQUELN AS varchar(50)) AS [link]
				,sm.sono AS SO_m, c.CUSTNAME AS customer_f, sm.pono AS PO_f
				,CAST(CASE WHEN sd.uniq_key=' ' THEN sd.[Sodet_Desc] ELSE RTRIM(i.part_no) END 
					+ CASE WHEN i.revision = ' ' THEN ' '  ELSE ' | ' + i.revision END AS varchar(MAX)) AS partNumRev_m
				,sm.ORDERDATE as orderDate
			from Somain sm  CROSS APPLY (SELECT TOP 1 * FROM sodetail where sm.sono=sono)sd 
			left outer join inventor i on sd.uniq_key = i.uniq_key INNER JOIN CUSTOMER c ON c.CUSTNO = sm.CUSTNO
			WHERE 1=CASE WHEN (@searchType = 40 OR @searchType = 44) THEN
						CASE WHEN sm.ORDERDATE>DATEADD(MONTH,-@activeMonthLimit,GETDATE()) THEN 1 ELSE 0 END
					WHEN @searchType = 43 THEN 
						CASE WHEN  RTRIM(sm.ORD_TYPE) = 'OPEN' THEN 1 ELSE 0 END 
					WHEN @searchType = 45 THEN
						CASE WHEN RTRIM(sm.ORD_TYPE) = 'CLOSED' THEN 1 ELSE 0 END
					WHEN @searchType = 46 THEN
						CASE WHEN RTRIM(sm.ORD_TYPE) = 'CANCEL' THEN 1 ELSE 0 END
					WHEN @searchType <>0 THEN 1 
					ELSE 0 END
				AND(PATINDEX(@thisTerm,CASE WHEN sd.uniq_key=' ' THEN sd.[Sodet_Desc] ELSE RTRIM(i.part_no)END
						+ '  ' + CASE WHEN sd.uniq_key=' ' THEN sd.[Sodet_Desc] ELSE cast(i.Descript as char(45))END)>0)
				AND (sm.CUSTNO IN (SELECT id FROM @tCustomers) OR 1 = CASE WHEN @ExternalEmp = 0 AND sm.CUSTNO = '' THEN 1 ELSE 0 END)
				AND NOT sm.CUSTNO IN (SELECT id FROM @tSearchId)
		SET @count = @count + @@ROWCOUNT
		--SELECT top 1 @count = COUNT(*) FROM @table
		--IF @count > 0
		--	SELECT searchProc,id,[group],[table],[link],SO_m,customer_f,PO_f,partNumberRev_m FROM @table order by orderDate DESC
	---- 08/27/13 DS added filter for full results, or any result
	--IF @fullResult=1
	--BEGIN
	--	/*colNames are the localizatoin keys for the column names returned in the results.*/
	--	DECLARE @table TABLE(searchProc varchar(MAX),id varchar(50),[group] nvarchar(255),[table] nvarchar(255),[link] varchar(255),  
	--		SO_m nvarchar(255), customer_f nvarchar(255),PO_f nvarchar(255),partNumberRev_m nvarchar(255), orderDate datetime2)
	--	-- 10/24/13 DS reduced the results of an "ALL" search to the most likely desired results in order to improve performance.
	--	/* 40 = Universal All, 37 = Order Status All */
	--	INSERT INTO @table
	--	SELECT DISTINCT TOP 50  'MnxSearchViewCustomerOrders'AS searchProc,sm.custno AS id,'SO_m' AS [group],'SO_m' AS [table]
	--			,'/Orders/' + CAST(sm.custno AS varchar(50)) + '/Details/' + CAST(sd.UNIQUELN AS varchar(50)) AS [link]
	--			,sm.sono, c.CUSTNAME, sm.pono
	--			,CAST(CASE WHEN sd.uniq_key=' ' THEN sd.[Sodet_Desc] ELSE RTRIM(i.part_no) END 
	--				+ CASE WHEN i.revision = ' ' THEN ' '  ELSE ' | ' + i.revision END AS varchar(MAX)) AS PartNumRev
	--			,sm.ORDERDATE
	--		from Somain sm  CROSS APPLY (SELECT TOP 1 * FROM sodetail where sm.sono=sono)sd 
	--		left outer join inventor i on sd.uniq_key = i.uniq_key INNER JOIN CUSTOMER c ON c.CUSTNO = sm.CUSTNO
	--		WHERE 1=CASE WHEN (@searchType = 40 OR @searchType = 44) THEN
	--				CASE WHEN sm.ORDERDATE>DATEADD(MONTH,-@activeMonthLimit,GETDATE()) THEN 1 ELSE 0 END
	--			WHEN @searchType = 43 THEN 
	--				CASE WHEN  RTRIM(sm.ORD_TYPE) = 'OPEN' THEN 1 ELSE 0 END 
	--			WHEN @searchType = 45 THEN
	--				CASE WHEN RTRIM(sm.ORD_TYPE) = 'CLOSED' THEN 1 ELSE 0 END
	--			WHEN @searchType = 46 THEN
	--				CASE WHEN RTRIM(sm.ORD_TYPE) = 'CANCEL' THEN 1 ELSE 0 END
	--			WHEN @searchType <>0 THEN 1 
	--			ELSE 0 END
	--			AND(PATINDEX(@thisTerm,
	--				sm.SONO+'  '+
	--				sm.PONO+'  '+
	--				c.CUSTNAME)>0)
	--			OR CASE WHEN ISDATE(@searchTerm)=1 THEN PATINDEX(cast(convert(date,@searchTerm) as varchar(10)),cast(convert(date,sm.ORDERDATE) as varchar(10)))
	--				ELSE 0 END >0
	--			AND sm.CUSTNO IN (SELECT id FROM @tCustomers)	
	--	-- 10/25/13 DS Separate select for the more details search of parts on a Sales Order
	--	INSERT INTO @table 
	--	SELECT DISTINCT TOP 50 'MnxSearchViewCustomerOrders'AS searchProc,sm.custno AS id,'SO_m' AS [group],'SO_m' AS [table]
	--			,'/Orders/' + CAST(sm.custno AS varchar(50)) + '/Details/' + CAST(sd.UNIQUELN AS varchar(50)) AS [link]
	--			,sm.sono, c.CUSTNAME, sm.pono
	--			,CAST(CASE WHEN sd.uniq_key=' ' THEN sd.[Sodet_Desc] ELSE RTRIM(i.part_no) END 
	--				+ CASE WHEN i.revision = ' ' THEN ' '  ELSE ' | ' + i.revision END AS varchar(MAX)) AS PartNumRev
	--			,sm.ORDERDATE
	--		from Somain sm  CROSS APPLY (SELECT TOP 1 * FROM sodetail where sm.sono=sono)sd 
	--		left outer join inventor i on sd.uniq_key = i.uniq_key INNER JOIN CUSTOMER c ON c.CUSTNO = sm.CUSTNO
	--		WHERE 1=CASE WHEN (@searchType = 40 OR @searchType = 44) THEN
	--				CASE WHEN sm.ORDERDATE>DATEADD(MONTH,-@activeMonthLimit,GETDATE()) THEN 1 ELSE 0 END
	--			WHEN @searchType = 43 THEN 
	--				CASE WHEN  RTRIM(sm.ORD_TYPE) = 'OPEN' THEN 1 ELSE 0 END 
	--			WHEN @searchType = 45 THEN
	--				CASE WHEN RTRIM(sm.ORD_TYPE) = 'CLOSED' THEN 1 ELSE 0 END
	--			WHEN @searchType = 46 THEN
	--				CASE WHEN RTRIM(sm.ORD_TYPE) = 'CANCEL' THEN 1 ELSE 0 END
	--			WHEN @searchType <>0 THEN 1 
	--			ELSE 0 END
	--			AND(PATINDEX(@thisTerm,CASE WHEN sd.uniq_key=' ' THEN sd.[Sodet_Desc] ELSE RTRIM(i.part_no)END
	--					+ '  ' + CASE WHEN sd.uniq_key=' ' THEN sd.[Sodet_Desc] ELSE cast(i.Descript as char(45))END)>0)
	--			AND sm.CUSTNO IN (SELECT id FROM @tCustomers)
		
	--	SELECT top 1 @count = COUNT(*) FROM @table
	--	IF @count > 0
	--		SELECT searchProc,id,[group],[table],[link],SO_m,customer_f,PO_f,partNumberRev_m FROM @table order by orderDate DESC
	--END
	--ELSE
	--BEGIN
	--	DECLARE @countTble SearchCountType
	--	INSERT INTO @countTble
	--	SELECT TOP 1 'MnxSearchViewCustomerOrders','SO_m' AS [group], 'SO_m' AS [table], '' AS [link]
	--		from Somain sm INNER JOIN sodetail sd on sm.sono=sd.sono
	--		left outer join inventor i on sd.uniq_key = i.uniq_key INNER JOIN CUSTOMER c ON c.CUSTNO = sm.CUSTNO
	--		WHERE 1=CASE WHEN (@searchType = 40 OR @searchType = 44) AND sm.ORDERDATE>DATEADD(MONTH,-@activeMonthLimit,GETDATE()) THEN 1
	--			WHEN @searchType = 43 THEN 
	--				CASE WHEN  RTRIM(sm.ORD_TYPE) = 'OPEN' THEN 1 ELSE 0 END 
	--			WHEN @searchType = 45 THEN
	--				CASE WHEN RTRIM(sm.ORD_TYPE) = 'CLOSED' THEN 1 ELSE 0 END
	--			WHEN @searchType = 46 THEN
	--				CASE WHEN RTRIM(sm.ORD_TYPE) = 'CANCEL' THEN 1 ELSE 0 END
	--			WHEN @searchType <>0 THEN 1 
	--			ELSE 0 END
	--			AND (PATINDEX(@thisTerm,
	--					sm.SONO+'  '+
	--					sm.PONO+'  '+
	--					c.CUSTNAME+'  '+
	--					CASE WHEN sd.uniq_key=' ' THEN sd.[Sodet_Desc] ELSE RTRIM(i.part_no)END
	--						+ '  ' + CASE WHEN sd.uniq_key=' ' THEN sd.[Sodet_Desc] ELSE cast(i.Descript as char(45))END)>0)
	--			OR CASE WHEN ISDATE(@searchTerm)=1 THEN PATINDEX(cast(convert(date,@searchTerm) as varchar(10)),cast(convert(date,sm.ORDERDATE) as varchar(10)))
	--				ELSE 0 END >0
	--			AND sm.CUSTNO IN (SELECT id FROM @tCustomers)	
	--	SET @count = @@ROWCOUNT
	--	IF @count > 0
	--		SELECT * FROM @countTble
	--END
	RETURN @count
END