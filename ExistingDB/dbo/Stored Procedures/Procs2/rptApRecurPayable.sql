-- =============================================
-- Author:		Debbie	
-- Create date:	10/29/2015
-- Report:		ap_rep5 and ap_rep6
-- Description:	Recurring Payable Detail and Summary                         
-- Modifaction: 10/29/15 DRP:  did not implement the row over partition on the INVAMOUNT field.  We will see if the users request it. 
--				03/23/16 VL:   Added FC code
--				04/08/16 VL:   Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--				02/06/17 VL:   Added functional currency code
-- 07/13/18 VL changed supname from char(30) to char(50)
-- =============================================
CREATE PROCEDURE [dbo].[rptApRecurPayable] 

--declare

@lcUniqSupNo as varchar(max) = 'All'	
,@lcPmtType as char(5) = 'Fixed'		--Fixed or Open 
,@lcStatus as char(10) = 'Current'		--Closed or Current
,@lcRptType as char(10) = 'Detailed'	--(Detailed or Summary)  Added just in case in the future the uses want me to change the quickview results and I do use this param in the report results
,@lcSort as char(10) = 'Reference'		--Invoice or Reference
,@userId uniqueidentifier= null

as 
begin

/*SUPPLIER LIST*/
	---- SET NOCOUNT ON added to prevent extra result sets from
	---- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE  @tSupplier tSupplier
	declare @tSupNo as table (Uniqsupno char (10))
	-- get list of Suppliers for @userid with access
	INSERT INTO @tSupplier EXEC aspmnxSP_GetSuppliers4user @userid, NULL, 'All';
	
	--- have to check for all suppliers @lcUniqSupNo for all no need to run [fn_simpleVarcharlistToTable], no data will be retuned
	IF @lcUniqSupNo is not null and @lcUniqSupNo <>'' and @lcUniqSupNo<>'All'
		insert into @tSupNo select * from dbo.[fn_simpleVarcharlistToTable](@lcUniqSupNo,',')
			where CAST (id as CHAR(10)) in (select Uniqsupno from @tSupplier)
	ELSE
	--- empty or null customer or part number means no selection were made
	IF  @lcUniqSupNo='All'	
	BEGIN
		INSERT INTO @tSupNo SELECT UniqSupno FROM @tSupplier	
	
	END

/*SELECT STATEMENT*/

-- 03/23/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
BEGIN
IF @lFCInstalled = 0
	BEGIN
	-- 07/13/18 VL changed supname from char(30) to char(50)
	declare @Results as table (SUPNAME CHAR(50),INVNO CHAR(20),PONUM CHAR(15),FIRSTPMT SMALLDATETIME,PMTTYPE CHAR(5),PERIOD CHAR (12),NO_INVCD NUMERIC(4,0),MAXPMTSCAL NUMERIC(4,0)
							,INVAMOUNT NUMERIC(12,2),DESCRIPT CHAR(30),ITEM_NO NUMERIC(10,0),ITEM_DESC CHAR (25),QTY_EACH NUMERIC (8,2),PRICE_EACH NUMERIC(13,5)
							,ITEM_TOTAL NUMERIC(10,2),GL_NBR CHAR(13),IS_CLOSED BIT,UNIQRECUR CHAR (10),UNIQSUPNO CHAR(10))
	; WITH zRecur as 
	(
	select	supname,R.invno,R.PONUM,R.FIRSTPMT,R.PMTTYPE,R.PERIOD,R.NO_INVCD,CASE WHEN R.MAXPMTS > 0 THEN R.MAXPMTS-R.NO_INVCD ELSE 0 END AS MaxPmtsCal,r.invamount,R.descript
			,D.ITEM_NO,D.ITEM_DESC,D.QTY_EACH,D.PRICE_EACH,D.ITEM_TOTAL,D.GL_NBR,r.IS_CLOSED,R.UNIQRECUR,r.UNIQSUPNO
	from	aprecur R
			inner join supinfo on R.uniqsupno = supinfo.uniqsupno
			inner join aprecdet D on R.uniqrecur = D.uniqrecur
	WHERE	(@lcUniqSupNo = 'All' or exists (select 1 from @tSupNo T inner join supinfo S on t.Uniqsupno = S.UNIQSUPNO where s.UNIQSUPNO = r.UNIQSUPNO))
			and @lcPmtType = R.PMTTYPE
			and 1 = case when @lcStatus = 'Closed' and is_closed = 1 then  1 else case when @lcStatus = 'Current' and is_closed = 0 then 1 else 0 end end 
	)

	insert into @Results select * from zRecur



	if @lcRptType = 'Detailed'
		Begin
			if @lcSort = 'Invoice' 
				Begin
					select * from @Results order by SupName,INVNO
				End

			else if @lcSort = 'Reference'
				BEGIN
					SELECT * FROM @Results ORDER BY SUPNAME,PONUM
				END
		End
	else if  @lcRptType = 'Summary'
		Begin
			if @lcSort = 'Invoice' 
				Begin
					select SUPNAME,INVNO,PONUM,FIRSTPMT,PMTTYPE,PERIOD,NO_INVCD,MAXPMTSCAL,INVAMOUNT,DESCRIPT from @Results
					GROUP BY SUPNAME,INVNO,PONUM,FIRSTPMT,PMTTYPE,PERIOD,NO_INVCD,MAXPMTSCAL,INVAMOUNT,DESCRIPT
				End

			else if @lcSort = 'Reference'
				BEGIN
					select SUPNAME,INVNO,PONUM,FIRSTPMT,PMTTYPE,PERIOD,NO_INVCD,MAXPMTSCAL,INVAMOUNT,DESCRIPT from @Results
					GROUP BY SUPNAME,PONUM,INVNO,PONUM,FIRSTPMT,PMTTYPE,PERIOD,NO_INVCD,MAXPMTSCAL,INVAMOUNT,DESCRIPT
				END
		End
	END
ELSE
-- FC installed
	BEGIN
	-- 07/13/18 VL changed supname from char(30) to char(50)
	declare @ResultsFC as table (SUPNAME CHAR(50),INVNO CHAR(20),PONUM CHAR(15),FIRSTPMT SMALLDATETIME,PMTTYPE CHAR(5),PERIOD CHAR (12),NO_INVCD NUMERIC(4,0),MAXPMTSCAL NUMERIC(4,0)
							,INVAMOUNT NUMERIC(12,2),DESCRIPT CHAR(30),ITEM_NO NUMERIC(10,0),ITEM_DESC CHAR (25),QTY_EACH NUMERIC (8,2),PRICE_EACH NUMERIC(13,5)
							,ITEM_TOTAL NUMERIC(10,2),GL_NBR CHAR(13),IS_CLOSED BIT,UNIQRECUR CHAR (10),UNIQSUPNO CHAR(10)
							,INVAMOUNTFC NUMERIC(12,2),PRICE_EACHFC NUMERIC(13,5),ITEM_TOTALFC NUMERIC(10,2)
							-- 02/06/17 VL comment out currency and added functional currency code
							--, Currency char(3))
							,INVAMOUNTPR NUMERIC(12,2),PRICE_EACHPR NUMERIC(13,5),ITEM_TOTALPR NUMERIC(10,2), TSymbol char(3), PSymbol char(3), Fsymbol char(3))

	; WITH zRecurFC as 
	(
	select	supname,R.invno,R.PONUM,R.FIRSTPMT,R.PMTTYPE,R.PERIOD,R.NO_INVCD,CASE WHEN R.MAXPMTS > 0 THEN R.MAXPMTS-R.NO_INVCD ELSE 0 END AS MaxPmtsCal,r.invamount,R.descript
			,D.ITEM_NO,D.ITEM_DESC,D.QTY_EACH,D.PRICE_EACH,D.ITEM_TOTAL,D.GL_NBR,r.IS_CLOSED,R.UNIQRECUR,r.UNIQSUPNO,r.invamountFC,D.PRICE_EACHFC,D.ITEM_TOTALFC
			-- 02/06/17 VL comment out currency and added functional currency code
			--,Fcused.Symbol AS Currency
			,r.invamountPR,D.PRICE_EACHPR,D.ITEM_TOTALPR, TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	from	aprecur R 
			-- 02/06/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON R.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON R.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON R.Fcused_uniq = TF.Fcused_uniq			
			inner join supinfo on R.uniqsupno = supinfo.uniqsupno
			inner join aprecdet D on R.uniqrecur = D.uniqrecur
	WHERE	(@lcUniqSupNo = 'All' or exists (select 1 from @tSupNo T inner join supinfo S on t.Uniqsupno = S.UNIQSUPNO where s.UNIQSUPNO = r.UNIQSUPNO))
			and @lcPmtType = R.PMTTYPE
			and 1 = case when @lcStatus = 'Closed' and is_closed = 1 then  1 else case when @lcStatus = 'Current' and is_closed = 0 then 1 else 0 end end 
	)

	insert into @ResultsFC select * from zRecurFC



	if @lcRptType = 'Detailed'
		Begin
			if @lcSort = 'Invoice' 
				Begin
					-- 02/06/17 VL added to sort by TSymbol, not currency
					select * from @ResultsFC order by TSymbol,SupName,INVNO
				End

			else if @lcSort = 'Reference'
				BEGIN
					SELECT * FROM @ResultsFC ORDER BY TSymbol, SUPNAME,PONUM
				END
		End
	else if  @lcRptType = 'Summary'
		Begin
			if @lcSort = 'Invoice' 
				Begin
					-- 02/06/17 VL comment out currency and added functional currency code, also added to sort by TSymbol, not currency
					select SUPNAME,INVNO,PONUM,FIRSTPMT,PMTTYPE,PERIOD,NO_INVCD,MAXPMTSCAL,INVAMOUNT,DESCRIPT,INVAMOUNTFC, INVAMOUNTPR, TSymbol, PSymbol, FSymbol from @ResultsFC
					GROUP BY SUPNAME,INVNO,PONUM,FIRSTPMT,PMTTYPE,PERIOD,NO_INVCD,MAXPMTSCAL,INVAMOUNT,DESCRIPT,INVAMOUNTFC, INVAMOUNTPR, TSymbol, PSymbol, FSymbol
				End

			else if @lcSort = 'Reference'
				BEGIN
					-- 02/06/17 VL comment out currency and added functional currency code, also added to sort by TSymbol, not currency
					select SUPNAME,INVNO,PONUM,FIRSTPMT,PMTTYPE,PERIOD,NO_INVCD,MAXPMTSCAL,INVAMOUNT,DESCRIPT,INVAMOUNTFC,INVAMOUNTPR, TSymbol, PSymbol, FSymbol from @ResultsFC
					GROUP BY SUPNAME,PONUM,INVNO,PONUM,FIRSTPMT,PMTTYPE,PERIOD,NO_INVCD,MAXPMTSCAL,INVAMOUNT,DESCRIPT,INVAMOUNTFC, INVAMOUNTPR, TSymbol, PSymbol, FSymbol
				END
		End

	END
END-- End of IF FC installed

end