
-- =============================================
-- Author:	Yelena/Debbie
-- Create date: 01/16/2015
-- Description:	This was created for Bill Of Material Outdented Where Used (bomrpt7)
-- Modified:	04/02/15 YS/DP changed order at the ebd of the code	  
--			05/19/2015 DRP:  Needed to add the actual part that the report was being ran for as reference for the users.  Added InquiredPart and InquiredRev
--			06/17/16 YS added customer information to dipslay in the new Inventory Tab in MX
--- 03/28/17 YS changed length of the part_no column from 25 to 35
--029/06/17 Shivshankar P : Display Part_Type ,Part_Class and Discription on One column
--09/12/17 Shivshankar P : Allow the users to create BOM's in the system that are not assigned to any specific customer
-- =============================================

CREATE PROC [dbo].[rptBomOutdentedWhereUsed]
--declare 
@lcuniq_key char(10) =''
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
;with BomOutdented
as
(
SELECT	cast(0 as Integer) as [Level],Eff_Dt,Term_Dt,Item_no,m.PART_SOURC
		,case when M.PART_SOURC = 'MAKE' and m.PHANT_MAKE = 1 then 'Phantom/Make'
			when M.PART_SOURC = 'MAKE' and M.MAKE_BUY = 1 then 'Make/Buy' else '' end as MbPhSource
		,m.Part_no,m.Revision,m.PART_CLASS +  '/' +  m.PART_TYPE +  '/' +LEFT(m.Descript,19) AS Descript,  --029/06/17 Shivshankar P : Display Part_Type ,Part_Class and Discription on One column
		USED_INKIT,m.U_OF_MEAS,Qty,DEPT_NAME,LEFT(m.Bom_Status,8) AS Bom_Status
		--			06/17/16 YS added customer information to dipslay in the new Inventory Tab in MX
		, M.Status,Bom_det.BomParent,'/'+CAST(bomparent as varchar(max)) as [path],@lcPartNo as InquiredPart ,@lcRev as InquiredRev,m.Bomcustno 
FROM	Bom_det 
		INNER JOIN Inventor M ON Bom_det.Bomparent = M.Uniq_key
		inner join DEPTS on bom_det.DEPT_ID = depts.DEPT_ID 
WHERE	Bom_det.Uniq_key = @lcUniq_key
		--and 1 = case when m.BOMCUSTNO in (select CUSTNO from @tcustomer) then 1 else 0 end  --09/12/17 Shivshankar P : Allow the users to create BOM's in the system that are not assigned to any specific customer


UNION ALL

SELECT  P.[Level]+1 as Level,b2.Eff_Dt,b2.Term_Dt,B2.Item_no,m2.PART_SOURC
		,case when M2.PART_SOURC = 'MAKE' and m2.PHANT_MAKE = 1 then 'Phantom/Make'
			when M2.PART_SOURC = 'MAKE' and M2.MAKE_BUY = 1 then 'Make/Buy' else '' end as MbPhSource
		,M2.part_no,M2.Revision,m2.PART_CLASS +  '/' +m2.PART_TYPE +  '/' +LEFT(M2.Descript,19) AS Descript,  --029/06/17 Shivshankar P : Display Part_Type ,Part_Class and Discription on One column
		B2.USED_INKIT,m2.U_OF_MEAS,B2.Qty,d2.DEPT_NAME,LEFT(M2.Bom_Status,8) AS Bom_Status
		--			06/17/16 YS added customer information to dipslay in the new Inventory Tab in MX
		, M2.Status,B2.BomParent,CAST(RTRIM(LTRIM(P.Path))+'/'+B2.bomparent as varchar(max)) as [path] ,@lcPartNo as InquiredPart,@lcRev as InquiredRev, m2.BOMCUSTNO
FROM	BomOutdented as P INNER JOIN BOM_DET B2 ON P.BomParent =B2.Uniq_key 
		INNER JOIN INVENTOR M2 ON B2.BOMPARENT =M2.UNIQ_KEY
		inner join DEPTS d2 on b2.DEPT_ID = d2.DEPT_ID  
WHERE	(P.PART_SOURC='PHANTOM' or P.PART_SOURC='MAKE')
		--and 1 = case when m2.BOMCUSTNO in (select CUSTNO from @tcustomer) then 1 else 0 end   --09/12/17 Shivshankar P : Allow the users to create BOM's in the system that are not assigned to any specific customer
)
 --04/02/15 YS/DP changed order at the ebd of the code	  
 --			06/17/16 YS added customer information to dipslay in the new Inventory Tab in MX
  SELECT E.*,isnull(c.custname,space(35)) as custname
	from BomOutdented E 
	left outer join Customer C on e.bomcustno=c.custno
	ORDER BY path 


end