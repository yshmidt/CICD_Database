
-- =============================================
-- Author:  Debbie    
-- Created:  04/25/2012    
-- Description: This Stored Procedure was created for the Work Order Summary with WIP by Due Date report    
-- Reports:  wsmwipdt.rpt//wsmwipd2.rpt    
-- Modified:  11/23/15 DRP:  Added @userId, /*CUSTOMER LIST*/, etc . . . to prepar it to work with the Web  Added @lcIsReport so I could use that to display the QuickView Results or Report results.      
--     They have to be different because we can not predict how many Depts they have setup within the system.     
--    07/11/16 DRP:  needed to change the filter within the zWip section to pull from the @customer intstead of @TCustomer.     
-- =============================================    
--"lcCustNo=All&lcDateStart=01/01/2017&lcDateEnd=12-08-2018&lcIsReport=No"    
-- 08/12/18 Shrikant B : Added LTRIM and RTRIM on Dept_id to avoid Extra Space into the column Names 
-- 12/26/18 Shrikant B :  DECLARE the @lcDateStart and @lcDateEnd from smallDateTime to varchar to Fix Conversion Error 
-- 12/26/18 Shrikant B :  CAST the @lcDateStart and @lcDateEnd from varchar to SMALLDATETIME to Fix Conversion Error
-- 01/02/19 Shrikant B :  Change @userId from UNIQIDENTIFIER  to VARCHAR(40) to Fix Conversion Error
-- 01/04/19 Shrikant B: Changed  Reverts @userId Changes from  VARCHAR(40) to UNIQUEIDENTIFIER 
-- 07/10/19 VL: fixed if the dept_id has special character like '&' it didn't work right for the dept_id column name
--[dbo].[rptWipSumDueDt] @lcCustNo = 'All', @lcDateStart = '12-17-2018', @lcDateEnd='12-24-2018', @lcIsReport = 'yes', @userId = '49f80792-e15e-4b62-b720-21b360e3108a'    
CREATE PROCEDURE [dbo].[rptWipSumDueDt]     
--declare    
  @lcCustNo AS VARCHAR(MAX) = 'All'  
   -- 12/26/18 Shrikant B :  DECLARE the @lcDateStart and @lcDateEnd from smallDateTime to varchar to Fix Conversion Error 
  ,@lcDateStart AS VARCHAR(MAX)= NULL    
  ,@lcDateEnd AS VARCHAR(MAX) = NULL    
  ,@lcIsReport AS CHAR(3) = 'Yes'  --11/23/15 DRP:  added so I could call results for either QuickView or Report form. Yes = report form results, No = QuickView Results    
  -- 01/02/19 Shrikant B :  Change @userId from UNIQIDENTIFIER  to VARCHAR(40) to Fix Conversion Error
  -- 01/04/19 Shrikant B: Changed  Reverts @userId Changes from  VARCHAR(40) to UNIQUEIDENTIFIER 
  ,@userId AS UNIQUEIDENTIFIER= NULL    
      
AS    
BEGIN    
    
/*CUSTOMER LIST*/      
 DECLARE  @tCustomer AS tCustomer    
  DECLARE @Customer TABLE (custno CHAR(10))    
  -- get list of customers for @userid with access    
  INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;    
  --SELECT * FROM @tCustomer     
      
  IF @lcCustNo IS NOT NULL AND @lcCustNo <>'' AND @lcCustNo<>'All'    
   INSERT INTO @Customer SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')    
     WHERE CAST (id AS CHAR(10)) IN (SELECT CustNo FROM @tCustomer)    
  ELSE    
    
  IF  @lcCustNo='All'     
  BEGIN    
   INSERT INTO @Customer SELECT CustNo FROM @tCustomer    
  END    
    
    
    
/*populating the @results with the system type tWip*/    
DECLARE @results AS tWipDueDt
    
/*RECORD SELECTION SECTION*/    
;    
--This will gather the work order and wip detail    
WITH zWip AS     
   (     
   SELECT woentry.WONO,due_date,Woentry.OPENCLOS,CUSTNAME,woentry.UNIQ_KEY,PART_NO,REVISION,inventor.PROD_ID,PART_CLASS,PART_TYPE,descript,kit,sono,bldqty, BLDQTY-COMPLETE as BalQty    
     ,dept_qty.DEPT_ID,depts.NUMBER,DEPT_NAME,dept_qty.CURR_QTY,woentry.UNIQUELN    
   FROM WOENTRY    
     INNER JOIN customer ON woentry.CUSTNO = customer.CUSTNO    
     INNER JOIN INVENTOR ON woentry.UNIQ_KEY = inventor.UNIQ_KEY    
     INNER JOIN DEPT_QTY ON WOENTRY.WONO = dept_qty.wono    
     INNER JOIN DEPTS ON depts.DEPT_ID = dept_qty.DEPT_ID    
   WHERE woentry.OPENCLOS NOT IN ('Closed','Cancel','ARCHIVED')    
     --and CUSTNAME like case when @lcCust ='*' then '%' else @lcCust + '%' end --11/23/15 DRP:  replaced with the below    
     AND EXISTS (SELECT 1 FROM @Customer t INNER JOIN customer c ON t.custno=c.custno WHERE c.custno=woentry.custno) --07/11/16 DRP:  needed to change it from @TCustomer to @customer    
     -- 12/26/18 Shrikant B :  CAST the @lcDateStart and @lcDateEnd from varchar to SMALLDATETIME to Fix Conversion Error 
	 AND woentry.DUE_DATE>=CAST( @lcDateStart AS SMALLDATETIME) AND woentry.due_date<CAST( @lcDateEnd AS SMALLDATETIME)+1    
   )    
    
--the below will link any pricing information from the sales order module if it is associated to the work order    
    
,    
zPrice AS     
  (    
  SELECT zwip.*,ISNULL(soprices.PRICE,0.00) AS Price     
  FROM zWip LEFT OUTER JOIN SOPRICES ON zWip.UNIQUELN = soprices.UNIQUELN AND soprices.RECORDTYPE = 'P'    
  )    
    
--the below will link the purchase order information from the sales order module if it is associated to the work order    
,    
ZResults AS     
  (    
  SELECT zPrice.*,ISNULL(somain.pono,space(20)) AS PoNo    
  FROM zPrice LEFT OUTER JOIN SOMAIN on zprice.SONO = somain.SONO    
  )    
    
INSERT INTO @results SELECT * FROM ZResults ORDER BY DUE_DATE,wono    
    
/*STING FOR THE NAMES OF THE COLUMNS BASED ON THE DEPTID*/    
-- 08/12/18 Shrikant : Added LTRIM and RTRIM  on @DeptId to avoid Extra Space into the column Names    
DECLARE @DeptId NVARCHAR(MAX)   
-- 07/10/19 VL fixed if the dept_id has special character like '&' it didn't work right for the dept_id column name 
--SELECT @DeptId =    
--  STUFF(    
--  (    
--    SELECT ',[' + LTRIM(RTRIM(D.Dept_id))  + ']'    
--    FROM DEPTS D WHERE DEPT_ID IN (SELECT dept_id FROM @results)  ORDER BY Number    
--    FOR XML PATH('')  ),  1,1,'')
SELECT @DeptId =
  STUFF(
  (
    SELECT N',[' + LTRIM(RTRIM(D.Dept_id))  + ']'
    FROM DEPTS D WHERE DEPT_ID IN (SELECT dept_id FROM @results)  ORDER BY Number
    FOR XML PATH, TYPE).value(N'.[1]',
	N'nvarchar(max)'), 1, 1, N'')
-- 07/10/19 VL End}
    
 --select @deptid    
        
/*USE SQL TO ASSIGN DEPTID AS THE COLUMN NAMES WITHIN PIVOT TABLE*/    
/*Please note:  that at this point in time it is only setup to work with Quick View only.  They way it is setup now it will not work with MRT designer.  */    
     
     
DECLARE @SQL NVARCHAR(max)    
    
IF (@lcIsReport = 'No')    
  BEGIN    
   SELECT @SQL = N'    
      SELECT *     
      FROM ( SELECT Wono as [WONUM],Due_Date,OpenClos,CustName,Uniq_key,part_no,revision,Prod_id,Part_Class,Part_type,Kit as IsKit,SONO as [SONUM],BldQty,BalQty,Dept_id     
        ,Curr_Qty,uniqueln,price,pono     
        from @results    
        group by WoNo,Due_Date,OpenClos,CustName,Uniq_key,part_no,revision,Prod_id ,Part_Class ,Part_type,Kit,SoNo,BldQty,BalQty,Dept_id,    
        Curr_Qty,uniqueln,price,pono    
        )  tData      
      PIVOT (SUM(Curr_qty) FOR Dept_id in ('+@DeptID+')) tPivot'     
    
      /*--sp_executesql procedure will take second parameter as User defined table type (UDTT) and we will pass @result table variable */    
      EXEC sp_executesql @SQL,N'@results tWipDueDt READONLY',@results     
  END --(@lcIsReport = 'No')     
ELSE IF (@lcIsReport = 'Yes')    
  BEGIN    
   SELECT WONO,due_date,OPENCLOS,CUSTNAME,UNIQ_KEY,PART_NO,REVISION,PROD_ID,PART_CLASS,PART_TYPE,descript,kit,sono,bldqty,BalQty,DEPT_ID,NUMBER,DEPT_NAME,CURR_QTY,UNIQUELN,Price,PoNo FROM @results    
		END
    
--select * from @results    
    
END  