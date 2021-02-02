
-- =============================================
-- Author:	Yelena/Debbie
-- Create date: 01/16/2015
-- Description:	report on part number and manufacturer where used
-- Modified: 03/25/15 YS used [rptBomOutdentedWhereUsed] as a base for this quick view
---	added new parameter @mfgrmasterid to use it to display where used for the part and manufacturer pn
--- need to add new quick view to mnxReports		 
--  04/02/15 YS/DP changed order at the ebd of the code	 
--  05/19/2015 DRP:  Needed to add the actual part that the report was being ran for as reference for the users.  Added InquiredPart and InquiredRev 
--  05/27/16 YS changed join with the "depts" table to left outer join, in case somehow dept_id is not present in the depts table
 --- 03/28/17 YS changed length of the part_no column from 25 to 35
 -- =============================================
CREATE PROC [dbo].[rptBomOutdentedWhereUsedMfgr]
--declare 
@lcuniq_key char(10) =''
,@mfgrmasterid bigint=NULL		---- 03/11/15 YS added new parameter @mfgrmasterid 
,@customerStatus varchar (20) = 'All'	--This is used to pass the customer status to the [aspmnxSP_GetCustomers4User] below.
,@userId uniqueidentifier= null

as 
begin 


/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,@customerStatus ;
		--SELECT * FROM @tCustomer	

/*INQUIRY DETAIL*/	--05/19/2015 DRP:  Added
--- 03/28/17 YS changed length of the part_no column from 25 to 35
DECLARE @lcPartNo as char(35),@lcRev as char(8)	
select @lcPartNo = part_no,@lcRev = Revision from inventor where @lcuniq_key = inventor.UNIQ_KEY
	
/*SELECT STATEMENT*/
---03/11/15 YS added new parameter @mfgrmasterid 
--  05/27/16 YS changed join with the "depts" table to left outer join, in case somehow dept_id is not present in the depts table
;with BomOutdented
	as
	(
	SELECT	cast(0 as Integer) as [Level],Eff_Dt,Term_Dt,Item_no,m.PART_SOURC
			,case when M.PART_SOURC = 'MAKE' and m.PHANT_MAKE = 1 then 'Phantom/Make'
				when M.PART_SOURC = 'MAKE' and M.MAKE_BUY = 1 then 'Make/Buy' else '' end as MbPhSource
			,M.Part_no,M.Revision,M.PART_CLASS,M.PART_TYPE,LEFT(M.Descript,19) AS Descript,USED_INKIT,M.U_OF_MEAS,Qty,
			--Depts.DEPT_NAME,
			--  05/27/16 YS changed join with the "depts" table to left outer join, in case somehow dept_id is not present in the depts table
			Bom_det.Dept_id,
			LEFT(M.Bom_Status,8) AS Bom_Status
			, M.Status,Bom_det.BomParent,'/'+CAST(bomparent as varchar(max)) as [path],@lcPartNo as InquiredPart ,@lcRev as InquiredRev
	FROM	Bom_det 
			INNER JOIN Inventor M ON Bom_det.Bomparent = M.Uniq_key
			--  05/27/16 YS changed join with the "depts" table to left outer join and move it to the last sql
			--inner join DEPTS on bom_det.DEPT_ID = depts.DEPT_ID 
			LEFT OUTER JOIN Inventor CustI on BOM_DET.uniq_key=CustI.Int_uniq and M.BomCustno=CustI.Custno and CustI.part_sourc='CONSG'
			inner join 
				(SELECT M.MfgrMasterid,L.Uniq_key,L.Uniqmfgrhd,M.PartMfgr,M.Mfgr_pt_no 
				from MfgrMaster M inner join InvtMPNLink L on M.MfgrMasterid=L.mfgrMasterid where M.mfgrmasterid=@MfgrMasterId) AML 
				ON (CustI.Uniq_key is null and bom_det.uniq_key=AML.Uniq_key) OR (CustI.Uniq_key is NOT null and custI.uniq_key=AML.Uniq_key)
	WHERE	@mfgrmasterid IS NOT NULL 
		AND Bom_det.Uniq_key = @lcUniq_key
			and EXISTS(select 1 from @tcustomer tc where tc.custno= m.BOMCUSTNO) 
			and NOT EXISTS (SELECT 1 FROM ANTIAVL A where A.BOMPARENT =Bom_det.bomParent 
			and ((CustI.Uniq_key is null and A.Uniq_key=Bom_det.Uniq_key) OR (CustI.Uniq_key is not null and A.Uniq_key=CustI.Uniq_key) )
			and A.PARTMFGR =AML.PARTMFGR and A.MFGR_PT_NO =AML.MFGR_PT_NO )
	UNION ALL
	SELECT  P.[Level]+1 as Level,b2.Eff_Dt,b2.Term_Dt,B2.Item_no,m2.PART_SOURC
			,case when M2.PART_SOURC = 'MAKE' and m2.PHANT_MAKE = 1 then 'Phantom/Make'
				when M2.PART_SOURC = 'MAKE' and M2.MAKE_BUY = 1 then 'Make/Buy' else '' end as MbPhSource
			,M2.part_no,M2.Revision,m2.PART_CLASS,m2.PART_TYPE,LEFT(M2.Descript,19) AS Descript,B2.USED_INKIT,m2.U_OF_MEAS,B2.Qty,
			--  05/27/16 YS changed join with the "depts" table to left outer join and move it to the last sql. Cannot have outer join in the recursive sql
			B2.DEPT_id,
			LEFT(M2.Bom_Status,8) AS Bom_Status
			, M2.Status,B2.BomParent,CAST(RTRIM(LTRIM(P.Path))+'/'+B2.bomparent as varchar(max)) as [path] ,@lcPartNo as InquiredPart ,@lcRev as InquiredRev
	FROM	BomOutdented as P INNER JOIN BOM_DET B2 ON P.BomParent =B2.Uniq_key 
			INNER JOIN INVENTOR M2 ON B2.BOMPARENT =M2.UNIQ_KEY
			inner join DEPTS d2 on b2.DEPT_ID = d2.DEPT_ID  
	WHERE	@mfgrmasterid IS NOT NULL 
		AND (P.PART_SOURC='PHANTOM' or P.PART_SOURC='MAKE')
			and 1 = case when m2.BOMCUSTNO in (select CUSTNO from @tcustomer) then 1 else 0 end
	)
	--04/02/15 YS/DP changed order at the ebd of the code	 
	--  05/27/16 YS changed join with the "depts" table to left outer join and move it to the last sql. Cannot have outer join in the recursive sql
  SELECT E.* ,ISNULL(depts.dept_name,space(25)) as dept_name
     from BomOutdented E LEFT OUTER JOIN Depts ON E.Dept_id=depts.dept_id
   ORDER BY path 

end

