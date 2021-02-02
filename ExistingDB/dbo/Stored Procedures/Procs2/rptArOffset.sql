-- =============================================  
-- Author:   Debbie  
-- Create date:  11/21/2013  
-- Description:  Created for the AR Offset report  
-- Reports Using:   ar_off1.rpt   
-- 02/07/17 VL Separate FC and non-FC, also added functional currency code  
-- 01/16/2019 Nilesh Sa Removed the Column 'CGROUP' from Selection,ordering 
-- =============================================  
CREATE procedure [dbo].[rptArOffset]  
   @lcDateStart smalldatetime = null  
  ,@lcDateEnd smalldatetime = null  
  ,@userId uniqueidentifier=null   
as  
begin  
IF dbo.fn_IsFCInstalled() = 0    
 select Customer.CUSTNAME,a.DATE,a.CUSTNO,a.INVNO,a.AMOUNT,a.INITIALS,a.OFFNOTE
 --,a.CGROUP   -- 01/16/2019 Nilesh Sa Removed the Column 'CGROUP' from Selection,ordering 
 from AROFFSET A,CUSTOMER  
 where a.custno = customer.custno  
   and cast(a.DATE as Date) between  @lcDateStart AND @lcDateEnd  
 order by CUSTNAME,DATE
 --,CGROUP -- 01/16/2019 Nilesh Sa Removed the Column 'CGROUP' from Selection,ordering 
 ,CTRANSACTION  
ELSE  
 select Customer.CUSTNAME,a.DATE,a.CUSTNO,a.INVNO,a.AMOUNT,a.INITIALS,a.OFFNOTE
 --,a.CGROUP -- 01/16/2019 Nilesh Sa Removed the Column 'CGROUP' from Selection,ordering 
 , a.AMOUNTFC, a.AMOUNTPR, TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol  
 from AROFFSET A  
 -- 02/07/17 VL changed criteria to get 3 currencies  
 INNER JOIN Fcused PF ON A.PrFcused_uniq = PF.Fcused_uniq  
 INNER JOIN Fcused FF ON A.FuncFcused_uniq = FF.Fcused_uniq     
 INNER JOIN Fcused TF ON A.Fcused_uniq = TF.Fcused_uniq     
 INNER JOIN CUSTOMER ON a.custno = customer.custno  
 WHERE cast(a.DATE as Date) between  @lcDateStart AND @lcDateEnd  
 order by CUSTNAME,DATE
 -- ,CGROUP -- 01/16/2019 Nilesh Sa Removed the Column 'CGROUP' from Selection,ordering 
 ,CTRANSACTION  
end  
  
  
  
  
  
  