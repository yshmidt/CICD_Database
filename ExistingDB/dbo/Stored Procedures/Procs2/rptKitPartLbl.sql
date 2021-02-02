-- =============================================
-- Author: Debbie
-- Create date: 06/10/2013
-- Description: Compiles the details for the Kit Part Labels
-- Used On: kitlablz.rpt, kitplabl.rpt and kitplabr
-- Modifications: 07/29/2013 DRP: Added the @lcOpenItems parameter and also the LabelQty Field
-- 08/13/2013 DRP: ADDED ANOTHER SELECTION STATEMENT THAT WILL BE USED FOR THE LABEL GRID
-- ALSO ADDED Label_Id field. this will be populated with the a unique indentifier each time the procedure is ran, it will then be used to pass to the label report itself from the grid selection
-- 10/02/2013 DRP: Found MatlType char (8) should have been MatlType char (10)
-- 04/30/2014 DRP: I believe when I was testing the procedure for some of the above changes that I accidentally left some select statements active. This was then causing the reports not to work properly because there were too many results.
-- 10/08/2014 DRP: Added RefDesg to the results so I can use this procedure for both Kit Label and Kit Label with Ref Desg
-- needed to add UniqBomNo to the @Results so I could use that to gather the REference Desg. Added <<,isnull(dbo.fnBomRefDesg(R2.UniqBomNo),'') as RefDesg>> to the final results
-- 02/17/2015 VL: added Eff_dt and status ='Active'
-- 03/06/2015 DS: Changed column order
--- 03/28/17 YS changed length of the part_no column from 25 to 35	
-- 05/01/17 DRP:  added the @lcLabelQty parameter per request of the users.  This way they can enter in a Label Qty to be populated into the grid, but should also then be able to change within the grid if needed.
-- there was code to default 0 for labelqty of there were no shortages, but since we are now implementing the labeqty parameter we will have to take what is entered in as the parameter. 
-- 05/07/20 VL changed table variable data structure because KitMainView was changed
-- 10/02/20 VL added allocatedQty, userid into @ZKitMainView because [KitMainView] are changed
-- =============================================
CREATE PROCEDURE [dbo].[rptKitPartLbl]
--declare
@lcWono AS char(10) = '' -- Work order number
,@lcIgnore as char(20) = 'No' -- used within the report to indicate if the user elects to ignore any of the scrap settings.
-- At this point in time I am leaving it as defaulted 'No' and I am not pulling it fwd into the report itself. I an leaving it, just in case it might want to be used in the future
,@lcOpenItems as char(5) = 'No' -- 07/29/2013 DRP: ('Yes' or 'No') This will indicate if the users would like labels printed for All items on the kit or Open items only. Open items are parts that still have shortages.
-- if 'Yes' is selected it will only display Open Items, if 'No' is selected then it will display All items from the kit.
,@lcLabelQty as int = null		--05/01/17 DRP:  added
,@userId uniqueidentifier = null
as
begin
SET NOCOUNT ON;
SET @lcWono=dbo.PADL(@lcWono,10,'0')
declare @lcKitStatus Char(10)
--Main Kitting Information
--- 03/28/17 YS changed length of the part_no column from 25 to 35	
-- 05/07/20 VL changed table variable data structure because KitMainView was changed
-- 10/02/20 VL added allocatedQty, userid into @ZKitMainView because [KitMainView] are changed
DECLARE @ZKitMainView TABLE (DispPart_no char(35),Req_Qty numeric(12,2),Phantom char(1),DispRevision char(8),Part_class char(8),Part_type char(8),Kaseqnum char(10)
,Entrydate smalldatetime,Initials char(8)--,Rej_qty numeric(12,2),Rej_date smalldatetime,Rej_reson char(10)
,Kitclosed bit,Act_qty numeric(12,2)
,Uniq_key char(10),Dept_id char(4),Dept_name char(25),Wono char(10),Scrap numeric(6,2),Setupscrap numeric(4,0),Bomparent char(10)
,Shortqty numeric(12,2),Lineshort bit,Part_sourc char(10),Qty numeric(12,2),Descript char(45),Inv_note text,U_of_meas char(4),Pur_uofm char(4)
,Ref_des char(15),
--- 03/28/17 YS changed length of the part_no column from 25 to 35	
Part_no char(35),Custpartno char(35),Ignorekit bit,Phant_make bit,Revision char(8),Serialyes bit,Matltype char(10),CustRev char(8)
-- 10/02/20 VL added allocatedQty, userid into @ZKitMainView because [KitMainView] are changed
,allocatedQty numeric(12,2), userid uniqueidentifier)

--Table that will compile the final results
--10/02/2013 DRP: Found MatlType char (8) should have been MatlType char (10)
--declare @results table (KitStatus char(10),Custname char(35),OrderDate smalldatetime,ParentBomPn char(25),ParentBomRev char(8),ParentBomDesc char(45),ParentMatlType char(10)
-- ,BldQty numeric (7,0),Item_No numeric(4,0),DispPart_No varchar(max),DispRevision char(8),Req_Qty numeric(12,2),Phantom char(1),Part_Class char(8)
-- ,Part_Type char(8),Kaseqnum char(10),KitClosed bit,Act_Qty numeric(12,2),Uniq_key char(10),Dept_Id char(4),Dept_Name char(25),Wono char(10),Scrap numeric (6,2)
-- ,SetupScrap numeric (4,0),BomParent char(10),ShortQty numeric(12,2),LineShort bit,Part_Sourc char(10),Qty numeric(12,2),Descript char(45),U_of_Meas char(4)
-- ,Part_No char(25),CustPartNo char(25),IgnoreKit bit,Phant_Make bit,Revision char(8),MatlType char(10),CustRev char(8),UniqBomNo char(10),Label_Id uniqueidentifier)
--03/06/15 DS Changed the order around
-- 07/16/18 VL changed custname from char(35) to char(50)
declare @results table (Item_No numeric(4,0),Part_Sourc char(10),DispPart_No varchar(max),DispRevision char(8),Descript char(45),Part_Class char(8),Part_Type char(8),U_of_Meas char(4),
Req_Qty numeric(12,2),ShortQty numeric(12,2),MatlType char(10),Custname char(50),
--- 03/28/17 YS changed length of the part_no column from 25 to 35	
CustPartNo char(35),CustRev char(8),
--- 03/28/17 YS changed length of the part_no column from 25 to 35	
KitStatus char(10),OrderDate smalldatetime,ParentBomPn char(35),ParentBomRev char(8),ParentBomDesc char(45),ParentMatlType char(10)
,BldQty numeric (7,0),Phantom char(1),Kaseqnum char(10),KitClosed bit,Act_Qty numeric(12,2),Uniq_key char(10),Dept_Id char(4),Dept_Name char(25),Wono char(10),Scrap numeric (6,2)
,SetupScrap numeric (4,0),BomParent char(10),LineShort bit,Qty numeric(12,2)
--- 03/28/17 YS changed length of the part_no column from 25 to 35	
,Part_No char(35),IgnoreKit bit,Phant_Make bit,Revision char(8),UniqBomNo char(10),Label_Id uniqueidentifier)
select @lcKitStatus = woentry.KITSTATUS from WOENTRY where @lcWono = woentry.WONO
IF @@ROWCOUNT <> 0
BEGIN
--This section will then pull all of the detailed information from the KaMAIN tables because the kit has been put into process.
--Otherwise, if not in process ever we will then have to later pull from the BOM information
if ( @lcKitStatus <> '')
Begin
INSERT @ZKitMainView EXEC [KitMainView] @lcwono
insert into @results
--select woentry.kitstatus,isnull(customer.custname,'') as CustName,woentry.ORDERDATE,i4.PART_NO as ParentBomPn,i4.REVISION as ParentBomRev,i4.DESCRIPT as ParentBomDesc,i4.MATLTYPE
-- ,woentry.bldqty
-- , isnull(bom_det.item_no,0)as Item_no,zmain2.DispPart_no,zmain2.DispRevision
-- ,case when @lcIgnore = 'No' then ZMain2.Req_Qty
-- else case when @lcIgnore = 'Ignore Scrap' then zmain2.Req_Qty-round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,0)
-- else case when @lcIgnore = 'Ignore Setup Scrap' then zmain2.req_qty-zmain2.setupscrap
-- else case when @lcIgnore = 'Ignore Both Scraps' then zmain2.req_qty-zmain2.setupscrap-round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,0) end end end end as Req_Qty
-- ,ZMain2.Phantom,ZMain2.Part_class,ZMain2.Part_type,ZMain2.Kaseqnum,ZMain2.Kitclosed,ZMain2.Act_qty,zmain2.Uniq_key,ZMain2.Dept_id,ZMain2.Dept_name
-- ,ZMain2.Wono,ZMain2.Scrap,ZMain2.Setupscrap,ZMain2.Bomparent
-- ,case when @lcIgnore = 'No' then ZMain2.ShortQty
-- else case when @lcIgnore = 'Ignore Scrap' then zmain2.Shortqty - round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,0)
-- else case when @lcIgnore = 'Ignore Setup Scrap' then zmain2.shortqty-zmain2.setupscrap
-- else case when @lcIgnore = 'Ignore Both Scraps' then zmain2.shortqty-zmain2.setupscrap-round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,0) end end end end as ShortQty
-- ,ZMain2.Lineshort,ZMain2.Part_sourc,ZMain2.Qty,ZMain2.Descript,ZMain2.U_of_meas,ZMain2.Part_no
-- ,isnull(CASE WHEN zmain2.PART_SOURC = 'consg' THEN DispPart_no else I5.custPARTNO end, '') as CustPartNo,ZMain2.Ignorekit
-- ,ZMain2.Phant_make,ZMain2.Revision,ZMain2.Matltype,isnull(case when zmain2.part_sourc = 'consg' then DispRevision else I5.CustRev end,'') as CustRev
-- ,UniqBomNo
-- ,NEWID()
--from @ZKitMainView as ZMain2
-- left outer join bom_det on zmain2.Bomparent = bom_det.BOMPARENT and zmain2.uniq_key = bom_det.Uniq_key
-- inner join WOENTRY on zmain2.Wono = woentry.WONO
-- inner join CUSTOMER on woentry.custno = customer.CUSTNO
-- inner join INVENTOR as I4 on woentry.UNIQ_KEY = i4.UNIQ_KEY
-- left outer join INVENTOR as I5 on ZMain2.Uniq_key = i5.INT_UNIQ and woentry.CUSTNO=i5.CUSTNO
select isnull(bom_det.item_no,0)as Item_no,
ZMain2.Part_sourc,
zmain2.DispPart_no,
zmain2.DispRevision,
ZMain2.Descript,
ZMain2.Part_class,
ZMain2.Part_type,
ZMain2.U_of_meas,
case when @lcIgnore = 'No' then ZMain2.Req_Qty
else case when @lcIgnore = 'Ignore Scrap' then zmain2.Req_Qty-round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,0)
else case when @lcIgnore = 'Ignore Setup Scrap' then zmain2.req_qty-zmain2.setupscrap
else case when @lcIgnore = 'Ignore Both Scraps' then zmain2.req_qty-zmain2.setupscrap-round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,0) end end end end as Req_Qty,
case when @lcIgnore = 'No' then ZMain2.ShortQty
else case when @lcIgnore = 'Ignore Scrap' then zmain2.Shortqty - round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,0)
else case when @lcIgnore = 'Ignore Setup Scrap' then zmain2.shortqty-zmain2.setupscrap
else case when @lcIgnore = 'Ignore Both Scraps' then zmain2.shortqty-zmain2.setupscrap-round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,0) end end end end as ShortQty,
ZMain2.Matltype,
isnull(customer.custname,'') as CustName,
isnull(CASE WHEN zmain2.PART_SOURC = 'consg' THEN DispPart_no else I5.custPARTNO end, '') as CustPartNo,
isnull(case when zmain2.part_sourc = 'consg' then DispRevision else I5.CustRev end,'') as CustRev,
woentry.kitstatus,
woentry.ORDERDATE,
i4.PART_NO as ParentBomPn,
i4.REVISION as ParentBomRev,
i4.DESCRIPT as ParentBomDesc,
i4.MATLTYPE,
woentry.bldqty
, ZMain2.Phantom,
ZMain2.Kaseqnum,
ZMain2.Kitclosed,
ZMain2.Act_qty,
zmain2.Uniq_key,
ZMain2.Dept_id,
ZMain2.Dept_name
,ZMain2.Wono,
ZMain2.Scrap,
ZMain2.Setupscrap,
ZMain2.Bomparent
,ZMain2.Lineshort,
ZMain2.Qty,
ZMain2.Part_no
,ZMain2.Ignorekit
,ZMain2.Phant_make,
ZMain2.Revision,
UniqBomNo
,NEWID()
from @ZKitMainView as ZMain2
left outer join bom_det on zmain2.Bomparent = bom_det.BOMPARENT and zmain2.uniq_key = bom_det.Uniq_key
inner join WOENTRY on zmain2.Wono = woentry.WONO
inner join CUSTOMER on woentry.custno = customer.CUSTNO
inner join INVENTOR as I4 on woentry.UNIQ_KEY = i4.UNIQ_KEY
left outer join INVENTOR as I5 on ZMain2.Uniq_key = i5.INT_UNIQ and woentry.CUSTNO=i5.CUSTNO
--08/13/2013 DRP: ADDED ANOTHER SELECTION STATEMENT THAT WILL BE USED FOR THE LABEL GRID
--08/13/2013 DRP: ALSO ADDED LabelId field. this will be populated with the kaseqnum so that it can be passed to the label report itself from the grid selection
/*04/30/2014 The below section was accidentally left in the procedure when it should have been deactivated.
select r1.Dept_Name,r1.DispPart_No,r1.DispRevision,r1.CustPartNo,r1.CustRev,r1.Part_Sourc,r1.Descript,CAST (1 as numeric (3,0))as LabelQty,r1.Label_id
from @results as R1
where 1 = case when @lcOpenItems = 'No' then 1 when @lcOpenItems = 'Yes' and r1.ShortQty > 0.00 then 1 else 0 end
04/30/2014 END*/
--07/29/2013 DRP: ADDED THE LabelQty FIELD. AND ALSO ADDED THE WHERE SECTION FOR THE @lcItems PARAMETER. IF USERS SELECTS OPEN THEN ONLY ITEMS THAT HAVE NOT YET BEEN FULFILLED WILL DISPLAY
select R2.*
--,case when R2.ShortQty > 0.00 then CAST (1 as numeric (3,0)) else CAST(0 as numeric(3,0)) end as LabelQty	--05/01/17 drp:  REPLACED WITH BELOW
,case when @lcLabelQty is null then 1 else @lcLabelQty end as LabelQty
,isnull(dbo.fnBomRefDesg(R2.UniqBomNo),'') as RefDesg
from @results as R2
where 1 = case when @lcOpenItems = 'No' then 1 when @lcOpenItems = 'Yes' and r2.ShortQty > 0.00 then 1 else 0 end
end
--if the kit has never been put into process then the below section will gather the information from the Bill of Material
else if ( @lcKitStatus = '')
begin
declare @lcBomParent char(10)
,@IncludeMakebuy bit = 1
,@ShowIndentation bit =1
--,@UserId uniqueidentifier=NULL
,@gridId varchar(50)= null
select @lcBomParent = woentry.UNIQ_KEY from WOENTRY where @lcWono = woentry.wono
--- 03/28/17 YS changed length of the part_no column from 25 to 35	
declare @tBom table (bomParent char(10),bomcustno char(10),UNIQ_KEY char(10),item_no numeric(4),PART_NO char(35),Revision char(8),Part_sourc char(10)
,ViewPartNo varchar(max),ViewRevision char(8),Part_class char(8),Part_type char(8),Descript char(45),MatlType char (10),Dept_id char(8)
,Item_note varchar(max),Offset numeric(4,0),Term_dt date,Eff_dt date, Used_inKit char(1),custno char(10),Inv_note varchar(max)
,U_of_meas char(4), Scrap numeric(6,2),SetupScrap numeric(4,0),USESETSCRP bit,STDBLDQTY numeric(8,0),Phantom_make bit,StdCost numeric(13,5)
,Make_buy bit,Status char(10),TopQty numeric(9,2),qty numeric(9,2),Level integer,path varchar(max),sort varchar(max),UniqBomNo char(10))
;
WITH BomExplode as (
SELECT B.bomParent,M.BOMCUSTNO,B.UNIQ_KEY, B.item_no,C.PART_NO,C.Revision,c.Part_sourc
,CAST(CASE WHEN C.part_sourc='CONSG' THEN C.Custpartno ELSE C.Part_no END as varchar(max)) AS ViewPartNo
,CASE WHEN C.part_sourc='CONSG' THEN C.Custrev ELSE C.Revision END AS ViewRevision,C.Part_class,C.Part_type,C.Descript,c.MATLTYPE
,B.Dept_id, B.Item_note, B.Offset, B.Term_dt, B.Eff_dt, B.Used_inKit,C.Custno, C.Inv_note, C.U_of_meas, C.Scrap, C.Setupscrap,M.USESETSCRP
,M.STDBLDQTY, C.Phant_Make, C.StdCost, C.Make_buy, C.Status,cast(1.00 as numeric(9,2)) as TopQty,B.qty as Qty, cast(0 as Integer) as Level
,'/'+CAST(bomparent as varchar(max)) as path,CAST(dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY Item_no) as varchar(max))),4,'0') as varchar(max)) AS Sort
,B.UNIQBOMNO
FROM BOM_DET B INNER JOIN INVENTOR C ON B.UNIQ_KEY =C.UNIQ_KEY
INNER JOIN INVENTOR M on B.BOMPARENT =M.UNIQ_KEY
WHERE B.BOMPARENT=@lcBomParent
UNION ALL
SELECT B2.BOMPARENT, M2.BOMCUSTNO ,B2.Uniq_key,B2.item_no ,C2.PART_NO,C2.Revision,c2.Part_sourc
,CAST(CASE WHEN @ShowIndentation=1 THEN SPACE((P.level+1)*4) ELSE SPACE(0) END +CASE WHEN C2.part_sourc='CONSG' THEN C2.Custpartno ELSE C2.Part_no END as varchar(max)) AS ViewPartNo
,CASE WHEN C2.part_sourc='CONSG' THEN C2.Custrev ELSE C2.Revision END AS ViewRevision,C2.Part_class, C2.Part_type, C2.Descript,c2.MATLTYPE,B2.Dept_id
,B2.Item_note, B2.Offset, B2.Term_dt, B2.Eff_dt, B2.Used_inKit,C2.Custno,C2.Inv_note, C2.U_of_meas, C2.Scrap, C2.Setupscrap,M2.USESETSCRP,M2.STDBLDQTY
,C2.Phant_Make, C2.StdCost, C2.Make_buy, C2.Status,P.Qty as TopQty,B2.QTY, P.Level+1,CAST(RTRIM(LTRIM(P.Path))+'/'+B2.bomparent as varchar(max)) as path
,CAST(RTRIM(p.Sort)+'-'+ dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY b2.Item_no) as varchar(4))),4,'0') as varchar(max)) AS Sort,B2.UNIQBOMNO
FROM BomExplode as P
INNER JOIN BOM_DET as B2 ON P.UNIQ_KEY =B2.BOMPARENT
INNER JOIN INVENTOR C2 ON B2.UNIQ_KEY =C2.UNIQ_KEY
INNER JOIN INVENTOR M2 ON B2.BOMPARENT =M2.UNIQ_KEY
WHERE P.PART_SOURC='PHANTOM'
or (p.PART_SOURC = 'MAKE' and P.PHANT_MAKE = 1)
--**THE BELOW WAS THE CODE THAT YELENA WAS USING WITHIN THE BOMINDENTED PROCEDURE, BUT IT DID NOT WORK FOR THIS REPORT
--**SO I TOOK THE ENTIRE CODE FROM THE PROCEDURE AND MADE THE BELOW CHANGES BY REMOVING THE BELOW
--or (P.PART_SOURC = 'MAKE' and P.MAKE_BUY = 1)
--or (P.PART_SOURC='MAKE' and P.MAKE_BUY=CASE WHEN @IncludeMakeBuy=1 THEN P.MAKE_BUY ELSE 0 END)
)
insert into @tbom SELECT E.* from BomExplode E
-- 02/17/15 also think need next line
where (Term_dt>GETDATE() OR Term_dt IS NULL)
-- 02/17/15 VL added Eff_dt and status ='Active'
AND (Eff_dt<GETDATE() OR Eff_dt IS NULL)
AND E.Status = 'Active'
ORDER BY sort OPTION (MAXRECURSION 100)
insert into @results
--select woentry.kitstatus,ISNULL(customer.custname,'') as CustName,woentry.ORDERDATE,i4.part_no as ParentBomPn,i4.REVISION as ParentBomRev,i4.DESCRIPT as ParentBomDesc,i4.MATLTYPE
-- ,woentry.BLDQTY,bom_det.item_no,t1.Part_no,t1.Revision
-- ,case when @lcIgnore = 'No' then ((T1.topqty*T1.qty)*woentry.BLDQTY)+T1.SetupScrap+ round((((t1.Qty * woentry.BldQty)*T1.Scrap)/100),0)
-- else case when @lcIgnore = 'Ignore Scrap' then ((t1.topqty*t1.qty)*woentry.BLDQTY)+t1.SetupScrap
-- else case when @lcIgnore = 'Ignore Setup Scrap' then ((t1.topqty*t1.qty)*woentry.BLDQTY) + round((((t1.Qty * woentry.BldQty)*t1.Scrap)/100),0)
-- else case when @lcIgnore = 'Ignore Both Scraps' then ((t1.topqty*t1.qty)*woentry.BLDQTY) end end end end as Req_Qty
-- ,CASE when woentry.UNIQ_KEY = t1.BomParent THEN ' ' ELSE 'f' end as Phantom,t1.Part_class,t1.Part_type
-- ,t1.UniqBomNo as kaseqnum
-- --,CAST('' as char(10)) as kaseqnum
-- ,CAST(0 as bit) as kitclosed,CAST(0.00 as numeric(5,2)) as Act_qty,t1.UNIQ_KEY,t1.Dept_id,depts.DEPT_NAME,woentry.WONO,t1.scrap
-- ,t1.SetupScrap,t1.bomParent
-- ,case when @lcIgnore = 'No' then ((t1.topqty*t1.qty)*woentry.BLDQTY)+t1.SetupScrap+ round((((t1.Qty * woentry.BldQty)*t1.Scrap)/100),0)
-- else case when @lcIgnore = 'Ignore Scrap' then ((t1.topqty*t1.qty)*woentry.BLDQTY)+t1.SetupScrap
-- else case when @lcIgnore = 'Ignore Setup Scrap' then ((t1.topqty*t1.qty)*woentry.BLDQTY) + round((((t1.Qty * woentry.BldQty)*t1.Scrap)/100),0)
-- else case when @lcIgnore = 'Ignore Both Scraps' then ((t1.topqty*t1.qty)*woentry.BLDQTY) end end end end as ShortQty
-- ,CAST (0 as bit) as lineshort,t1.Part_sourc,t1.TopQty*t1.qty as Qty,t1.Descript,t1.U_of_meas,t1.PART_NO
-- ,case when t1.Part_sourc = 'CONSG' then t1.ViewPartNo else cast ('' as char(25)) end as CustPartNo,CAST(0 as bit) as Ignorekit
-- ,CAST (0 as bit) as Phant_make,t1.Revision,t1.MatlType,case when t1.Part_sourc = 'CONSG' THEN T1.ViewRevision ELSE CAST ('' AS CHAR(8)) END AS CustRev,t1.UniqBomNo
-- ,NEWID()
--03/06/15 DS Changed column order
select bom_det.item_no,
t1.Part_sourc,
t1.Part_no,
t1.Revision,
t1.Descript,
t1.Part_class,
t1.Part_type,
t1.U_of_meas,
case when @lcIgnore = 'No' then ((T1.topqty*T1.qty)*woentry.BLDQTY)+T1.SetupScrap+ round((((t1.Qty * woentry.BldQty)*T1.Scrap)/100),0)
else case when @lcIgnore = 'Ignore Scrap' then ((t1.topqty*t1.qty)*woentry.BLDQTY)+t1.SetupScrap
else case when @lcIgnore = 'Ignore Setup Scrap' then ((t1.topqty*t1.qty)*woentry.BLDQTY) + round((((t1.Qty * woentry.BldQty)*t1.Scrap)/100),0)
else case when @lcIgnore = 'Ignore Both Scraps' then ((t1.topqty*t1.qty)*woentry.BLDQTY) end end end end as Req_Qty,
case when @lcIgnore = 'No' then ((t1.topqty*t1.qty)*woentry.BLDQTY)+t1.SetupScrap+ round((((t1.Qty * woentry.BldQty)*t1.Scrap)/100),0)
else case when @lcIgnore = 'Ignore Scrap' then ((t1.topqty*t1.qty)*woentry.BLDQTY)+t1.SetupScrap
else case when @lcIgnore = 'Ignore Setup Scrap' then ((t1.topqty*t1.qty)*woentry.BLDQTY) + round((((t1.Qty * woentry.BldQty)*t1.Scrap)/100),0)
else case when @lcIgnore = 'Ignore Both Scraps' then ((t1.topqty*t1.qty)*woentry.BLDQTY) end end end end as ShortQty,
t1.MatlType,
ISNULL(customer.custname,'') as CustName
--- 03/28/17 YS changed length of the part_no column from 25 to 35	
,case when t1.Part_sourc = 'CONSG' then t1.ViewPartNo else cast ('' as char(35)) end as CustPartNo
,case when t1.Part_sourc = 'CONSG' THEN T1.ViewRevision ELSE CAST ('' AS CHAR(8)) END AS CustRev
,woentry.kitstatus,
woentry.ORDERDATE,
i4.part_no as ParentBomPn,
i4.REVISION as ParentBomRev,
i4.DESCRIPT as ParentBomDesc,
i4.MATLTYPE,
woentry.BLDQTY,
CASE when woentry.UNIQ_KEY = t1.BomParent THEN ' ' ELSE 'f' end as Phantom,
t1.UniqBomNo as kaseqnum
,CAST(0 as bit) as kitclosed,
CAST(0.00 as numeric(5,2)) as Act_qty,
t1.UNIQ_KEY,
t1.Dept_id,
depts.DEPT_NAME,
woentry.WONO,
t1.scrap
,t1.SetupScrap
,t1.bomParent
,CAST (0 as bit) as lineshort,
t1.TopQty*t1.qty as Qty,
t1.PART_NO
,CAST(0 as bit) as Ignorekit
,CAST (0 as bit) as Phant_make,
t1.Revision,
t1.UniqBomNo
,NEWID()
from @tBom as T1
inner join WOENTRY on t1.UNIQ_KEY = t1.UNIQ_KEY
inner join CUSTOMER on woentry.custno = customer.CUSTNO
inner join INVENTOR as I4 on woentry.UNIQ_KEY = i4.UNIQ_KEY
left outer join bom_det on t1.Bomparent = bom_det.BOMPARENT and t1.uniq_key = bom_det.Uniq_key and t1.item_no = bom_Det.ITEM_NO
left outer join DEPTS on t1.Dept_id = depts.DEPT_ID
where @lcWono = woentry.WONO
AND T1.part_sourc <> 'PHANTOM'
AND t1.Phantom_make <> 1
--08/13/2013 DRP: ADDED ANOTHER SELECTION STATEMENT THAT WILL BE USED FOR THE LABEL GRID
--08/13/2013 DRP: ALSO ADDED LabelId field. this will be populated with the kaseqnum so that it can be passed to the label report itself from the grid selection
/*04/30/2014 The below section was accidentally left in the procedure when it should have been deactivated.
select r1.Dept_Name,r1.DispPart_No,r1.DispRevision,r1.CustPartNo,r1.CustRev,r1.Part_Sourc,r1.Descript,CAST (1 as numeric (3,0))as LabelQty,Label_Id
from @results as R1
04/30/2014 END */
--07/29/2013 DRP: added the labelQty below. I have it just defaulted here as 1 because this section is for wo's not yet kitted so there should not be any fulfilled items at this time
select R1.*
--, CAST (1 as numeric (3,0))as LabelQty --05/01/17 DRP:  Replaced with below
,case when @lcLabelQty is null then 1 else @lcLabelQty end as LabelQty
,isnull(dbo.fnBomRefDesg(R1.UniqBomNo),'') as RefDesg
from @results as R1
order by item_no
end
--select * from @results order by item_no
ELSE -- ELSE of @@ROWCOUNT <> 0
--07/29/2013 DRP: added the labelQty below. I have it just defaulted here as 1 because this section is for wo's not yet kitted so there should not be any fulfilled items at this time
select R2.*
--,CAST (1 as numeric (3,0)) as LabelQty	--05/01/147 DRP:  REPLACED WITH BELOW
,case when @lcLabelQty is null then 1 else @lcLabelQty end as LabelQty
,isnull(dbo.fnBomRefDesg(R2.UniqBomNo),'') as RefDesg
from @results as R2
order by item_no
end
end