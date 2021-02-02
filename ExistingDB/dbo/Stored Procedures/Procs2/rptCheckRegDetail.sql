
-- =============================================
-- Author:		Debbie
-- Create date: 01/09/2013
-- Description:	Created for the Check Register Detail and Summary reports within payment scheduling
-- Reports Using Stored Procedure:  ckregdet.rpt  ~ ckregsum.rpt
-- Modifications:    	11/25/2013 DRP:  had to add comma seperator into the procedure for the Supplier Select.  also changed the @lcUniqsupno from char(10) to varchr(max)
--						12/03/2013 YS: have to check for all suppliers @lcUniqSupNo for all no need to run [fn_simpleVarcharlistToTable], no data will be retuned
--						01/22/2014 YS: we found that if the user left All for the supplier that it was incorrectly not displaying the suppliers that were approved for the userid.  It was bringing forward all suppliers regardless if the user was approved for the Userid or not. 
--						07/11/2014 DRP:  Added a new paramter @lcRptType so I could indicate within WebManex if it should display Detailed or Summary results for the QuickView. 
--						12/12/14 DS Added supplier status filter
--						01/30/2015 DRP: needed to change the [inner join apchkdet] to be [left outer join apchkdet] in the situation that they have a large number of invoices on one check and it overflows onto the next physical Check form. 
--						08/27/15 DRP:  Needed to add order by invno to the Row Over Partition in the Detail section.  otherwise it was not display the CheckAmt correctly on the reports
--						08/31/15 DRP:  needed to change the sort order at the end of the resuls from <<ORDER BY	Checkno,invno,Apchkdet.item_no>>  to be <<ORDER BY	Checkno,status,invno,Apchkdet.item_no>>>  otherwise the Void and Void Entry records would be mixed together. 
--						06/14/16 DRP:  Need to and the CheckAmtFC to the declared @ChkHd table in order to match the changes that were made to the [CheckRegView]
--						02/06/17 VL:   Added functional currency code in @ChkHd, but I didn't added functional fields and currency symbols for now
-- 08/31/17 VL added functional currency code
-- 09/04/17 VL added functional currency code for detailed report
-- 09/05/17 VL minor fix for aprpayPR
-- 07/13/18 VL changed supname from char(30) to char(50) 
-- 12/05/19 VL:  If user leave @lcBk_Uniq blank, the report didn't retuan any result, so add 'All' if @lcBk_Uniq is blank to make it show all banks
-- 04/22/20 VL Added ShipTo as RemitTo, request by Paramit, zendesk#6244
-- =============================================
CREATE PROCEDURE [dbo].[rptCheckRegDetail]

--declare
--below are the same Parameters that were delcared on the CheckRegView procedure.  Hopefully these can be passed from he selections made onscreen to the report. 
	@lcDateStart as char(10) = null,
	@lcDateEnd as char(10) = null,
	@lcStartCkNo as char(10)= '',
	@lcEndCkNo as char(10) ='',
	@lcUniqSupNo as varchar(max)='All',
	@lcBk_Uniq as char(10)= 'All',
	@lnStatus as int=1,				--1 =  all transactions, 2 = Printed/OS Only, 3 = Cleared Only, 4 = Printed/OS Or Cleared, 5 = Void Transactions
	@lcRptType as char(10) = 'Detailed',	--07/11/2014 DRP:  (Detailed or Summary)  Added for Quickview results so it knows to display detailed or summary results. 
	@userId as uniqueidentifier = null
	,@supplierStatus varchar(20) = 'All'   
				
as
begin

--11/25/2013 DRP:  added the CSV Start
	---- SET NOCOUNT ON added to prevent extra result sets from
	---- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE  @tSupplier tSupplier
	declare @tSupNo as table (Uniqsupno char (10))
	-- get list of Suppliers for @userid with access
	INSERT INTO @tSupplier EXEC aspmnxSP_GetSuppliers4user @userid, NULL, @supplierStatus;
	
	--- 12/03/2013 YS: have to check for all suppliers @lcUniqSupNo for all no need to run [fn_simpleVarcharlistToTable], no data will be retuned
	IF @lcUniqSupNo is not null and @lcUniqSupNo <>'' and @lcUniqSupNo<>'All'
		insert into @tSupNo select * from dbo.[fn_simpleVarcharlistToTable](@lcUniqSupNo,',')
			where CAST (id as CHAR(10)) in (select Uniqsupno from @tSupplier)
	ELSE
	---- 12/03/2013 YS empty or null customer or part number means no selection were made
	IF  @lcUniqSupNo='All'	
	BEGIN
		INSERT INTO @tSupNo SELECT UniqSupno FROM @tSupplier	
	
	END		 
--11/25/2013 DRP:  added the CSV End

	-- 12/05/19 VL added if @lcBk_Uniq is blank, added 'All' to use all banks
	IF @lcBk_Uniq = ''
		SELECT @lcBk_Uniq = 'All'			

--11/25/2013 DRP:  ADDED UniqSupNo Char(10) to match the [CheckRegView] that was updated	
	--06/14/16 DRP:  Added the CheckAmtFC to match the [CheckRegView] that was updated. 		
--The below table will be used to populate the information from the CheckRegView procedure 
	-- 02/06/17 VL added functional currency fields
	-- 08/31/17 VL added functional currency code
	-- 07/13/18 VL changed supname from char(30) to char(50) 
	-- 04/22/20 VL Added ShipTo as RemitTo, request by Paramit, zendesk#6244
	declare @ChkHd table	(ApChk_uniq char(10),Bank char(35),Bk_acct_no char(15),iCheckno char(10),Checkno char(10),CheckDate smalldatetime,SupName char(50),CheckAmt numeric(12,2)
							,Status char(15), Detail char(6),CheckNote text,ReconcileStatus char(1),ReconciledDate smalldatetime,Uniqsupno char(10),CheckAmtFC numeric(12,2),CheckAmtPR numeric(12,2),
							-- 08/31/17 VL added functional currency code
							Fcused_uniq char(10), FuncFcused_uniq char(10), PRFcusedUniq char(10), FSymbol char(3), TSymbol char(3), PSymbol char(3), RemitTo char(50))

--inserting the information from the CheckRegView into the table above				
	Insert into @ChkHd		exec [CheckRegView] @lcDateStart,@lcDateEnd,@lcStartCkNo,@lcEndCkNo,@lcUniqSupNo,@lcBk_Uniq,@lnStatus	

-- 08/31/17 VL added to separate FC and non FC
IF dbo.fn_IsFCInstalled() = 0
------------------------------
-- FC not installed
------------------------------

	BEGIN
	if (@lcRptType = 'Detailed')
	begin  --&&Detailed Begin
			
	--putting together the CheckRegView (header) and the AP Check detail information. 
		SELECT		c1.ApChk_uniq,c1.Bank,c1.Bk_acct_no,c1.iCheckno,c1.Checkno,c1.CheckDate,c1.SupName
					,case when ROW_NUMBER() over (partition by c1.apchk_uniq order by c1.checkno,Invno) = 1 then CheckAmt else cast(0.00 as numeric(12,2)) end as CheckAmt
					,c1.status,c1.checknote,isnull(Apchkdet.item_no,0)item_no,isnull(Apchkdet.ponum,'')ponum,isnull(Apchkdet.invno,'')invno,Apchkdet.invdate, Apchkdet.due_date
					, isnull(Apchkdet.item_desc,'')item_desc,isnull(Apchkdet.invamount,0.00)invamount,isnull(Apchkdet.disc_tkn,0.00)disc_tkn,isnull(Apchkdet.aprpay,0.00)aprpay
					,isnull(Apchkdet.apchk_uniq,'')apchkdet_uniq,isnull(Apchkdet.itemnote,'')itemnote
					-- 04/22/20 VL Added ShipTo as RemitTo, request by Paramit, zendesk#6244
					,C1.RemitTo
					--,MICSSYS.LIC_NAME
		FROM		@ChkHd as C1 
					left outer join apchkdet on apchkdet.APCHK_UNIQ = c1.ApChk_uniq		--01/30/2015 DRP:  changed from inner join to left outer join
					--cross join micssys
					-- 12/03/13 YS is null means no selection, 'All' means all 
		where		1= case WHEN C1.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
	--01/22/2014 YS: 
				--1= CASE WHEN @lcUniqSupno ='All' THEN 1    -- any supplier
				--		WHEN C1.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
		ORDER BY	Checkno,status,invno,Apchkdet.item_no
	end  --&&Detailed End


	else if (@lcRptType = 'Summary')
	begin --&&Summary Begin

	--putting together the CheckRegView (header) and the AP Check detail information. 
		SELECT		c1.ApChk_uniq,rtrim(c1.Bank) as Bank,c1.Bk_acct_no,c1.iCheckno,c1.Checkno,c1.CheckDate,c1.SupName
					,case when ROW_NUMBER() over (partition by c1.apchk_uniq order by c1.checkno) = 1 then CheckAmt else cast(0.00 as numeric(12,2)) end as CheckAmt
					,isnull(d1.disc_tkn,0.00)disc_tkn,c1.status,c1.checknote
					-- 04/22/20 VL Added ShipTo as RemitTo, request by Paramit, zendesk#6244
					,C1.RemitTo
		FROM		@ChkHd as C1
					left outer join (select apchkdet.APCHK_UNIQ,SUM(disc_tkn)as Disc_tkn from APCHKDET group by apchkdet.APCHK_UNIQ) as D1 on c1.ApChk_uniq = d1.APCHK_UNIQ	--01/30/2015 DRP:  changed from inner join to left outer join
					--inner join apchkdet on apchkdet.APCHK_UNIQ = c1.ApChk_uniq    --07/11/2014 DRP:  replaced with the above. 
					--cross join micssys  --07/11/2014 DRP:  removed from results
					-- 12/03/13 YS is null means no selection, 'All' means all 
		where		1= case WHEN C1.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
		order by	Checkno,status	--08/31/15 DRP:  added

	--01/22/2014 YS: 
				--1= CASE WHEN @lcUniqSupno ='All' THEN 1    -- any supplier
				--		WHEN C1.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
 
	end  --&&Summary End
	END
ELSE
------------------------------
-- FC installed
------------------------------

	BEGIN
	if (@lcRptType = 'Detailed')
		begin  --&&Detailed Begin
			
		--putting together the CheckRegView (header) and the AP Check detail information. 
			SELECT		c1.ApChk_uniq,c1.Bank,c1.Bk_acct_no,c1.iCheckno,c1.Checkno,c1.CheckDate,c1.SupName
						,case when ROW_NUMBER() over (partition by c1.apchk_uniq order by c1.checkno,Invno) = 1 then CheckAmt else cast(0.00 as numeric(12,2)) end as CheckAmt,
						-- 08/31/17 VL added functional currency code
						 FSymbol, case when ROW_NUMBER() over (partition by c1.apchk_uniq order by c1.checkno,Invno) = 1 then CheckAmtFC else cast(0.00 as numeric(12,2)) end as CheckAmtFC, TSymbol,
						 case when ROW_NUMBER() over (partition by c1.apchk_uniq order by c1.checkno,Invno) = 1 then CheckAmtPR else cast(0.00 as numeric(12,2)) end as CheckAmtPR, PSymbol 
						,c1.status,c1.checknote,isnull(Apchkdet.item_no,0)item_no,isnull(Apchkdet.ponum,'')ponum,isnull(Apchkdet.invno,'')invno,Apchkdet.invdate, Apchkdet.due_date
						, isnull(Apchkdet.item_desc,'')item_desc,isnull(Apchkdet.invamount,0.00)invamount,isnull(Apchkdet.disc_tkn,0.00)disc_tkn,isnull(Apchkdet.aprpay,0.00)aprpay,
						-- 09/04/17 VL added functional currency code
						isnull(Apchkdet.invamountFC,0.00)invamountFC,isnull(Apchkdet.disc_tknFC,0.00)disc_tknFC,isnull(Apchkdet.aprpayFC,0.00)aprpayFC,
						isnull(Apchkdet.invamountPR,0.00)invamountPR,isnull(Apchkdet.disc_tknPR,0.00)disc_tknPR,isnull(Apchkdet.aprpayPR,0.00)aprpayPR
						,isnull(Apchkdet.apchk_uniq,'')apchkdet_uniq,isnull(Apchkdet.itemnote,'')itemnote
						-- 04/22/20 VL Added ShipTo as RemitTo, request by Paramit, zendesk#6244
						,C1.RemitTo
						--,MICSSYS.LIC_NAME
			FROM		@ChkHd as C1 
						left outer join apchkdet on apchkdet.APCHK_UNIQ = c1.ApChk_uniq		--01/30/2015 DRP:  changed from inner join to left outer join
						--cross join micssys
						-- 12/03/13 YS is null means no selection, 'All' means all 
			where		1= case WHEN C1.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
		--01/22/2014 YS: 
					--1= CASE WHEN @lcUniqSupno ='All' THEN 1    -- any supplier
					--		WHEN C1.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
			ORDER BY	Checkno,status,invno,Apchkdet.item_no
		end  --&&Detailed End


		else if (@lcRptType = 'Summary')
		begin --&&Summary Begin

		--putting together the CheckRegView (header) and the AP Check detail information. 
			SELECT		c1.ApChk_uniq,rtrim(c1.Bank) as Bank,c1.Bk_acct_no,c1.iCheckno,c1.Checkno,c1.CheckDate,c1.SupName
						,case when ROW_NUMBER() over (partition by c1.apchk_uniq order by c1.checkno) = 1 then CheckAmt else cast(0.00 as numeric(12,2)) end as CheckAmt,
						-- 08/31/17 VL added functional currency code
						 FSymbol, case when ROW_NUMBER() over (partition by c1.apchk_uniq order by c1.checkno) = 1 then CheckAmtFC else cast(0.00 as numeric(12,2)) end as CheckAmtFC, TSymbol,
						 case when ROW_NUMBER() over (partition by c1.apchk_uniq order by c1.checkno) = 1 then CheckAmtPR else cast(0.00 as numeric(12,2)) end as CheckAmtPR, PSymbol
						,isnull(d1.disc_tkn,0.00)disc_tkn,c1.status,c1.checknote
						-- 04/22/20 VL Added ShipTo as RemitTo, request by Paramit, zendesk#6244
						,C1.RemitTo
			FROM		@ChkHd as C1
						left outer join (select apchkdet.APCHK_UNIQ,SUM(disc_tkn)as Disc_tkn from APCHKDET group by apchkdet.APCHK_UNIQ) as D1 on c1.ApChk_uniq = d1.APCHK_UNIQ	--01/30/2015 DRP:  changed from inner join to left outer join
						--inner join apchkdet on apchkdet.APCHK_UNIQ = c1.ApChk_uniq    --07/11/2014 DRP:  replaced with the above. 
						--cross join micssys  --07/11/2014 DRP:  removed from results
						-- 12/03/13 YS is null means no selection, 'All' means all 
			where		1= case WHEN C1.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
			order by	Checkno,status	--08/31/15 DRP:  added

		--01/22/2014 YS: 
					--1= CASE WHEN @lcUniqSupno ='All' THEN 1    -- any supplier
					--		WHEN C1.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
 
		end  --&&Summary End
	END
end