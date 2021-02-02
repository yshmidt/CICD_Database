-- =============================================  
-- Author:  Shivshankar P  
-- Create date: 19/02/2020 
-- Description: Get information according to find for "PO Change Actions" screen of the MRP module  
-- 03/18/2020 Shivshankar P : Change buyer parameter char to UNIQUEIDENTIFIER  
-- 12/08/2020 Shivshankar P : Get DISTINCT UNIQ_KEY INTO #tBOM table
-- 12/14/2020 Shivshankar P : Change buyer parameter char to varchar  
-- ============================================= 
CREATE PROCEDURE GetMrpPOFullActionView --@isScheduler=0 ,@isTakeAll=1,@startRecord=100,@isQtyChange = 1,@isReschedl = 1,@isCancel = 1,@mrpAction = 'All PO Actions'
   -- Add the parameters for the stored procedure here  
 @partNumber char(35)=' ',   
 @buyer UNIQUEIDENTIFIER = NULL, --char(3)=' ',  -- 03/18/2020 Shivshankar P : Change buyer parameter char to UNIQUEIDENTIFIER
 @partStatus varchar(10)='All',  
 @mrpAction varchar(50)='All Actions',     
 @projectUnique char(10)=' ',  
 @custNumber varchar(50)=' ',  
 @soNumber varchar(50)=' ',    
 @isTakeAct bit=0,  
 @lastActionDate smalldatetime=NULL,  
 @lcBomParentPart char(35)=' ',  
 @lcBomPArentRev char(8)=' ' ,  
 @showForecast AS bit = 0,  
 @isQtyChange AS bit = 0,  
 @isReschedl AS bit=0,  
 @isScheduler AS bit=0,  
 @isCancel AS bit  =0,  
 @startRecord int=0,  
 @endRecord int=10,  
 @isTakeAll bit=0,    
 @startDate smalldatetime=NULL,  
 @endDate smalldatetime=NULL,  
 @ref varchar(50) ='',  -- 12/14/2020 Shivshankar P : Change buyer parameter char to varchar 
 @isRelease AS BIT=0,  
 @isQtyDecrs AS BIT = 0,
 @sortExpression VARCHAR(MAX) = ''  
  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets FROM  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON; 
  
  DECLARE @sqlQuery NVARCHAR(MAX),@rowCount NVARCHAR(MAX)

    -- Insert statements for procedure here  
  IF @lastActionDate is null  -- get default  
   SELECT @lastActionDate=cast (mpssys.viewdays + getdate() AS date) FROM mpssys  
    
  
 IF(@isTakeAll =1)  
    SELECT @endRecord=COUNT(UNIQMRPACT) FROM MrpAct  
  
 DECLARE @lcUniq_key AS char(10)=' ',@lnResult int=0  ,@isSoWoCustFilter BIT = 0  
 DECLARE @lcSql nvarchar(max)  
  
 SET @startDate = CASE WHEN @startDate IS NULL OR @startDate ='' THEN '' ELSE @startDate END  
 SET @endDate = CASE WHEN @endDate IS NULL OR @endDate ='' THEN '' ELSE @endDate END  
 IF (@lcBomParentPart <>' ')  
 BEGIN  
  SELECT @lcUniq_key=Uniq_key FROM INVENTOR   
   where PART_NO=@lcBomParentPart   
  AND REVISION=@lcBomPArentRev   
  AND (PART_SOURC='MAKE' OR PART_SOURC='PHANTOM')  
  SET @lnResult=@@ROWCOUNT  
   
 END    

IF OBJECT_ID('tempdb..#tSOlist') IS NOT NULL
DROP TABLE #tSOlist

IF OBJECT_ID('tempdb..#tCustomer') IS NOT NULL
DROP TABLE #tCustomer

IF OBJECT_ID('tempdb..#tBOM') IS NOT NULL
DROP TABLE #tBOM

IF OBJECT_ID('tempdb..#tWolist') IS NOT NULL
DROP TABLE #tWolist
    
	-- 12/08/2020 Shivshankar P : Get DISTINCT UNIQ_KEY INTO #tBOM table
	SELECT DISTINCT i.UNIQ_KEY INTO #tBOM FROM MRPACT m JOIN BOM_DET det ON m.UNIQ_KEY=det.UNIQ_KEY
	JOIN INVENTOR i ON i.uniq_key=det.UNIQ_KEY
	WHERE BOMPARENT=@lcUniq_key	
	
	SELECT  i.UNIQ_KEY 
	INTO #tCustomer 
	FROM MRPACT m 
	JOIN BOM_DET det ON m.UNIQ_KEY=det.UNIQ_KEY
	JOIN INVENTOR i ON i.uniq_key=det.UNIQ_KEY
	JOIN WOENTRY wo ON wo.UNIQ_KEY=det.BOMPARENT
	JOIN CUSTOMER c ON c.CUSTNO=wo.CUSTNO
	WHERE c.CUSTNO like @custNumber
	
	SELECT  i.UNIQ_KEY INTO #tSOlist FROM MRPACT m
	JOIN INVENTOR i ON i.uniq_key=m.UNIQ_KEY
	JOIN sodetail so ON so.UNIQ_KEY=m.UNIQ_KEY
	WHERE so.SONO LIKE dbo.padl(@soNumber,10,'0')
	
	SELECT  i.UNIQ_KEY INTO #tWolist FROM MRPACT m JOIN BOM_DET det ON m.UNIQ_KEY=det.UNIQ_KEY
	JOIN INVENTOR i ON i.uniq_key=det.UNIQ_KEY
	JOIN WOENTRY wo ON wo.UNIQ_KEY=det.BOMPARENT
	WHERE wo.WONO LIKE dbo.padl(@ref,10,'0')
 
    SELECT DISTINCT A.Uniq_key, Part_Class, Part_Type, Part_no, Revision, CustPartNo, CustRev,Descript,
      PART_CLASS + '/' + PART_TYPE + '/'+ Descript AS Descript_view,  
	  Part_Sourc ,BUYER_TYPE, totalCount = COUNT(A.Uniq_key) OVER() 
      ,A.action,0  AS IsChecked , PoBuyer.UserName AS Buyer ,A.dttAkeact,M.PART_NO + '/' +  M.REVISION  AS PartNoRevision  
      ,A.ref,A.wono,A.balance,A.reqqty,A.due_date  AS DueDate, A.due_date,A.reqdate,A.days,A.Uniq_key AS UniqKey,  
      A.ActionStatus ,A.dttAkeact AS DtToTakeAction,A.dttAkeact AS DateToTakeAct,  
     CASE WHEN woentr.wocnt > 0 AND  (A.action  = '- Qty RESCH WO ' OR A.action  = '- Qty WO ') THEN  1 ELSE 0  END AS wocnt,  
      SERIALYES,A.UniqMRPAct,   
      CASE WHEN A.REF LIKE '%Dem SO%' THEN SO.CUSTNAME  
        WHEN A.REF LIKE '%Kit Shortag%' THEN WOCustom.CUSTNAME  
		WHEN A.REF LIKE '%Dem WO%' THEN WOCust.CUSTNAME
        WHEN A.REF LIKE '%Safety Stock%' THEN (select CUSTNAME from CUSTOMER where CUSTNO='000000000~')  
		ELSE CASE WHEN WONOCust.CUSTNAME IS NOT NULL THEN WONOCust.CUSTNAME ELSE '' END
        END AS CustName    
		,A.ActionNotes 
		INTO #temp
       FROM MrpAct A INNER JOIN inventor M ON A.uniq_key=M.Uniq_key  
          OUTER APPLY (SELECT UserName FROM aspnet_Users LEFT JOIN POMAIN ON aspnet_Users.UserId = POMAIN.aspnetBuyer  
                       WHERE  POMAIN.PONUM=replace(A.REF,'PO ','')) PoBuyer  
          OUTER APPLY (SELECT COUNT(WOENTRY.WONO) AS wocnt FROM WOENTRY JOIN dept_qty ON  dept_qty.WONO =  WOENTRY.WONO  
              WHERE  WOENTRY.WONO =  A.WONO AND NUMBER <> 1 AND CURR_QTY > 0) woentr  
  
			OUTER APPLY (SELECT top 1 CUSTNAME FROM SOMAIN
						LEFT JOIN SODETAIL ON SOMAIN.SONO=SODETAIL.SONO AND SODETAIL.UNIQ_KEY= A.UNIQ_KEY  
						LEFT JOIN CUSTOMER ON CUSTOMER.CUSTNO = SOMAIN.CUSTNO  
						WHERE SOMAIN.SONO =RTRIM(LTRIM(replace(A.REF,'Dem SO','')))) SO  
                                              
			OUTER APPLY (SELECT top 1 CUSTNAME FROM MRPACT 
                         JOIN WOENTRY ON WOENTRY.WONO = RTRIM(LTRIM(replace(replace(A.REF,'WO',''),' Kit Shortag','' )))  
                         JOIN CUSTOMER ON CUSTOMER.CUSTNO = WOENTRY.CUSTNO  
                        ) WOCustom 
						 
			OUTER APPLY (SELECT top 1 CUSTNAME FROM MRPACT 
						      JOIN WOENTRY ON WOENTRY.WONO = RTRIM(LTRIM(replace(A.REF,'Dem WO','')))
							  JOIN CUSTOMER ON CUSTOMER.CUSTNO = WOENTRY.CUSTNO
						) WOCust

			OUTER APPLY (SELECT top 1 CUSTNAME FROM MRPACT 
						      JOIN WOENTRY ON WOENTRY.WONO = RTRIM(LTRIM(replace(A.REF,'WO','')))
							  JOIN CUSTOMER ON CUSTOMER.CUSTNO = WOENTRY.CUSTNO
						) WONOCust
		
			OUTER APPLY (SELECT COUNT(WONO) AS wcCount ,WONO  FROM DEPT_QTY WHERE WONO = A.WONO and CURR_QTY > 0 
						AND DEPT_ID NOT IN ('FGI','SCRP')  
						GROUP BY WONO HAVING COUNT(wono) > 1) tDeptQTY 

			OUTER APPLY (SELECT COUNT(DEPT_ID) AS wcDCount  FROM DEPT_QTY WHERE WONO = A.WONO and CURR_QTY > 0 
							    GROUP BY WONO ) tNegDeptQTY 

			OUTER APPLY(SELECT UserName FROM aspnet_Users WHERE UserId = @buyer) Buyer					
        WHERE M.PART_SOURC<>'CONSG'  
        AND (((@mrpAction  ='All WO Actions' OR @mrpAction  ='All PO Actions')   
			      AND ((@isCancel = 1 and ACTION like ('%Cancel%')) 
					  OR (@isQtyChange = 1 and (ACTION like ('%+ Qty%') OR ACTION like ('%+ Qty%'))) 
					  OR (@isQtyChange = 1 and (ACTION like ('%- Qty%') OR ACTION like ('%- Qty%'))) AND tNegDeptQTY.wcDCount = 1
					 OR (@isReschedl = 1 and (ACTION like ('%RESCH%') OR ACTION like ('%RESCH%')))
					 OR (@isRelease = 1 and (ACTION like ('%Rel%') OR ACTION like ('%Rel%')))
					 OR (@isQtyDecrs = 1 and (ACTION like ('%- Qty%') OR ACTION like ('%- Qty%')) AND (M.SERIALYES=1 OR tDeptQTY.WONO = A.WONO))))   
					 OR (@mrpAction  ='Release PO'AND A.ACTION  = 'Release PO'))   
					 AND ((@mrpAction  ='All WO Actions'AND A.ACTION  like '%WO%') -- WO Action  
					 OR (@mrpAction  ='All PO Actions'AND A.ACTION  like '%PO%') -- PO Change Action  
					 OR (@mrpAction  ='Release PO'AND A.ACTION  = 'Release PO'))     
          
  AND (DATEDIFF(Day,A.DTTAKEACT,@lastActionDate)>=0 OR A.DTTAKEACT IS NULL)   
  AND (( @startDate <> '' AND @endDate <> '' AND A.DTTAKEACT >= @startDate AND A.DTTAKEACT < DATEADD(DAY,1,CAST(@endDate AS DATE))) OR   
  (@startDate ='' AND @endDate ='' AND A.DTTAKEACT=A.DTTAKEACT))  
  
  AND ((@isTakeAct =0 AND A.ActionStatus IS NULL OR A.ActionStatus = ' ')   
  OR (@isTakeAct =1 AND A.ActionStatus  = 'Success' OR A.ActionStatus = 'Failed'))  
	AND ((ISNULL(Buyer.UserName,'') <> '' AND PoBuyer.UserName = Buyer.UserName) OR (ISNULL(Buyer.UserName,'') = '' AND 1=1)) 
	AND ((ISNULL(@custNumber,'') = '' AND 1=1) OR (ISNULL(@custNumber,'') <> '' AND EXISTS (SELECT UNIQ_KEY FROM #tCustomer t WHERE t.UNIQ_KEY = A.UNIQ_KEY)))
	AND ((ISNULL(@lcUniq_key,'') = '' AND 1=1) OR (ISNULL(@lcUniq_key,'') <> '' AND A.UNIQ_KEY IN (SELECT UNIQ_KEY FROM #tBOM WHERE UNIQ_KEY = A.UNIQ_KEY)))
	AND ((ISNULL(@ref,'') = '' AND 1=1) OR (ISNULL(@ref,'') <> '' AND EXISTS (SELECT UNIQ_KEY FROM #tWolist WHERE UNIQ_KEY = A.UNIQ_KEY)))
    AND ((ISNULL(@soNumber,'') = '' AND 1=1) OR (ISNULL(@soNumber,'') <> '' AND EXISTS (SELECT UNIQ_KEY FROM #tSOlist  WHERE UNIQ_KEY = A.UNIQ_KEY)))
  ORDER BY A.DTTAKEACT,A.REF 

		SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #temp','',@sortExpression,'','Part_no',@startRecord,@endRecord))           
		EXEC sp_executesql @rowCount        
 
		SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #temp','',@sortExpression,N'Part_no','',@startRecord,@endRecord))      
		EXEC sp_executesql @sqlQuery 
 
END  
  
  
  