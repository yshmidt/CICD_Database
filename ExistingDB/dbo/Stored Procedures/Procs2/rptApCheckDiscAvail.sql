
	--/****** Object:  StoredProcedure [dbo].[rptApCheckDiscAvail]    Script Date: 12/21/2015 13:33:14 ******/
	--SET ANSI_NULLS ON
	--GO
	--SET QUOTED_IDENTIFIER ON
	--GO

	-- =============================================
	-- Author:			Debbie 
	-- Create date:		12/22/2015
	-- Description:		Created for the Discount Available Report
	-- Reports:			ckrep4.rpt 
	-- Modified:
	-- 03/21/2016	VL:	Added FC code, also added InvDate + Disc_Days >= GETDATE() criteria
	-- 04/08/2016	VL: Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
	-- 02/03/2017	VL:	Added functional currency fields
-- 07/13/18 VL changed supname from char(30) to char(50)
	-- =============================================
	CREATE PROCEDURE  [dbo].[rptApCheckDiscAvail]

--declare
	@userId uniqueidentifier=null


as
begin

/*SUPPLIER LIST*/	
	-- get list of approved suppliers for this user
	DECLARE @tSupplier tSupplier
	INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, 'All';
	--select * from @tSupplier




/*RECORD SELECT SECTION*/
-- 03/21/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

BEGIN
IF @lFCInstalled = 0
	BEGIN
	-- 07/13/18 VL changed supname from char(30) to char(50)
	DECLARE @zSchDet as table (SupName Char(50),Terms Char(15),InvNo Char(20),InvDate date,  InvAmount Numeric(12,2),BalAmt Numeric(12,2), Disc_Amt Numeric(10,2), Due_Date date 
								,ApPmts Numeric(12,2),  Disc_Perc Numeric(6,2), Disc_Date date,UniqAphead char(10),UniqSupNo Char(10))

	insert into @zschDet
					SELECT	SupInfo.SupName,apmaster.terms,INVNO,INVDATE,INVAMOUNT,INVAMOUNT-APPMTS as BalAmt, ((apmaster.invamount-apmaster.APPMTS) * apmaster.DISC_PERC)/100 as DISC_AMT
							,DUE_DATE,APPMTS,DISC_PERC, apmaster.INVDATE+pmtterms.disc_days as Disc_Date,uniqaphead,supinfo.uniqsupno
		 			FROM	SupInfo
							inner join apmaster on supinfo.uniqsupno = apmaster.uniqsupno 
							inner join PMTTERMS on apmaster.TERMS = PMTTERMS.DESCRIPT
		 			WHERE	ApMaster.Invamount - (ApMaster.ApPmts + Disc_Tkn) > 0
							AND Disc_Amt > 0
		 					AND Due_Date >= GETDATE() 
		 					AND ApStatus <> 'Deleted' 
							-- 03/21/2016 VL added next criteria (from 963 version)
							AND apmaster.INVDATE+pmtterms.disc_days >= GETDATE()
							and exists (select 1 from @tSupplier t inner join supinfo s on t.uniqsupno=s.UNIQSUPNO where s.UNIQSUPNO=apmaster.UNIQSUPNO)
		 		
		 		  --)

	--select * from @zSchDet

	; with 
	  zBatch as (
				 select	A.fk_uniqaphead,A.disc_tkn
				 from	APBATDET A
						inner join @zSchDet B on A.FK_UNIQAPHEAD = b.UniqAphead
				)

	--select * from zBatch

	update @zschdet set Disc_Amt =z.DISC_TKN from @zSchDet C,zBatch Z where c.uniqaphead = z.FK_UNIQAPHEAD

	select F.*,F.BalAmt-F.Disc_Amt AS NetAmount from @zSchDet F  order by Disc_Date,SupName,InvNo

	END
ELSE
-- FC installed	
	BEGIN
	-- 07/13/18 VL changed supname from char(30) to char(50)
	DECLARE @zSchDetFC as table (SupName Char(50),Terms Char(15),InvNo Char(20),InvDate date,  InvAmount Numeric(12,2),BalAmt Numeric(12,2), Disc_Amt Numeric(10,2), Due_Date date 
								,ApPmts Numeric(12,2),  Disc_Perc Numeric(6,2), Disc_Date date,UniqAphead char(10),UniqSupNo Char(10)
								,InvAmountFC Numeric(12,2),BalAmtFC Numeric(12,2), Disc_AmtFC Numeric(10,2),ApPmtsFC Numeric(12,2)
								-- 02/03/17 VL comment out Currency and added functional currency fields
								--, Currency char(3))
								,InvAmountPR Numeric(12,2),BalAmtPR Numeric(12,2), Disc_AmtPR Numeric(10,2),ApPmtsPR Numeric(12,2)
								,TSymbol char(3), PSymbol char(3), FSymbol char(3))

	insert into @zschDetFC
					SELECT	SupInfo.SupName,apmaster.terms,INVNO,INVDATE,INVAMOUNT,INVAMOUNT-APPMTS as BalAmt, ((apmaster.invamount-apmaster.APPMTS) * apmaster.DISC_PERC)/100 as DISC_AMT
							,DUE_DATE,APPMTS,DISC_PERC, apmaster.INVDATE+pmtterms.disc_days as Disc_Date,uniqaphead,supinfo.uniqsupno
							,INVAMOUNTFC,INVAMOUNTFC-APPMTSFC as BalAmtFC, ((apmaster.invamountFC-apmaster.APPMTSFC) * apmaster.DISC_PERC)/100 as DISC_AMTFC
							,APPMTSFC
							-- 02/03/17
							--, Fcused.Symbol AS Currency
							,INVAMOUNTPR,INVAMOUNTPR-APPMTSPR as BalAmtPR, ((apmaster.invamountPR-apmaster.APPMTSPR) * apmaster.DISC_PERC)/100 as DISC_AMTPR
							,APPMTSPR, TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
		 			FROM	SupInfo
							inner join apmaster on supinfo.uniqsupno = apmaster.uniqsupno 
							-- 02/03/17 VL changed criteria to get 3 currencies
							INNER JOIN Fcused PF ON apmaster.PrFcused_uniq = PF.Fcused_uniq
							INNER JOIN Fcused FF ON apmaster.FuncFcused_uniq = FF.Fcused_uniq			
							INNER JOIN Fcused TF ON apmaster.Fcused_uniq = TF.Fcused_uniq			
							inner join PMTTERMS on apmaster.TERMS = PMTTERMS.DESCRIPT
		 			WHERE	ApMaster.Invamount - (ApMaster.ApPmts + Disc_Tkn) > 0
							AND Disc_Amt > 0
		 					AND Due_Date >= GETDATE() 
		 					AND ApStatus <> 'Deleted' 
							-- 03/21/2016 VL added next criteria (from 963 version)
							AND apmaster.INVDATE+pmtterms.disc_days >= GETDATE()
							and exists (select 1 from @tSupplier t inner join supinfo s on t.uniqsupno=s.UNIQSUPNO where s.UNIQSUPNO=apmaster.UNIQSUPNO)
		 		
		 		  --)

	--select * from @zSchDet

	; with 
	  zBatch as (
				 select	A.fk_uniqaphead,A.disc_tkn, A.disc_tknFC,A.disc_tknPR
				 from	APBATDET A
						inner join @zSchDet B on A.FK_UNIQAPHEAD = b.UniqAphead
				)

	--select * from zBatch

	update @zschdetFC set Disc_Amt =z.DISC_TKN, Disc_AmtFC =z.DISC_TKNFC,Disc_AmtPR =z.DISC_TKNPR from @zSchDet C,zBatch Z where c.uniqaphead = z.FK_UNIQAPHEAD

	select F.*,F.BalAmt-F.Disc_Amt AS NetAmount, F.BalAmtFC-F.Disc_AmtFC AS NetAmountFC, F.BalAmtPR-F.Disc_AmtPR AS NetAmountPR from @zSchDetFC F  order by Disc_Date,SupName,InvNo
	END
END-- if FC installed

end