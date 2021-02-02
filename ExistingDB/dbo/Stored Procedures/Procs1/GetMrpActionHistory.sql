-- =============================================  
-- Author:  Shivshankar P  
-- Create date: 12/13/2017  
-- Description: Get inFORmation according to find screen of the MRP module  
-- Shivshankar P : 12/30/17 - Remove Columns from 'MRPACT' Table (ActionStatus,ActDate) and added Email Temaplate  
-- Shivshankar P : 12/30/17 - Changed Sql data Type to Capital  
-- Shivshankar P : 07/03/18 - Changes made for formate  
-- Nitesh B : 7/11/19 - Change User Initials to UserName 
-- Shivshankar P : 05/07/20 - Change buyer parameter char to UNIQUEIDENTIFIER 
-- Shivshankar P : 06/02/20 - OUTER APPLY Join get supplier name to show in History grid 
-- Shivshankar P 06/08/20: Apply sorting on PO New Actions History grid
-- Shivshnakar P 06/10/20: Apply Default sorting by latest action date first 
-- Shivshnakar P 06/29/20: Modify Sp to Compose Email Detail when PO number change after approve
-- =============================================  
CREATE PROCEDURE [dbo].[GetMrpActionHistory]     
   -- Add the parameters FOR the stored procedure here
	@partNumber VARCHAR(MAX)=' ', 
	@buyer UNIQUEIDENTIFIER = NULL, --char(3)=' ', -- Shivshankar P : 05/07/20 - Change buyer parameter char to UNIQUEIDENTIFIER 
	@partStatus VARCHAR(10)='All',
	@mrpAction VARCHAR(50)='All Actions',   
	@projectUnique CHAR(10)=' ',
	@custNumber CHAR(10)=' ',
	@soNumber CHAR(10)=' ',  
	@isTakeAct BIT=0,
	@lastActionDate SMALLDATETIME=NULL,
	@lcBomParentPart CHAR(35)=' ',
	@lcBomPArentRev CHAR(8)=' ' ,
    @showForecast AS BIT = 0,
	@isQtyChange AS BIT = 0,
	@isReschedl AS BIT=0,
	@isScheduler AS BIT=0,
	@isCancel AS BIT  =0,
	@startRecord INT=1,
	@endRecord INT=10,  
	@startDate SMALLDATETIME=NULL,
	@endDate SMALLDATETIME=NULL,
	@isRelease AS BIT = 1,
	@isQtyDecrs AS BIT  =0,
	@sortExpression VARCHAR(MAX) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets FROM
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @sqlQuery NVARCHAR(MAX),@rowCount NVARCHAR(MAX)  
	-- Insert statements FOR procedure here
	IF @lastActionDate is null  -- get default
	SELECT @lastActionDate=cast (mpssys.viewdays + getdate() AS DATE) FROM mpssys
 	-- Shivshnakar P 06/10/20: Apply Default sorting by latest action date first 
	IF(@sortExpression = NULL OR @sortExpression = '')
	BEGIN
		SET @sortExpression = 'ActDate desc'
	END

	DECLARE @lcUniq_key AS CHAR(10)=' ',@lnResult INT=0
	DECLARE @lcSql NVARCHAR(max)
	
	IF (@lcBomParentPart <>' ')
	BEGIN
		SELECT @lcUniq_key=Uniq_key FROM INVENTOR 
		WHERE PART_NO=@lcBomParentPart 
			AND REVISION=@lcBomPArentRev 
			AND (PART_SOURC='MAKE' OR PART_SOURC='PHANTOM')
		SET @lnResult=@@ROWCOUNT
	
	END 

	IF (@lnResult=0 AND @lcBomParentPart =' ' AND  @isScheduler=0)  -- NO BOM parent
	BEGIN	
		SELECT DISTINCT A.Uniq_key, Part_Class,Part_Type,Part_no,Revision,CustPartNo,CustRev,Descript
			,PART_CLASS + '/' + PART_TYPE + '/'+ Descript AS Descript_view
			,Part_Sourc ,BUYER_TYPE, totalCount = COUNT(A.Uniq_key) OVER() 
			,A.action,0  AS IsChecked , PoBuyer.UserName AS Buyer ,A.dttAkeact,M.PART_NO + '/' +  M.REVISION  AS PartNoRevision
			,A.ref,A.wono,A.balance,A.reqqty, A.duedate,A.reqdate,A.days,A.Uniq_key AS UniqKey
			,A.ActDate,A.dttAkeact AS DtToTakeAction,A.dttAkeact AS DateToTakeAct,aspnet_Users.UserName AS Initials
			,ActionStatus,CASE WHEN EmailStatus = 1 THEN 'YES' ELSE 'NO' END AS EmailStatus
			,A.MRPActUniqKey,ISNULL(sup.SUPNAME,'') AS supplier -- Shivshankar P : 06/02/20 - OUTER APPLY Join get supplier name to show in History grid 
		INTO #MRPHistoryData  
		FROM MRPACTLog A 
		INNER JOIN inventor M ON A.uniq_key=M.Uniq_key
		LEFT JOIN aspnet_Users ON A.ActUserId=aspnet_Users.UserId
		OUTER APPLY (
			SELECT UserName FROM aspnet_Users 
			LEFT JOIN POMAIN ON UserId = POMAIN.aspnetBuyer
			WHERE  POMAIN.PONUM = REPLACE(A.REF,'PO ','') OR POMAIN.PONUM = REPLACE(A.REF,'PO T','0')
		) PoBuyer
		-- Shivshnakar P 06/29/20: Modify Sp to Compose Email Detail when PO number change after approve
	    OUTER APPLY ( -- Shivshankar P : 06/02/20 - OUTER APPLY Join get supplier name to show in History grid 
			SELECT SUPNAME FROM POMAIN 
			JOIN SUPINFO on POMAIN.UNIQSUPNO = SUPINFO.UNIQSUPNO 
			WHERE POMAIN.PONUM = REPLACE(A.REF,'PO ','') OR POMAIN.PONUM = REPLACE(A.REF,'PO T','0')
		) sup
		WHERE M.PART_SOURC<>'CONSG' AND M.CUSTNO= CASE WHEN  @custNumber <> ' ' OR @custNumber IS NOT NULL THEN @custNumber ELSE M.CUSTNO END
			AND (((@mrpAction  ='All WO Actions' OR @mrpAction  ='All PO Actions') 
			      AND ((@isCancel = 1 and ACTION like ('%Cancel%')) 
					 OR (@isQtyChange = 1 and (ACTION like ('%Qty%') OR ACTION like ('%Qty%'))) 
					 OR (@isReschedl = 1 and (ACTION like ('%RESCH%') OR ACTION like ('%RESCH%')))
					 OR (@isRelease = 1 and (ACTION like ('%Rel%') OR ACTION like ('%Rel%')))
					-- OR (@showForecast = 1 and a.is_forecast=@showForecast)
				 )) OR (@mrpAction  ='Release PO'AND A.ACTION  = 'Release PO'))
			AND ((@mrpAction  ='All WO Actions'AND A.ACTION  like '%WO%') -- WO Action
					OR (@mrpAction  ='All PO Actions'AND A.ACTION  like '%PO%') -- PO Change Action
					OR (@mrpAction  ='Release PO'AND A.ACTION  = 'Release PO')
				)   
				--AND (DATEDIFF(Day,A.DTTAKEACT,@lastActionDate)>=0 OR A.DTTAKEACT IS NULL) 
				--AND ((@startDate IS NOT NULL AND @endDate IS NOT NULL AND A.ActDate >= @startDate AND A.ActDate < @endDate + 1) 
				--OR  (@startDate IS NULL AND @endDate IS NULL  AND A.ActDate=A.ActDate))
		ORDER BY PoBuyer.UserName,A.dttAkeact,A.ACTION,A.REF,supplier 
			-- OFFSET (@startRecord -1) ROWS  
		    -- FETCH NEXT @endRecord ROWS ONLY;  

		-- Shivshankar P 06/08/20: Apply sorting on PO New Actions History grid 
		-- Shivshnakar P 06/10/20: Apply Default sorting by latest action date first 
		SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #MRPHistoryData','',@sortExpression,'','MRPActUniqKey',@startRecord,@endRecord))         
		   EXEC sp_executesql @rowCount      
  
		SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #MRPHistoryData','',@sortExpression,N'MRPActUniqKey','',@startRecord,@endRecord))    
		   EXEC sp_executesql @sqlQuery  

	END    
        -- Shivshankar P :  12/30/17 -Remove Columns from 'MRPACT' Table (ActionStatus,ActDate) and added Email Temaplate Changed Sql data Type to Capital
		-- Shivshnakar P 06/29/20: Modify Sp to Compose Email Detail when PO number change after approve
		ELSE IF(@isScheduler=1) 
		BEGIN
	 		DECLARE  @companyName NVARCHAR(max)
			SELECT @companyName=LIC_NAME FROM MICSSYS
			IF OBJECT_ID('tempdb..#temp') IS NOT NULL
				DROP TABLE #temp

			SELECT QtyRes = CASE  WHEN t1.ACTION ='+ Qty RESCH PO ' OR  t1.ACTION ='+ PO Qty'  OR t1.ACTION ='- Qty RESCH PO ' OR  t1.ACTION ='- PO Qty' 
							 THEN  '@'+'Order Qty of Part '+ CAST (t1.MFGRS AS VARCHAR(255))  + ' Changed FROM '+ CAST (t1.Balance AS VARCHAR(255))  + ' to ' + CAST (t1.ReqQty AS VARCHAR(255)) + CHAR(10)
							 WHEN t1.ACTION ='Cancel PO' 
							 THEN '@'+'OutStanding balance of the Part Number '+ CAST (t1.MFGRS AS VARCHAR(255))  + ' has been canceled' + CHAR(10)
							 WHEN  t1.ACTION ='RESCH PO' OR t1.ACTION ='+ Qty RESCH PO ' OR  t1.ACTION ='- Qty RESCH PO ' 
							 THEN 'Part Number ' + CAST (t1.MFGRS AS VARCHAR(255))  + ' Delivery Date changed FROM ' + CAST (t1.DueDate AS VARCHAR(255))  + ' to '  + CAST (t1.ReqDate AS VARCHAR(255)) + CHAR(10)
							 WHEN t1.ACTION ='Release PO' 
							 THEN '@'+'New PO is created, PO Number: ' + CAST (POMAIN.ponum AS VARCHAR(50))   + CHAR(10)
							 ELSE '' END ,
				 SUPINFO.SUPNAME,
				 ISNULL(ccontact.firstname +' '+ ccontact.lastname,'To whom it may concerned') AS emailGreet,
				 shipto,
				 CAST(CASE WHEN CCONTACT.EMAIL IS null THEN ISNULL(ShipBill.E_MAIL,'') ELSE ccontact.EMAIL END as varchar(max)) as EMAIL,
				 dbo.fRemoveLeadingZeros(POMAIN.PONUM) AS PONUM,
				 t1.Action,Balance,
				 t1.ReqQty,
				 DueDate,
				 t1.ReqDate,
				 mfgrs,
				 t1.MRPActUniqKey,
				 SUPINFO.UNIQSUPNO,
				 aspnet_Profile.FirstName + ' ' + aspnet_Profile.LastName AS BuyerName,
				 LINKADD
             INTO #temp  
             FROM MRPACTLog t1 
			 JOIN POITEMS ON t1.UNIQ_KEY = POITEMS.UNIQ_KEY AND (POITEMS.PONUM = TRIM(REPLACE(t1.REF,'PO ','')) OR POITEMS.PONUM =  TRIM(REPLACE(t1.REF,'PO T','0')))
			 LEFT JOIN POMAIN ON POITEMS.PONUM = POMAIN.PONUM 
			 LEFT JOIN SUPINFO on POMAIN.UNIQSUPNO = SUPINFO.UNIQSUPNO 
			 LEFT outer join SHIPBILL ON SUPINFO.supid=SHIPBILL.CUSTNO and Pomain.C_LINK =ShipBill.LINKADD and Shipbill.recordtype ='C'
			 LEFT OUTER JOIN CCONTACT on (Shipbill.custno+'S'+RTRIM(Shipbill.attention)) = ( Ccontact.custno+Ccontact.type+Ccontact.cid )
			 LEFT JOIN aspnet_Profile ON aspnet_Profile.UserId = POMAIN.aspnetBuyer 
			 OUTER APPLY (SELECT MRPACTUNIQKEY FROM  MRPACTLOG 
				               OUTER APPLY (SELECT REF FROM  MRPACTLOG T WHERE ACTION ='RELEASE PO' GROUP BY REF) TT 
							                       WHERE ACTION ='RELEASE PO' AND  MRPACTLOG.REF = TT.REF) T 
			 WHERE (((@partNumber IS NOT NULL OR @partNumber !=' ') AND t1.MRPActUniqKey in (select id  from dbo.[fn_simpleVarcharlistToTable](@partNumber,','))) OR
													      ((@partNumber IS  NULL OR @partNumber =' ') AND t1.MRPActUniqKey = t1.MRPActUniqKey))
				 AND ((t1.ACTION ='RELEASE PO' AND  T.MRPACTUNIQKEY = T1.MRPACTUNIQKEY) OR  (t1.ACTION <> 'RELEASE PO' AND 1=1))
			 ORDER BY UNIQSUPNO, PONUM

			
			;WITH MrpTempPOItems AS (
					SELECT t2.emailGreet,t2.shipto,t2.LINKADD, t2.SUPNAME,UNIQSUPNO,t2.EMAIL,t2.PONUM, 
						CASE WHEN t2.Action ='Release PO' THEN CHAR(10)+ '@@'+''+ CHAR(10) ELSE 
								CHAR(10)+ '@@'+' Below is list of updates in PO # '+ t2.PONUM + CHAR(10) END + stuff(
							(
								SELECT  ' ' + t1.QtyRes 
								FROM    #temp t1
								WHERE   t1.PONUM = t2.PONUM
								ORDER BY t1.UNIQSUPNO
								FOR XML PATH('') 
							),1,1,'') Concats ,
							STUFF((SELECT DISTINCT ',' + PONUM
								  FROM   #temp WHERE  #temp.UNIQSUPNO = t2.UNIQSUPNO
								  FOR XML PATH('')),1,1,'') Sub,
							STUFF((SELECT DISTINCT ',' + PONUM
								  FROM   #temp WHERE  #temp.UNIQSUPNO = t2.UNIQSUPNO
								  FOR XML PATH('')),1,1,'') PONums,
							STUFF((SELECT DISTINCT ',' + BuyerName 
								  FROM   #temp WHERE  #temp.UNIQSUPNO = t2.UNIQSUPNO
								  FOR XML PATH('')),1,1,'') BuyerName
							 FROM  #temp t2
								GROUP BY t2.SUPNAME,UNIQSUPNO ,t2.PONUM,t2.EMAIL,t2.Action,t2.emailGreet,t2.shipto,t2.LINKADD

			) , MrpTempSupInfo AS (
					SELECT t2.SUPNAME,t2.shipto,t2.LINKADD,MrpTempPOItems.BuyerName, t2.UNIQSUPNO, 
						   t2.EMAIL, @companyName + ' PO # ' + Sub AS Sub,PONums, + CHAR(10) + --' Hi '+ 
						   RTRIM(t2.emailGreet) + ',' + CHAR(10) 
						   + stuff (
						   (
								SELECT  ' ' + t1.Concats
								FROM    MrpTempPOItems t1
								WHERE   t1.UNIQSUPNO = t2.UNIQSUPNO
								ORDER BY t1.UNIQSUPNO
								FOR XML PATH('') 
						   ),1,1, '')  Body 
					FROM  #temp t2 JOIN MrpTempPOItems on t2.UNIQSUPNO =MrpTempPOItems.UNIQSUPNO
					GROUP BY t2.SUPNAME,t2.UNIQSUPNO,t2.EMAIL,Sub,PONums,MrpTempPOItems.BuyerName,t2.emailGreet,t2.shipto,t2.LINKADD 
			)


            SELECT Shipto
				  ,SUPNAME
			      ,BuyerName
				  ,EMAIL
				  ,Sub
				  ,PONums
				  ,LINKADD UNIQSUPNO
				  ,ROW_NUMBER() OVER(ORDER BY SHIPTO) AS RowNumber
				  ,(SELECT REPLACE( Body+ CHAR(10) +  CHAR(10) + '@@'+' Purchase order attached.'
				    + CHAR(10) +  CHAR(10) + '@@'+  ' Thanks,'  + CHAR(10) + '@'+ BuyerName +'@@'
				    + CHAR(10)  + CHAR(10) + ' This is a system generated  E-Mail, Please do not reply to this mail address.','@','<br>')) AS Body
			FROM  MrpTempSupInfo

		END
END