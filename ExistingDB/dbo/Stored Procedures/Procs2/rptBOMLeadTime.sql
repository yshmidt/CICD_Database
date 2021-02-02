-- =============================================
-- Author:		Yelena Shmidt
-- Create date:	03/17/2014 (My father is 84 today :) )
-- Description:	 Bill of material lead time report (BOMRPT5 in VFP)
-- Modified:		09/08/2014 DRP:  added @lcDate so that I could properly filter out Term_dt and Eff_Dt records from the results. 
--								 added the @Detail table so that I could control the order of the fields in the result, added new fields (cuniq_key), and also would then allow me to update the reults in that table
--								 added ZCust so I could gather the Customer information 
--								 changed the @lcUniqBomParent parameter to be @lcUniqKey, so it will work with CloudManex Parameters that already exist.				
-- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int, removed invtmfhd and replaced with mfgrmaster and invtmpnlink
-- 02/17/2015 VL: Added one more parameter @lcStatus to show only Active parts or not
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- =============================================
CREATE PROCEDURE [dbo].[rptBOMLeadTime]

	--@lcUniqBomParent char(10)=null,		--09/08/2014 DRP replaced with @lcUniqKey
	@lcUniqKey char (10) = null,
	@sortBy char(35)='Part Number',			--Part Number or Lead Time:  This is where the users will pick how they wish for the report to be orderd by
	@userId uniqueidentifier = null,
	@lcStatus char(8) = 'Active'

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    declare @bomDet tBomDet
    declare @custno char(10)=''
    DECLARE @tCustomers tCustomer ;
	-- get list of customers for @userid with access
	-- even if @lcCustomer is not empty we cannot assume that the user has rights to those customers. They might just know the codes of the customers that they have no rights to
	--!! talk to David regarding inactive customers
	--INSERT INTO @tCustomers EXEC [aspmnxSP_GetCustomers4User] @userid ;
    
	SELECT @custno=case when inventor.BOMCUSTNO=dbo.padl('~',10,'0') THEN ' ' ELSE Inventor.BOMCUSTNO END 
			FROM INVENTOR where UNIQ_KEY=@lcUniqKey
	---!!! comment untill resolve with inactive customers	
			--AND inventor.BOMCUSTNO In (SELECT CUSTNO from @tCustomers
			--							UNION
			--							SELECT dbo.PADL('~',10,'0'))
 

 declare @lcDate smalldatetime = null	--09/08/2014 DRP:  ADDED THE @LCDATE TO BE USED TO FILTER OUT THE EFF_DT AND TERM_DT
		select @lcDate = DATEADD(day, DATEDIFF(day, 0, GETDATE()), 0)
--- 03/28/17 YS changed length of the part_no column from 25 to 35		
 declare @Detail as table (Item_no numeric(4,0),LeadTime int,Part_sourc char(10),Part_no char(35),Revision char(8),Part_class char(8),Part_type char(8),Descript char(45),Qty numeric(9, 2)
			--- 03/28/17 YS changed length of the part_no column from 25 to 35
			,CustPartno char(35),Custrev char(8),BomParent char(10),Uniq_key char(10),Dept_id char(4),Item_note varchar(max),Offset numeric(4, 0)
			,Term_dt smalldatetime,Eff_dt smalldatetime,Used_inKit char(1),Custno char(10),Inv_note varchar(max),U_of_meas char(4),Scrap numeric(6, 2),Setupscrap numeric(4, 0)
			,UniqBomno char(10),Phant_Make bit,StdCost numeric(13, 5),Make_buy bit,Status char(8),CUniq_key char(10)) --09/08/2014 DRP:  Added the @Detail table.

--This table will be used to find the Product, revision and uniq_key for the product entered by the user.  The uniq_key from this table will then be used to pull fwd from the [BomIndented] Yelena had created. --09/08/2014 DRP
--- 03/28/17 YS changed length of the part_no column from 25 to 35
DECLARE @t TABLE(ProdNo CHAR (35),ProdRev CHAR(8),ProdDesc char (45),Prod_UNIQkey CHAR (10),ProdMatlType char(10),BomCustNo char(10),BomCustName char(35), Bom_Note text,PLeadTime int)	

INSERT @T	SELECT	part_no,revision,descript,uniq_key,matltype,BOMCUSTNO,isnull(custname,'') as CustName, bom_note
					,CASE WHEN Inventor.Prod_lunit = 'DY' THEN Inventor.Prod_ltime
							WHEN Inventor.Prod_lunit = 'WK' THEN Inventor.Prod_ltime * 5
								WHEN Inventor.Prod_lunit = 'MO' THEN Inventor.Prod_ltime * 20
									ELSE Inventor.Prod_ltime
					END +
					CASE WHEN Inventor.Kit_lunit = 'DY' THEN Inventor.Kit_ltime
							WHEN Inventor.Kit_lunit = 'WK' THEN Inventor.Kit_ltime * 5
								WHEN Inventor.Kit_lunit = 'MO' THEN Inventor.Kit_ltime * 20
									ELSE Inventor.Kit_ltime
					END as PLeadTime
			from	inventor 
					left outer join CUSTOMER on inventor.BOMCUSTNO = customer.CUSTNO 
			where	Uniq_key=@lcUniqKey  AND PART_SOURC <> 'CONSG'


INSERT into @bomDet exec Bom_det_view @lcUniqKey 

-- find lead time for phantom parts
-- 02/17/15 VL added 9 and 10 parameters to fn_PhantomSubSelect
;with phantom
as
(
select MAX(p.leadtime) as phantomleadtime,B.BomParent,b.Uniq_key,b.Item_no,b.UniqBomno 
	FROM @bomDet B  
--CROSS apply dbo.fn_phantomSubSelect(B.Uniq_key,1,'t',getdate(),'F','All','F',0,0) p
CROSS apply dbo.fn_phantomSubSelect(B.Uniq_key,1,'t',getdate(),'F','All','F',0,0, CASE WHEN @lcStatus = 'Active' THEN 0 ELSE 1 END) p
WHERE B.Part_sourc ='PHANTOM'
GROUP BY B.BomParent ,B.BomParent,b.Uniq_key,b.Item_no,b.UniqBomno 
)
UPDATE @bomDet set LeadTime = Phantom.phantomleadtime FROM @bomdet b inner join phantom on phantom.UniqBomno = b.UniqBomno

	/*09/08/2014 DRP:  removed the below section*//*
		--SELECT CASE WHEN C.Uniq_key IS not null then  c.Uniq_key else b.uniq_key end  as CUniq_key,
		--	CASE WHEN c.CUSTPARTNO IS NOT null then c.CUSTPARTNO else b.CustPartno end as [Customer Part Number],
		--	CASE WHEN c.CUSTREV IS NOT null then c.CUSTREV else b.Custrev end as [Customer Revision],
		--	B.* ,ISNULL(D.DEPT_NAME,space(25)) as Dept_name, 
		--	isnull(m.PARTMFGR,space(8)) as PartMfgr ,isnull(m.MFGR_PT_NO,space(35)) as mfgr_pt_no ,isnull(m.MATLTYPE,space(10)) as MatlType 
		--FROM @bomDet B LEFT OUTER JOIN INVENTOR C ON b.Uniq_key=c.INT_UNIQ and @custno=c.CUSTNO and b.part_sourc<>'CONSG'
		--LEFT OUTER JOIN INVTMFHD M on c.UNIQ_KEY=M.UNIQ_KEY and c.UNIQ_KEY is not null and M.IS_DELETED =0
		--LEFT OUTER JOIN DEPTS D ON B.Dept_id =D.DEPT_ID 
		--WHERE 
		--	NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent 
		--	AND A.UNIQ_KEY =  CASE WHEN C.Uniq_key IS not null then  c.Uniq_key else b.uniq_key END 
		--	AND A.PARTMFGR =M.PARTMFGR AND A.MFGR_PT_NO =M.MFGR_PT_NO)
		--ORDER BY 
		--CASE @sortBy WHEN 'Lead Time' THEN b.LeadTime END,
		--CASE @sortBy WHEN 'Part Number' THEN  b.Part_no END	
	*/

--09/08/2014 DRP:  I needed to gather the cUniq_key information so I could use that to determine and display the Customer Part number information when needed and then insert that into the @Detail Table
;
with
ZCust
as
(
select	b.Item_no,LeadTime,b.Part_sourc,b.Part_no,b.Revision,b.Part_class,b.Part_type,b.Descript,b.Qty,case when c.UNIQ_KEY is NOT null then c.CUSTPARTNO else b.CustPartno end as CustPartNo
		,case when c.UNIQ_KEY is NOT null then c.CUSTrev else b.Custrev end asCustrev,BomParent,b.Uniq_key,b.Dept_id,b.Item_note,b.Offset,b.Term_dt,b.Eff_dt
		,case when b.Used_inKit = 'F' then 'N' else 'Y' end as Used_inKit,b.Custno,b.Inv_note,b.U_of_meas,b.Scrap,b.Setupscrap,b.UniqBomno,b.Phant_Make,b.StdCost,b.Make_buy
		,b.Status,CASE WHEN C.Uniq_key IS not null then  c.Uniq_key else b.uniq_key end  as CUniq_key
from	@bomDet as B 
		left outer join INVENTOR as C on b.Uniq_key = C.INT_UNIQ
)
insert into @Detail select * from ZCust

--09-08-2014 DRP:  Gathered the Bom Avil Information from the @Detail Table 
;
with
BomWithAvl
	AS
	(
	select B.* ,
		M.PARTMFGR ,M.MFGR_PT_NO,L.ORDERPREF ,L.UNIQMFGRHD,M.MatlType as MfgrMatlType,M.MATLTYPEVALUE
 		FROM @Detail B LEFT OUTER JOIN InvtMpnLink L ON B.CUniq_key=L.UNIQ_KEY
		LEFT OUTER JOIN Mfgrmaster M ON L.MfgrMasterId=M.MfgrMasterId 
		WHERE B.CUniq_Key<>' '
		-- 03/06/15 YS make sure if record is not exists in InvtMpnLink we still get it added or l.is_deleted is null
		AND (L.IS_DELETED =0 or l.is_deleted is null)
		and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.CUniq_Key and A.PARTMFGR =m.PARTMFGR and A.MFGR_PT_NO =m.MFGR_PT_NO )
	UNION ALL
		select B.*,m.PARTMFGR ,m.MFGR_PT_NO,l.ORDERPREF ,l.UNIQMFGRHD ,m.MatlType as MfgrMatlType,m.MATLTYPEVALUE
		-- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int
		--FROM @Detail B LEFT OUTER JOIN INVTMFHD ON B.UNIQ_KEY=INVTMFHD.UNIQ_KEY 
		FROM @Detail B LEFT OUTER JOIN INVTMPNLINK L ON B.UNIQ_KEY=L.UNIQ_KEY
		LEFT OUTER JOIN MfgrMaster M ON L.MfgrMasterId=M.MfgrMasterId
		WHERE B.CUniq_Key=' '
		AND (L.IS_DELETED =0 or l.is_deleted is null) 
		and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.UNIQ_KEY and A.PARTMFGR =m.PARTMFGR and A.MFGR_PT_NO =m.MFGR_PT_NO )
		)
-- 02/17/15 VL added to consider status if show only active parts or not		
select	E.Item_no,t.PLeadTime+E.LeadTime as LeadTime,E.Part_sourc,E.Part_no,E.Revision,E.Part_class,E.Part_type,E.Descript,E.Qty,E.CustPartno
		,E.Custrev,BomParent,E.Uniq_key,E.Dept_id,E.Used_inKit,E.Custno,E.Inv_note,E.U_of_meas,E.Scrap,E.Setupscrap,E.UniqBomno,E.Phant_Make,E.StdCost
		,E.Make_buy,E.Status,e.PARTMFGR,e.MFGR_PT_NO,e.MfgrMatlType,E.Cuniq_key,T.ProdNo,T.ProdRev,t.ProdDesc,t.BomCustName,t.ProdMatlType,depts.DEPT_NAME,E.Item_note,E.Offset,E.Term_dt,E.Eff_dt 
from	BomWithAvl as E 
		cross join @t as T
		inner join DEPTS on e.Dept_id = depts.DEPT_ID
where  1 = CASE WHEN  @lcDate IS NULL THEN 1
						WHEN  @lcDate IS NOT NULL 
							  AND (Eff_dt is null or DATEDIFF(day,EFF_DT,@lcDate)>=0)
							  AND (Term_dt is Null or DATEDIFF(day,TERM_DT,@lcDate)<0) THEN 1 ELSE 0 END
							  AND 1 = CASE @lcStatus WHEN 'Active' THEN CASE WHEN Status = 'Active' THEN 1 ELSE 0 END ELSE 1 END
ORDER BY 
	CASE @sortBy WHEN 'Part Number' THEN E.Part_no+E.Revision+cast(e.Item_no as CHAR(4))+e.PARTMFGR+e.MFGR_PT_NO END,
	case @sortBy when 'Lead Time' then e.LeadTime end desc

END