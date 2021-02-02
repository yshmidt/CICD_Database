﻿-- =============================================
-- Author:		Rajendra K	
-- Create date: <12/08/2016>
-- Description:Get Contract list from UI
--Modification
  -- 03/28/17 YS changed length of the part_no column from 25 to 35
  -- 04/19/2017 Rajendra K : Add paging logic
  -- 08/18/2017 Rajendra K : Added table FCUsed in Join condition and FC.Currency in select list to get supplier currency
  -- 08/21/2017 Rajendra K : Added dbo.fn_IsFCInstalled() in select lis to get FCInstalled value
  -- 09/12/2017 Rajendra K : Added ITAR
  -- 07/27/2018 Rajendra K : Replaced ContractH_unique by PartNumber/Revision in Order by clause
  -- 07/30/2018 Rajendra K : Set @TodayDate AS DateOnly Format(Set GetDate if @TodayDate is Null)
  -- 07/30/2018 Rajendra K : Change condition for ExpDate condition (Get only active records if @ExpiredContract is false)
  -- 07/30/2018 Rajendra K : supname increased from 30 to 50
  -- 07/30/2018 Rajendra K : @SupplierUniq decreased from 30 to 10
  -- 05/20/2019 Nitesh B : Change the join table aspnet_Profile to aspnet_Users for getting UserName
  -- 01/23/2020 Rajendra K : Added Parameter @filter And @sortExpression
  -- 01/23/2020 Rajendra K : Removed the "order by" , added fn_GetDataBySortAndFilters function and #contractData table to get data with sort functionality
-- =============================================
CREATE PROCEDURE [dbo].[GetContractList]
(
@ContractHeaderKey CHAR(10)=null,
--- 03/28/17 YS changed length of the part_no column from 25 to 35
@PartNumber CHAR(35),
@Rev CHAR(8),
 -- 07/30/2018 Rajendra K : supname increased from 30 to 50
@SupplierName CHAR(50),
 -- 07/30/2018 Rajendra K : SupplierUniq decreased from 30 to 10
@SupplierUniq CHAR(10),
@ContractNumber NVARCHAR(20),
@ExpiredContract BIT = 0,
@IsAutoGenerated BIT = 0,
@TodayDate DATETIME,
@StartRecord int =1,
@EndRecord int =10,
@Out_TotalNumberOfRecord INT OUTPUT,    
@sortExpression NVARCHAR(1000) = null      -- 01/23/2020  Rajendra K : Added Parameter @filter And @sortExpression
)
AS
BEGIN
   SET NOCOUNT ON;  
   DECLARE @SupplierUniqKey CHAR(10),@sqlQuery NVARCHAR(MAX);  
 	 --Get SupplierUniqKey from SupplierName

   -- 07/30/2018 Rajendra K : Set @TodayDate AS DateOnly Format(Set GetDate if @TodayDate is Null)
   IF(@TodayDate IS NULL)
   BEGIN
   SET @TodayDate = CAST(GETDATE() AS DATE)
   END
   ELSE 
   BEGIN
   SET @TodayDate = CAST(@TodayDate AS DATE)
   END

   IF @SupplierName IS NOT NULL
	 BEGIN
		SET @SupplierUniqKey = (SELECT TOP(1)UNIQSUPNO FROM SUPINFO WHERE SUPNAME = @SupplierName)
	 END
	 ELSE
	 BEGIN
	 IF @SupplierUniq IS NOT NULL
	 BEGIN
	 SET @SupplierUniqKey = @SupplierUniq
	 END
	 END

	SELECT COUNT(1) AS CountRecords
    INTO #tempContract
	FROM contractHeader CH 
		  INNER JOIN CONTRACT C ON CH.ContractH_unique = C.contractH_unique 
		  INNER JOIN INVENTOR I ON C.UNIQ_KEY  = I.UNIQ_KEY
		  INNER JOIN CONTMFGR CM ON C.CONTR_UNIQ = CM.CONTR_UNIQ
		  INNER JOIN CONTPRIC CP ON CM.CONTR_UNIQ = CP.CONTR_UNIQ AND CM.MFGR_UNIQ = CP.MFGR_UNIQ
		  INNER JOIN SUPINFO S ON CH.uniqsupno = S.UNIQSUPNO
		  INNER JOIN aspnet_Users AP ON CH.contrUserId = AP.UserId   -- 05/20/2019 Nitesh B : Change the join table aspnet_Profile to aspnet_Users for getting UserName
	WHERE ((@PartNumber IS NULL OR @PartNumber = '')OR (I.PART_NO =  @PartNumber AND (PART_SOURC ='BUY' OR (PART_SOURC = 'MAKE' AND MAKE_BUY = 1))
		  AND (REVISION = ISNULL(@Rev,REVISION ) OR @Rev='')))
	      AND (@SupplierName IS NULL OR @SupplierName = '' OR CH.uniqsupno = @SupplierUniqKey)
		  AND (@SupplierUniq IS NULL OR @SupplierName = '' OR CH.uniqsupno = @SupplierUniqKey)
		  AND (@ContractNumber ='' OR CH.Contr_no = ISNULL(@ContractNumber,CH.Contr_no ))
		  -- 07/30/2018 Rajendra K : Change condition for ExpDate condition (Get only active records if @ExpiredContract is false)
		  -- AND (@ExpiredContract = 0 OR CH.expireDate < ISNULL(@TodayDate,GETDATE()))
		  AND ((@ExpiredContract = 0 AND (CH.expireDate IS NULL OR (CAST(CH.expireDate AS DATE) > @TodayDate)))
		  OR ( @ExpiredContract = 1  AND CAST(CH.expireDate AS DATE) < @TodayDate))
		  AND (CH.AutoGenerated = @IsAutoGenerated)
		  AND (@ContractHeaderKey IS NULL OR @ContractHeaderKey ='' OR CH.ContractH_unique = @ContractHeaderKey )

  SELECT DISTINCT
		   CH.ContractH_unique
		  ,C.UNIQ_KEY 
		  ,I.PART_NO + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) AS PART_NO
		  ,(CASE WHEN I.PART_CLASS IS NULL OR  I.PART_CLASS = '' THEN I.PART_CLASS ELSE I.PART_CLASS +'/ ' END ) + 
		  (CASE WHEN I.PART_TYPE IS NULL OR I.PART_TYPE ='' THEN ' / '+ I.DESCRIPT ELSE I.PART_TYPE + '/'+I.DESCRIPT END) AS Descript 
		  ,I.REVISION
		  ,I.PART_TYPE
		  ,CH.uniqsupno
		  ,S.SUPNAME AS supname
		  ,S.SUPID 
		  ,CH.Contr_no
		  ,CH.quote_no
		  ,CH.startDate
		  ,CH.expireDate
		  ,CH.primSupplier
		  ,CH.contractNote
		  ,CH.AutoGenerated
		  ,AP.UserName AS UserId
		  ,C.CONTR_UNIQ
		  ,C.QTYLIMIT
		  ,ISNULL(C.MINQTY,0) AS MINQTY
		  ,CAST (C.contractItemNote AS NVARCHAR(MAX)) AS contractItemNote
		  ,ISNULL(FC.Currency,'') AS Currency -- 08/18/2017 Rajendra K : Added FC.Currency in select list to get supplier currency
		  ,dbo.fn_IsFCInstalled() AS IsFCInstalled -- 08/21/2017 Rajendra K : Added dbo.fn_IsFCInstalled() in select lis to get FCInstalled value
		  ,I.ITAR -- Added ITAR on 09/12/2017 - Rajendra K
 INTO #contractData
	FROM contractHeader CH 
		  INNER JOIN CONTRACT C ON CH.ContractH_unique = C.contractH_unique 
		  INNER JOIN INVENTOR I ON C.UNIQ_KEY  = I.UNIQ_KEY
		  INNER JOIN CONTMFGR CM ON C.CONTR_UNIQ = CM.CONTR_UNIQ
		  INNER JOIN CONTPRIC CP ON CM.CONTR_UNIQ = CP.CONTR_UNIQ AND CM.MFGR_UNIQ = CP.MFGR_UNIQ
		  INNER JOIN SUPINFO S ON CH.uniqsupno = S.UNIQSUPNO
		  INNER JOIN aspnet_Users AP ON CH.contrUserId = AP.UserId   -- 05/20/2019 Nitesh B : Change the join table aspnet_Profile to aspnet_Users for getting UserName
		  LEFT JOIN FcUsed FC ON S.Fcused_Uniq = FC.FcUsed_Uniq -- 08/18/2017 Rajendra K : Added table FCUsed in Join condition to get supplier currency
	WHERE ((@PartNumber IS NULL OR @PartNumber = '')OR (I.PART_NO =  @PartNumber AND (PART_SOURC ='BUY' OR (PART_SOURC = 'MAKE' AND MAKE_BUY = 1))
		  AND (REVISION = ISNULL(@Rev,REVISION ) OR @Rev='')))
	      AND (@SupplierName IS NULL OR @SupplierName = '' OR CH.uniqsupno = @SupplierUniqKey)
		  AND (@SupplierUniq IS NULL OR @SupplierName = '' OR CH.uniqsupno = @SupplierUniqKey)
		  AND (@ContractNumber ='' OR CH.Contr_no = ISNULL(@ContractNumber,CH.Contr_no ))
		  -- 07/30/2018 Rajendra K : Change condition for ExpDate condition (Get only active records if @ExpiredContract is false)
		  -- AND (@ExpiredContract = 0 OR CH.expireDate < ISNULL(@TodayDate,GETDATE()))
		  AND ((@ExpiredContract = 0 AND (CH.expireDate IS NULL OR (CAST(CH.expireDate AS DATE) >= @TodayDate)))
		  OR ( @ExpiredContract = 1  AND CAST(CH.expireDate AS DATE) < @TodayDate))
		  AND (CH.AutoGenerated = @IsAutoGenerated)
		  AND (@ContractHeaderKey IS NULL OR @ContractHeaderKey ='' OR CH.ContractH_unique = @ContractHeaderKey )
   --ORDER BY I.PART_NO + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END)-- 07/27/2018 Rajendra K : Replaced ContractH_unique by PartNumber/Revision in Order by clause  
   --OFFSET (@StartRecord-1) ROWS  
   --FETCH NEXT @EndRecord ROWS ONLY;    -- 01/23/2020 Rajendra K : Removed the "order by" and added fn_GetDataBySortAndFilters function to get data with sort functionality
    SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #contractData','',@sortExpression,N'PART_NO','',@StartRecord,@endRecord))  
	EXEC sp_executesql @sqlQuery

   SET @Out_TotalNumberOfRecord = (SELECT COUNT(1) FROM #tempContract)
END