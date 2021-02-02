
-- =============================================
-- Author:		Debbie
-- Create date: 06/05/2013
-- Description:	This Stored Procedure was created for the Reconciled History All Suppliers reports within the PO Reconciliation module 
-- Reports Using Stored Procedure: poinvrp.rpt  
--								   (as of 06/07/2013 I only converted the poinvrp.rpt to crystal per request by users. poinvno.rpt and poinvre.rpt should also be able to use this same procedure but will wait on converted until requested.
-- Modified:	01/28/2014 DRP:  FOUND THAT THIS PROCEDURE SHOULD ALSO HAVE @USERID SO THAT IT WILL ONLY DISPLAY SUPPLIERS THAT THIS USER IS APPROVED TO SEE. 
--							 So I also had to add the @lcUniqSupNo to the procedure along with the @userId
--			12/12/14 DS Added supplier status filter
--			03/19/15 DRP:  Per Request I added the TAX and FREIGHT fields to the results from the sinvoice table.
--			04/17/15 DRP: added the Saveinit to the results per request of an user.  
--			05/27/15 DRP: added the @results table and then added the @lcSort parameter to change the sort order results to match the Cloud Selections.  removed the 'Reconciled Hist. All Supp. sort by Invoice' and 'Reconciled Hist. All Supp. sort by Receiver' from the Cloud tables
--						  This one report should now be covered by this one report "Reconciled History All Suppliers"
--			08/31/15 DRP: needed to increase the saveinit char(4) to be char (8)
-- 10/19/15 YS added back item_desc column for the misc items added during the reconciliation
-- 03/28/16 YS changed some column numbers in the porecdtl table
--			01/25/17 VL:  added functional currency code 
-- 07/16/18 VL changed supname from char(30) to char(50)
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================
CREATE PROCEDURE [dbo].[rptPoReconHistoryAllSup]
	--declare
	@lcDateStart as smalldatetime= null,
	@lcDateEnd as smalldatetime = null,
	@lcUniqSupNo varchar(max) = 'All',     ---NULL or empty - all suppliers, allow CSV --01/28/2014 DRP added
	@userId uniqueidentifier = null		--01/28/2014 DRP Added
	--,@supplierStatus varchar(20) = 'All'
	,@lcSort char (25) = 'By Purchase Order'	--By Purchase Order, By Invoice, By Receiver
		
as 
begin


--01/28/2014 DRP: Newly Added 
	--get list of approved suppliers for this user
	DECLARE  @tSupplier tSupplier
	DECLARE @Supplier TABLE (Uniqsupno char(10))
	-- get list of Suppliers for @userid with access
	INSERT INTO @tSupplier EXEC aspmnxSP_GetSuppliers4user @userid, NULL, 'All'  ;
	--SELECT * FROM @tSupplier	
	-- have to check for all suppliers @lcUniqSupNo for all no need to run [fn_simpleVarcharlistToTable], no data will be retuned
	IF @lcUniqSupNo is not null and @lcUniqSupNo <>'' and @lcUniqSupNo<>'All'
		insert into @Supplier select * from dbo.[fn_simpleVarcharlistToTable](@lcUniqSupNo,',')
				where CAST (id as CHAR(10)) in (select Uniqsupno from @tSupplier)
	ELSE
	---- 12/03/2013 YS empty or null customer or part number means no selection were made
	IF  @lcUniqSupNo='All'	
	BEGIN
		INSERT INTO @Supplier SELECT UniqSupno FROM @tSupplier	
	END		 
--01/28/2014 DRP:  Newly Added End

-- 01/25/17 VL separate FC and non FC
IF dbo.fn_IsFCInstalled() = 0
	BEGIN
	/*05/27/2015 DRP added the @results table*/
	-- 07/16/18 VL changed supname from char(30) to char(50)
	-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
	declare @results as table(supname char(50),PONUM char(15),Conum numeric(3,0),PODATE smalldatetime,receiverno char(10),sinv_uniq char(10),INVNO char(22),INVDATE smalldatetime,RECON_DATE smalldatetime
			,invamount numeric (20,2),sdet_uniq char(10),uniqlnno char(10),Part_no char(35),Revision char(8),PO_desc char(45),RecvQty numeric(20,2), acpt_qty numeric(20,2),costeach numeric(20,5)
			,uniq_key char(10),extension numeric(20,2),TAX numeric(20,2),FREIGHT numeric(20,2),saveinit char(8),LIC_NAME char(40))


	--This section will gather the header information pertaining to the Reconciliation record
	;WITH Header
	as
	(
	select	P.supname,P.PONUM,P.Conum,P.PODATE,sinvoice.receiverno,sinvoice.sinv_uniq,sinvoice.INVNO,sinvoice.INVDATE,sinvoice.RECON_DATE,sinvoice.INVAMOUNT,TAX,FREIGHT,SAVEINIT,micssys.LIC_NAME 
	FROM	SINVOICE 
			CROSS APPLY	(SELECT	distinct Pomain.PONUM,Pomain.Conum,Pomain.PODATE, Supinfo.supname,supinfo.UNIQSUPNO 
						 FROM	POMAIN 
								INNER JOIN Poitems ON Pomain.PONUM=Poitems.PONUM
								INNER JOIN Porecdtl on poitems.UNIQLNNO=porecdtl.UNIQLNNO
								INNER JOIN SUPINFO on Pomain.UNIQSUPNO=supinfo.uniqsupno
						 WHERE	Porecdtl.RECEIVERNO=sinvoice.receiverno) P
			cross apply MICSSYS
	where	sinvoice.recon_date>=@lcdatestart and sinvoice.recon_date<@lcdateend+1
			and 1= case WHEN P.UNIQSUPNO IN (SELECT Uniqsupno FROM @Supplier) THEN 1 ELSE 0  END	--01/28/2014 DRP:  added
	)

	insert into @results

	--I had to insert into the t1 table and then use the partition command below to get the invoice amount to only display once per invoice.  This was to get the totaling correct on the report. 
	select	t1.supname,t1.PONUM,t1.Conum,t1.PODATE,t1.receiverno,t1.sinv_uniq,t1.INVNO,t1.INVDATE,t1.RECON_DATE
			,CASE WHEN ROW_NUMBER() OVER(Partition by t1.sinv_uniq Order by t1.part_no)=1 Then invamount else CAST(0.00 as Numeric(20,2)) END AS invamount
			,t1.sdet_uniq, t1.uniqlnno,t1.Part_no,t1.Revision,t1.PO_desc,t1.ReceivedQty, t1.acpt_qty, t1.costeach,t1.uniq_key,t1.extension,T1.TAX,T1.FREIGHT,t1.saveinit,t1.LIC_NAME


	--the below section will take the header info and join it with the poreceipt/poitem detial.  Then union with the misc items added within the po recon module
	from
	(		
		SELECT	header.supname,header.PONUM,header.Conum,header.PODATE,header.receiverno,header.sinv_uniq,header.INVNO,header.INVDATE,header.RECON_DATE
				,Header.INVAMOUNT 
				,Sinvdetl.sdet_uniq, Sinvdetl.uniqlnno,ISNULL(Inventor.part_no,Poitems.PART_NO) as Part_no,ISNULL(Inventor.Revision,PoItems.REVISION) as Revision,
				--Sinvdetl.item_desc as PO_desc,
				ISNULL(Inventor.DESCRIPT,Poitems.DESCRIPT) as PO_desc,
				-- 03/28/16 YS changed some column numbers in the porecdtl table
				PORECDTL.ReceivedQty, Sinvdetl.acpt_qty, Sinvdetl.costeach,PoItems.uniq_key
				,ROUND(Sinvdetl.acpt_qty*Sinvdetl.costeach,2) AS extension,TAX,FREIGHT,SAVEINIT,header.LIC_NAME
		FROM	SINVDETL 
				INNER JOIN Header ON Header.sInv_Uniq = SInvDetl.Sinv_Uniq 
				INNER JOIN PoREcDtl ON Header.receiverno = PORECDTL.RECEIVERNO  AND Sinvdetl.Uniqlnno=Porecdtl.UNIQLNNO 
				inner join POITEMS ON PORECDTL.UNIQLNNO = POITEMS.Uniqlnno
				LEFT OUTER JOIN Inventor on POITEMS.UNIQ_KEY = INVENTOR.Uniq_Key
			
		UNION
    
		SELECT	header.supname,header.PONUM,header.Conum,header.PODATE,header.receiverno,header.sinv_uniq,header.INVNO,Header.INVDATE,header.RECON_DATE
				,header.invamount
				,Sinvdetl.sdet_uniq, Sinvdetl.uniqlnno,SPACE(25) as Part_no,SPACE(8) as Revision,
				--cast('Misc Item added at Reconciliation' as CHAR(45)) as PO_desc
				--- added back Sinvdetl.item_desc
				Sinvdetl.item_desc as PO_desc
				,CAST(0.00 as numeric(10,2)) as RecvQty,Sinvdetl.acpt_qty, Sinvdetl.costeach,SPACE(10) as uniq_key,ROUND(Sinvdetl.acpt_qty*Sinvdetl.costeach,2) AS extension
				,TAX,FREIGHT,SAVEINIT,header.LIC_NAME
		FROM	Sinvdetl INNER JOIN Header ON Sinvdetl.sinv_uniq=Header.SINV_UNIQ  
		WHERE	UNIQLNNO = ' '
	   )t1
  
	/*05/27/2015 DRP added the different sort orders*/ 
	if ( @lcSort = 'By Purchase Order')
		Begin 
			select * from @results order by SUPNAME,PONUM,INVno,invamount 
		end

	else if ( @lcSort = 'By Invoice')
		Begin 
			select * from @results order by SUPNAME,INVno,INVDATE 
		end

	else if ( @lcSort = 'By Receiver')
		Begin 
			select * from @results order by SUPNAME,receiverno 
		end
	END
ELSE
	BEGIN
	/*05/27/2015 DRP added the @results table*/
	-- 07/16/18 VL changed supname from char(30) to char(50)
	-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
	declare @resultsFC as table(supname char(50),PONUM char(15),Conum numeric(3,0),PODATE smalldatetime,receiverno char(10),sinv_uniq char(10),INVNO char(22),INVDATE smalldatetime,RECON_DATE smalldatetime
			,invamount numeric (20,2),sdet_uniq char(10),uniqlnno char(10),Part_no char(35),Revision char(8),PO_desc char(45),RecvQty numeric(20,2), acpt_qty numeric(20,2),costeach numeric(20,5)
			,uniq_key char(10),extension numeric(20,2),TAX numeric(20,2),FREIGHT numeric(20,2),saveinit char(8),LIC_NAME char(40)
			-- 01/25/17 VL added functional currency code
			,invamountFC numeric (20,2),costeachFC numeric(20,5),extensionFC numeric(20,2),TAXFC numeric(20,2),FREIGHTFC numeric(20,2)
			,invamountPR numeric (20,2),costeachPR numeric(20,5),extensionPR numeric(20,2),TAXPR numeric(20,2),FREIGHTPR numeric(20,2)
			,TSymbol char(3), PSymbol char(3), FSymbol char(3))


	--This section will gather the header information pertaining to the Reconciliation record
	;WITH Header
	as
	(
	select	P.supname,P.PONUM,P.Conum,P.PODATE,sinvoice.receiverno,sinvoice.sinv_uniq,sinvoice.INVNO,sinvoice.INVDATE,sinvoice.RECON_DATE,sinvoice.INVAMOUNT,TAX,FREIGHT,SAVEINIT,micssys.LIC_NAME, 
			-- 01/25/17 VL added functional currency code 
			sinvoice.INVAMOUNTFC,TAXFC,FREIGHTFC, sinvoice.INVAMOUNTPR,TAXPR,FREIGHTPR, TSymbol, PSymbol, FSymbol 
	FROM	SINVOICE 
			CROSS APPLY	(SELECT	distinct Pomain.PONUM,Pomain.Conum,Pomain.PODATE, Supinfo.supname,supinfo.UNIQSUPNO,TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol   
						 FROM	POMAIN 
								-- 01/25/17 VL changed criteria to get 3 currencies
								INNER JOIN Fcused PF ON POMAIN.PrFcused_uniq = PF.Fcused_uniq
								INNER JOIN Fcused FF ON POMAIN.FuncFcused_uniq = FF.Fcused_uniq			
								INNER JOIN Fcused TF ON POMAIN.Fcused_uniq = TF.Fcused_uniq			
								INNER JOIN Poitems ON Pomain.PONUM=Poitems.PONUM
								INNER JOIN Porecdtl on poitems.UNIQLNNO=porecdtl.UNIQLNNO
								INNER JOIN SUPINFO on Pomain.UNIQSUPNO=supinfo.uniqsupno
						 WHERE	Porecdtl.RECEIVERNO=sinvoice.receiverno) P
			cross apply MICSSYS
	where	sinvoice.recon_date>=@lcdatestart and sinvoice.recon_date<@lcdateend+1
			and 1= case WHEN P.UNIQSUPNO IN (SELECT Uniqsupno FROM @Supplier) THEN 1 ELSE 0  END	--01/28/2014 DRP:  added
	)

	insert into @resultsFC

	--I had to insert into the t1 table and then use the partition command below to get the invoice amount to only display once per invoice.  This was to get the totaling correct on the report. 
	select	t1.supname,t1.PONUM,t1.Conum,t1.PODATE,t1.receiverno,t1.sinv_uniq,t1.INVNO,t1.INVDATE,t1.RECON_DATE
			,CASE WHEN ROW_NUMBER() OVER(Partition by t1.sinv_uniq Order by t1.part_no)=1 Then invamount else CAST(0.00 as Numeric(20,2)) END AS invamount
			,t1.sdet_uniq, t1.uniqlnno,t1.Part_no,t1.Revision,t1.PO_desc,t1.ReceivedQty, t1.acpt_qty, t1.costeach,t1.uniq_key,t1.extension,T1.TAX,T1.FREIGHT,t1.saveinit,t1.LIC_NAME
			-- 01/25/17 VL added functional currency code 
			,CASE WHEN ROW_NUMBER() OVER(Partition by t1.sinv_uniq Order by t1.part_no)=1 Then invamountFC else CAST(0.00 as Numeric(20,2)) END AS invamountFC
			,t1.costeachFC,t1.extensionFC,T1.TAXFC,T1.FREIGHTFC
			,CASE WHEN ROW_NUMBER() OVER(Partition by t1.sinv_uniq Order by t1.part_no)=1 Then invamountPR else CAST(0.00 as Numeric(20,2)) END AS invamountPR
			,t1.costeachPR,t1.extensionPR,T1.TAXPR,T1.FREIGHTPR
			, TSymbol, PSymbol, FSymbol


	--the below section will take the header info and join it with the poreceipt/poitem detial.  Then union with the misc items added within the po recon module
	from
	(		
		SELECT	header.supname,header.PONUM,header.Conum,header.PODATE,header.receiverno,header.sinv_uniq,header.INVNO,header.INVDATE,header.RECON_DATE
				,Header.INVAMOUNT 
				,Sinvdetl.sdet_uniq, Sinvdetl.uniqlnno,ISNULL(Inventor.part_no,Poitems.PART_NO) as Part_no,ISNULL(Inventor.Revision,PoItems.REVISION) as Revision,Sinvdetl.item_desc as PO_desc,
				--,ISNULL(Inventor.DESCRIPT,Poitems.DESCRIPT) as PO_desc,
				-- 03/28/16 YS changed some column numbers in the porecdtl table
				PORECDTL.ReceivedQty, Sinvdetl.acpt_qty, Sinvdetl.costeach,PoItems.uniq_key
				,ROUND(Sinvdetl.acpt_qty*Sinvdetl.costeach,2) AS extension,TAX,FREIGHT,SAVEINIT,header.LIC_NAME
				-- 01/25/17 VL added functional currency code 
				,Header.INVAMOUNTFC,Sinvdetl.costeachFC ,ROUND(Sinvdetl.acpt_qty*Sinvdetl.costeachFC,2) AS extensionFC,TAXFC,FREIGHTFC
				,Header.INVAMOUNTPR,Sinvdetl.costeachPR ,ROUND(Sinvdetl.acpt_qty*Sinvdetl.costeachPR,2) AS extensionPR,TAXPR,FREIGHTPR
				, TSymbol, PSymbol, FSymbol

		FROM	SINVDETL 
				INNER JOIN Header ON Header.sInv_Uniq = SInvDetl.Sinv_Uniq 
				INNER JOIN PoREcDtl ON Header.receiverno = PORECDTL.RECEIVERNO  AND Sinvdetl.Uniqlnno=Porecdtl.UNIQLNNO 
				inner join POITEMS ON PORECDTL.UNIQLNNO = POITEMS.Uniqlnno
				LEFT OUTER JOIN Inventor on POITEMS.UNIQ_KEY = INVENTOR.Uniq_Key
			
		UNION
    
		SELECT	header.supname,header.PONUM,header.Conum,header.PODATE,header.receiverno,header.sinv_uniq,header.INVNO,Header.INVDATE,header.RECON_DATE
				,header.invamount
				,Sinvdetl.sdet_uniq, Sinvdetl.uniqlnno,SPACE(25) as Part_no,SPACE(8) as Revision,cast('Misc Item added at Reconciliation' as CHAR(45)) as PO_desc
				,CAST(0.00 as numeric(10,2)) as RecvQty,Sinvdetl.acpt_qty, Sinvdetl.costeach,SPACE(10) as uniq_key,ROUND(Sinvdetl.acpt_qty*Sinvdetl.costeach,2) AS extension
				,TAX,FREIGHT,SAVEINIT,header.LIC_NAME
				-- 01/25/17 VL added functional currency code 
				,Header.INVAMOUNTFC,Sinvdetl.costeachFC ,ROUND(Sinvdetl.acpt_qty*Sinvdetl.costeachFC,2) AS extensionFC,TAXFC,FREIGHTFC
				,Header.INVAMOUNTPR,Sinvdetl.costeachPR ,ROUND(Sinvdetl.acpt_qty*Sinvdetl.costeachPR,2) AS extensionPR,TAXPR,FREIGHTPR
				, TSymbol, PSymbol, FSymbol

		FROM	Sinvdetl INNER JOIN Header ON Sinvdetl.sinv_uniq=Header.SINV_UNIQ  
		WHERE	UNIQLNNO = ' '
	   )t1
  
	/*05/27/2015 DRP added the different sort orders*/ 
	-- 01/25/17 VL added functional currency code  
	if ( @lcSort = 'By Purchase Order')
		Begin 
			select * from @resultsFC order by TSymbol,SUPNAME,PONUM,INVno,invamount 
		end

	else if ( @lcSort = 'By Invoice')
		Begin 
			select * from @resultsFC order by TSymbol,SUPNAME,INVno,INVDATE 
		end

	else if ( @lcSort = 'By Receiver')
		Begin 
			select * from @resultsFC order by TSymbol,SUPNAME,receiverno 
		end
	END
end