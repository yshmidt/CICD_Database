-- =============================================
-- Author : Satish B
-- Create date: 06/23/2017
-- Description:	Get buyer status grid data for  : Accept,Return,Pending (i.e.inspHeader.BuyerAction='')
-- Modified : 06/30/2017 Satish B : Added parameters
--		    : 06/30/2017 Satish B : Select part number
--		    : 06/30/2017 Satish B : Create temporary table
--		    : 06/30/2017 Satish B : Implement filter search against selected filter from UI
--		    : 06/30/2017 Satish B : Setect Description as combination of PartClass,PartType and Description
--		    : 07/20/2017 Satish B : Comment code (This code generate an wrong output when search for specific record)
--		    : 07/20/2017 Satish B : Added new code to get filter record
--		    : 07/21/2017 Satish B : Select reject reason
--		    : 07/25/2017 Satish B : Change alise PartRev to PartNo
--		    : 07/26/2017 Satish B : Select Reject Reason from support table instade of from inspectiondetail table
--		    : 07/26/2017 Satish B : Implement left join with Support table
--		    : 10/12/2017 Satish B : Display status as pending for the record which has (inspHeader.FailedQty-inspHeader.ReturnQty-inspHeader.Buyer_Accept)>0
--		    : 10/12/2017 Satish B : Add optional filter of inspHeader.BuyerAction='Return'
--		    : 11/03/2017 Satish B : Removed the identity(int,1,1) as RowNumber
--		    : 11/06/2017 Satish B : Change the filter logic to get records when  @filter <> '' AND @sortExpression <> ''
--		    : 11/06/2017 Satish B : Change the filter logic to get records when  @filter = '' AND @sortExpression <> ''
--		    : 11/06/2017 Satish B : Change the filter logic to get records when @filter <> '' AND @sortExpression = ''
--		    : 11/06/2017 Satish B : Change the filter logic to get records by default
--		    : 11/06/2017 Satish B : Added offset and fetch next record on the basis of @startRecord and @endRecord
--		    : 12/15/2017 Satish B : Create temp table and mearge the Reject Reason into single column sperated by comma(,)
--		    : 12/15/2017 Satish B : Change selection from returnStatusList to tempReturnStatusList
--		    : 03/08/2018 Satish B : Comment the selection of status conditionally and select Return as Status
--		    : 03/08/2018 Satish B : Removed the filter of inspHeader.BuyerAction='Return' OR inspHeader.BuyerAction='')
---			: 07/11/18 YS supname increased from 30 to 50
--			: 11/30/2018 Satish B : Replace LEFT JOIN with LEFT JOIN
--          : 02/18/2019 Satish B : Replace INNER JOIN with LEFT JOIN 
--          : 05/20/2019 Nitesh B : Change join table aspnet_Profile to aspnet_Users to get UserName
--			: 01/15/2020 Nitesh B : Remove condition to get only received PO rejected record for buyer 
--			: 01/16/2020 Nitesh B : Change condition to get PO buyer 
-- exec GetBuyerStatusList '','','','',''

-- =============================================
CREATE PROCEDURE GetBuyerStatusList
-- 06/30/2017 Satish B : Added parameters
-- Add the parameters for the stored procedure here
	@poNumber varchar(15)=null,
--- 07/11/18 YS supname increased from 30 to 50
	@supplier varchar(50)=null,
	@plNumber varchar(10)=null,
	@iPNorMPN varchar(25)=null,
	@buyer varchar(8)=null, 
	@startRecord int =1,
    @endRecord int =10, 
    @sortExpression nvarchar(1000) = null,
    @filter nvarchar(1000) = null
 AS
 BEGIN
	 SET NOCOUNT ON	 
	 DECLARE @SQLQuery varchar(1000) ,@SQL varchar(1000);
	 DECLARE @qryMain  NVARCHAR(2000); 
	 -- 06/30/2017 Satish B : Create temporary table
	;WITH returnStatusList as(
	--Get Accept List
	--10/12/2017 Satish B : Display status as pending for the record which has (inspHeader.FailedQty-inspHeader.ReturnQty-inspHeader.Buyer_Accept)>0
		SELECT  CASE WHEN inspHeader.BuyerAction ='' OR inspHeader.BuyerAction ='Return' THEN 'Pending' ELSE inspHeader.BuyerAction END AS Status
				,inspHeader.RejectedAt
				,RTRIM(inventor.PART_NO) + CASE WHEN inventor.REVISION IS NULL OR inventor.REVISION='' THEN '' ELSE '/' END + inventor.REVISION AS PartNo
				--06/30/2017 Satish B : Setect Description as combination of PartClass,PartType and Description
				,RTRIM(inventor.PART_CLASS) + CASE WHEN inventor.PART_CLASS IS NULL OR inventor.PART_CLASS='' THEN '' ELSE '/' END + 
				 RTRIM(inventor.PART_TYPE) + CASE WHEN inventor.PART_TYPE IS NULL OR inventor.PART_TYPE='' THEN '' ELSE '/' END +
				 inventor.DESCRIPT AS Descript
				--,RTRIM(inventor.PART_CLASS) + CASE WHEN inventor.PART_CLASS IS NULL OR inventor.PART_CLASS='' THEN '' ELSE '/' END + 
				-- CASE WHEN inventor.DESCRIPT IS NULL OR inventor.DESCRIPT='' THEN '' ELSE '/' END+inventor.DESCRIPT AS Descript
				,CAST(dbo.fremoveLeadingZeros(recHeader.ponum) AS VARCHAR(MAX)) AS PoNumber
				,recHeader.recPklNo AS PackingList
				,supInfo.SUPNAME AS Supplier
				,aspnetUser.UserName AS Buyer
				,(inspHeader.FailedQty-inspHeader.ReturnQty-inspHeader.Buyer_Accept) AS Quantity
				,inspHeader.inspHeaderId AS InspHeaderId
				-- 06/30/2017 Satish B : Select part number
				,inventor.PART_NO
				-- 07/21/2017 Satish B : Select reject reason
				-- 07/26/2017 Satish B : Select Reject Reason from support table instade of from inspectiondetail table
				--,inspDtl.defectNote AS RejectReason
				,support.Text AS RejectReason
		FROM inspectionHeader inspHeader
  --02/18/2019 Satish B : Replace INNER JOIN with LEFT JOIN  
  LEFT JOIN inspectionDetail inspDtl ON inspDtl.inspHeaderId=inspHeader.inspHeaderId  
		INNER JOIN receiverDetail recdtl ON recdtl.receiverDetId=inspHeader.receiverDetId
		INNER JOIN INVENTOR  inventor ON inventor.UNIQ_KEY=recdtl.Uniq_key
		INNER JOIN receiverHeader recHeader ON recHeader.receiverHdrId=recdtl.receiverHdrId
		INNER JOIN SUPINFO supInfo ON recHeader.SenderId=supInfo.Uniqsupno
		INNER JOIN POITEMS poitem ON poitem.UNIQLNNO=recdtl.uniqlnno
		INNER JOIN Pomain  pomain ON pomain.PONUM=poitem.PONUM
		--11/30/2018 Satish B : Replace LEFT JOIN with LEFT JOIN
		--01/15/2020 Nitesh B : Remove condition to get only received PO rejected record for buyer
		--01/16/2020 Nitesh B : Change condition to get PO buyer 
		LEFT JOIN aspnet_Users aspnetUser ON (aspnetUser.UserId=pomain.aspnetBuyer) -- 05/20/2019 Nitesh B :  Change join table aspnet_Profile to aspnet_Users to get UserName
		-- 07/26/2017 Satish B : Implement left join with Support table
		LEFT JOIN SUPPORT support on support.UNIQFIELD=inspDtl.def_code
		 --10/12/2017 Satish B : Add optional filter of inspHeader.BuyerAction='Return'
		WHERE (inspHeader.BuyerAction='Accept' OR inspHeader.BuyerAction='' OR inspHeader.BuyerAction='Return')
		AND (inspHeader.FailedQty-inspHeader.ReturnQty-inspHeader.Buyer_Accept)>0

	--Get Return List
		UNION 
		-- 03/08/2018 Satish B : Comment the selection of status conditionally and select Return as Status
		 SELECT  'Return' AS Status--CASE WHEN inspHeader.BuyerAction ='' THEN 'Pending' ELSE inspHeader.BuyerAction END AS Status
				,inspHeader.RejectedAt
				,RTRIM(inventor.PART_NO) + CASE WHEN inventor.REVISION IS NULL OR inventor.REVISION='' THEN '' ELSE '/' END + inventor.REVISION AS PartNo  -- Modified : 07/25/2017 Satish B : Change alise PartRev to PartNo
				,RTRIM(inventor.PART_CLASS) + CASE WHEN inventor.PART_TYPE IS NULL OR inventor.PART_TYPE='' THEN '' ELSE '/' END +
				 CASE WHEN inventor.DESCRIPT IS NULL OR inventor.DESCRIPT='' THEN '' ELSE '/' END+inventor.DESCRIPT AS Descript
				,CAST(dbo.fremoveLeadingZeros(recHeader.ponum) AS VARCHAR(MAX)) AS PoNumber
				,recHeader.recPklNo AS PackingList
				,supInfo.SUPNAME AS Supplier
				,aspnetUser.UserName AS Buyer
				,dmdetail.RET_QTY AS Quantity
				,inspHeader.inspHeaderId AS InspHeaderId
				-- 06/30/2017 Satish B : Select part number
				,inventor.PART_NO
				-- 07/21/2017 Satish B : Select reject reason
				-- 07/26/2017 Satish B : Select Reject Reason from support table instade of from inspectiondetail table
				--,inspDtl.defectNote AS RejectReason
				,support.Text AS RejectReason
		FROM inspectionHeader inspHeader
  --02/18/2019 Satish B : Replace INNER JOIN with LEFT JOIN  
  LEFT JOIN inspectionDetail inspDtl ON inspDtl.inspHeaderId=inspHeader.inspHeaderId  
		INNER JOIN receiverDetail recdtl ON recdtl.receiverDetId=inspHeader.receiverDetId
		INNER JOIN INVENTOR  inventor ON inventor.UNIQ_KEY=recdtl.Uniq_key
		INNER JOIN receiverHeader recHeader ON recHeader.receiverHdrId=recdtl.receiverHdrId
		INNER JOIN SUPINFO supInfo ON recHeader.SenderId=supInfo.Uniqsupno
		INNER JOIN POITEMS poitem ON poitem.UNIQLNNO=recdtl.uniqlnno
		INNER JOIN Pomain  pomain ON pomain.PONUM=poitem.PONUM
		--11/30/2018 Satish B : Replace LEFT JOIN with LEFT JOIN
		--01/15/2020 Nitesh B : Remove condition to get only received PO rejected record for buyer 
		--01/16/2020 Nitesh B : Change condition to get PO buyer 
		LEFT JOIN aspnet_Users aspnetUser ON (aspnetUser.UserId=pomain.aspnetBuyer) -- 05/20/2019 Nitesh B :  Change join table aspnet_Profile to aspnet_Users to get UserName
		INNER JOIN DMRDetail dmdetail on dmdetail.inspHeaderId=inspDtl.inspHeaderId
		INNER JOIN DMrheader dmHeader on dmHeader.DMRUNIQUE=dmdetail.DMRUNIQUE
		-- 07/26/2017 Satish B : Implement left join with Support table
		LEFT JOIN SUPPORT support on support.UNIQFIELD=inspDtl.def_code
		--03/08/2018 Satish B : Removed the filter of inspHeader.BuyerAction='Return' OR inspHeader.BuyerAction='')
		WHERE --(inspHeader.BuyerAction='Return' OR inspHeader.BuyerAction='') AND
		      dmHeader.PRINTDMR=0   
		)

		-- 12/15/2017 Satish B : Create temp table and mearge the Reject Reason into single column sperated by comma(,)
		,tempReturnStatusList AS(
		 SELECT distinct Status
		        ,RejectedAt
				,PartNo
				,Descript
				,PoNumber
				,PackingList 
				,Supplier
				,Buyer
				,Quantity
				,InspHeaderId
				,PART_NO
			    ,(STUFF((SELECT CAST(', ' + RTRIM(returnStatusList.RejectReason) AS VARCHAR(MAX)) 
				 FROM returnStatusList 
				 WHERE returnStatusList.InspHeaderId =resultList.InspHeaderId and  returnStatusList.Status =resultList.Status
                 FOR XML PATH ('')), 1, 2, '')) AS RejectReason
				 FROM returnStatusList resultList)

	-- 06/30/2017 Satish B : Implement filter search against selected filter from UI
	-- 07/20/2017 Satish B : Comment code (This code generate an wrong output when search for specific record)
    --SELECT identity(int,1,1) as RowNumber,*INTO #TEMP from returnStatusList 
    ----Get Default Data
    -- 	IF ((@poNumber = '' OR @poNumber IS NULL) AND (@supplier ='' OR @supplier IS NULL) AND  (@plNumber = '' OR @plNumber IS NULL) AND  (@iPNorMPN = '' OR @iPNorMPN IS NULL) AND  (@buyer = '' OR @buyer IS NULL))
	--	BEGIN
	--		SET @SQLQuery = 'select *  from #TEMP'
	--	END
	----Get Filter Data by PO Number
	--ELSE IF ((@poNumber <> '' OR @poNumber IS NOT NULL) AND ( @supplier ='' OR @supplier IS NULL) AND  (@plNumber = '' OR @plNumber IS NULL) AND  (@iPNorMPN = '' OR @iPNorMPN IS NULL) AND  (@buyer = '' OR @buyer IS NULL)) 
	--	BEGIN
	--		SET @SQLQuery = 'select *  from #TEMP Where PoNumber LIKE ''%' + @poNumber + '%'''
	--	END
	----Get Filter Data by  Supplier
	--ELSE IF ((@poNumber = '' OR @poNumber IS  NULL) AND ( @supplier <>'' OR @supplier IS NOT NULL) AND  (@plNumber = '' OR @plNumber IS NULL) AND  (@iPNorMPN = '' OR @iPNorMPN IS NULL) AND  (@buyer = '' OR @buyer IS NULL)) 
	--	BEGIN
	--		SET @SQLQuery = 'select *  from #TEMP Where Supplier  LIKE ''%' + @supplier + '%'''
	--	END
	----Get Filter Data by PL Number
	--ELSE IF ((@poNumber = '' OR @poNumber IS  NULL) AND ( @supplier ='' OR @supplier IS NULL) AND  (@plNumber <> '' OR @plNumber IS NOT NULL) AND  (@iPNorMPN = '' OR @iPNorMPN IS NULL) AND  (@buyer = '' OR @buyer IS NULL)) 
	--	BEGIN
	--		SET @SQLQuery = 'select *  from #TEMP where PackingList LIKE ''%' + @plNumber + '%'''
	--	END
	----Get Filter Data by IPN OR MPN
	--ELSE IF ((@poNumber = '' OR @poNumber IS  NULL) AND ( @supplier ='' OR @supplier IS NULL) AND  (@plNumber = '' OR @plNumber IS NULL) AND  (@iPNorMPN <>'' OR @iPNorMPN IS NOT NULL) AND  (@buyer = '' OR @buyer IS NULL)) 
	--	BEGIN
	--		SET @SQLQuery = 'select *  from #TEMP where PART_NO LIKE ''%' + @iPNorMPN + '%'''
	--	END
    --   --Get Filter Data by Buyer
	--ELSE IF ((@poNumber = '' OR @poNumber IS  NULL) AND ( @supplier ='' OR @supplier IS NULL) AND  (@plNumber = '' OR @plNumber IS NULL) AND  (@iPNorMPN='' OR @iPNorMPN IS NULL) AND  (@buyer <> '' OR @buyer IS NOT NULL)) 
	--	BEGIN
	--		SET @SQLQuery = 'select *  from #TEMP where Buyer LIKE ''%' + @buyer + '%'''
	--	END
 
    -- 07/20/2017 Satish B : Added new code to get filter record
    -- 11/03/2017 Satish B : Removed the identity(int,1,1) as RowNumber
    --SELECT identity(int,1,1) as RowNumber,*INTO #TEMP from returnStatusList where 
	-- 12/15/2017 Satish B : Change selection from returnStatusList to tempReturnStatusList
	--SELECT *INTO #TEMP from returnStatusList where 
	SELECT *INTO #TEMP from tempReturnStatusList where 
  
    ((@poNumber = '' OR @poNumber IS NULL) OR  ((@poNumber <> '' OR @poNumber IS NOT NULL) AND PoNumber LIKE '%' + @poNumber + '%' ))
    AND 
    ((@supplier = '' OR @supplier IS NULL) OR  ((@supplier <> '' OR @supplier IS NOT NULL) AND Supplier LIKE '%' + @supplier + '%' ))
    AND 
    ((@plNumber = '' OR @plNumber IS NULL) OR  ((@plNumber <> '' OR @plNumber IS NOT NULL) AND PackingList LIKE '%' + @plNumber + '%' ))
    AND 
    ((@iPNorMPN = '' OR @iPNorMPN IS NULL) OR  ((@iPNorMPN <> '' OR @iPNorMPN IS NOT NULL) AND PartNo LIKE '%' + @iPNorMPN + '%' ))
     AND 
    ((@buyer = '' OR @buyer IS NULL) OR  ((@buyer <> '' OR @buyer IS NOT NULL) AND Buyer LIKE '%' + @buyer + '%' ))
		
	SET @SQLQuery ='select *  from #TEMP'
	SET @qryMain=';SELECT COUNT(*) AS ''Total'' FROM('+@SQLQuery+')a'

	IF @filter <> '' AND @sortExpression <> ''
		BEGIN
		-- 11/06/2017 Satish B : Change the filter logic to get records when  @filter <> '' AND @sortExpression <> ''
			--SET @qryMain=@qryMain +';SELECT * FROM('+@SQLQuery+')a WHERE RowNumber BETWEEN ('+CONVERT(VARCHAR(10),@startRecord)+') AND ('+CONVERT(VARCHAR(10),@endRecord)+') AND ' +@filter+ ' ORDER BY '+ @sortExpression+''
			SET @qryMain=@qryMain +';SELECT * FROM('+@SQLQuery+')a  ' +@filter+ ' ORDER BY '+ @sortExpression+''
		END
	ELSE IF @filter = '' AND @sortExpression <> ''
		BEGIN
		-- 11/06/2017 Satish B : Change the filter logic to get records when  @filter = '' AND @sortExpression <> ''
			--SET @qryMain=@qryMain +';SELECT * FROM('+@SQLQuery+')a WHERE RowNumber BETWEEN ('+CONVERT(VARCHAR(10),@startRecord)+') AND ('+CONVERT(VARCHAR(10),@endRecord)+')  ORDER BY '+ @sortExpression+''
			SET @qryMain=@qryMain +';SELECT * FROM('+@SQLQuery+')a ORDER BY '+ @sortExpression+''
		END
	ELSE IF @filter <> '' AND @sortExpression = ''
		BEGIN
		-- 11/06/2017 Satish B : Change the filter logic to get records when @filter <> '' AND @sortExpression = ''
			--SET @qryMain=@qryMain +';SELECT * FROM('+@SQLQuery+')a WHERE  RowNumber BETWEEN ('+CONVERT(VARCHAR(10),@startRecord)+') AND ('+CONVERT(VARCHAR(10),@endRecord)+')  AND ' +@filter+ ''
			SET @qryMain=@qryMain +'SELECT * FROM('+@SQLQuery+')a ' +@filter+ ''
		END
	ELSE
		BEGIN
		-- 11/06/2017 Satish B : Change the filter logic to get records by default
			--SET @qryMain=@qryMain +';SELECT * FROM('+@SQLQuery+')a WHERE RowNumber BETWEEN ('+CONVERT(VARCHAR(10),@startRecord)+') AND ('+CONVERT(VARCHAR(10),@endRecord)+')  ORDER BY PoNumber'
			SET @qryMain=@qryMain +';SELECT * FROM('+@SQLQuery+')a ORDER BY PoNumber'
		END
	-- 11/06/2017 Satish B : Added offset and fetch next record on the basis of @startRecord and @endRecord
	SET @qryMain = @qryMain + ' OFFSET ('+CONVERT(VARCHAR(10),@startRecord -1)+') ROWS  
							    FETCH NEXT ('+CONVERT(VARCHAR(10),@endRecord)+') ROWS ONLY'
	EXEC sp_executesql @qryMain   
END 

