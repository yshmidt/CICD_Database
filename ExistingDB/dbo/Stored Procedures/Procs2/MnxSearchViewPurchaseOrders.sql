-- =============================================
-- Author:		David Sharp
-- Create date: 12/7/2011
-- Description:	gets info about purchase orders
-- 08/27/13 DS added filter for full results, or any result
-- 10/25/13 DS added PATINDEX for performance and @activeMonthLimit for consistency in seach sp
-- 11/15/13 DS changed approach to return TOP 15 excluding previous results
-- 01/02/14 DS fixed the search to use @thisTerm
-- 05/07/14 DS Added ExternalEmp param
-- 11/06/14 DS removed leading 0's from ponum and changed date format
--04/08/15 YS customer settings saved in wmsettings
-- =============================================
CREATE PROCEDURE [dbo].[MnxSearchViewPurchaseOrders] 
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
	IF @searchType = 15
		SET @searchTerm = cast(convert(date,@searchTerm) as varchar(20))
		
	-- 10/25/13 DS Default Month Limit
    IF @activeMonthLimit = 0 
		--04/08/15 YS customer settings saved in wmsettings
		--SELECT @activeMonthLimit = settingValue FROM MnxSettingsManagement WHERE settingId='0c91389f-0559-410f-b5f8-12d8659a857f' --special limit for orders
		SELECT @activeMonthLimit = COALESCE(s.settingValue,w.settingvalue) 
				FROM MnxSettingsManagement s left outer join wmSettingsManagement w 
					ON s.settingid=w.settingid
				WHERE settingName='orderMonthLimit'

    DECLARE @thisTerm varchar(MAX) = '%' + @searchTerm + '%'
    DECLARE @count int
    /*colNames are the localizatoin keys for the column names returned in the results.*/
    --DECLARE @table TABLE(searchProc varchar(MAX),id varchar(50),[group] nvarchar(255),[table] nvarchar(255),[link] varchar(255),  
	--	PO_f nvarchar(255), supplier_f nvarchar(255),orderDate_f nvarchar(255),buyer_f nvarchar(255))
	
	--INSERT INTO @table
	IF @ExternalEmp = 0
	BEGIN
		SELECT DISTINCT TOP 15 'MnxSearchViewPurchaseOrders' AS searchProc,po.PONUM AS id, 'po' AS [group], 'PO_f' as [table],
				'/PurchaseOrder/' + CAST(po.PONUM AS varchar(50)) AS [link],
				SUBSTRING(po.PONUM,PATINDEX('%[^0]%',po.PONUM+'.'),LEN(po.PONUM)) AS PO_f,  si.SUPNAME AS supplier_f, CONVERT(varchar(10),po.PODATE,101) AS orderDate_f, po.BUYER as buyer_f
			FROM POMAIN po INNER JOIN SUPINFO si on po.UNIQSUPNO = si.UNIQSUPNO LEFT OUTER JOIN POITEMS pi ON po.PONUM = pi.PONUM LEFT OUTER JOIN INVENTOR i ON pi.UNIQ_KEY = i.UNIQ_KEY
			WHERE (PATINDEX(@thisTerm,
					po.PONUM+'  '+
					po.POSTATUS+'  '+
					po.BUYER+'  '+
					po.APPVNAME+'  '+
					po.CONFNAME+'  '+
					si.SUPNAME+'  '+
					cast(convert(date,po.PODATE) as varchar(20))+'  '+
					CASE WHEN NOT i.part_no IS NULL THEN i.part_no ELSE '' END)>0 
				AND (po.UNIQSUPNO IN (SELECT id FROM @tSupplier)))
				AND 1=CASE WHEN po.PODATE>DATEADD(MONTH,-@activeMonthLimit,GETDATE()) THEN 1 ELSE 0 END
				AND NOT po.PONUM IN (SELECT id FROM @tSearchId)
		SET @count = @@ROWCOUNT
	END
	--IF @count > 0	SELECT * FROM @table
			
			
	---- 08/27/13 DS added filter for full results, or any result
	--IF @fullResult=1
	--BEGIN
	--	INSERT INTO @table
	--	SELECT DISTINCT 'MnxSearchViewPurchaseOrders',po.PONUM AS id, 'po' AS [group], 'PO_f' as [table],'/PurchaseOrder/' + CAST(po.PONUM AS varchar(50)) AS [link],
	--			po.PONUM AS po,  si.SUPNAME AS supplier, cast(convert(date,po.PODATE) as varchar(20)) AS orderDate, po.BUYER as buyer
	--		FROM POMAIN po INNER JOIN SUPINFO si on po.UNIQSUPNO = si.UNIQSUPNO LEFT OUTER JOIN POITEMS pi ON po.PONUM = pi.PONUM LEFT OUTER JOIN INVENTOR i ON pi.UNIQ_KEY = i.UNIQ_KEY
	--		WHERE (PATINDEX(@searchTerm,
	--				po.PONUM+'  '+
	--				po.POSTATUS+'  '+
	--				po.BUYER+'  '+
	--				po.APPVNAME+'  '+
	--				po.CONFNAME+'  '+
	--				si.SUPNAME+'  '+
	--				cast(convert(date,po.PODATE) as varchar(20))+'  '+
	--				CASE WHEN NOT i.part_no IS NULL THEN i.part_no ELSE '' END)>0 
	--			AND (po.UNIQSUPNO IN (SELECT id FROM @tSupplier)))
	--			AND 1=CASE WHEN po.PODATE>DATEADD(MONTH,-@activeMonthLimit,GETDATE()) THEN 1 ELSE 0 END
	--	SET @count = @@ROWCOUNT
	--	IF @count > 0
	--		SELECT * FROM @table
	--END
	--ELSE
	--BEGIN
	--	DECLARE @countTble SearchCountType
	--	INSERT INTO @countTble
	--	SELECT TOP 1 'MnxSearchViewPurchaseOrders','po' [group], 'PO_f' [table],'' [link]
	--		FROM POMAIN po INNER JOIN SUPINFO si on po.UNIQSUPNO = si.UNIQSUPNO LEFT OUTER JOIN POITEMS pi ON po.PONUM = pi.PONUM LEFT OUTER JOIN INVENTOR i ON pi.UNIQ_KEY = i.UNIQ_KEY
	--		WHERE (PATINDEX(@searchTerm,
	--				po.PONUM+'  '+
	--				po.POSTATUS+'  '+
	--				po.BUYER+'  '+
	--				po.APPVNAME+'  '+
	--				po.CONFNAME+'  '+
	--				si.SUPNAME+'  '+
	--				cast(convert(date,po.PODATE) as varchar(20))+'  '+
	--				CASE WHEN NOT i.part_no IS NULL THEN i.part_no ELSE '' END)>0
	--			OR 1=CASE WHEN ISDATE(@searchTerm)=1 THEN PATINDEX(cast(convert(date,@searchTerm) as varchar(10)),cast(convert(date,po.PODATE) as varchar(10))) ELSE 0 END)
	--			AND po.UNIQSUPNO IN (SELECT id FROM @tSupplier)
	--			AND 1=CASE WHEN po.PODATE>DATEADD(MONTH,-@activeMonthLimit,GETDATE()) THEN 1 ELSE 0 END
	--	SET @count = @@ROWCOUNT
	--	IF @count > 0
	--		SELECT * FROM @countTble
	--END	
	RETURN @count
END