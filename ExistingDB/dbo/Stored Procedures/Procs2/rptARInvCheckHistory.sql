
-- =============================================
-- Author:		Debbie
-- Create date: 04/28/2010
-- Description:	This Stored Procedure was created to pull fwd AR History information (Invoice, Credit Memos, Offsets, Write-offs and Check Deposits) based off of the Users selection 
-- Reports Using Stored Procedure:  arsoinv.rpt
-- =============================================

-- =============================================
-- Modification Notes:
-- 01/11/2012	DRP:	Noticed that if the Invoices happen to have either an Offset or Write-off Only applied to it, that my prior code was not pulling fwd the Invoice Total. 
--						I have made modifications below to pull from the plmain.invtotal instead of Cast (0.00 as numeric(12,2) as InvTotal.
--				DRP:	Also found that if the invoices happen to only have Offset or Write-off's applied that these records were not being pulled fwd at all.
--						This was due to the fact that the below was pulling from the Arcredit table and if only Offsets or Write-offs exist at this time there will actually NOT be 
--						any records within the ArCredit table for that invoice.   Removed AND EXISTS  (SELECT 1 FROM ArCredit A2 WHERE A2.Invno= dbo.padl(@lcRecord,10,'0') and A2.Custno=Aroffset.Custno and  Plmain.InvoiceNo=A2.InvNo)			
-- 10/08/2012	DRP:	Testing found that if an invoice existed but did not have any credits yet applied that the prior code was not display those invoice records on the report.  
--						Then I inserted the @InvDtl to first pull all of the Invoice detail then left outer join to all of the AR Credit records.
-- 10/10/2014 DRP:  needed to add the @userId to make sure only customers that the user is approved to view are displayed in the results.  
--				  Added <<cast(rtrim(@lcSelect)+':  '+rtrim(@lcRecord)as CHAR(35)) as RecSelected>> to be used in QuickView
-- 01/06/2015 DRP:  Added @customerStatus Filter 
-- 03/01/2016 VL:	Added FC codes, always use latest rate to calculate HC values (for now)
-- 04/08/2016 VL:	Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 01/11/2017 VL:	added one more parameter for fn_CalculateFCRateVariance() which is the rate ratio calculated based on functional currency or presentation currency
-- 01/13/2017 VL:	Added functional currency fields
-- 07/24/17 DRP:  removed @customerStatus and just typed in the Customer Status into the /*CUSTOMER LISTS*/ section
-- =============================================
						
CREATE PROCEDURE [dbo].[rptARInvCheckHistory]
 
--declare
@lcSelect char(25)= 'By Sales Order'	--By Sales Order, By Invoice Number or By Customer Check Number
,@lcRecord char(10) = ''
--,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED	--07/24/17 DRP:  removed
,@userId uniqueidentifier = null

AS 
BEGIN

/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer	
					INSERT INTO @Customer SELECT CustNo FROM @tCustomer

-- 03/01/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

BEGIN
IF @lFCInstalled = 0
	BEGIN


	--10/08/2012 DRP:  this table was added in the situation that the invoice exist but no credits yet applied.  This table will hold all of the AR invoice information 
	declare @InvDtl as table (InvNo char(10),InvDate smalldatetime,SoNo char(10),CustName char(35),Custno char(10),InvTotal numeric(20,2))

	--10/08/2012 DRP:  This will populate the @InvDtl table above with all of the Invoice information
	insert into @InvDtl select	invno,acctsrec.INVDATE,sono,custname,acctsrec.custno,acctsrec.INVTOTAL
						from	ACCTSREC
								inner join CUSTOMER on acctsrec.CUSTNO = customer.CUSTNO
								inner join PLMAIN on acctsrec.INVNO = plmain.INVOICENO
						WHERE	1 = case when ACCTSREC.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end	--10/10/2014 drp:  Added

	if (@lcSelect='By Customer Check Number')
	BEGIN
		select	t1.Rec_Advice, t1.Rec_Date, t1.Rec_Amount, t1.InvNo, t1.InvDate, t1.SoNo,t1.Custname,t1.Custno,
				CASE WHEN ROW_NUMBER() OVER(Partition by custno,invno Order by rec_date)=1 Then InvTotal ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotal
				,cast(rtrim(@lcSelect)+':  '+rtrim(@lcRecord)as CHAR(35)) as RecSelected	--10/10/2014 DRP:  Added to be used in QuickView
		from	(
				SELECT	Rec_Advice, Rec_Date, Rec_Amount, Plmain.InvoiceNo as InvNo, InvDate, InvTotal, SoNo,Customer.Custname,A1.Custno
				FROM	ArCredit A1, PlMain, Customer
				WHERE	A1.CustNo = Customer.CustNo 
						AND PlMain.InvoiceNo = A1.InvNo 
						AND EXISTS  (SELECT 1 FROM ArCredit A2 WHERE A2.Rec_Advice = @lcRecord and A2.Custno=A1.Custno and A1.InvNo=A2.InvNo)
					
				UNION

				--offset
				SELECT DISTINCT	'Offset:'+Uniq_ArOff AS Rec_Advice,date AS Rec_date,-Amount AS Rec_Amount,Invno,InvDate,CAST(0.00 as Numeric(20,2)) as InvTotal,
								PlMain.Sono,Customer.CustName,ArOffset.Custno 
				FROM	Aroffset,PlMain,Customer
				WHERE	ArOffset.Custno=Customer.CustNo 
						AND ArOffset.Invno =Plmain.InvoiceNo
						AND EXISTS  (SELECT 1 FROM ArCredit A2 WHERE A2.Rec_Advice = @lcRecord and A2.Custno=Aroffset.Custno and  Plmain.InvoiceNo=A2.InvNo)		
			
				UNION
			
				-- write off
				SELECT DISTINCT 'Write-Off:'+ArWOUnique AS Rec_Advice,WoDate AS Rec_date,Wo_Amt AS Rec_Amount,AcctsRec.Invno,
						PlMain.InvDate,CAST(0.00 as Numeric(20,2)) as InvTotal,PlMain.SONO,Customer.CustName,AcctsRec.Custno
				FROM	Ar_wo,PlMain,Customer,AcctsRec
				WHERE	AcctsRec.Custno=Customer.CustNo 
						AND AcctsRec.Invno =PlMain.InvoiceNo
						AND ACCTSREC.UNIQUEAR = AR_WO.UniqueAR
						AND  EXISTS  (SELECT 1 FROM ArCredit A2 WHERE A2.Rec_Advice = @lcRecord and A2.Custno=ACCTSREC.Custno and  Plmain.InvoiceNo=A2.InvNo) 
				) t1
		ORDER BY 7,4,2
	END

	--10/08/2012 DRP:  in the below section is where I added code to pull form the @InvDtl table above.  
		IF (@lcSelect='By Invoice Number')
	BEGIN
		select	isnull(t1.Rec_Advice,CAST( '' as CHAR(10))) as Rec_advice, t1.Rec_Date, isnull(t1.Rec_Amount,0.00) as Rec_amount, I1.InvNo, I1.InvDate, I1.SoNo,I1.Custname,I1.Custno,
				CASE WHEN ROW_NUMBER() OVER(Partition by i1.custno,I1.invno Order by rec_date)=1 Then I1.InvTotal ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotal
				,cast(rtrim(@lcSelect)+':  '+rtrim(@lcRecord)as CHAR(35)) as RecSelected	--10/10/2014 DRP:  Added to be used in QuickView
		from	@InvDtl as I1 
				left outer join(
								SELECT Rec_Advice, Rec_Date, Rec_Amount, Plmain.InvoiceNo as InvNo, InvDate, InvTotal, SoNo,Customer.Custname,A1.Custno
								FROM ArCredit A1, PlMain, Customer
								WHERE A1.CustNo = Customer.CustNo 
								AND PlMain.InvoiceNo = A1.InvNo 
								AND EXISTS  (SELECT 1 FROM ArCredit A2 WHERE A2.invno = dbo.padl(@lcRecord,10,'0') and A2.Custno=A1.Custno and A1.InvNo=A2.InvNo)
							
								UNION
							
								--offset
								SELECT DISTINCT 'Offset:'+Uniq_ArOff AS Rec_Advice,date AS Rec_date,-Amount AS Rec_Amount,Invno,InvDate
									,plmain.invtotal
								--01/11/2012, DRP	--,CAST(0.00 as Numeric(20,2)) as InvTotal,
									,PlMain.Sono,Customer.CustName,ArOffset.Custno 
								FROM Aroffset,PlMain,Customer
								WHERE ArOffset.Custno=Customer.CustNo 
								AND ArOffset.Invno =Plmain.InvoiceNo
								AND EXISTS  (SELECT 1 FROM acctsrec a2 WHERE A2.INVNO =dbo.padl(@lcRecord,10,'0') and A2.Custno=Aroffset.Custno and Plmain.InvoiceNo=A2.InvNo)	
								--01/11/2012, DRP  --AND EXISTS  (SELECT 1 FROM ArCredit A2 WHERE A2.Invno= dbo.padl(@lcRecord,10,'0') and A2.Custno=Aroffset.Custno and  Plmain.InvoiceNo=A2.InvNo)				
							
								UNION

								-- write off
								SELECT DISTINCT 'Write-Off:'+ArWOUnique AS Rec_Advice,WoDate AS Rec_date,Wo_Amt AS Rec_Amount,
								AcctsRec.Invno,PlMain.InvDate,ACCTSREC.INVTOTAL
								-- 01/11/2012, DRP	--,CAST(0.00 as Numeric(20,2)) as InvTotal
								,Plmain.Sono,Customer.CustName,AcctsRec.Custno
								FROM Ar_wo,PlMain,Customer,acctsrec
								WHERE Acctsrec.Custno=Customer.CustNo 
								AND AcctsRec.Invno =PlMain.InvoiceNo
								AND ACCTSREC.UNIQUEAR  = Ar_wo.UniqueAr
								and exists (select 1 from acctsrec A2 where A2.INVNO = dbo.padl(@lcRecord,10,'0') and ar_wo.UniqueAR = a2.UNIQUEAR )
								-- 01/11/2012, DRP  --AND  EXISTS  (SELECT 1 FROM ArCredit A2 WHERE A2.Invno = dbo.padl(@lcRecord,10,'0') and A2.Custno=ACCTSREC.Custno and  Plmain.InvoiceNo=A2.InvNo) 
								) t1  on I1.InvNo = t1.InvNo
		where	I1.InvNo = dbo.padl(@lcRecord,10,'0')
		ORDER BY 7,4,2;
	END

	--10/08/2012 DRP:  in the below section is where I added code to pull form the @InvDtl table above. 
	IF (@lcSelect='By Sales Order')
	BEGIN
		select	isnull(t1.Rec_Advice,CAST( '' as CHAR(10))) as Rec_advice, t1.Rec_Date, isnull(t1.Rec_Amount,0.00) as Rec_amount, I1.InvNo, I1.InvDate, I1.SoNo,I1.Custname,I1.Custno,
				CASE WHEN ROW_NUMBER() OVER(Partition by I1.custno,I1.invno Order by rec_date)=1 Then I1.INVTOTAL ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotal
				,cast(rtrim(@lcSelect)+':  '+rtrim(@lcRecord)as CHAR(35)) as RecSelected	--10/10/2014 DRP:  Added to be used in QuickView
		from	@InvDtl as I1 
				left outer join (
								SELECT	Rec_Advice, Rec_Date, Rec_Amount, Plmain.InvoiceNo as InvNo, InvDate, InvTotal, SoNo,Customer.Custname,A1.Custno
								FROM	ArCredit A1, PlMain, Customer
								WHERE	A1.CustNo = Customer.CustNo 
										AND PlMain.InvoiceNo = A1.InvNo 
										AND EXISTS  (SELECT 1 FROM Plmain P2 WHERE P2.Sono = dbo.padl(@lcRecord,10,'0') and P2.Custno=A1.Custno and A1.InvNo=P2.Invoiceno)
									
							
								UNION
							
							--offset
							SELECT DISTINCT 'Offset:'+Uniq_ArOff AS Rec_Advice,date AS Rec_date,-Amount AS Rec_Amount,Invno,InvDate,PLMAIN.INVTOTAL
							-- 01/11/2012, DRP	,CAST(0.00 as Numeric(20,2)) as InvTotal,
									,PlMain.Sono,Customer.CustName,ArOffset.Custno
							FROM	Aroffset,PlMain,Customer
							WHERE	ArOffset.Custno=Customer.CustNo 
									AND ArOffset.Invno =Plmain.InvoiceNo
									AND EXISTS  (SELECT 1 FROM Plmain P2 WHERE P2.Sono = dbo.padl(@lcRecord,10,'0') and P2.Custno=ArOffset.Custno and Aroffset.InvNo=P2.Invoiceno)
								
						
							UNION
						
							-- write off
							SELECT DISTINCT 'Write-Off:'+ArWOUnique AS Rec_Advice,WoDate AS Rec_date,Wo_Amt AS Rec_Amount,
									AcctsRec.Invno,PlMain.InvDate,PLMAIN.INVTOTAL
							--01/11/2012, DRP:  ,CAST(0.00 as Numeric(20,2)) as InvTotal
									,PlMain.Sono,Customer.CustName,AcctsRec.Custno
							FROM	Ar_wo,PlMain,Customer,AcctsRec
							WHERE	AcctsRec.Custno=Customer.CustNo 
									AND AcctsRec.Invno =PlMain.InvoiceNo
									AND ACCTSREC.UNIQUEAR=AR_WO.UniqueAr
									AND  EXISTS  (SELECT 1 FROM Plmain P2 WHERE P2.Sono = dbo.padl(@lcRecord,10,'0') and P2.Custno=Acctsrec.Custno and Acctsrec.InvNo=P2.Invoiceno)
								
							) t1 on I1.InvNo = t1.InvNo
		where I1.sono = dbo.padl(@lcRecord,10,'0')
		ORDER BY 7,4,2;
	END

	END
ELSE
-- FC installed
	BEGIN
	--10/08/2012 DRP:  this table was added in the situation that the invoice exist but no credits yet applied.  This table will hold all of the AR invoice information 
	-- 03/01/16 VL added InvTotalFC and Currency
	-- 01/13/17 VL added functional currency fields
	declare @InvDtlFC as table (InvNo char(10),InvDate smalldatetime,SoNo char(10),CustName char(35),Custno char(10),InvTotal numeric(20,2), InvTotalFC numeric(20,2), Fchist_key char(10),
			InvTotalPR numeric(20,2), TSymbol char(3), PSymbol char(3), FSymbol char(3))

	--10/08/2012 DRP:  This will populate the @InvDtl table above with all of the Invoice information
	insert into @InvDtlFC select	invno,acctsrec.INVDATE,sono,custname,acctsrec.custno,acctsrec.INVTOTAL, acctsrec.InvtotalFC, acctsrec.Fchist_key, 
								-- 01/13/17 VL added functional currency fields
								acctsrec.InvtotalPR,TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
								--Fcused.Symbol AS Currency
						from	ACCTSREC
							-- 01/13/17 VL changed criteria to get 3 currencies
							INNER JOIN Fcused PF ON ACCTSREC.PrFcused_uniq = PF.Fcused_uniq
							INNER JOIN Fcused FF ON ACCTSREC.FuncFcused_uniq = FF.Fcused_uniq			
							INNER JOIN Fcused TF ON ACCTSREC.Fcused_uniq = TF.Fcused_uniq								
								inner join CUSTOMER on acctsrec.CUSTNO = customer.CUSTNO
								inner join PLMAIN on acctsrec.INVNO = plmain.INVOICENO
						WHERE	1 = case when ACCTSREC.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end	--10/10/2014 drp:  Added

-- 03/02/2016 VL added InvTotal*dbo.fn_CalculateFCRateVariance(FcHist_key) to re-calculate HC with latest rate
	if (@lcSelect='By Customer Check Number')
	BEGIN
		select	t1.Rec_Advice, t1.Rec_Date, t1.Rec_Amount, t1.InvNo, t1.InvDate, t1.SoNo,t1.Custname,t1.Custno,
				--CASE WHEN ROW_NUMBER() OVER(Partition by custno,invno Order by rec_date)=1 Then InvTotal ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotal
				CASE WHEN ROW_NUMBER() OVER(Partition by custno,invno Order by rec_date)=1 Then CAST(INVTOTAL*dbo.fn_CalculateFCRateVariance(FcHist_key,'F') as numeric(20,2)) ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotal
				,cast(rtrim(@lcSelect)+':  '+rtrim(@lcRecord)as CHAR(35)) as RecSelected	--10/10/2014 DRP:  Added to be used in QuickView
				,t1.Rec_AmountFC
				,CASE WHEN ROW_NUMBER() OVER(Partition by custno,invno Order by rec_date)=1 Then InvTotalFC ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotalFC
				-- 01/13/17 VL added functional currency fields
				,t1.Rec_AmountPR
				,CASE WHEN ROW_NUMBER() OVER(Partition by custno,invno Order by rec_date)=1 Then CAST(INVTOTALPR*dbo.fn_CalculateFCRateVariance(FcHist_key,'P') as numeric(20,2)) ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotalPR
		from	(
				-- 01/13/17 VL added functional currency fields
				SELECT	Rec_Advice, Rec_Date, Rec_Amount, Plmain.InvoiceNo as InvNo, InvDate, InvTotal, SoNo,Customer.Custname,A1.Custno, Rec_AmountFC, InvTotalFC, PlMain.Fchist_key,
						Rec_AmountPR, InvTotalPR
				FROM	ArCredit A1, PlMain, Customer
				WHERE	A1.CustNo = Customer.CustNo 
						AND PlMain.InvoiceNo = A1.InvNo 
						AND EXISTS  (SELECT 1 FROM ArCredit A2 WHERE A2.Rec_Advice = @lcRecord and A2.Custno=A1.Custno and A1.InvNo=A2.InvNo)
					
				UNION

				--offset
				-- 01/13/17 VL added functional currency fields
				SELECT DISTINCT	'Offset:'+Uniq_ArOff AS Rec_Advice,date AS Rec_date,-Amount AS Rec_Amount,Invno,InvDate,CAST(0.00 as Numeric(20,2)) as InvTotal,
								PlMain.Sono,Customer.CustName,ArOffset.Custno,-AmountFC AS Rec_AmountFC, CAST(0.00 as Numeric(20,2)) as InvTotalFC, PlMain.Fchist_key,
								-AmountPR AS Rec_AmountPR, CAST(0.00 as Numeric(20,2)) as InvTotalPR
				FROM	Aroffset,PlMain,Customer
				WHERE	ArOffset.Custno=Customer.CustNo 
						AND ArOffset.Invno =Plmain.InvoiceNo
						AND EXISTS  (SELECT 1 FROM ArCredit A2 WHERE A2.Rec_Advice = @lcRecord and A2.Custno=Aroffset.Custno and  Plmain.InvoiceNo=A2.InvNo)		
			
				UNION
			
				-- write off
				-- 01/13/17 VL added functional currency fields
				SELECT DISTINCT 'Write-Off:'+ArWOUnique AS Rec_Advice,WoDate AS Rec_date,Wo_Amt AS Rec_Amount,AcctsRec.Invno,
						PlMain.InvDate,CAST(0.00 as Numeric(20,2)) as InvTotal,PlMain.SONO,Customer.CustName,AcctsRec.Custno, Wo_AmtFC AS Rec_AmountFC, 
						CAST(0.00 as Numeric(20,2)) as InvTotalFC, PlMain.Fchist_key,
						Wo_AmtPR AS Rec_AmountPR,CAST(0.00 as Numeric(20,2)) as InvTotalPR
				FROM	Ar_wo,PlMain,Customer,AcctsRec
				WHERE	AcctsRec.Custno=Customer.CustNo 
						AND AcctsRec.Invno =PlMain.InvoiceNo
						AND ACCTSREC.UNIQUEAR = AR_WO.UniqueAR
						AND  EXISTS  (SELECT 1 FROM ArCredit A2 WHERE A2.Rec_Advice = @lcRecord and A2.Custno=ACCTSREC.Custno and  Plmain.InvoiceNo=A2.InvNo) 
				) t1
		ORDER BY 7,4,2
	END

	--10/08/2012 DRP:  in the below section is where I added code to pull form the @InvDtl table above.  
		IF (@lcSelect='By Invoice Number')
	BEGIN
		select	isnull(t1.Rec_Advice,CAST( '' as CHAR(10))) as Rec_advice, t1.Rec_Date, isnull(t1.Rec_Amount,0.00) as Rec_amount, I1.InvNo, I1.InvDate, I1.SoNo,I1.Custname,I1.Custno,
				--CASE WHEN ROW_NUMBER() OVER(Partition by i1.custno,I1.invno Order by rec_date)=1 Then I1.InvTotal ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotal
				CASE WHEN ROW_NUMBER() OVER(Partition by i1.custno,I1.invno Order by rec_date)=1 Then CAST(I1.INVTOTAL*dbo.fn_CalculateFCRateVariance(I1.FcHist_key,'F') as numeric(20,2)) ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotal
				,cast(rtrim(@lcSelect)+':  '+rtrim(@lcRecord)as CHAR(35)) as RecSelected	--10/10/2014 DRP:  Added to be used in QuickView
				,isnull(t1.Rec_AmountFC,0.00) as Rec_amountFC
				,CASE WHEN ROW_NUMBER() OVER(Partition by i1.custno,I1.invno Order by rec_date)=1 Then I1.InvTotalFC ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotalFC
				-- 01/13/17 VL added functional currency fields 
				,isnull(t1.Rec_AmountPR,0.00) as Rec_amountPR
				,CASE WHEN ROW_NUMBER() OVER(Partition by i1.custno,I1.invno Order by rec_date)=1 Then CAST(I1.INVTOTALPR*dbo.fn_CalculateFCRateVariance(I1.FcHist_key,'P') as numeric(20,2)) ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotalPR
		from	@InvDtlFC as I1 
				left outer join(
								-- 01/13/17 VL added functional currency fields 
								SELECT Rec_Advice, Rec_Date, Rec_Amount, Plmain.InvoiceNo as InvNo, InvDate, InvTotal, SoNo,Customer.Custname,A1.Custno,Rec_AmountFC,
									InvTotalFC, Plmain.Fchist_key,Rec_AmountPR,InvTotalPR
								FROM ArCredit A1, PlMain, Customer
								WHERE A1.CustNo = Customer.CustNo 
								AND PlMain.InvoiceNo = A1.InvNo 
								AND EXISTS  (SELECT 1 FROM ArCredit A2 WHERE A2.invno = dbo.padl(@lcRecord,10,'0') and A2.Custno=A1.Custno and A1.InvNo=A2.InvNo)
							
								UNION
							
								--offset
								-- 01/13/17 VL added functional currency fields 
								SELECT DISTINCT 'Offset:'+Uniq_ArOff AS Rec_Advice,date AS Rec_date,-Amount AS Rec_Amount,Invno,InvDate
									,plmain.invtotal
								--01/11/2012, DRP	--,CAST(0.00 as Numeric(20,2)) as InvTotal,
									,PlMain.Sono,Customer.CustName,ArOffset.Custno, -AmountFC AS Rec_AmountFC, plmain.invtotalFC, Plmain.Fchist_key
									,-AmountPR AS Rec_AmountPR, plmain.invtotalPR
								FROM Aroffset,PlMain,Customer
								WHERE ArOffset.Custno=Customer.CustNo 
								AND ArOffset.Invno =Plmain.InvoiceNo
								AND EXISTS  (SELECT 1 FROM acctsrec a2 WHERE A2.INVNO =dbo.padl(@lcRecord,10,'0') and A2.Custno=Aroffset.Custno and Plmain.InvoiceNo=A2.InvNo)	
								--01/11/2012, DRP  --AND EXISTS  (SELECT 1 FROM ArCredit A2 WHERE A2.Invno= dbo.padl(@lcRecord,10,'0') and A2.Custno=Aroffset.Custno and  Plmain.InvoiceNo=A2.InvNo)				
							
								UNION

								-- write off
								-- 01/13/17 VL added functional currency fields 
								SELECT DISTINCT 'Write-Off:'+ArWOUnique AS Rec_Advice,WoDate AS Rec_date,Wo_Amt AS Rec_Amount,
								AcctsRec.Invno,PlMain.InvDate,ACCTSREC.INVTOTAL
								-- 01/11/2012, DRP	--,CAST(0.00 as Numeric(20,2)) as InvTotal
								,Plmain.Sono,Customer.CustName,AcctsRec.Custno,Wo_AmtFC AS Rec_AmountFC, ACCTSREC.INVTOTALFC, Plmain.Fchist_key
								,Wo_AmtPR AS Rec_AmountPR, ACCTSREC.INVTOTALPR
								FROM Ar_wo,PlMain,Customer,acctsrec
								WHERE Acctsrec.Custno=Customer.CustNo 
								AND AcctsRec.Invno =PlMain.InvoiceNo
								AND ACCTSREC.UNIQUEAR  = Ar_wo.UniqueAr
								and exists (select 1 from acctsrec A2 where A2.INVNO = dbo.padl(@lcRecord,10,'0') and ar_wo.UniqueAR = a2.UNIQUEAR )
								-- 01/11/2012, DRP  --AND  EXISTS  (SELECT 1 FROM ArCredit A2 WHERE A2.Invno = dbo.padl(@lcRecord,10,'0') and A2.Custno=ACCTSREC.Custno and  Plmain.InvoiceNo=A2.InvNo) 
								) t1  on I1.InvNo = t1.InvNo
		where	I1.InvNo = dbo.padl(@lcRecord,10,'0')
		ORDER BY 7,4,2;
	END

	--10/08/2012 DRP:  in the below section is where I added code to pull form the @InvDtl table above. 
	IF (@lcSelect='By Sales Order')
	BEGIN
		select	isnull(t1.Rec_Advice,CAST( '' as CHAR(10))) as Rec_advice, t1.Rec_Date, isnull(t1.Rec_Amount,0.00) as Rec_amount, I1.InvNo, I1.InvDate, I1.SoNo,I1.Custname,I1.Custno,
				--CASE WHEN ROW_NUMBER() OVER(Partition by I1.custno,I1.invno Order by rec_date)=1 Then I1.INVTOTAL ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotal
				CASE WHEN ROW_NUMBER() OVER(Partition by I1.custno,I1.invno Order by rec_date)=1 Then CAST(I1.INVTOTAL*dbo.fn_CalculateFCRateVariance(I1.FcHist_key,'F') as numeric(20,2)) ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotal
				,cast(rtrim(@lcSelect)+':  '+rtrim(@lcRecord)as CHAR(35)) as RecSelected	--10/10/2014 DRP:  Added to be used in QuickView
				,isnull(t1.Rec_AmountFC,0.00) as Rec_amountFC
				,CASE WHEN ROW_NUMBER() OVER(Partition by I1.custno,I1.invno Order by rec_date)=1 Then I1.INVTOTALFC ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotalFC
				-- 01/13/17 VL added functional currency fields 
				,isnull(t1.Rec_AmountPR,0.00) as Rec_amountPR
				,CASE WHEN ROW_NUMBER() OVER(Partition by I1.custno,I1.invno Order by rec_date)=1 Then CAST(I1.INVTOTALPR*dbo.fn_CalculateFCRateVariance(I1.FcHist_key,'P') as numeric(20,2)) ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotalPR
		from	@InvDtlFC as I1 
				left outer join (
								-- 01/13/17 VL added functional currency fields 
								SELECT	Rec_Advice, Rec_Date, Rec_Amount, Plmain.InvoiceNo as InvNo, InvDate, InvTotal, SoNo,Customer.Custname,A1.Custno,Rec_AmountFC
									,InvTotalFC, Plmain.Fchist_key,Rec_AmountPR,InvTotalPR
								FROM	ArCredit A1, PlMain, Customer
								WHERE	A1.CustNo = Customer.CustNo 
										AND PlMain.InvoiceNo = A1.InvNo 
										AND EXISTS  (SELECT 1 FROM Plmain P2 WHERE P2.Sono = dbo.padl(@lcRecord,10,'0') and P2.Custno=A1.Custno and A1.InvNo=P2.Invoiceno)
									
							
								UNION
							
							--offset
							-- 01/13/17 VL added functional currency fields 
							SELECT DISTINCT 'Offset:'+Uniq_ArOff AS Rec_Advice,date AS Rec_date,-Amount AS Rec_Amount,Invno,InvDate,PLMAIN.INVTOTAL
							-- 01/11/2012, DRP	,CAST(0.00 as Numeric(20,2)) as InvTotal,
									,PlMain.Sono,Customer.CustName,ArOffset.Custno,-AmountFC AS Rec_AmountFC, PLMAIN.INVTOTALFC, Plmain.Fchist_key
									,-AmountPR AS Rec_AmountPR, PLMAIN.INVTOTALPR
							FROM	Aroffset,PlMain,Customer
							WHERE	ArOffset.Custno=Customer.CustNo 
									AND ArOffset.Invno =Plmain.InvoiceNo
									AND EXISTS  (SELECT 1 FROM Plmain P2 WHERE P2.Sono = dbo.padl(@lcRecord,10,'0') and P2.Custno=ArOffset.Custno and Aroffset.InvNo=P2.Invoiceno)
								
						
							UNION
						
							-- write off
							-- 01/13/17 VL added functional currency fields 
							SELECT DISTINCT 'Write-Off:'+ArWOUnique AS Rec_Advice,WoDate AS Rec_date,Wo_Amt AS Rec_Amount,
									AcctsRec.Invno,PlMain.InvDate,PLMAIN.INVTOTAL
							--01/11/2012, DRP:  ,CAST(0.00 as Numeric(20,2)) as InvTotal
									,PlMain.Sono,Customer.CustName,AcctsRec.Custno,Wo_AmtFC AS Rec_AmountFC,PLMAIN.INVTOTALFC, Plmain.Fchist_key
									,Wo_AmtPR AS Rec_AmountPR,PLMAIN.INVTOTALPR
							FROM	Ar_wo,PlMain,Customer,AcctsRec
							WHERE	AcctsRec.Custno=Customer.CustNo 
									AND AcctsRec.Invno =PlMain.InvoiceNo
									AND ACCTSREC.UNIQUEAR=AR_WO.UniqueAr
									AND  EXISTS  (SELECT 1 FROM Plmain P2 WHERE P2.Sono = dbo.padl(@lcRecord,10,'0') and P2.Custno=Acctsrec.Custno and Acctsrec.InvNo=P2.Invoiceno)
								
							) t1 on I1.InvNo = t1.InvNo
		where I1.sono = dbo.padl(@lcRecord,10,'0')
		ORDER BY 7,4,2;
	END
	END
END-- END of if FC installed
END