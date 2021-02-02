
-- =============================================
-- Author:			<Debbie>
-- Create date:		<07/28/2014>
-- Description:		<>
-- Used On:			defctloc
-- Modifications:	01/06/2015 DRP:  Added @customerStatus Filter
-- =============================================
CREATE PROCEDURE [dbo].[rptQaDefectDataByLoc]

	@lcDateStart as smalldatetime = NULL
	,@lcDateEnd as smalldatetime = NULL
	,@lcWoNo as varchar(max) = 'All'
	,@lcDeptId as varchar(max) = 'All'
	,@lcDefCode as varchar(max) = 'All'
	,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
	,@userId uniqueidentifier= NULL

as
begin

/*COMPILING APPROVED CUSTOMER PER USERID*/ -- which will be used in each of the below Work Order List Selection
DECLARE  @tCustomer as tCustomer
	-- get list of Customers for @userid with access
	INSERT INTO @tCustomer EXEC aspmnxSP_Getcustomers4user @userid, NULL, @customerStatus ;


/*WORK ORDER LIST*/
declare @tWono as tWono
	declare @Wono table(wono char(10),custno char(10),openclos char(10))
	insert into @Wono select distinct wono, custno,openclos from View_Wo4Qa W where w.custno in (select custno from @tCustomer)
	--select * from @Wono
	--Get list of work order the user is approved to view based off of the approved Customer listing
	if @lcwono is not null and @lcWoNo <> '' and @lcWoNo <> 'All'
		insert into @tWono select * from dbo.[fn_simpleVarcharlistToTable](@lcwono,',')
	else
	if @lcWoNo = 'All'
		Begin 
			insert into @tWono select wono from @Wono
		end
		
--select * from @twono
/*DEPARTMENT LIST*/		
	DECLARE  @tDepts as tDepts
		DECLARE @Depts TABLE (dept_id char(4))
		-- get list of Departments for @userid with access
		INSERT INTO @tDepts (Dept_id,Dept_name,[Number]) EXEC DeptsView @userid ;
		
		IF @lcDeptId is not null and @lcDeptId <>'' and @lcDeptId<>'All'
			insert into @Depts select * from dbo.[fn_simpleVarcharlistToTable](@lcDeptId,',')
					where CAST (id as CHAR(4)) in (select Dept_id from @tDepts)
		ELSE

		IF  @lcDeptId='All'	
		BEGIN
			INSERT INTO @Depts SELECT Dept_id FROM @tDepts
		END
		
/*DEFECT CODE LIST*/	
	declare @DefCode table(DefCode char(10))
	if @lcDefCode is not null and @lcDefCode <> '' and @lcDefCode <> 'All'
		insert into @DefCode select * FROM dbo.[fn_simpleVarcharlistToTable] (@lcDefCode,',')
		else
		if @lcDefCode = 'All'
		begin
			insert into @DefCode Select LEFT(Text2,10) FROM Support WHERE FieldName = 'DEF_CODE'
		end	


/*RECORD SELECT SECTION*/
-- Get all QA data from user's selection first
;WITH 
ZQA AS (
		SELECT	ZWO.Wono,QadefLoc.Location,Woentry.Uniq_key AS ParentUnKy,LocQty,Def_code,ChgDept_id,
				Part_no,Revision,Descript,Part_class,Part_type, Qadef.Qaseqmain AS QALink, Qadefloc.Uniq_key
		FROM	@tWONO ZWO,Woentry,Qadef,QadefLoc LEFT OUTER JOIN Inventor ON QadefLoc.Uniq_key=Inventor.Uniq_key
		WHERE	Qadef.LocSeqNo=QadefLoc.LocSeqNo
				AND Qadef.Wono=ZWO.Wono
				AND Woentry.Wono=ZWO.Wono
				AND CONVERT(Date,DefDate) BETWEEN '' +CONVERT(varchar(10), @lcDateStart,112)+'' AND ''+CONVERT(varchar(10),@lcDateEnd,112)+''
				AND Def_code IN (SELECT Defcode FROM @DefCode)
				AND ChgDept_id IN (SELECT Dept_id FROM @Depts)
)

-- Group, omit Zdefectloc1_1 cursor
,
Zdefectloc2	AS (
		SELECT	Inventor.Part_no AS ProductNo,Inventor.Revision AS ProductRev,
				CASE WHEN Location = '' THEN dbo.PADR('EMPTY',SPACE(30),' ') ELSE Location END AS Location,	ParentUnKy,SUM(LocQty) AS LocQty,
				Def_code, Support.Text3 AS DefDescrp, ZQA.Uniq_key
		FROM	ZQA,Inventor,Support
		WHERE	Inventor.Uniq_key=ParentUnKy
				AND Support.FieldName='DEF_CODE'
				AND LTRIM(RTRIM(Support.Text2))=LTRIM(RTRIM(Def_code))
		GROUP BY ParentUnKy,Inventor.Part_no,Inventor.Revision,Location,Def_code, Support.Text3, ZQA.Uniq_key
		)

-- Final SQL to combine Zdefectloc1_1 and Zdefectloc2
SELECT	Zdefectloc2.ProductNo, Zdefectloc2.ProductRev, Zdefectloc2.Location, Zdefectloc2.ParentUnKy, Zdefectloc2.LocQty, 
		Zdefectloc2.Def_code, Zdefectloc2.DefDescrp,isnull(Inventor.Part_no,'') AS Part_no, isnull(Inventor.Revision,'') AS Revision, 
		isnull(Inventor.Descript,'') AS Descript,isnull(Inventor.Part_class,'') AS Part_class, isnull(Inventor.Part_type,'') AS Part_type
FROM	Zdefectloc2 
		LEFT OUTER JOIN Inventor ON Zdefectloc2.Uniq_key = Inventor.Uniq_key
ORDER BY Zdefectloc2.ProductNo, Zdefectloc2.ProductRev, Zdefectloc2.Location, Def_code, LocQty
end