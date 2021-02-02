-- =============================================  
-- Author:  Shivshankar P  
-- Create date: 25/08/2017  
-- Description: Get information according to find screen of the MRP module  
-- 21/12/17 Shivshankar P : Changed the filters  
-- 12/30/17 Shivshankar P :  -Remove Columns from 'MRPACT' Table (ActionStatus,ActDate)  
-- 01/19/18 Shivshankar P :  -Added Column UniqMRPAct  
-- 07/05/18 Shivshankar P :  -Added filters  
-- 11/01/18 Shivshankar P :  -Get data for Release WO  
-- 07/11/19 Nitesh B : - Change User Initials to UserName  
-- 16/08/19 Shivshankar P :  To show the only - Qty Resch records  
-- 27/08/19 Shivshankar P :  Dont allow to display the WONO in@isQtyDecrs WO grid whose serialyes zero and qty in single wc  
-- 28/01/20 Shivshankar P : Show the only if - qty is available in single WC  
-- 02/04/2020 Shivshankar P : Added ActionNotes column in selection list  
-- 02/11/2020 Shivshankar P : Get customer name for only 'WO' and 'Dem WO'  
-- 02/24/2020 Shivshankar P : Apply sorting on PO/WO Change Action    
-- 03/18/2020 Shivshankar P : Change buyer parameter char to UNIQUEIDENTIFIER  
-- 06/19/2020 Sachin B : Fix the Issue the Negative Work Order Data is Getting Displayed in Main Grid
-- 07/22/2020 Shivshankar P : Added condition tNegDeptQTY.wcDCount = 1 To show the only - Qty Resch records 
-- 09/17/2020 Shivshankar P : Modify SP for the assembly filter not work properly from WO MRP Action screen
-- 11/03/2020 YS missing actions for work order increase/decrease qty, no schedule changes  
-- 11/30/2020 Shivshankar P : Modify Sp for Customer search is not working in the WO MRP actions screen
-- 12/01/2020 Shivshankar P : Modify SP for the Sales Order and work order not work properly from WO MRP Action screen
-- 12/14/2020 Shivshankar P : Change buyer parameter char to varchar  
--[dbo].[GetMrpFullActionView] @lcBomParentPart= '9FGI-66A7718G01',@lcBomPArentRev='002'  
--[dbo].[GetMrpFullActionView] @isScheduler=0 ,@isTakeAll=1,@startRecord=1 ,@mrpAction='All PO Actions'  
-- =============================================  
CREATE PROCEDURE GetMrpFullActionView --@isScheduler=1 ,@isTakeAll=1,@startRecord=0  
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
 @isQtyDecrs AS BIT=0,  
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
  
 DECLARE @lcUniq_key AS char(10)=' ',@lnResult int=0 
 DECLARE @lcSql nvarchar(max)  
  
 SET @startDate = CASE WHEN @startDate IS NULL OR @startDate ='' THEN '' ELSE @startDate END  
 SET @endDate = CASE WHEN @endDate IS NULL OR @endDate ='' THEN '' ELSE @endDate END  
 IF (@lcBomParentPart <>' ')  
 BEGIN  
  SELECT @lcUniq_key=Uniq_key FROM INVENTOR where PART_NO=@lcBomParentPart AND REVISION=@lcBomPArentRev AND (PART_SOURC='MAKE' OR PART_SOURC='PHANTOM')  
  SET @lnResult=@@ROWCOUNT     
 END   

 -- 12/01/2020 Shivshankar P : Modify SP for the Sales Order and work order not work properly from WO MRP Action screen
  IF OBJECT_ID ('tempdb.dbo.#TempBom') IS NOT NULL  
         DROP TABLE #TempBom 	
  IF OBJECT_ID ('tempdb.dbo.#tempCust') IS NOT NULL  
         DROP TABLE #tempCust 
  IF OBJECT_ID ('tempdb.dbo.#tempSO') IS NOT NULL  
         DROP TABLE #tempSO 
  IF OBJECT_ID ('tempdb.dbo.#tempWO') IS NOT NULL  
         DROP TABLE #tempWO 

  -- 09/17/2020 Shivshankar P : Modify SP for the assembly filter not work properly from WO MRP Action screen
 IF (@isScheduler=0)  -- NO BOM parent  
 BEGIN   
   --UniqMRPAct repeared chec---------------------------------------------  
  SELECT DISTINCT A.Uniq_key, Part_Class, Part_Type, Part_no, Revision, CustPartNo, CustRev,Descript,  
      PART_CLASS + '/' + PART_TYPE + '/'+ Descript AS Descript_view,  
      Part_Sourc ,BUYER_TYPE, totalCount = COUNT(A.Uniq_key) OVER()   
      ,A.action,0  AS IsChecked , PoBuyer.UserName AS Buyer ,A.dttAkeact,M.PART_NO + '/' +  M.REVISION  AS PartNoRevision  
      ,A.ref,A.wono,A.balance,A.reqqty,A.due_date  AS DueDate, A.due_date,A.reqdate,A.days,A.Uniq_key AS UniqKey,  
      A.ActionStatus ,A.dttAkeact AS DtToTakeAction,A.dttAkeact AS DateToTakeAct,  
   --11/03/20 YS there is not actions '- Qty WO' only '- WO Qty       '  
      --CASE WHEN woentr.wocnt > 0 AND (A.action  = '- Qty RESCH WO ' OR A.action  = '- Qty WO ') THEN  1 ELSE 0  END AS wocnt,    
      CASE WHEN woentr.wocnt > 0 AND (A.action  = '- Qty RESCH WO ' OR A.action  = '- WO Qty') THEN  1 ELSE 0  END AS wocnt,    
      SERIALYES,A.UniqMRPAct,   
      CASE WHEN A.REF LIKE '%Dem SO%' THEN SO.CUSTNAME  
           WHEN A.REF LIKE '%Kit Shortag%' THEN WOCustom.CUSTNAME  
           WHEN A.REF LIKE '%Dem WO%' THEN WOCust.CUSTNAME  -- 02/11/2020 Shivshankar P : Get customer name for only 'WO' and 'Dem WO'  
           WHEN A.REF LIKE '%Safety Stock%' THEN (select CUSTNAME from CUSTOMER where CUSTNO='000000000~')  
      ELSE CASE WHEN WONOCust.CUSTNAME IS NOT NULL THEN WONOCust.CUSTNAME ELSE '' END END AS CustName    
      ,A.ActionNotes   --02/04/2020 Shivshankar P : Added ActionNotes column in selection list  
       INTO #temp  
       FROM MrpAct A INNER JOIN inventor M ON A.uniq_key=M.Uniq_key  
          OUTER APPLY 
		  ( 
			SELECT UserName FROM aspnet_Users LEFT JOIN POMAIN ON aspnet_Users.UserId = POMAIN.aspnetBuyer WHERE  POMAIN.PONUM=replace(A.REF,'PO ','')
		  ) PoBuyer -- 07/11/19 Nitesh B : - Change User Initials to UserName    
          OUTER APPLY 
		  (
			SELECT COUNT(WOENTRY.WONO) AS wocnt FROM WOENTRY JOIN dept_qty ON  dept_qty.WONO =  WOENTRY.WONO WHERE  WOENTRY.WONO =  A.WONO AND NUMBER <> 1 AND CURR_QTY > 0
		  ) woentr   
          OUTER APPLY 
		  (   
		    SELECT top 1 CUSTNAME FROM SOMAIN  
            LEFT JOIN SODETAIL ON SOMAIN.SONO=SODETAIL.SONO AND SODETAIL.UNIQ_KEY= A.UNIQ_KEY  
            LEFT JOIN CUSTOMER ON CUSTOMER.CUSTNO = SOMAIN.CUSTNO  
            WHERE SOMAIN.SONO = RTRIM(LTRIM(replace(A.REF,'Dem SO','')))
		  ) SO                                            
          OUTER APPLY 
		  (
			SELECT top 1 CUSTNAME FROM MRPACT   
            JOIN WOENTRY ON WOENTRY.WONO = RTRIM(LTRIM(replace(replace(A.REF,'WO',''),' Kit Shortag','' )))  
            JOIN CUSTOMER ON CUSTOMER.CUSTNO = WOENTRY.CUSTNO  
          ) WOCustom  
          -- 02/11/2020 Shivshankar P : Get customer name for only 'WO' and 'Dem WO'  
          OUTER APPLY 
		  (
			SELECT top 1 CUSTNAME FROM MRPACT   
            JOIN WOENTRY ON WOENTRY.WONO = RTRIM(LTRIM(replace(A.REF,'Dem WO','')))  
            JOIN CUSTOMER ON CUSTOMER.CUSTNO = WOENTRY.CUSTNO  
          ) WOCust  
          OUTER APPLY 
		  (
			  SELECT top 1 CUSTNAME FROM MRPACT   
              JOIN WOENTRY ON WOENTRY.WONO = RTRIM(LTRIM(replace(A.REF,'WO','')))  
              JOIN CUSTOMER ON CUSTOMER.CUSTNO = WOENTRY.CUSTNO  
          ) WONOCust  
          OUTER APPLY 
		  (
				SELECT COUNT(WONO) AS wcCount ,WONO  FROM DEPT_QTY WHERE WONO = A.WONO and CURR_QTY > 0   
				AND DEPT_ID NOT IN ('FGI','SCRP')    
				GROUP BY WONO HAVING COUNT(wono) > 1
		  ) tDeptQTY --27/08/19 Shivshankar P :  Dont allow to display the WONO in WO grid whose serialyes zero and qty in single wc  
          OUTER APPLY
		  (
			SELECT COUNT(DEPT_ID) AS wcDCount  FROM DEPT_QTY WHERE WONO = A.WONO and CURR_QTY > 0   
            GROUP BY WONO-- HAVING COUNT(wono) = 1
		  ) tNegDeptQTY --28/01/20 Shivshankar P : Show the only if - qty is available in single WC  
          
        WHERE M.PART_SOURC<>'CONSG' --AND M.CUSTNO= CASE WHEN  @custNumber <> ' ' OR @custNumber IS NOT NULL THEN @custNumber ELSE M.CUSTNO END  
        AND 
		(
			(
				(@mrpAction  ='All WO Actions' OR @mrpAction  ='All PO Actions')   
				 AND 
				 (
     ---11/03/2020 missing actions when qty increased or decreased  
     --      (@isCancel = 1 and ACTION like ('%Cancel%'))     
     --OR (@isQtyChange = 1 and (ACTION like ('%+ Qty%')))     
     --OR (@isQtyChange = 1 and (ACTION like ('%- Qty%'))) AND tNegDeptQTY.wcDCount = 1    
     --OR (@isReschedl = 1 and (ACTION like ('%RESCH%')))    
     --OR (@isRelease = 1 and (ACTION like ('%Rel%')))    
     ---- OR (@isQtyDecrs = 1 and (ACTION like ('%- Qty%') OR ACTION like ('%- Qty%'))) -- 16/08/19 Shivshankar P :  To show the only - Qty Resch records   
     --               -- 07/22/2020 Shivshankar P : Added condition tNegDeptQTY.wcDCount = 1 To show the only - Qty Resch records   
     --   OR (@isQtyDecrs = 1 and (ACTION like ('%- Qty%')) AND (tNegDeptQTY.wcDCount = 1 OR M.SERIALYES=1 OR tDeptQTY.WONO = A.WONO)) --16/08/19 Shivshankar P :  To show the only - Qty Resch records    
     --   -- OR (@showForecast = 1 and a.is_forecast=@showForecast)    
      
				       (@isCancel = 1 and ACTION like ('%Cancel%'))   
      ---11/03/2020 missing actions when qty increased or decreased  
     OR (@isQtyChange = 1 and (ACTION like ('%+%Qty%')))     
     ---11/03/2020 missing some actions like when only qty encreased  
     OR (@isQtyChange = 1 and (ACTION like ('%-%Qty%'))) AND tNegDeptQTY.wcDCount = 1    
					OR (@isReschedl = 1 and (ACTION like ('%RESCH%')))  
					OR (@isRelease = 1 and (ACTION like ('%Rel%')))  
					-- OR (@isQtyDecrs = 1 and (ACTION like ('%- Qty%') OR ACTION like ('%- Qty%'))) -- 16/08/19 Shivshankar P :  To show the only - Qty Resch records 
                    -- 07/22/2020 Shivshankar P : Added condition tNegDeptQTY.wcDCount = 1 To show the only - Qty Resch records 
       ---11/03/2020 missing actions when qty increased or decreased  
       OR (@isQtyDecrs = 1 and (ACTION like ('%-%Qty%')) AND (tNegDeptQTY.wcDCount = 1 OR M.SERIALYES=1 OR tDeptQTY.WONO = A.WONO)) --16/08/19 Shivshankar P :  To show the only - Qty Resch records    
				    -- OR (@showForecast = 1 and a.is_forecast=@showForecast)  
      
				)
			)   
		    OR (@mrpAction  ='Release PO'AND A.ACTION  = 'Release PO')
	    )  
		AND 
		(
				(@mrpAction  ='All WO Actions'AND A.ACTION  like '%WO%') -- WO Action  
			 OR (@mrpAction  ='All PO Actions'AND A.ACTION  like '%PO%') -- PO Change Action  
			 OR (@mrpAction  ='Release PO'AND A.ACTION  = 'Release PO')  
		 )  
	  -- 06/19/2020 Sachin B : Fix the Issue the Negative Work Order Data is Getting Displayed in Main Grid  
	  -- 07/22/2020 Shivshankar P : Added condition tNegDeptQTY.wcDCount = 1 To show the only - Qty Resch records 
        AND 
	    (
    ---11/03/2020 missing actions when qty increased or decreased  
   (@isQtyDecrs = 1 and (ACTION like ('%-%Qty%')) AND (tNegDeptQTY.wcDCount = 1 OR M.SERIALYES=1 OR tDeptQTY.WONO = A.WONO))    
         OR (@isQtyDecrs = 0 and (((ACTION  = '- Qty RESCH WO') AND tNegDeptQTY.wcDCount = 1 ) OR ACTION  <> '- Qty RESCH WO' ))      
	    )      
        AND (DATEDIFF(Day,A.DTTAKEACT,@lastActionDate)>=0 OR A.DTTAKEACT IS NULL)   
        AND 
	    (
			( @startDate <> '' AND @endDate <> '' AND A.DTTAKEACT >= @startDate AND A.DTTAKEACT < DATEADD(DAY,1,CAST(@endDate AS DATE))) OR   
			(@startDate ='' AND @endDate ='' AND A.DTTAKEACT=A.DTTAKEACT)
		)    
		AND 
		(
			(@isTakeAct =0 AND A.ActionStatus IS NULL OR A.ActionStatus = ' ')   
			OR (@isTakeAct =1 AND A.ActionStatus  = 'Success' OR A.ActionStatus = 'Failed')
		)    
		ORDER BY A.DTTAKEACT,A.REF  --PoBuyer.Initials,A.DTTAKEACT,A.ACTION,A.REF      
 
 -- 09/17/2020 Shivshankar P : Modify SP for the assembly filter not work properly from WO MRP Action screen
  IF (@lnResult<>0 AND @lcBomParentPart  <>' ' )  
	  BEGIN  
	  ;with  
	   BOMIndented  
	   as  
	   (  
			SELECT Uniq_key,bomparent,term_dt,eff_dt FROM dbo.fn_getAllUniqKey4BomParent(@lcUniq_key)   
	   ),  
	   Sch  
	   as  
	   (
			SELECT DISTINCT s.Uniq_key,s.ParentPt ,b.term_dt,b.eff_dt,sp.reqdate as due_date  
			FROM mrpsch2 S 
			inner join BOMIndented B on S.UNIQ_KEY=b.Uniq_key and s.PARENTPT=b.bomparent  
			left outer JOIN mrpsch2 SP ON b.bomparent=sp.UNIQ_KEY and right(s.ref,10)=right(sp.ref,10)  
			WHERE ((sp.reqdate is null and (eff_dt is null OR (eff_dt is not null and datediff(day,eff_dt,getdate())>=0))   
			and (term_dt is null or (term_dt is not null and datediff(day,getdate(),term_dt)>0)))  
			or ((eff_dt is null or datediff(day,eff_dt,sp.reqdate)>=0)   
			and (term_dt is null or datediff(day,sp.reqdate,term_dt)>0)))  
		UNION  
			SELECT Uniq_key,bomparent,term_dt,eff_dt,null as due_date FROM BOMIndented WHERE Uniq_key=@lcUniq_key  
	   ) 

	   SELECT * INTO #TempBom FROM #temp t WHERE t.UNIQ_KEY IN (SELECT Uniq_key FROM Sch WHERE sch.UNIQ_KEY = t.UNIQ_KEY) 

   			  SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #TempBom','',@sortExpression,'','Part_no',@startRecord,@endRecord))             
			  EXEC sp_executesql @rowCount          
      
			  SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #TempBom','',@sortExpression,N'Part_no','',@startRecord,@endRecord))        
			  EXEC sp_executesql @sqlQuery 
	 END
 ELSE
	BEGIN
	   -- 11/30/2020 Shivshankar P : Modify Sp for Customer search is not working in the WO MRP actions screen
	   --For Customer   
		IF (@custNumber <>' ')  
		BEGIN  
			SELECT * INTO #tempCust FROM #temp WHERE CustName = (SELECT CustName FROM CUSTOMER WHERE CUSTNO = @custNumber);
		      SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #tempCust','',@sortExpression,'','Part_no',@startRecord,@endRecord))             
			  EXEC sp_executesql @rowCount          
      
			  SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #tempCust','',@sortExpression,N'Part_no','',@startRecord,@endRecord))        
			  EXEC sp_executesql @sqlQuery 
		END 
		-- 12/01/2020 Shivshankar P : Modify SP for the Sales Order and work order not work properly from WO MRP Action screen
		--For SO 
		ELSE IF (@soNumber <>' ')  
		BEGIN  
			SELECT * INTO #tempSO FROM #temp WHERE REF LIKE '%'+ @soNumber +'%';
		      SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #tempSO','',@sortExpression,'','Part_no',@startRecord,@endRecord))             
			  EXEC sp_executesql @rowCount          
      
			  SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #tempSO','',@sortExpression,N'Part_no','',@startRecord,@endRecord))        
			  EXEC sp_executesql @sqlQuery 	    
		END  
		 --For WO
		ELSE IF (@ref <>' ')  
		BEGIN  
			  SELECT * INTO #tempWO FROM #temp WHERE ref LIKE '%'+ @ref +'%';
		      SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #tempWO','',@sortExpression,'','Part_no',@startRecord,@endRecord))             
			  EXEC sp_executesql @rowCount          
      
			  SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #tempWO','',@sortExpression,N'Part_no','',@startRecord,@endRecord))        
			  EXEC sp_executesql @sqlQuery 	   
		END   
        ELSE
		BEGIN
			  SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #temp','',@sortExpression,'','Part_no',@startRecord,@endRecord))             
			  EXEC sp_executesql @rowCount          
      
			  SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #temp','',@sortExpression,N'Part_no','',@startRecord,@endRecord))        
			  EXEC sp_executesql @sqlQuery 
		END 
	 END
 END  
 -- 09/17/2020 Shivshankar P : Modify SP for the assembly filter not work properly from WO MRP Action screen
 --ELSE IF (@lcBomParentPart  <>' ' )  
 --BEGIN  
 -- ;with  
 --  BOMIndented  
 --  as  
 --  (  
	--	SELECT Uniq_key,bomparent,term_dt,eff_dt FROM dbo.fn_getAllUniqKey4BomParent(@lcUniq_key)   
 --  ),  
 --  Sch  
 --  as  
 --  (
	--	SELECT DISTINCT s.Uniq_key,s.ParentPt ,b.term_dt,b.eff_dt,sp.reqdate as due_date  
	--	FROM mrpsch2 S 
	--	inner join BOMIndented B on S.UNIQ_KEY=b.Uniq_key and s.PARENTPT=b.bomparent  
	--	left outer JOIN mrpsch2 SP ON b.bomparent=sp.UNIQ_KEY and right(s.ref,10)=right(sp.ref,10)  
	--	WHERE ((sp.reqdate is null and (eff_dt is null OR (eff_dt is not null and datediff(day,eff_dt,getdate())>=0))   
 --       and (term_dt is null or (term_dt is not null and datediff(day,getdate(),term_dt)>0)))  
 --       or ((eff_dt is null or datediff(day,eff_dt,sp.reqdate)>=0)   
 --       and (term_dt is null or datediff(day,sp.reqdate,term_dt)>0)))  
 --   UNION  
 --       SELECT Uniq_key,bomparent,term_dt,eff_dt,null as due_date FROM BOMIndented WHERE Uniq_key=@lcUniq_key  
 --  )  

 -- SELECT DISTINCT A.Uniq_key, Part_Class, Part_Type, Part_no, Revision, CustPartNo, CustRev, Descript,   
 --              PART_CLASS + '/' + PART_TYPE + '/'+ Descript AS Descript_view,-- 07/18/17 Shivshankar P Merged the columns PART_CLASS ,PART_TYPE and Descript  
 --              Part_Sourc ,BUYER_TYPE,UniqMrpAct, --- 18/07/17 Shivshankar P Get Buyer and Total Number of Rows  
 --              totalCount = COUNT(A.Uniq_key) OVER()   
 --     INTO #temp1  
 --         FROM MrpAct A INNER JOIN inventor M ON A.uniq_key=M.Uniq_key   
 --         WHERE M.PART_SOURC<>'CONSG' --AND M.CUSTNO= CASE WHEN  @custNumber <> ' ' OR @custNumber IS NOT NULL THEN @custNumber ELSE M.CUSTNO END  
 --       AND (((@mrpAction  ='All WO Actions' OR @mrpAction  ='All PO Actions')   
 --        AND ((@isCancel = 1 and ACTION like ('%Cancel%'))   
 --     OR (@isQtyChange = 1 and (ACTION like ('%Qty%') OR ACTION like ('%Qty%')))   
 --     OR (@isReschedl = 1 and (ACTION like ('%RESCH%') OR ACTION like ('%RESCH%')))  
 --     OR (@isRelease = 1 and (ACTION like ('%Rel%') OR ACTION like ('%Rel%')))  
 --    -- OR (@showForecast = 1 and a.is_forecast=@showForecast)  
 --    ))   
 --    OR (@mrpAction  ='Release PO'AND A.ACTION  = 'Release PO'))  
 --    AND ((@mrpAction  ='All WO Actions'AND A.ACTION  like '%WO%') -- WO Action  
 --        OR (@mrpAction  ='All PO Actions'AND A.ACTION  like '%PO%') -- PO Change Action  
 --     OR (@mrpAction  ='Release PO'AND A.ACTION  = 'Release PO')  
 --     )      
 --      AND (DATEDIFF(Day,A.DTTAKEACT,@lastActionDate)>=0 OR A.DTTAKEACT IS NULL)   
 --      AND ((@startDate IS NOT NULL AND @endDate IS NOT NULL AND A.DTTAKEACT >= @startDate AND A.DTTAKEACT <= @endDate) OR   
 --     (@startDate IS NULL AND @endDate IS NULL  AND A.DTTAKEACT=A.DTTAKEACT))  
 --      AND ((@isTakeAct =0 AND A.ActionStatus IS NULL OR A.ActionStatus = ' ')   
 --     OR (@isTakeAct =1 AND A.ActionStatus  = 'Success' OR A.ActionStatus = 'Failed'))  
 --      AND (@isSoWoCustFilter = 1 AND  A.UNIQMRPACT IN ( select filterMrpUniq from #filterMrpTemp) OR (@isSoWoCustFilter =  0 AND  A.UNIQMRPACT= A.UNIQMRPACT))                 
 --    AND EXISTS (select 1 from Sch where m.UNIQ_KEY=sch.UNIQ_KEY )  
 --    ORDER BY A.Uniq_key    
  
 --     SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #temp1','',@sortExpression,'','Part_no',@startRecord,@endRecord))             
 --     EXEC sp_executesql @rowCount          
      
 --     SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #temp1','',@sortExpression,N'Part_no','',@startRecord,@endRecord))        
 --     EXEC sp_executesql @sqlQuery          
 --END    
 ELSE  if(@isScheduler=1)  
 BEGIN    
  SELECT DISTINCT A.Uniq_key, Part_Class, Part_Type, Part_no, Revision, CustPartNo, CustRev, Descript,  
                   PART_CLASS + '/' + PART_TYPE + '/'+ Descript AS Descript_view,  
                   A.action,Part_Sourc ,BUYER_TYPE, totalCount = COUNT(A.Uniq_key) OVER(),0  AS IsChecked  
				  ,PoBuyer.UserName AS Buyer ,A.dttAkeact,M.PART_NO + '/' +  M.REVISION  AS PartNoRevision  
				   ,A.ref,A.wono,A.balance,A.reqqty,A.due_date  AS DueDate, A.due_date,A.reqdate,A.days ,A.Uniq_key AS UniqKey  
				   ,A.ActionStatus, --,A.ActDate,A.ActionFailureMsg ,aspnet_Users.Initials,  
				   woentr.wocnt,SERIALYES ,UniqMRPAct  -- 01/19/18 Shivshankar P :  -Added Column UniqMRPAct  
				   ,A.ActionNotes --02/04/2020 Shivshankar P : Added ActionNotes column in selection list  
  INTO #temp2  
  FROM MrpAct A INNER JOIN inventor M ON A.uniq_key=M.Uniq_key  
           --   LEFT JOIN aspnet_Users ON A.ActUserId=aspnet_Users.UserId  -- 12/30/17 Shivshankar P :  -Remove Columns from 'MRPACT' Table (ActionStatus,ActDate)  
              OUTER APPLY (SELECT UserName FROM aspnet_Users LEFT JOIN POMAIN ON UserId = POMAIN.aspnetBuyer  
                 WHERE  POMAIN.PONUM=replace(A.REF,'PO ','')) PoBuyer -- 07/11/19 Nitesh B : - Change User Initials to UserName    
     OUTER APPLY  (SELECT COUNT(WOENTRY.WONO) AS wocnt FROM WOENTRY JOIN dept_qty ON  dept_qty.WONO =  WOENTRY.WONO  
                             WHERE  WOENTRY.WONO =  A.WONO AND NUMBER <> 1 AND CURR_QTY >0) woentr  
  WHERE M.PART_SOURC<>'CONSG' --AND M.CUSTNO= CASE WHEN  @custNumber <> ' ' OR @custNumber IS NOT NULL THEN @custNumber ELSE M.CUSTNO END  
        AND (((@mrpAction  ='All WO Actions' OR @mrpAction  ='All PO Actions')   
         AND ((@isCancel = 1 and ACTION like ('%Cancel%'))   
      OR (@isQtyChange = 1 and (ACTION like ('%Qty%') OR ACTION like ('%Qty%')))   
      OR (@isReschedl = 1 and (ACTION like ('%RESCH%') OR ACTION like ('%RESCH%')))  
      OR (@isRelease = 1 and (ACTION like ('%Rel%') OR ACTION like ('%Rel%')))  
     -- OR (@showForecast = 1 and a.is_forecast=@showForecast)  
     ))   
     OR (@mrpAction  ='Release PO'AND A.ACTION  = 'Release PO'))  
     AND ((@mrpAction  ='All WO Actions'AND A.ACTION  like '%WO%') -- WO Action  
         OR (@mrpAction  ='All PO Actions'AND A.ACTION  like '%PO%') -- PO Change Action  
      OR (@mrpAction  ='Release PO'AND A.ACTION  = 'Release PO')  
      )        
	  AND (DATEDIFF(Day,A.DTTAKEACT,@lastActionDate)>=0 OR A.DTTAKEACT IS NULL)  
	  AND M.Uniq_key IN (SELECT Uniq_key FROM dbo.fn_getAllUniqKey4BomParent(@lcUniq_key))  
	  AND ((@startDate IS NOT NULL AND @endDate IS NOT NULL AND A.DTTAKEACT >= @startDate AND A.DTTAKEACT <= @endDate) OR   
	  (@startDate IS NULL AND @endDate IS NULL  AND A.DTTAKEACT=A.DTTAKEACT))  
	  AND ((@isTakeAct =0 AND A.ActionStatus IS NULL OR A.ActionStatus = ' ')   
	  OR (@isTakeAct =1 AND A.ActionStatus  = 'Success' OR A.ActionStatus = 'Failed'))  
  ORDER By  A.DTTAKEACT,A.REF  --PoBuyer.Initials,A.DTTAKEACT,A.ACTION,A.REF      
	
  SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #temp2','',@sortExpression,'','Part_no',@startRecord,@endRecord))             
  EXEC sp_executesql @rowCount          
      
  SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #temp2','',@sortExpression,N'Part_no','',@startRecord,@endRecord))        
  EXEC sp_executesql @sqlQuery   
 END    
END  
  
  