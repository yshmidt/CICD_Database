-- =============================================
-- Author: Satish B
-- Create date: <06/15/2017>
-- Description:	<Get Return DMR grid data and history grid data conditionally, in Buyer Action module>
-- Modified : 06/29/2017 Satish B : Use existing function to remove leading zeros
--		    : 07/20/2017 Satish B : Comment code (This code generate an wrong output when search for specific record)
--		    : 07/20/2017 Satish B : Added new code to get filter record
--		    : 07/24/2017 Satish B : Added two new parameters i.e. @fromDate and @toDate
--		    : 07/24/2017 Satish B : Get last 90 days record for history grid and records between filter from date and to date
--			: 07/12/2018 YS supname column increased from 30 to 50
--			: 11/30/2018 Satish B : Replace LEFT JOIN with LEFT JOIN
--          : 04/30/2020 Shivshankar P : Added outer apply to get recordId of note
-- exec GetReturnDmr 1,Null,'','','','','',''

-- =============================================
CREATE PROCEDURE [dbo].[GetReturnDmr] 
	-- Add the parameters for the stored procedure here
	@isHistory bit=0,
    @buyerId uniqueidentifier=null,
	@dmrNumber nvarchar(10)  =null,
	@poNumber nvarchar(15) = null ,
	@rmaNumber nvarchar(15) = null ,
	-- 07/12/2018 YS supname column increased from 30 to 50
	@supplier nvarchar(50) = null ,
	-- Modified : 07/24/2017 Satish B : Added two new parameters i.e. @fromDate and @toDate
	@fromDate date = null ,
	@toDate date = null ,
	@startRecord int =1,
    @endRecord int =100, 
    @sortExpression nvarchar(1000) = null,
    @filter nvarchar(1000) = null
AS
BEGIN
	SET NoCount on;
	DECLARE @SQLQuery varchar(1000) ,@SQL varchar(1000);
	DECLARE @qryMain  NVARCHAR(2000); 
	;WITH returnDmr as(
			SELECT dmrHeader.DmrUnique
				,dmrHeader.RMA_NO AS RMANO
				,dmrHeader.RMA_DATE AS RMADate
				--06/29/2017 Satish B : Use existing function to remove leading zeros
				,CAST(dbo.fremoveLeadingZeros(dmrHeader.dmr_no) AS VARCHAR(MAX)) AS DmrNo
				--,SUBSTRING(dmrHeader.dmr_no , PATINDEX('%[^0]%',dmrHeader.dmr_no ), 10) AS DmrNo
				,dmrHeader.dmr_Date AS DmrDate
				--06/29/2017 Satish B : Use existing function to remove leading zeros
				,CAST(dbo.fremoveLeadingZeros(dmrHeader.PoNum) AS VARCHAR(MAX)) AS PoNum
				--,SUBSTRING(dmrHeader.PoNum , PATINDEX('%[^0]%',dmrHeader.PoNum ), 15) AS PoNum
				,dmrHeader.LinkAdd
				,dmrHeader.ConfirmBy
				,dmrHeader.PrintDmr
				,dmrHeader.ShipVia
				,dmrHeader.WayBill
				,supinfo.Supid AS CustomerNumber
				,supinfo.Supname AS Supplier
				,Note.RecordId -- 04/30/2020 Shivshankar P : Added outer apply to get recordId of note
			FROM DMRHeader dmrHeader
				INNER JOIN PoMaiN poMain ON dmrHeader.PoNum=poMain.PONUM
				--11/30/2018 Satish B : Replace LEFT JOIN with LEFT JOIN
				LEFT JOIN Aspnet_Profile aspnetProfile ON poMain.AspnetBuyer=aspnetProfile.UserId
				INNER JOIN Supinfo supinfo ON poMain.UNIQSUPNO=supinfo.Uniqsupno
				OUTER APPLY (SELECT RecordId FROM wmNotes WHERE RecordType = 'BuyerAction' and RecordId = poMain.PONUM)Note 
			WHERE dmrHeader.PRINTDMR=@isHistory AND (@buyerId IS NULL  OR  aspnetProfile.UserId=@buyerId)
			-- Modified : 07/24/2017 Satish B : Get last 90 days record for history grid and records between filter from date and to date
				AND (@isHistory =0 OR ((((@fromDate IS NULL OR @fromDate ='') AND (@toDate IS NULL OR @toDate ='')) AND dmrHeader.dmr_Date >= DATEADD(MONTH, -3, GETDATE()))
				OR cast(dmrHeader.dmr_Date AS DATE) BETWEEN cast(@fromDate AS DATE) AND cast(@toDate AS DATE)))
	)
	-- 07/20/2017 Satish B : Comment code (This code generate an wrong output when search for specific record)R
	--SELECT identity(int,1,1) as RowNumber,*INTO #TEMP from returnDmr 
	--IF ((@dmrNumber = '' OR @dmrNumber IS NULL) AND (@poNumber ='' OR @poNumber IS NULL) AND  (@rmaNumber = '' OR @rmaNumber IS NULL) AND  (@supplier = '' OR @supplier IS NULL))
	--	BEGIN
	--		SET @SQLQuery = 'select *  from #TEMP'
	--	END
	----Get Filter Data by Dmr Number
	--ELSE IF ((@dmrNumber <> '' OR @dmrNumber IS NOT NULL) AND ( @poNumber ='' OR @poNumber IS NULL) AND  (@rmaNumber = '' OR @rmaNumber IS NULL) AND  (@supplier = '' OR @supplier IS NULL)) 
	--	BEGIN
	--		SET @SQLQuery = 'select *  from #TEMP Where DmrNo LIKE ''%' + @dmrNumber + '%'''
	--	END
	----Get Filter Data by  PO Number
	--ELSE IF ((@dmrNumber = '' OR @dmrNumber IS  NULL) AND ( @poNumber <>'' OR @poNumber IS NOT NULL) AND  (@rmaNumber = '' OR @rmaNumber IS NULL) AND  (@supplier = '' OR @supplier IS NULL)) 
	--	BEGIN
	--		SET @SQLQuery = 'select *  from #TEMP Where PoNum  LIKE ''%' + @poNumber + '%'''
	--	END
	----Get Filter Data by RMA Number
	--ELSE IF ((@dmrNumber = '' OR @dmrNumber IS  NULL) AND ( @poNumber ='' OR @poNumber IS NULL) AND  (@rmaNumber <> '' OR @rmaNumber IS NOT NULL) AND  (@supplier = '' OR @supplier IS NULL)) 
	--	BEGIN
	--		SET @SQLQuery = 'select *  from #TEMP where RMANO LIKE ''%' + @rmaNumber + '%'''
	--	END
	----Get Filter Data by Supplier
	--ELSE IF ((@dmrNumber = '' OR @dmrNumber IS  NULL) AND ( @poNumber ='' OR @poNumber IS NULL) AND  (@rmaNumber = '' OR @rmaNumber IS NULL) AND  (@supplier <>'' OR @supplier IS NOT NULL)) 
	--	BEGIN
	--		SET @SQLQuery = 'select *  from #TEMP where Supplier LIKE ''%' + @supplier + '%'''
	--	END
	-- 07/20/2017 Satish B : Added new code to get filter record
	SELECT identity(int,1,1) as RowNumber,*INTO #TEMP FROM returnDmr WHERE
	 ((@dmrNumber = '' OR @dmrNumber IS NULL) OR  ((@dmrNumber <> '' OR @dmrNumber IS NOT NULL) AND DmrNo LIKE '%' + @dmrNumber + '%'))
    AND 
    ((@supplier = '' OR @supplier IS NULL) OR  ((@supplier <> '' OR @supplier IS NOT NULL) AND Supplier LIKE '%' + @supplier + '%'))
    AND 
    ((@poNumber = '' OR @poNumber IS NULL) OR  ((@poNumber <> '' OR @poNumber IS NOT NULL) AND PoNum LIKE '%' + @poNumber + '%'))
    AND 
    ((@rmaNumber = '' OR @rmaNumber IS NULL) OR  ((@rmaNumber <> '' OR @rmaNumber IS NOT NULL) AND RMANO LIKE '%' + @rmaNumber + '%'))

	SET @SQLQuery ='select *  from #TEMP'
	SET @qryMain=';SELECT COUNT(*) AS ''Total'' FROM('+@SQLQuery+')a'

	IF @filter <> '' AND @sortExpression <> ''
		BEGIN
			SET @qryMain=@qryMain +';SELECT * FROM('+@SQLQuery+')a WHERE RowNumber BETWEEN ('+CONVERT(VARCHAR(10),@startRecord)+') AND ('+CONVERT(VARCHAR(10),@endRecord)+') AND ' +@filter+ ' ORDER BY '+ @sortExpression+''
		END
	ELSE IF @filter = '' AND @sortExpression <> ''
		BEGIN
			SET @qryMain=@qryMain +';SELECT * FROM('+@SQLQuery+')a WHERE RowNumber BETWEEN ('+CONVERT(VARCHAR(10),@startRecord)+') AND ('+CONVERT(VARCHAR(10),@endRecord)+')  ORDER BY '+ @sortExpression+''
		END
	ELSE IF @filter <> '' AND @sortExpression = ''
		BEGIN
			SET @qryMain=@qryMain +';SELECT * FROM('+@SQLQuery+')a WHERE  RowNumber BETWEEN ('+CONVERT(VARCHAR(10),@startRecord)+') AND ('+CONVERT(VARCHAR(10),@endRecord)+')  AND ' +@filter+ ''
		END
	ELSE
		BEGIN
			SET @qryMain=@qryMain +';SELECT * FROM('+@SQLQuery+')a WHERE RowNumber BETWEEN ('+CONVERT(VARCHAR(10),@startRecord)+') AND ('+CONVERT(VARCHAR(10),@endRecord)+')  ORDER BY DmrDate'
		END
	EXEC sp_executesql @qryMain   
END