-- =============================================
-- Author:		Debbie
-- Create date: original report name (yeildpas)   
-- Modified:	06/05/2014 DRP:  Upon review with Yelena we found that we needed to change the date filter to increase the response time.  
--			10/07/2014 DRP:  removed the /* Get PassQty and Failqty*/ section and gathered that type of information within the [insert into @ZQa1121 ] section.  The information that is needed is now all available within the QAINSP table.
--							 added PassQty numeric(16,0),FailQty numeric(16,0) to the  @ZQa1121 table.
-- 07/16/18 VL changed custname from char(35) to char(50)
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================
CREATE PROCEDURE [dbo].[rptQaYieldPass]
--declare
	@lcDateStart as smalldatetime = null
	,@lcDateEnd as smalldatetime = null
	,@lcPassTime as numeric(2,0) = 1
	,@lcDeptId as varchar(max) = 'All'
	,@userId uniqueidentifier= null

as
begin

/*FINAL RESULTS*/
-- 07/16/18 VL changed custname from char(35) to char(50)
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
DECLARE @ZQaYield AS TABLE	(Custname CHAR(50),Part_no char(35),Revision CHAR(8),LotSize NUMERIC(16,0),
							InspQty NUMERIC(16,0),PassQty NUMERIC(16,0),FailQty NUMERIC(16,0),Yield NUMERIC(7,3),[Date] SMALLDATETIME,Inspby CHAR(10))


/* This is where it will combine ZQa11 and ZQa21 together to finally group by Qaseqmain*/
-- 07/16/18 VL changed custname from char(35) to char(50)
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
declare @ZQa1121 as table (Custname Char(50),Part_no char(35),Revision Char(8),LotSize Numeric(16,0),InspQty Numeric(16,0),[Date] smalldatetime
						,Inspby Char(10), Qaseqmain Char(10), Is_Passed numeric (1), Locseqno Char(10),PassQty numeric(16,0),FailQty numeric(16,0))							



/*DEPARTMENT LIST*/		
	DECLARE  @tDepts as tDepts
		DECLARE @Depts TABLE (dept_id char(4))
		-- get list of Departments for @userid with access
		INSERT INTO @tDepts (Dept_id,Dept_name,[Number]) EXEC DeptsView @userid ;
		--SELECT * FROM @tDepts	
		IF @lcDeptId is not null and @lcDeptId <>'' and @lcDeptId<>'All'
			insert into @Depts select * from dbo.[fn_simpleVarcharlistToTable](@lcDeptId,',')
					where CAST (id as CHAR(4)) in (select Dept_id from @tDepts)
		ELSE

		IF  @lcDeptId='All'	
		BEGIN
			INSERT INTO @Depts SELECT Dept_id FROM @tDepts
		END
		
		
		
		
/*BEGINNING OF SELECT STATEMENT*/		
;
WITH 
/* 1. Has Serial number, Has Qadef, Has Qadefloc*/
zQa11_1 as (SELECT	COUNT(*) AS InspQty, Uniq_loc 
			FROM	Qainsp,Qadef,Qadefloc
			WHERE	[DATE] >= @lcDateStart and DATE< DATEDIFF(day,1,@lcdateend)
/*06/05/2014 DRP:	--CONVERT(Date,[Date]) BETWEEN '' +CONVERT(varchar(10), @lcDateStart,112)+'' AND ''+CONVERT(varchar(10),@lcDateEnd,112)+''*/
					AND qainsp.qaseqmain = qadef.qaseqmain 
					AND qadef.locseqno = qadefloc.locseqno 
					AND 1 = CASE WHEN QADEFLOC.CHGDEPT_ID IN(SELECT DEPT_ID FROM @Depts) THEN 1 ELSE 0 END
					AND Qadef.Serialno <> '' 
					AND PassNum = @lcPassTime 
		GROUP BY Qadefloc.Uniq_loc 	
)
,
ZQa11 as (
		SELECT DISTINCT Custname, Part_no, Revision, Qainsp.LotSize
		,ZQa11_1.InspQty, Date, Inspby, Qainsp.Qaseqmain, Is_Passed, Qadef.Locseqno 
		 FROM	ZQa11_1, Qainsp, Woentry, Inventor,Customer,Qadef,Qadefloc
		WHERE Inventor.Uniq_key = Woentry.Uniq_key 
		AND Customer.Custno = Woentry.Custno 
		AND Qainsp.Wono = Woentry.Wono 
		AND CONVERT(Date,[Date]) BETWEEN '' +CONVERT(varchar(10), @lcDateStart,112)+'' AND ''+CONVERT(varchar(10),@lcDateEnd,112)+''
		AND qainsp.qaseqmain = qadef.qaseqmain 
		AND qadef.locseqno = qadefloc.locseqno 
		AND 1 = CASE WHEN QADEFLOC.CHGDEPT_ID IN(SELECT DEPT_ID FROM @Depts) THEN 1 ELSE 0 END
		AND Qadef.Serialno <> '' 
		AND PassNum = @lcPassTime 
		AND Qadefloc.Uniq_loc= Zqa11_1.Uniq_loc
		)
,
/* 2. Has Serial number, Has Qadef, Has no Qadefloc*/
ZQa21_1 as (
		SELECT	COUNT(*) AS InspQty, Qadef.Locseqno 
		FROM	Qainsp, Qadef
		WHERE	CONVERT(Date,[Date]) BETWEEN '' +CONVERT(varchar(10), @lcDateStart,112)+'' AND ''+CONVERT(varchar(10),@lcDateEnd,112)+''
				AND qainsp.qaseqmain = qadef.qaseqmain 
				AND 1 = CASE WHEN QADEf.DEPT_ID IN(SELECT DEPT_ID FROM @Depts) THEN 1 ELSE 0 END 
				AND Qadef.Locseqno NOT IN (SELECT Locseqno FROM ZQa11) 
				AND Qadef.Locseqno NOT IN (SELECT Locseqno FROM Qadefloc) 
				AND qadef.SERIALNO  <> ''
				AND PassNum = @lcPassTime 
		GROUP BY Qadef.Locseqno 
		)
,
ZQa21 as (
		SELECT	Custname, Part_no, Revision, Qainsp.LotSize
				,ZQa21_1.InspQty, Date, Inspby, Qainsp.Qaseqmain, Is_Passed, Qadef.Locseqno 
		FROM	ZQa21_1, Qainsp, Woentry, Inventor,Customer,Qadef
		WHERE	Inventor.Uniq_key = Woentry.Uniq_key 
				AND Customer.Custno = Woentry.Custno 
				AND Qainsp.Wono = Woentry.Wono 
				AND CONVERT(Date,[Date]) BETWEEN '' +CONVERT(varchar(10), @lcDateStart,112)+'' AND ''+CONVERT(varchar(10),@lcDateEnd,112)+'' 
				AND qainsp.qaseqmain = qadef.qaseqmain 
				aND 1 = CASE WHEN QADEf.DEPT_ID IN(SELECT DEPT_ID FROM @Depts) THEN 1 ELSE 0 END 
				AND Qadef.Locseqno NOT IN (SELECT Locseqno FROM ZQa11) 
				AND Qadef.Locseqno NOT IN (SELECT Locseqno FROM Qadefloc) 
				AND qadef.SERIALNO  <> '' 
				AND PassNum = @lcPassTime 
				AND Qadef.Locseqno = ZQa21_1.Locseqno
		) 


		
/* Combine these two SQL set together to finally group by Qaseqmain*/					
insert into @ZQa1121 
		select	custname,Part_no,Revision,LOTSIZE,inspQty,date,INSPBY,QASEQMAIN,is_passed,LOCSEQNO
				,case when Is_Passed = 1 then 1 else 0 end as passQty,(InspQty - case when Is_Passed = 1 then 1 else 0 end) as FailQty 
		from	zQa11
		union 
		select	custname,Part_no,Revision,LOTSIZE,inspQty,date,INSPBY,QASEQMAIN,is_passed,LOCSEQNO 
				,case when Is_Passed = 1 then 1 else 0 end as passQty,(InspQty - case when Is_Passed = 1 then 1 else 0 end) as FailQty 
		from	zQa21


/*10/07/2014 DRP:  removed . . . the information is now pullfrom the qainsp table above int the @zQa1121
/* Get PassQty and Failqty*/
;
with ZQa22 as (
		SELECT	z1.*,case when Is_Passed = 1 then 1 else 0 end as passQty
				,(InspQty - case when Is_Passed = 1 then 1 else 0 end) as FailQty
		FROM	@ZQa1121 as z1 
				)
,
10/07/2014 removal end*/

;
with
/* Get correct InspQty, PassQty, and FailQty*/
ZQa23 as (
		SELECT	Custname, Part_no, Revision, Lotsize, SUM(Inspqty) AS Inspqty, Date, Inspby, Qaseqmain, SUM(PassQty) AS PassQty, SUM(Failqty) AS FailQty 
		FROM	@ZQa1121	--10/07/2014 DRP:  FROM	ZQa22 
		GROUP BY Qaseqmain, Custname, Part_no, Revision, LotSize, Date, Inspby 
		)
,ZQa2 as (
		SELECT	Custname,Part_no,Revision,SUM(Lotsize) AS LotSize, SUM(Inspqty) AS InspQty,SUM(PassQty) AS PassQty,SUM(FailQty) AS FailQty
		,(100*SUM(PassQty)/SUM(InspQty)) AS Yield, Date, Inspby 
		FROM	ZQa23 
		GROUP BY CustName,Part_No,Revision,Date,InspBy
		)
		
insert into @ZQaYield		
	SELECT	Custname, Part_no, Revision, SUM(Lotsize) AS LotSize
			,SUM(InspQty) AS InspQty, SUM(PassQty) AS PassQty
			,SUM(FailQty) AS FailQty, (100*SUM(PassQty)/SUM(InspQty)) AS Yield, Date, Inspby 
	FROM	ZQa2 
	GROUP BY CustName,Part_No,Revision,Date,InspBy
	
select * from @ZQaYield order by Custname,Part_no,Revision,DATE
end