--=============================================  
-- Author:  Debbie  
-- Create date: 02/23/2012  
-- Description: This Stored Procedure was created for the Invoice Register by Invoice Number  
-- Reports Using Stored Procedure:  inv_rep3.rpt, inv_rep6.rpt  
-- Modified: 01/15/2014 DRP:  added the @userid parameter for WebManex  
--    10/30/15 DRP:  changed the Date Range filter. added the @lcSort param so I could use the same procedure to two reports.   
--    02/18/16 VL:   Added FC code  
--    04/08/16 VL:   Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement  
--    01/24/17 VL:   added functional currency code  
-- 07/16/18 VL changed custname from char(35) to char(50)
-- 05/23/2020 Satayawn H: Added to get invoice By customerNo   
-- 05/23/2020 Satyawan H: Added logic to filter data based on all or selected customers
-- 05/23/2020 Satyawan H: Added join with selected or all customers
-- EXEC [dbo].[rptInvoiceRegister2008] @userid='49F80792-E15E-4B62-B720-21B360E3108A' 
-- =============================================  
CREATE PROCEDURE [dbo].[rptInvoiceRegister2008]  
--declare  
   @lcDateStart as smalldatetime= null  
  ,@lcDateEnd as smalldatetime = null  
  ,@lcSort as char(10) = 'by Invoice' --By Invoice or By Date --10/30/15 DRP:  Added   
  ,@lcCustNo as varchar (Max) = 'All' -- 05/23/2020 Satayawn H: Added to get invoice By customerNo 
  ,@userId uniqueidentifier=null  
AS   
BEGIN  
	SET NOCOUNT ON 
	-- 02/17/16 VL added for FC installed or not  
	DECLARE @lFCInstalled bit  
	-- 04/08/16 VL changed to get FC installed from function  
	SELECT @lFCInstalled = dbo.fn_IsFCInstalled()  

    -- 05/23/2020 Satyawan H: Added logic to filter data based on all or selected customers
	/*CUSTOMER LIST*/  
	DECLARE  @tCustomer as tCustomer  
	DECLARE @Customer TABLE (custno char(10))  
	-- get list of customers for @userid with access  
	INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;  

	IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'  
		INSERT INTO @Customer SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')  
		WHERE CAST (id AS CHAR(10)) IN (SELECT CustNo FROM @tCustomer)  
	ELSE  
	IF @lcCustNo='All'   
	BEGIN  
		INSERT INTO @Customer SELECT CustNo FROM @tCustomer  
	END  
	
	BEGIN  
		IF @lFCInstalled = 0  
		 BEGIN  
			IF @lcSort = 'by Date'  
			BEGIN  
				-- 07/16/18 VL changed custname from char(35) to char(50)  
				DECLARE @tI table (custno char(10),custname char(50), invoiceno char(10),invdate smalldatetime,
								   sono char(10),PACKLISTNO char(10),invtotal numeric(8,2),PRINT_INVO bit,
								   id int not null identity(1,1) primary key)  
				INSERT INTO @tI (custno,custname,INVOICENO,INVDATE,SONO,PACKLISTNO,INVTOTAL,PRINT_INVO)  
				SELECT plmain.custno,custname,INVOICENO,INVDATE,SONO,PACKLISTNO,INVTOTAL,PRINT_INVO  
				FROM PLMAIN   
				INNER JOIN CUSTOMER on plmain.CUSTNO = customer.CUSTNO 
				-- 05/23/2020 Satyawan H: Added join with selected or all customers 
				INNER JOIN @Customer cust ON customer.CUSTNO = cust.custNo
				WHERE DATEDIFF(Day,INVDATE,@lcDateStart)<=0 AND DATEDIFF(Day,INVDATE,@lcDateEnd)>=0  
				AND PRINT_INVO = 1  
				ORDER BY invdate,custname  
    
				SELECT custno,custname,INVOICENO,INVDATE,SONO,PACKLISTNO,INVTOTAL,PRINT_INVO ,  
				(SELECT SUM(b.invtotal)FROM @ti b WHERE b.id <= a.id) as RunningBal  
				from @ti a order by a.invdate,a.custname  
			END --- @lcSort = 'by Date'  
			ELSE IF @lcSort = 'by Invoice'  
			BEGIN  
				SELECT plmain.custno,custname,INVOICENO,INVDATE,SONO,PACKLISTNO,INVTOTAL,PRINT_INVO  
				FROM PLMAIN  
				INNER JOIN CUSTOMER on plmain.CUSTNO = customer.CUSTNO  
				INNER JOIN @Customer cust ON customer.CUSTNO = cust.custNo
				WHERE DATEDIFF(Day,INVDATE,@lcDateStart)<=0 AND DATEDIFF(Day,INVDATE,@lcDateEnd)>=0  
				--INVDATE >=@lcDateStart AND INVDATE<@lcDateEnd+1 --10/30/15 DRP:  replaced with the above  
				AND PRINT_INVO = 1  
				ORDER BY INVOICENO,custname  
			End  
			END  
		ELSE  
		-- FC installed  
		BEGIN  
			IF @lcSort = 'by Date'  
			BEGIN  
				-- 01/24/17 VL added functional currency code  
				-- 07/16/18 VL changed custname from char(35) to char(50)  
				declare @tI2 table (custno char(10),custname char(50), invoiceno char(10),invdate smalldatetime,sono char(10),PACKLISTNO char(10)  
								   ,invtotal numeric(8,2),PRINT_INVO bit,id int not null identity(1,1) primary key,invtotalFC numeric(8,2),  
									invtotalPR numeric(8,2), TSymbol char(3), PSymbol char(3), FSymbol char(3))  
			
				INSERT INTO @tI2 (custno,custname,INVOICENO,INVDATE,SONO,PACKLISTNO,INVTOTAL,PRINT_INVO,INVTOTALFC,INVTOTALPR, TSymbol, PSymbol, FSymbol)  
			
				SELECT plmain.custno,custname,INVOICENO,INVDATE,SONO,PACKLISTNO,INVTOTAL,PRINT_INVO,INVTOTALFC,  
					   INVTOTALPR, TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol   
				FROM PLMAIN   
				-- 01/24/17 VL changed criteria to get 3 currencies  
				INNER JOIN Fcused PF ON PLMAIN.PrFcused_uniq = PF.Fcused_uniq  
				INNER JOIN Fcused FF ON PLMAIN.FuncFcused_uniq = FF.Fcused_uniq     
				INNER JOIN Fcused TF ON PLMAIN.Fcused_uniq = TF.Fcused_uniq     
				INNER JOIN CUSTOMER on plmain.CUSTNO = customer.CUSTNO   
				INNER JOIN @Customer cust ON customer.CUSTNO = cust.custNo
				WHERE DATEDIFF(Day,INVDATE,@lcDateStart)<=0 AND DATEDIFF(Day,INVDATE,@lcDateEnd)>=0 AND PRINT_INVO = 1  
				ORDER BY invdate,custname  
    
				SELECT custno,custname,INVOICENO,INVDATE,SONO,PACKLISTNO,INVTOTAL,PRINT_INVO, (SELECT SUM(b.invtotal)
				FROM @ti b WHERE b.id <= a.id) as RunningBal, INVTOTALFC, INVTOTALPR, TSymbol, PSymbol, FSymbol  
				from @ti2 a order by a.TSymbol, a.invdate,a.custname  
			END --- @lcSort = 'by Date'  
			ELSE IF @lcSort = 'by Invoice'  
			BEGIN  
				-- 01/24/17 VL added functional currency code  
				SELECT plmain.custno,custname,INVOICENO,INVDATE,SONO,PACKLISTNO,INVTOTAL,PRINT_INVO, INVTOTALFC,   
					   INVTOTALPR, TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol   
				FROM PLMAIN  
				-- 01/24/17 VL changed criteria to get 3 currencies  
				INNER JOIN Fcused PF ON PLMAIN.PrFcused_uniq = PF.Fcused_uniq  
				INNER JOIN Fcused FF ON PLMAIN.FuncFcused_uniq = FF.Fcused_uniq     
				INNER JOIN Fcused TF ON PLMAIN.Fcused_uniq = TF.Fcused_uniq     
				inner join CUSTOMER on plmain.CUSTNO = customer.CUSTNO  
        -- 05/23/2020 Satyawan H: Added join with selected or all customers
				INNER JOIN @Customer cust ON customer.CUSTNO = cust.custNo
				WHERE DATEDIFF(Day,INVDATE,@lcDateStart)<=0 AND DATEDIFF(Day,INVDATE,@lcDateEnd)>=0  
				--INVDATE >=@lcDateStart AND INVDATE<@lcDateEnd+1 --10/30/15 DRP:  replaced with the above  
				and PRINT_INVO = 1  
				ORDER BY TSymbol, INVOICENO,custname  
			END  
		END  
	END-- IF FC Installed  
END