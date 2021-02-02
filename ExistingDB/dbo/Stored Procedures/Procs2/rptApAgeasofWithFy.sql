
-- =============================================
-- Author:		<Yelena>
-- Create date: <09/09/2010>
-- Description:	<Was created and used on [apageasof.rpt]>
-- Modification:  01/15/2014 DRP:  Added the @userid for WebManex
--				  01/27/2017  VL:  Separate FC and non FC, also added functional currency code
-- 07/13/18 VL changed supname from char(30) to char(50)
-- =============================================
CREATE PROCEDURE [dbo].[rptApAgeasofWithFy]
	-- Add the parameters for the stored procedure here
		@lcDate as datetime=null
		,@lcFy as char(4)=' '
		,@lnPeriod as int =0 
		,@lcAgeBy as varchar(12)='Invoice Date'
		,@userId uniqueidentifier=null 
AS
BEGIN
IF @lcDate IS NULL
BEGIN
	-- look for the end of the given fiscal year period
	if @lcFy<>' ' and @lnPeriod<>0
	BEGIN
		SELECT @lcDate=glfyrsdetl.ENDDATE 
			FROM glfyrsdetl inner join glfiscalyrs on glfiscalyrs.FY_UNIQ = glfyrsdetl.FK_FY_UNIQ 
			WHERE glfiscalyrs.FISCALYR =@lcFy and glfyrsdetl.PERIOD =@lnPeriod
	END -- @lcFy<>' ' and @lnPeriod<>0
END	-- @lcDate IS NULL

-- 01/27/17 VL separate FC and non FC
IF dbo.fn_IsFCInstalled() = 0
	BEGIN
	select t1.supname, t1.UNIQSUPNO, t1.uniqaphead,t1.invno, t1.InvTransDt, t1.INVDATE, t1.DUE_DATE,SUM(t1.amount) as Amount, 
		t1.R1Start, t1.R1End, t1.R2Start, t1.R2End, t1.R3Start, t1.R3End, t1.R4Start, t1.R4End,
		CASE WHEN @lcAgeBy='Invoice Date' THEN t1.INVDATE ELSE t1.DUE_DATE END as AgeDate

	from(
	--This will pull the main information from the APMASTER tables.  This should include and pull fwd General Debit Memo's also.
	-- 07/13/18 VL changed supname from char(30) to char(50)
	SELECT		ap1.UNIQAPHEAD, ap1.TRANS_DT, cast (s1.SUPNAME as CHAR(50)) as supname, s1.uniqsupno, cast (ap1.INVNO as CHAR(25)) as invno, 
				ap1.TRANS_DT as InvTransDt, ap1.INVDATE, ap1.DUE_DATE, cast (ap1.PONUM as CHAR(15)) as PONUM, cast (ap1.INVAMOUNT as numeric (12,2)) as Amount, 
				ap1.IS_REL_GL, cast (ap1.APSTATUS as CHAR(15)) as Status,CAST ('' as CHAR (25)) as Reference, 
				a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End, a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start, a4.nEnd AS R4End 
            
	FROM         dbo.APMASTER as ap1 INNER JOIN
						  dbo.SUPINFO as s1 ON ap1.unIQSUPNO = s1.UNIQSUPNO cross join
						  dbo.AgingRangeSetup AS a4 CROSS JOIN
						  dbo.AgingRangeSetup AS a1 CROSS JOIN
						  dbo.AgingRangeSetup AS a2 CROSS JOIN
						  dbo.AgingRangeSetup AS a3
	WHERE     (ap1.INVAMOUNT <> 0.00) and (ap1.APSTATUS <> '= Deleted') and (ap1.is_rel_gl = 1)and (a1.cType = 'AP') AND (a1.nRange = 1) AND (a2.cType = 'AP') AND (a2.nRange = 2) 
						  AND (a3.cType = 'Ap') AND (a3.nRange = 3) AND (a4.cType = 'Ap') AND (a4.nRange = 4)


	union
	--This is pulling the APCHECK information.  It should also include records for AP Prepayments.
	-- 07/13/18 VL changed supname from char(30) to char(50)
	SELECT		ckd2.UNIQAPHEAD, ckm2.CHECKDATE AS Trans_dt, cast (s2.SUPNAME as CHAR(50)) as supname, s2.uniqsupno, 
				case when left(ckd2.item_desc,6) = 'PrePay' then cast ('PrePayment: ' + right(ckd2.item_desc,11)  as CHAR(25)) else cast (ckd2.INVNO as CHAR(25)) end as InvNo, 
				ap2.TRANS_DT as InvTransDt, case when LEFT(ckd2.item_desc, 6) = 'PrePay' then ap2.trans_dt else ap2.INVDATE end as INVDATE, 
				ap2.DUE_DATE, cast('' as char(15)) as ponum, CAST(-(ckd2.APRPAY + ckd2.DISC_TKN) as numeric(12,2)) AS Amount, ckm2.IS_REL_GL, 
				cast (ckm2.STATUS as CHAR(15)) as status, cast ('Chk:  ' + ckm2.CHECKNO AS CHAR (25)) AS Reference, 
				a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End, a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start, a4.nEnd AS R4End
            
	FROM         dbo.apmaster as ap2 left outer join 
						  dbo.APCHKDET as ckd2 on ap2.UNIQAPHEAD = ckd2.UNIQAPHEAD INNER JOIN
						  dbo.APCHKMST as ckm2 ON ckd2.APCHK_UNIQ = ckm2.APCHK_UNIQ INNER JOIN
						  dbo.SUPINFO as s2 ON ckm2.UNIQSUPNO = s2.UNIQSUPNO CROSS JOIN
						  dbo.AgingRangeSetup AS a4 CROSS JOIN
						  dbo.AgingRangeSetup AS a1 CROSS JOIN
						  dbo.AgingRangeSetup AS a2 CROSS JOIN
						  dbo.AgingRangeSetup AS a3
	WHERE     (ckm2.IS_REL_GL = 1) and (a1.cType = 'AP') AND (a1.nRange = 1) AND (a2.cType = 'AP') AND (a2.nRange = 2) AND (a3.cType = 'Ap') AND (a3.nRange = 3) AND (a4.cType = 'Ap') 
						  AND (a4.nRange = 4)  
	Union

	--this will pull fwd any Invoice Debit Memo information.
	-- 07/13/18 VL changed supname from char(30) to char(50)
	SELECT			dm3.UNIQAPHEAD, dm3.DMDATE AS Trans_dt, cast (s3.SUPNAME as CHAR(50)) as supname, s3.uniqsupno, cast (dm3.INVNO as CHAR (25)) as invno, 
					ap3.trans_dt as InvTransDt,ap3.INVDATE, ap3.DUE_DATE, CAST(dm3.PONUM AS CHAR(15)) AS PONUM, cast (-(dm3.DMTOTAL) as numeric(12,2)) AS Amount, 
					dm3.IS_REL_GL, cast (dm3.DMSTATUS as CHAR(15)) AS Status, CAST('DM:  ' + dm3.DMEMONO AS CHAR(25)) AS Reference, 
					a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End, a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start, a4.nEnd AS R4End
				
	FROM         dbo.DMEMOS as dm3 INNER JOIN
						  dbo.SUPINFO as s3 ON dm3.UNIQSUPNO = s3.UNIQSUPNO INNER JOIN
						  dbo.APMASTER as ap3 ON dm3.UNIQAPHEAD = ap3.UNIQAPHEAD CROSS JOIN
						  dbo.AgingRangeSetup AS a4 CROSS JOIN
						  dbo.AgingRangeSetup AS a1 CROSS JOIN
						  dbo.AgingRangeSetup AS a2 CROSS JOIN
						  dbo.AgingRangeSetup AS a3
	WHERE     (dm3.IS_REL_GL = 1) AND (a1.cType = 'AP') AND (a1.nRange = 1) AND (a2.cType = 'AP') AND (a2.nRange = 2) AND (a3.cType = 'Ap') AND 
						  (a3.nRange = 3) AND (a4.cType = 'Ap') AND (a4.nRange = 4) AND (dm3.DMTYPE = 1)                      
	union
	--this section will pull fwd the ap offset information
	-- 07/13/18 VL changed supname from char(30) to char(50)
	SELECT		apo4.UNIQAPHEAD, apo4.DATE as Trans_dt, cast (s4.SUPNAME as CHAR(50)) as supname, s4.uniqsupno, 
				CASE WHEN apo4.ref_no = 'PrePaidCk' THEN CAST('PrePayment: ' + ap4.ponum AS char(25)) ELSE CAST(apo4.Invno AS char(25)) END AS Invno, 
				ap4.trans_dt as InvTransDt, CASE WHEN APO4.REF_NO = 'PrePaidCk' then ap4.trans_dt else ap4.INVDATE end as INVDATE, 
				ap4.DUE_DATE, cast ('' as char(15)) as ponum, cast (apo4.AMOUNT as numeric(12,2)) as Amount, APO4.is_rel_gl, 
				CAST('' AS char(15)) AS status, CAST('Offset:  ' + apo4.UNIQ_APOFF AS CHAR(25))AS reference, 
				a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End, a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start, a4.nEnd AS R4End
			
	FROM         dbo.APOFFSET as apo4 INNER JOIN
						  dbo.SUPINFO as s4 ON apo4.UNIQSUPNO = s4.UNIQSUPNO INNER JOIN
						  dbo.APMASTER as ap4 ON apo4.UNIQAPHEAD = ap4.UNIQAPHEAD CROSS JOIN
						  dbo.AgingRangeSetup AS a4 CROSS JOIN
						  dbo.AgingRangeSetup AS a1 CROSS JOIN
						  dbo.AgingRangeSetup AS a2 CROSS JOIN
						  dbo.AgingRangeSetup AS a3
	WHERE     (a1.cType = 'AP') AND (a1.nRange = 1) AND (a2.cType = 'AP') AND (a2.nRange = 2) AND (a3.cType = 'Ap') AND (a3.nRange = 3) AND (a4.cType = 'Ap') 
						  AND (a4.nRange = 4)
	) t1 
	where (DATEPART(Year,t1.TRANS_DT)<DatePart(Year,@lcDate)) 
		OR (DATEPART(Year,t1.TRANS_DT)=DatePart(Year,@lcDate) and DATEPART(Month,t1.TRANS_DT)<DatePart(Month,@lcDate))
		OR (DATEPART(Year,t1.TRANS_DT)=DatePart(Year,@lcDate) and DATEPART(Month,t1.TRANS_DT)=DatePart(Month,@lcDate) AND DatePart(Day,t1.TRANS_DT)<=DatePart(Day,@lcDate)) 

	group by t1.supname, t1.UNIQSUPNO, t1.uniqaphead, t1.invno, t1.invTransDt, t1.INVDATE, t1.DUE_DATE,  t1.R1Start, t1.R1End, t1.R2Start, t1.R2End, t1.R3Start, t1.R3End, t1.R4Start, t1.R4End

	order by SUPNAME,invno
	END
ELSE
	BEGIN
	select t1.supname, t1.UNIQSUPNO, t1.uniqaphead,t1.invno, t1.InvTransDt, t1.INVDATE, t1.DUE_DATE,SUM(t1.amount) as Amount, 
		t1.R1Start, t1.R1End, t1.R2Start, t1.R2End, t1.R3Start, t1.R3End, t1.R4Start, t1.R4End,
		-- 01/27/17 VL added FC and Functional currency code
		SUM(t1.amountFC) as AmountFC, SUM(t1.amountPR) as AmountPR, TSymbol, PSymbol, FSymbol,
		CASE WHEN @lcAgeBy='Invoice Date' THEN t1.INVDATE ELSE t1.DUE_DATE END as AgeDate

	from(
	--This will pull the main information from the APMASTER tables.  This should include and pull fwd General Debit Memo's also.
	-- 07/13/18 VL changed supname from char(30) to char(50)
	SELECT		ap1.UNIQAPHEAD, ap1.TRANS_DT, cast (s1.SUPNAME as CHAR(50)) as supname, s1.uniqsupno, cast (ap1.INVNO as CHAR(25)) as invno, 
				ap1.TRANS_DT as InvTransDt, ap1.INVDATE, ap1.DUE_DATE, cast (ap1.PONUM as CHAR(15)) as PONUM, cast (ap1.INVAMOUNT as numeric (12,2)) as Amount, 
				ap1.IS_REL_GL, cast (ap1.APSTATUS as CHAR(15)) as Status,CAST ('' as CHAR (25)) as Reference, 
				a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End, a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start, a4.nEnd AS R4End,
				-- 01/27/17 VL added FC and Functional currency code 
				cast (ap1.INVAMOUNTFC as numeric (12,2)) as AmountFC, cast (ap1.INVAMOUNT as numeric (12,2)) as AmountPR, 
				TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol

	FROM         dbo.APMASTER as ap1 
						-- 01/27/17 VL changed criteria to get 3 currencies
						INNER JOIN Fcused PF ON ap1.PrFcused_uniq = PF.Fcused_uniq
						INNER JOIN Fcused FF ON ap1.FuncFcused_uniq = FF.Fcused_uniq			
						INNER JOIN Fcused TF ON ap1.Fcused_uniq = TF.Fcused_uniq 
						INNER JOIN
						  dbo.SUPINFO as s1 ON ap1.unIQSUPNO = s1.UNIQSUPNO cross join
						  dbo.AgingRangeSetup AS a4 CROSS JOIN
						  dbo.AgingRangeSetup AS a1 CROSS JOIN
						  dbo.AgingRangeSetup AS a2 CROSS JOIN
						  dbo.AgingRangeSetup AS a3
	WHERE     (ap1.INVAMOUNT <> 0.00) and (ap1.APSTATUS <> '= Deleted') and (ap1.is_rel_gl = 1)and (a1.cType = 'AP') AND (a1.nRange = 1) AND (a2.cType = 'AP') AND (a2.nRange = 2) 
						  AND (a3.cType = 'Ap') AND (a3.nRange = 3) AND (a4.cType = 'Ap') AND (a4.nRange = 4)


	union
	--This is pulling the APCHECK information.  It should also include records for AP Prepayments.
	-- 07/13/18 VL changed supname from char(30) to char(50)
	SELECT		ckd2.UNIQAPHEAD, ckm2.CHECKDATE AS Trans_dt, cast (s2.SUPNAME as CHAR(50)) as supname, s2.uniqsupno, 
				case when left(ckd2.item_desc,6) = 'PrePay' then cast ('PrePayment: ' + right(ckd2.item_desc,11)  as CHAR(25)) else cast (ckd2.INVNO as CHAR(25)) end as InvNo, 
				ap2.TRANS_DT as InvTransDt, case when LEFT(ckd2.item_desc, 6) = 'PrePay' then ap2.trans_dt else ap2.INVDATE end as INVDATE, 
				ap2.DUE_DATE, cast('' as char(15)) as ponum, CAST(-(ckd2.APRPAY + ckd2.DISC_TKN) as numeric(12,2)) AS Amount, ckm2.IS_REL_GL, 
				cast (ckm2.STATUS as CHAR(15)) as status, cast ('Chk:  ' + ckm2.CHECKNO AS CHAR (25)) AS Reference, 
				a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End, a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start, a4.nEnd AS R4End,
				-- 01/27/17 VL added FC and Functional currency code 
				CAST(-(ckd2.APRPAYFC + ckd2.DISC_TKNFC) as numeric(12,2)) AS AmountFC, CAST(-(ckd2.APRPAYPR + ckd2.DISC_TKNPR) as numeric(12,2)) AS AmountPR, 
				TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol

	FROM         dbo.apmaster as ap2 
						-- 01/27/17 VL changed criteria to get 3 currencies
						INNER JOIN Fcused PF ON ap2.PrFcused_uniq = PF.Fcused_uniq
						INNER JOIN Fcused FF ON ap2.FuncFcused_uniq = FF.Fcused_uniq			
						INNER JOIN Fcused TF ON ap2.Fcused_uniq = TF.Fcused_uniq 
						left outer join 
						  dbo.APCHKDET as ckd2 on ap2.UNIQAPHEAD = ckd2.UNIQAPHEAD INNER JOIN
						  dbo.APCHKMST as ckm2 ON ckd2.APCHK_UNIQ = ckm2.APCHK_UNIQ INNER JOIN
						  dbo.SUPINFO as s2 ON ckm2.UNIQSUPNO = s2.UNIQSUPNO CROSS JOIN
						  dbo.AgingRangeSetup AS a4 CROSS JOIN
						  dbo.AgingRangeSetup AS a1 CROSS JOIN
						  dbo.AgingRangeSetup AS a2 CROSS JOIN
						  dbo.AgingRangeSetup AS a3
	WHERE     (ckm2.IS_REL_GL = 1) and (a1.cType = 'AP') AND (a1.nRange = 1) AND (a2.cType = 'AP') AND (a2.nRange = 2) AND (a3.cType = 'Ap') AND (a3.nRange = 3) AND (a4.cType = 'Ap') 
						  AND (a4.nRange = 4)  
	Union

	--this will pull fwd any Invoice Debit Memo information.
	-- 07/13/18 VL changed supname from char(30) to char(50)
	SELECT			dm3.UNIQAPHEAD, dm3.DMDATE AS Trans_dt, cast (s3.SUPNAME as CHAR(50)) as supname, s3.uniqsupno, cast (dm3.INVNO as CHAR (25)) as invno, 
					ap3.trans_dt as InvTransDt,ap3.INVDATE, ap3.DUE_DATE, CAST(dm3.PONUM AS CHAR(15)) AS PONUM, cast (-(dm3.DMTOTAL) as numeric(12,2)) AS Amount, 
					dm3.IS_REL_GL, cast (dm3.DMSTATUS as CHAR(15)) AS Status, CAST('DM:  ' + dm3.DMEMONO AS CHAR(25)) AS Reference, 
					a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End, a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start, a4.nEnd AS R4End,
					-- 01/27/17 VL added FC and Functional currency code 
					cast (-(dm3.DMTOTALFC) as numeric(12,2)) AS AmountFC, cast (-(dm3.DMTOTALPR) as numeric(12,2)) AS AmountPR,
					TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol

	FROM         dbo.DMEMOS as dm3 
						-- 01/27/17 VL changed criteria to get 3 currencies
						INNER JOIN Fcused PF ON dm3.PrFcused_uniq = PF.Fcused_uniq
						INNER JOIN Fcused FF ON dm3.FuncFcused_uniq = FF.Fcused_uniq			
						INNER JOIN Fcused TF ON dm3.Fcused_uniq = TF.Fcused_uniq 
						INNER JOIN
						  dbo.SUPINFO as s3 ON dm3.UNIQSUPNO = s3.UNIQSUPNO INNER JOIN
						  dbo.APMASTER as ap3 ON dm3.UNIQAPHEAD = ap3.UNIQAPHEAD CROSS JOIN
						  dbo.AgingRangeSetup AS a4 CROSS JOIN
						  dbo.AgingRangeSetup AS a1 CROSS JOIN
						  dbo.AgingRangeSetup AS a2 CROSS JOIN
						  dbo.AgingRangeSetup AS a3
	WHERE     (dm3.IS_REL_GL = 1) AND (a1.cType = 'AP') AND (a1.nRange = 1) AND (a2.cType = 'AP') AND (a2.nRange = 2) AND (a3.cType = 'Ap') AND 
						  (a3.nRange = 3) AND (a4.cType = 'Ap') AND (a4.nRange = 4) AND (dm3.DMTYPE = 1)                      
	union
	--this section will pull fwd the ap offset information
	-- 07/13/18 VL changed supname from char(30) to char(50)
	SELECT		apo4.UNIQAPHEAD, apo4.DATE as Trans_dt, cast (s4.SUPNAME as CHAR(50)) as supname, s4.uniqsupno, 
				CASE WHEN apo4.ref_no = 'PrePaidCk' THEN CAST('PrePayment: ' + ap4.ponum AS char(25)) ELSE CAST(apo4.Invno AS char(25)) END AS Invno, 
				ap4.trans_dt as InvTransDt, CASE WHEN APO4.REF_NO = 'PrePaidCk' then ap4.trans_dt else ap4.INVDATE end as INVDATE, 
				ap4.DUE_DATE, cast ('' as char(15)) as ponum, cast (apo4.AMOUNT as numeric(12,2)) as Amount, APO4.is_rel_gl, 
				CAST('' AS char(15)) AS status, CAST('Offset:  ' + apo4.UNIQ_APOFF AS CHAR(25))AS reference, 
				a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End, a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start, a4.nEnd AS R4End,
				-- 01/27/17 VL added FC and Functional currency code
				cast (apo4.AMOUNTFC as numeric(12,2)) as AmountFC, cast (apo4.AMOUNTPR as numeric(12,2)) as AmountPR,
				TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol

	FROM         dbo.APOFFSET as apo4 
						-- 01/27/17 VL changed criteria to get 3 currencies
						INNER JOIN Fcused PF ON apo4.PrFcused_uniq = PF.Fcused_uniq
						INNER JOIN Fcused FF ON apo4.FuncFcused_uniq = FF.Fcused_uniq			
						INNER JOIN Fcused TF ON apo4.Fcused_uniq = TF.Fcused_uniq 
						INNER JOIN
						  dbo.SUPINFO as s4 ON apo4.UNIQSUPNO = s4.UNIQSUPNO INNER JOIN
						  dbo.APMASTER as ap4 ON apo4.UNIQAPHEAD = ap4.UNIQAPHEAD CROSS JOIN
						  dbo.AgingRangeSetup AS a4 CROSS JOIN
						  dbo.AgingRangeSetup AS a1 CROSS JOIN
						  dbo.AgingRangeSetup AS a2 CROSS JOIN
						  dbo.AgingRangeSetup AS a3
	WHERE     (a1.cType = 'AP') AND (a1.nRange = 1) AND (a2.cType = 'AP') AND (a2.nRange = 2) AND (a3.cType = 'Ap') AND (a3.nRange = 3) AND (a4.cType = 'Ap') 
						  AND (a4.nRange = 4)
	) t1
	where (DATEPART(Year,t1.TRANS_DT)<DatePart(Year,@lcDate)) 
		OR (DATEPART(Year,t1.TRANS_DT)=DatePart(Year,@lcDate) and DATEPART(Month,t1.TRANS_DT)<DatePart(Month,@lcDate))
		OR (DATEPART(Year,t1.TRANS_DT)=DatePart(Year,@lcDate) and DATEPART(Month,t1.TRANS_DT)=DatePart(Month,@lcDate) AND DatePart(Day,t1.TRANS_DT)<=DatePart(Day,@lcDate)) 

	group by t1.supname, t1.UNIQSUPNO, t1.uniqaphead, t1.invno, t1.invTransDt, t1.INVDATE, t1.DUE_DATE,  t1.R1Start, t1.R1End, t1.R2Start, t1.R2End, t1.R3Start, t1.R3End, t1.R4Start, t1.R4End, t1.TSymbol, t1.PSymbol, t1.FSymbol

	order by SUPNAME,invno
	END
END
