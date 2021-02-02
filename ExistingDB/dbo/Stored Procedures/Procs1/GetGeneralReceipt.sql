-- ==================================================================================================
-- Author:		Nilesh S
-- Create date: <02/26/2018>
-- Description:	 Used to General receiving to get receipt
-- exec [dbo].[GetGeneralReceipt] '','NEW PL','','','',null,null,'','',1,250,'',''
-- exec [dbo].[GetGeneralReceipt] '','','','',1,'','','','G',1,20,'',''  
-- exec [dbo].[GetGeneralReceipt] '','','','',1,'3/18/2018 8:33:56 PM','3/25/2019 8:33:56 PM','','','S',1,20,'',''
-- Nilesh Sa : 03/07/2018  Addded default sort by ReceiverNo desc
-- Nilesh Sa : 03/21/2018  Addded Parameter For date range search
-- Nilesh Sa : 03/21/2018  Addded Code For date range search
-- Nilesh Sa 4/11/2018  Added new columns in selections as per review changes
-- Nilesh Sa 4/11/2018 Removed columns from grid and comments not allowed in quer string
-- Nilesh Sa : 04/13/2018  Addded Parameter for lot code  and sid search
-- Nilesh Sa 4/13/2018 Modified  SP with lot code  and sid search
-- Nilesh Sa 4/26/2018 Modified  SP with join condition changed for ipkeyuniq search
-- Nilesh Sa 4/26/2018 Modified SP remove lot code and sid search join and keep outside string 
-- Nilesh Sa : 05/15/2018  Addded Code For sid and lot code search
-- Nilesh Sa : 05/30/2018  Addded RTRIM and LTRIM for search
-- Nitesh B : 3/26/2019 Added @inspectionSource for search 
-- 06/25/2019 Nitesh B : Change the user Initials to UserName
-- ==================================================================================================
CREATE PROCEDURE [dbo].[GetGeneralReceipt] 
	@reason NVARCHAR(MAX)  =' ',
	@reckPklNo nvarchar(50) =  ' ' ,
	@mfgrPtNo CHAR (30) =' ',
	@uniqKey CHAR(10) =' ',
	@isIsnpection bit = 0,
	-- Nilesh Sa : 03/21/2018  Addded Parameter for date range search
	@startDate smalldatetime = null,
	@endDate smalldatetime = null,
		-- Nilesh Sa : 04/13/2018  Addded Parameter for lot code  and sid search
	@lotCode nvarchar(25) = '',
	@sid char(10) = '',
  @inspectionSource char(2)='',  
	@startRecord INT = 1 ,
    @endRecord INT = 50, 
    @sortExpression nvarchar(1000) = NULL,
    @filter nvarchar(1000) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SQLQuery NVARCHAR(MAX);
	DECLARE @dateQuery NVARCHAR(MAX),
	-- Nilesh Sa : 05/15/2018  Addded Code For sid and lot code search
	@lotQuery NVARCHAR(MAX),@sidQuery NVARCHAR(MAX); 

	-- Nilesh Sa : 03/21/2018  Addded Code For date range search
	IF @startDate IS NOT NULL AND @endDate IS NOT NULL
		SET @dateQuery=' AND CAST(receiverHeader.dockDate AS DATE) BETWEEN ''' +  CONVERT(VARCHAR(10),CAST(@startDate AS DATE) , 101) + ''' AND ''' +  CONVERT(VARCHAR(10),CAST(@endDate AS DATE), 101) + ''''
	ELSE IF @startDate IS NOT NULL
		SET @dateQuery=' AND CAST(receiverHeader.dockDate AS DATE) >= ''' +  CONVERT(VARCHAR(10),CAST(@startDate AS DATE), 101) + ''''
	ELSE IF @endDate IS NOT NULL
		SET @dateQuery=' AND CAST(receiverHeader.dockDate AS DATE) <= ''' +  CONVERT(VARCHAR(10),CAST(@endDate AS DATE), 101) + ''''

    -- Nilesh Sa : 05/15/2018  Addded Code For sid and lot code search
	-- Nilesh Sa : 05/30/2018  Addded RTRIM and LTRIM for search
    IF @lotCode IS NOT NULL AND @lotCode <> ''
	  SET  @lotQuery = ' AND INVT_REC.LOTCODE like ''%' + RTRIM(LTRIM(CONVERT(NVARCHAR(25),RTRIM(LTRIM(@lotCode)), 101))) + '%'''

	IF @sid IS NOT NULL AND @sid <> ''
	  SET  @sidQuery = ' AND iRecIpKey.ipkeyunique like ''%' + RTRIM(LTRIM(CONVERT(CHAR(10),RTRIM(LTRIM(@sid)), 101))) + '%'''

	IF(@sortExpression = NULL OR @sortExpression = '')
	BEGIN
		SET @sortExpression = 'ReceiverNo desc' --  Nilesh Sa : 03/07/2018  Addded default sort by ReceiverNo desc
	END

	BEGIN
	-- Nilesh Sa 4/11/2018 Added new columns in selections as per review changes
	-- Nilesh Sa 4/11/2018 Removed columns from grid and comments not allowed in queru string
	-- Nilesh Sa 4/13/2018 Modified  SP with lot code  and sid search
	-- Nilesh Sa : 05/30/2018  Addded RTRIM and LTRIM for search
    -- Nitesh B : 3/26/2019 Added @inspectionSource for search 
    -- 06/25/2019 Nitesh B : Change the user Initials to UserName
		 SET @SQLQuery = 'SELECT DISTINCT reason AS Reason,recPklNo AS RecPklNo
				,receiverno AS ReceiverNo,receiverDetail.Uniq_key
				,AspnetProfile.UserName AS ReceivedBy
    ,RTRIM(INVENTOR.PART_NO) + (CASE WHEN INVENTOR.REVISION IS NULL OR INVENTOR.REVISION = '''' THEN INVENTOR.REVISION ELSE ''/''+ INVENTOR.REVISION END) AS PartRev  
				,INVENTOR.DESCRIPT AS Description 
				,receiverDetail.Qty_rec AS QtyRec
				,receiverDetail.Partmfgr AS PartMfgr
				,receiverDetail.mfgr_pt_no AS MfgrPartNo
        ,receiverHeader.DockDate AS ReceiveDate
      	,receiverHeader.inspectionSource  
				FROM receiverHeader
				JOIN receiverDetail ON receiverDetail.receiverHdrId =  receiverHeader.receiverHdrId
				LEFT OUTER JOIN INVT_REC ON receiverDetail.receiverDetId = INVT_REC.receiverdetId 
				LEFT OUTER JOIN iRecIpKey ON INVT_REC.INVTREC_NO = iRecIpKey.invtrec_no 
				JOIN aspnet_Profile ON receiverHeader.recvBy = aspnet_Profile.UserId
				JOIN INVENTOR ON receiverDetail.Uniq_key = INVENTOR.UNIQ_KEY
				OUTER APPLY(
					SELECT UserName
					 FROM aspnet_Users WHERE UserId =receiverHeader.recvBy
				) AS AspnetProfile
        WHERE inspectionSource =''' + RTRIM(LTRIM(CONVERT(VARCHAR(02),@inspectionSource, 101))) + '''  
					AND  ((''' + CONVERT(VARCHAR(10),@isIsnpection, 101) + '''= 1 AND receiverDetail.isinspCompleted = 1 and receiverDetail.isCompleted = 0) 
					OR  (''' + CONVERT(VARCHAR(10),@isIsnpection, 101) + '''= 0 AND receiverDetail.isinspCompleted = receiverDetail.isinspCompleted))
					
					AND ((''' + CONVERT(VARCHAR(50),@reckPklNo, 101) + '''='''' AND receiverHeader.recPklNo = receiverHeader.recPklNo) 
					OR (''' + CONVERT(VARCHAR(50),@reckPklNo, 101) + ''' <> '''' AND receiverHeader.recPklNo = ''' + RTRIM(LTRIM(CONVERT(VARCHAR(50),@reckPklNo, 101))) + '''))

					AND ((''' + CONVERT(VARCHAR(10),@uniqKey, 101) + '''='''' AND receiverDetail.Uniq_key = receiverDetail.Uniq_key) 
					OR (''' + CONVERT(VARCHAR(10),@uniqKey, 101) + ''' <> '''' AND receiverDetail.Uniq_key= ''' + RTRIM(LTRIM(CONVERT(VARCHAR(10),@uniqKey, 101))) + '''))

                    AND ((''' + CONVERT(VARCHAR(30),@mfgrPtNo, 101) + '''='''' AND mfgr_pt_no = mfgr_pt_no) 
					OR (''' + CONVERT(VARCHAR(30),@mfgrPtNo, 101) + ''' <> '''' AND mfgr_pt_no = ''' + RTRIM(LTRIM(CONVERT(VARCHAR(30),@mfgrPtNo, 101))) + '''))
					
					AND ((''' + CONVERT(VARCHAR(120),@reason, 101) + '''='''' AND reason = reason) 
					OR (''' + CONVERT(VARCHAR(120),@reason, 101) + ''' <> '''' AND receiverHeader.reason = ''' + RTRIM(LTRIM(CONVERT(VARCHAR(120),@reason, 101))) + '''))'


					-- Nilesh Sa : 05/15/2018  Addded Code For sid and lot code search
					IF @lotCode IS NOT NULL AND @lotCode <> ''
						SET @SQLQuery = @SQLQuery + @lotQuery

					IF @sid IS NOT NULL AND @sid <> ''
						SET @SQLQuery = @SQLQuery + @sidQuery

					-- Nilesh Sa 4/26/2018 Modified SP remove lot code and sid search join and keep outside string 
					--AND ((''' + CONVERT(NVARCHAR(25),@lotCode, 101) + '''='' '' AND INVT_REC.LOTCODE = INVT_REC.LOTCODE) 
					--OR (''' + CONVERT(NVARCHAR(25),@lotCode, 101) + ''' <> '' '' AND INVT_REC.LOTCODE like ''%' + CONVERT(NVARCHAR(25),RTRIM(LTRIM(@lotCode)), 101) + '%''))
					
					--AND ((''' + CONVERT(CHAR(10),@sid, 101) + '''='' '' AND INVT_REC.invtrec_no = iRecIpKey.invtrec_no) 
					--OR (''' + CONVERT(CHAR(10),@sid, 101) + ''' <> '' '' AND iRecIpKey.ipkeyunique like ''%' + CONVERT(CHAR(10),RTRIM(LTRIM(@sid)), 101) + '%'')

					-- Nilesh Sa 4/26/2018 Modified  SP with join condition changed for ipkeyuniq search
					-- Nilesh Sa : 03/21/2018  Addded Code For date range search
					IF @startDate IS NOT NULL OR @endDate IS NOT NULL
						SET @SQLQuery = @SQLQuery + @dateQuery
	END

	DECLARE @rowCount NVARCHAR(MAX) = (SELECT dbo.fn_GetDataBySortAndFilters(@SQLQuery,@filter,@sortExpression,'','ReceiverNo',@startRecord,@endRecord))
    EXEC SP_EXECUTESQL @rowCount


	SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters(@SQLQuery,@filter,@sortExpression,'ReceiverNo','',@startRecord,@endRecord))
	EXEC SP_EXECUTESQL @sqlQuery
END