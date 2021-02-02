-- =======================================================================================================================================    
-- Author:  Mahesh B.     
-- Create date: 09/10/2018     
-- Description: Get the Production Control Details.    
-- 10/01/2018 Mahesh B:Added the Work order status column in the production control main grid       
-- 03/04/2019 Mahesh B:Comment out the calculation of the Total     
-- 03/08/2019 Mahesh B:Calaculate the Total Time from  PROD_DTS table     
-- 03/11/2019 Mahesh B:Remove leading zeros from a Work order    
-- 03/15/2019 Mahesh B:Normalized the SQL in Dynamic SQL    
-- 03/15/2019 Mahesh B:Buildable Qty at least zero       
-- 05/22/2019 Mahesh B:Removed the perticular characher replacement      
-- 05/06/2020 Sachin B:Change the Logic for the get priority if dept_pri is 0 then use  prod_dts table slack priority    
-- 06/02/2020 Sachin B: Add KIT Column in the select statement  
-- 07/25/2020 Sachin B: Add Condition for the ignore kit column AND KAMAIN.IGNOREKIT = 0 
-- 07/28/2020 Sachin B: For the Work order If kit not Pull then show bldQty in the Buildable
-- 08/11/2020 Satyawan H: Added UNIQUELN, WOENTRY.SONO to selection and group by for getting linked SO in Production control
-- 10/01/2020 Sachin B : Set default value for @pageSize AND @skip
-- 12/01/2020 YS when calculating buildable, we need to take into consideration act_qty, not just allocatedQty
-- Exec GetProductionControlDetails '',3000,0,''       
-- =======================================================================================================================================      
CREATE PROCEDURE [dbo].[GetProductionControlDetails]    
(    
	@sortExpression CHAR(1000) = null,    
	@pageSize INT = 150,    -- 10/01/2020 Sachin B : Set default value for @pageSize AND @skip
	@skip INT = 0,    
	@filter NVARCHAR(1000) = NULL    
)    
AS    
BEGIN    
    
SET NOCOUNT ON;     
    
DECLARE @DeptId nvarchar(max)    
DECLARE @SQL nvarchar(max)    
    
 -- 05/22/2019 Mahesh B:Removed the perticular characher replacement     
 SELECT @DeptId = STUFF((SELECT ',[' + RTRIM(LTRIM(D.Dept_id)) + ']' -- REPLACE(D.Dept_id,'-','_')    
                  FROM DEPTS D WHERE DEPT_ID IN   
      (SELECT dp.dept_id FROM DEPTS dp INNER JOIN DEPT_QTY dq ON dp.DEPT_ID=dq.DEPT_ID WHERE (dq.CURR_QTY > 0 AND dq.CURR_QTY IS NOT NULL))    
                  for xml path('')  ),  1,1,'')    
 -- 03/15/2019 Mahesh B:Normalized the SQL in Dynamic SQL     
 -- 05/06/2020 Sachin B:Change the Logic for the get priority if dept_pri is 0 then use  prod_dts table slack priority    
 --COALESCE(NULLIF(prt.pri,0), 0) AS Priority,     
 SELECT @SQL = N'    
             SELECT  * from     
          (SELECT  
      CASE COALESCE(NULLIF(prt.pri,0), 0)  
   WHEN 0 THEN COALESCE(NULLIF(pd.SLACKPRI,0), 0)    
      ELSE COALESCE(NULLIF(prt.pri,0), 0) END AS Priority,  
          dbo.fRemoveLeadingZeros(woentry.WONO) AS WONO ' -- 03/11/2019 Mahesh B:Remove leading zeros from a Work order    
    +',due_date AS WODue,    
    CASE COALESCE(NULLIF(INVENTOR.REVISION,''''), '''')    
          WHEN '''' THEN  LTRIM(RTRIM(INVENTOR.PART_NO))     
          ELSE LTRIM(RTRIM(INVENTOR.PART_NO)) + ''/'' + INVENTOR.REVISION     
          END AS AssemblyWithRev '      
    -- 03/04/2019 Mahesh B:Comment out the calculation of the Total     
    --CASE WHEN DEPT_QTY.NUMBER<=2 THEN [dbo].[GetTimeInHoursAndMinByTimeInSeconds](((QuotDept.RUNTIMESEC * WOENTRY.BLDQTY )+QuotDept.SETUPSEC )/60)          
          -- ELSE [dbo].[GetTimeInHoursAndMinByTimeInSeconds](((QuotDept.RUNTIMESEC * DEPT_QTY.CURR_QTY)+QuotDept.SETUPSEC)/60)    
             --  END AS Total,    
    +',COALESCE(NULLIF(pd.PROCESSTM, 0),0) AS Total ' -- 03/08/2019 Mahesh B: Calaculate the Total Time from  PROD_DTS table      
    +',KitStatus,    
    DEPT_QTY.Dept_id,    
    bldqty As WOQty,    
    CUSTNAME As Company,    
    JobType,    
    dept_qty.CURR_QTY As Curr_Qty,    
    ITAR,     
    OPENCLOS As Status ' -- 10/01/2018 Mahesh B: Added the Work order status column in the production control main grid   
 -- 06/02/2020 Sachin B : Add KIT Column in the select statement 
 -- 07/25/2020 Sachin B: Add Condition for the ignore kit column AND KAMAIN.IGNOREKIT = 0 
 -- 07/28/2020 Sachin B: For the Work order If kit not Pull then show bldQty in the Buildable  
 -- 12/01/2020 YS when calculating buildable, we need to take into consideration act_qty, not just allocatedQty
    +',COALESCE(CONVERT(INT,MIN((KAMAIN.allocatedQty+Kamain.Act_qty)/NULLIF(KAMAIN.QTY, 0))),bldqty) AS Buildable,KIT,UNIQUELN,WOENTRY.SONO ' -- 03/15/2019 Mahesh B: Buildable Qty at least zero 
-- 08/11/2020 Satyawan H: Added UNIQUELN, WOENTRY.SONO to selection and group by for getting linked SO in Production control   
             +'FROM WOENTRY woentry     
     LEFT JOIN customer ON woentry.CUSTNO = customer.CUSTNO    
     LEFT JOIN KAMAIN On KAMAIN.WONO=WOENTRY.WONO    
     LEFT JOIN INVENTOR ON woentry.UNIQ_KEY = inventor.UNIQ_KEY    
     LEFT JOIN DEPT_QTY ON WOENTRY.WONO = dept_qty.wono    
     Left JOIN DEPTS on depts.DEPT_ID = dept_qty.DEPT_ID    
     LEFT JOIN QuotDept  ON QuotDept.UNIQNUMBER = DEPT_QTY.DEPTKEY     
     OUTER APPLY (SELECT TOP 1 DEPT_PRI AS pri FROM DEPT_QTY WHERE CURR_QTY > 0 AND WONO = WOENTRY.WONO ORDER BY NUMBER) prt    
     LEFT JOIN PROD_DTS pd ON pd.WONO = WOENTRY.WONO    
     WHERE woentry.OPENCLOS NOT IN (''Closed'',''Cancel'') AND (KAMAIN.IGNOREKIT IS NULL OR KAMAIN.IGNOREKIT = 0)
  GROUP BY COALESCE(NULLIF(pd.SLACKPRI,0), 0),KITSTATUS,DEPT_QTY.Dept_id,bldqty,woentry.WONO,    
              due_date,CUSTNAME,JobType,INVENTOR.PART_NO,INVENTOR.REVISION, Inventor.ITAR,dept_qty.CURR_QTY,    
              WOENTRY.BLDQTY,DEPT_QTY.NUMBER,OPENCLOS,prt.pri,pd.PROCESSTM,KIT,UNIQUELN,WOENTRY.SONO) tdata    
              PIVOT (SUM(Curr_qty) FOR Dept_id in ('+ @DeptID +')) PVT'    
        
      IF @sortExpression <> '' AND @filter <> ''    
           BEGIN    
           SET @SQL = @SQL + ' WHERE '+@filter+' ORDER BY ' +@sortExpression+' OFFSET '+CONVERT(VARCHAR,@skip)+' ROWS FETCH NEXT ('+CONVERT(varchar,@pageSize)+') ROWS ONLY;'    
        END    
        ELSE IF @filter = '' AND @sortExpression <> ''    
           BEGIN    
        SET @SQL = @SQL +' ORDER BY '+@sortExpression+' OFFSET '+CONVERT(VARCHAR,@skip)+' ROWS FETCH NEXT ('+CONVERT(VARCHAR,@pageSize)+') ROWS ONLY;'    
        END    
          ELSE IF @filter <> '' AND @sortExpression = ''    
           BEGIN    
            SET @SQL = @SQL + ' WHERE '+@filter+' ORDER BY Priority OFFSET '+CONVERT(VARCHAR,@skip)+' ROWS FETCH NEXT ('+CONVERT(varchar,@pageSize)+') ROWS ONLY;'    
        END    
        ELSE     
        BEGIN    
         SET @SQL = @SQL +' ORDER BY Priority OFFSET '+CONVERT(VARCHAR,@skip)+' ROWS FETCH NEXT ('+CONVERT(varchar,@pageSize)+') ROWS ONLY;'    
     END    

     EXEC sp_executesql @SQL    
END    