    
 -- =============================================    
 -- Author:   Debbie    
 -- Create date:  05/01/2014    
 -- Description:  Compiles the details for the Defect Logging History Report    
 -- Used On:   qahist    
 -- Modifications: 05/01/2014 DRP:  VFP had different selection options and order by reports available.  (by Customer, by Product Number, by Work Order Number, By Work Center)    
 --     but for SQL we converted just the By Customer version fwd at this time.    
 --     01/06/2015 DRP:  Added @customerStatus Filter      
-- 07/16/18 VL changed custname from char(35) to char(50)    
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)    
-- 04/29/20 Satyawan : Changed dept_Id column name to WC   
-- 10/21/20 Sachin B : Increase length of [Part Number] varchar(34) to [Part Number] varchar(45) becuase it is combing PartNo and Revision
-- [rptQaDefectLogHist] 'by Product','All','_1LR0NALBN,BBT57SGAQ9,_2BK0I3NSW,_38Y0YA811,_3SX0TLY16,_26F0JVLZK,_1ZN0N4W6J,ZYNKBN6JOH,_0TQ0MOGPO,_1EP0Q018H,_14C0OQLVM,_1LJ0V1KRH,_14X0Q7VEY,_26L0THVA8,_2730YA0P5,_2AY0TEPED,9THZQON12E,_33U0XM9LE,Q05CYHPWHS,_3F00U8WJ5,JKYABZ1CEJ','All','All','01/01/2020','10/21/2020','1320274C-F08D-4939-B363-40AEFC4869C3'
-- -- =============================================    
CREATE PROCEDURE  [dbo].[rptQaDefectLogHist]    
    
 @lcRptType as char(15) = 'by Customer' -- avaialalbe selections:  by Customer,by Product,by Work Order,by Work Center.  this will determine the results (sort order) displayed on screen.     
 ,@lcCustNo as varchar(max) = 'All'  --if null will select all Customers that exist within qainsp, @lcCustNo could have a single value for a custno or a CSV    
 ,@lcUniqkey as varchar(max) = 'All'  --_14C0OQLVM --if null will select all Product that exist within qainsp, @lcUniqkey could have a single value for a uniqkey or a CSV    
 ,@lcWoNo as varchar(max) = 'All'  --if null will select all WoNo that exist within qainsp, @lcWoNo could have a single value for a custno or a CSV    
 ,@lcDeptId as varchar(max) = 'All'  --if null will select all DeptId that exist within qainsp, @lcDeptId could have a single value for a custno or a CSV    
 ,@lcDateStart as smalldatetime = null    
 ,@lcDateEnd as smalldatetime = null    
 ,@customerStatus varchar (20) = 'All' --01/06/2015 DRP: ADDED    
 ,@userId uniqueidentifier= null     
     
as     
begin     
    
-- 07/16/18 VL changed custname from char(35) to char(50)    
Declare @tResults as table (DefDate smalldatetime,InspBy char(10),CustName char(50),Part_no char(35),Revision char(8)    
       ,WoNo char(10),Dept_Id char(4),SerialNo char(30),Def_code char(10),location char(30),custno char(10))    
    
declare @sql nvarchar(max)    
    
    
SELECT @sql= N'SELECT Qadef.Defdate, Qainsp.Inspby, Customer.Custname, Inventor.Part_no,inventor.REVISION, Qadef.Wono,     
      Qadefloc.chgDept_id AS Dept_id, Qadef.Serialno, Qadefloc.Def_code, Qadefloc.Location,customer.CUSTNO     
    FROM Qainsp, qadef,Qadefloc, Customer, Inventor, Woentry    
    where Qainsp.Wono = Qadef.Wono     
      AND Qainsp.Qaseqmain = Qadef.Qaseqmain     
      AND Qadef.Locseqno = Qadefloc.Locseqno     
      AND Qadef.Wono = Woentry.Wono     
      AND Woentry.Custno = Customer.Custno     
      AND Woentry.Uniq_key = Inventor.Uniq_key     
      AND CONVERT(Date,DefDate) BETWEEN ''' +CONVERT(varchar(10), @lcDateStart,112)+''' AND '''+CONVERT(varchar(10),@lcDateEnd,112)+''''    
    
    
/*COMPILING APPROVED CUSTOMER PER USERID*/ -- which will be used in each of the below If statements    
DECLARE  @tCustomer as tCustomer    
 --DECLARE @Customer TABLE (custno char(10))    
     
 -- get list of Customers for @userid with access    
 INSERT INTO @tCustomer EXEC aspmnxSP_Getcustomers4user @userid,null,@customerStatus ;    
    
    
/*BY CUSTOMER*/    
if (@lcRptType = 'by Customer')     
begin    
    
 declare @customer tCustno    
 -- get list of Customers for @userid with access    
 IF @lcCustno is not null and @lcCustNo <>'' and @lcCustNo<>'All'    
  insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')    
    where CAST (id as CHAR(10)) in (select Custno from @tCustomer)    
 ELSE    
    
 IF  @lccustNo='All'     
 BEGIN    
  INSERT INTO @Customer SELECT Custno FROM @tCustomer    
 END     
    
 select @sql=@sql+'and 1= case WHEN woentry.custNO IN (SELECT custno FROM @CUSTOMER) THEN 1 ELSE 0  END '+    
 'order by CUSTNAME,DEFDATE,PART_NO,revision,WONO,DEF_CODE'    
     
 INSERT INTO @tresults EXEC sp_executesql @sql, N'@Customer tCustno READONLY',@Customer     
    
end    
    
/*BY PRODUCT*/    
else if (@lcRptType = 'By Product')    
begin    
    
 declare @tInvt as tUniq_key 
 -- 10/21/20 Sachin B : Increase length of [Part Number] varchar(34) to [Part Number] varchar(45) becuase it is combing PartNo and Revision   
  declare @Invt table(uniq_key char(10),[Part Number] varchar(45) ,part_no char(35),revision char(8))    
 insert into @Invt SELECT Uniq_key,[PART Number],Part_no,Revision from View_InvtMake4Qa I where I.Custno IN (SELECT Custno from @tCustomer)    
 --get list of Product the user is approved to view based off of the approve Customer listing    
 if @lcUniqkey is not null and @lcUniqkey <>'' and @lcUniqkey<>'All'    
  insert into @tInvt select * from dbo.[fn_simpleVarcharlistToTable](@lcUniqkey,',')    
    
 ELSE    
    
 IF  @lcUniqkey='All'     
 BEGIN    
  INSERT INTO @tInvt SELECT Uniq_key FROM @Invt    
 END    
    
 select @sql=@sql+'and 1= case WHEN woentry.Uniq_key IN (SELECT uniq_key FROM @tInvt) THEN 1 ELSE 0  END '+    
 'order by PART_NO,revision,defdate,WONO,DEF_CODE'    
    
 INSERT INTO @tresults EXEC sp_executesql @sql, N'@tInvt tUniq_key READONLY',@tInvt     
    
end    
    
/*BY WORK ORDER*/    
else if (@lcRptType = 'by Work Order')    
begin    
    
 declare @tWono as tWono    
  declare @Wono table(wono char(10),custno char(10),openclos char(10))    
 insert into @Wono select wono, custno,openclos from View_Wo4Qa W where w.custno in (select custno from @tCustomer)    
 --Get list of work order the user is approved to view based off of the approved Customer listing    
 if @lcwono is not null and @lcWoNo <> '' and @lcWoNo <> 'All'    
  insert into @tWono select * from dbo.[fn_simpleVarcharlistToTable](@lcwono,',')    
    
 else    
 if @lcWoNo = 'All'    
  Begin     
   insert into @tWono select wono from @Wono    
  end    
    
 select @sql=@sql+'and 1= case WHEN woentry.wono IN (SELECT wono FROM @twono) THEN 1 ELSE 0  END '+    
  'order by wono,defdate,part_no,revision,def_code'    
    
 INSERT INTO @tresults EXEC sp_executesql @sql, N'@tWono twono READONLY',@tWoNo     
end    
    
/*BY WORK CENTER*/    
else if (@lcRptType = 'by Work Center')     
begin    
      
 DECLARE  @tDepts as tDeptId    
  DECLARE @Depts table (Dept_id char (4), Dept_name char(25) ,[Number] numeric(4,0),custno char(10))    
 -- get list of Departments for @userid with access    
 INSERT INTO @Depts select Dept_id,Dept_name,Number,CustNo from View_Wc4Qa Wc where Wc.Custno in (select custno from @tCustomer)    
    
 IF @lcDeptId is not null and @lcDeptId <>'' and @lcDeptId<>'All'    
  insert into @tDepts select * from dbo.[fn_simpleVarcharlistToTable](@lcDeptId,',')    
    
 ELSE    
 IF  @lcDeptId='All'     
  BEGIN    
   INSERT INTO @tDepts SELECT Dept_id FROM @Depts    
  END    
    
 select @sql=@sql+'and 1= case WHEN qainsp.dept_id IN (SELECT dept_id FROM @tDepts) THEN 1 ELSE 0  END '+    
  'order by Dept_id,CUSTNAME,DEFDATE,PART_NO,revision,WONO,DEF_CODE'    
    
    
 INSERT INTO @tresults EXEC sp_executesql @sql, N'@tDepts tDeptId READONLY',@tDepts     
    
end    
    
-- 04/29/20 Satyawan : Changed dept_Id column name to WC   
select DefDate, InspBy, CustName, Part_no, Revision, WoNo, Dept_Id WC, SerialNo, Def_code, [location], custno from @tresults    
    
END