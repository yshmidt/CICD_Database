-- =============================================
-- Author:		<Debbie>
-- Create date: <05/04/2020,>
-- Description:	<Inventory Adjustment Tool Quickview used by inventory adjustment utility>
-- Modified:	
-- 05/05/20 VL: Changed the code, so it shows correct records with lot and ipkey on or off (4 different conditions), added lotdetail and union non lot and lot records
-- 05/11/20 VL: Removed unncecessary code and created it as a quickview
-- 05/13/20 VL: List the column in sort by warehouse
-- 05/22/20 VL: Removed udf code
-- 06/01/20 VL changed to show expdate, don't understand why use '' as expdate
-- 06/15/20 VL Added the UDF code back, Broadcom wants to see those UDF columns
-- 11/09/20 VL changed from INNER JOIN Parttype to LEFT OUTER JOIN Parttype because we allow part_type to be blank, also minor change for lotdetail field. CAPA 3198
---- =============================================
CREATE PROCEDURE [dbo].[rptInvtAdjustmentTool]

	-- Add the parameters for the stored procedure here
		@lcSupZero as char(3) = 'No',
		@lcDisplayQty as char(3) = 'Yes',		--05/04/20:  DRP added to give the users the ability to display the system current qty on hand or not. 		
		@lcType as char (20) = 'Internal',		--where the user would specify Internal, Internal & In Store, In Store, Consigned
		@lcClass as varchar (max) = 'All',
		@lcUniqWh as varchar (max) = 'All',
		@lcCustNo as varchar (10) = 'ALL',
		@lcUniq_keyStart char(10)='',
		@lcUniq_keyEnd char(10)='',
		@lcSort as char(12) = 'Part Number'	--Part Number or Warehouse
		,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED this is passed within the /*CUSTOMER LIST*/ section below. 
		,@userId uniqueidentifier = null,
		@PageNumber int=1, 
		@PageSize int = 50 -- 01/22/18 Satyawan H: Changed Default value of @PageSize from 150 to 50

AS
BEGIN

/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,@customerStatus ;
		
		IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select CustNo from @tCustomer)
		ELSE

		IF  @lcCustNo='All'	    
		BEGIN
			INSERT INTO @Customer SELECT CustNo FROM @tCustomer
		END
		
		/*WAREHOUSE LIST*/
		--09/13/2013 DRP:  added code to handle Warehouse List
			declare @Whse table(Uniqwh char(10))
			if @lcUniqWh is not null and @lcUniqWh <> '' AND @lcUniqWh <> 'All'
				insert into @Whse select * from dbo.[fn_simpleVarcharlistToTable](@lcUniqWh,',')

			else

			if @lcUniqWh = 'All'
			Begin
				insert into @Whse select uniqwh from WAREHOUS
			end
			--select * from @Whse

/*PART CLASS LIST*/
DECLARE @PartClass TABLE (part_class char(8))
	IF @lcClass is not null and @lcClass <>'' and @lcClass <> 'All'
		INSERT INTO @PartClass SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcClass,',')
			
	else
	if @lcClass = 'All'
	begin
		--08/01/17 YS moved part_class setup from "support" table to partClass table
		insert into @PartClass SELECT part_class FROM partClass 
	end	
--select * from @PartClass
SET NOCOUNT ON;
	--02/20/15 YS changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
	declare @lcPartStart char(35)='',@lcRevisionStart char(8)='',
		@lcPartEnd char(35)='',@lcRevisionEnd char(8)=''
	
	--02/20/15 YS changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
	-- find starting part number
	IF  @lcUniq_keyStart IS NULL or  @lcUniq_keyStart ='' 
		SELECT @lcPartStart=' ', @lcRevisionStart=' '
	ELSE
		SELECT @lcPartStart = case when @lctype='Consigned' THEN ISNULL(I.Custpartno,' ') ELSE  ISNULL(I.Part_no,' ') END,	--03/26/205 DRP added the Case when for the Consigned
			@lcRevisionStart = case when @lctype='Consigned' THEN ISNULL(I.Custrev,' ') ELSE ISNULL(I.Revision,' ') END		--03/26/205 DRP added the Case when for the Consigned
		FROM Inventor I where Uniq_key=@lcUniq_keyStart
		
	-- find ending part number
	IF  @lcUniq_keyEnd IS NULL or  @lcUniq_keyEnd ='' 
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
		SELECT @lcPartEnd = REPLICATE('Z',35), @lcRevisionEnd=REPLICATE('Z',8)
	ELSE
		SELECT @lcPartEnd =case when @lctype='Consigned' THEN ISNULL(I.custpartno,' ') ELSE ISNULL(I.Part_no,' ') END,		--03/26/205 DRP added the Case when for the Consigned
			@lcRevisionEnd = case when @lctype='Consigned' THEN ISNULL(I.Custrev,' ') ELSE  ISNULL(I.Revision,' ') END		--03/26/205 DRP added the Case when for the Consigned
		FROM Inventor I where Uniq_key=@lcUniq_keyEnd
	--select @lcPartStart, @lcRevisionStart	,@lcPartEnd,@lcRevisionEnd



/*SELECT STATEMENT*/
-- 04/14/15 YS Location length is changed to varchar(256)
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 07/16/18 VL changed custname from char(35) to char(50)
-- 12/03/18 YS missed updating lotcode width to 25
--05/05/19 YS added uniq_lot to add udf for the lot to the report
--03/04/20 DRP added supname
--05/04/20 DRP added mtc and mtcQtyBalance
declare @results as table 
(part_no char(35),revision char(8),custno char(10),custname char(50),part_sourc char(10),part_class char(8),part_type char(8),descript char(45),u_of_meas char(4),stdcost numeric(13,5),buyer char(3)
,uniq_key char(10),instore bit,w_key char(10),warehouse char (6),location varchar(256),partmfgr char(8),mfgr_pt_no char(30),qty_oh numeric(12,2),reserved numeric(12,2),availqty numeric(12,2)
,lotcode char(25),expdate smalldatetime,reference char(12),ponum char(15),lotqty numeric(12,2),lotresqty numeric(12,2),lotavailqty numeric(12,2),uniq_lot char(10) null,supname char(50)
,mtc char(10),mtcQtyBalance numeric(12,2),ReservedMtcQty numeric(12,2),AvailMtcQty numeric(12,2),useipkey bit)



if (@lcType = 'Internal')
	Begin
	--05/05/19 YS added uniq_lot to add udf for the lot to the report
	--03/04/20 DRP added supname
	--05/04/20 DRP added mtc and mtcQtyBalance and the IPKEY table
	insert into @results 
	select	t1.part_no, t1.revision, t1.custno,t1.custname, t1.part_sourc, t1.part_class, t1.Part_type, t1.Descript, t1.u_of_meas, t1.stdcost, t1.buyer,
		t1.uniq_key, t1.instore, t1.w_key, t1.warehouse, t1.location, t1.partmfgr, t1.mfgr_pt_no, 
		CASE WHEN ROW_NUMBER() OVER(Partition by part_no, revision, Uniq_key,w_key Order by mfgr_pt_no)=1 Then t1.qty_oh else CAST(0.00 as Numeric(20,2)) END AS qty_oh,
		CASE WHEN ROW_NUMBER() OVER(Partition by part_no, revision, Uniq_key,w_key Order by mfgr_pt_no)=1 Then t1.reserved else CAST(0.00 as Numeric(20,2)) END AS reserved,
		CASE WHEN ROW_NUMBER() OVER(Partition by part_no, revision, Uniq_key,w_key Order by mfgr_pt_no)=1 Then t1.availqty else CAST(0.00 as Numeric(20,2)) END as availqty,
		t1.lotcode,t1.expdate, t1.reference, t1.ponum, t1.lotqty, t1.lotresqty, t1.lotavailqty,t1.UNIQ_LOT,supname
		,t1.mtc
		,t1.pkgBalance
		,t1.ReservedMtcQty
		,t1.AvailMtcQty
		,t1.useipkey

from (
--03/02/15 ys no customer connection for the internal parts
-- 07/16/18 VL changed custname from char(35) to char(50)
--05/05/19 YS added uniq_lot to add udf for the lot to the report
--03/04/20 DRP added supname
--05/04/20 DRP added mtc and mtcQtyBalance and the IPKEY table
----05/05/20 VL: Changed the code, so it shows correct records with lot and ipkey on or off (4 different conditions), added lotdetail and union non lot and lot records
-- Lot coded parts
	SELECT	INVENTOR.PART_NO, INVENTOR.Revision ,INVENTOR.CUSTNO,space(50) as CUSTNAME,
			Inventor.Part_sourc,Inventor.Part_class,Inventor.Part_type,Descript,Inventor.U_of_meas,Inventor.StdCost, CAST (Inventor.buyer_type as CHAR(20)) as buyer, 
			Inventor.Uniq_key,INVTMFGR.INSTORE,invtmfgr.w_key, WAREHOUS.WAREHOUSE,INVTMFGR.LOCATION, M.PARTMFGR, 
			M.MFGR_PT_NO, INVTMFGR.QTY_OH, INVTMFGR.RESERVED, INVTMFGR.QTY_OH - INVTMFGR.RESERVED as AvailQty, 
			INVTLOT.LOTCODE, INVTLOT.EXPDATE, INVTLOT.REFERENCE, 
			INVTLOT.PONUM, INVTLOT.LOTQTY, INVTLOT.LOTRESQTY, INVTLOT.LOTQTY-INVTLOT.LOTRESQTY  as LotAvailQty	,
			invtlot.UNIQ_LOT,'' as supname
			,K.IPKEYUNIQUE AS MTC, k.pkgBalance as pkgBalance,k.qtyAllocatedTotal as ReservedMtcQty,k.pkgBalance - k.qtyAllocatedTotal as AvailMtcQty
			,inventor.useipkey,lotdetail					
	from	INVENTOR INNER JOIN InvtMpnLink L On Inventor.Uniq_key=L.Uniq_key
			INNER JOIN  INVTMFGR ON INVTMFGR.UNIQMFGRHD=L.UNIQMFGRHD
			inner join MfgrMaster M on L.MfgrmasterId = M.MfgrmasterId 
			--	10/10/14 YS replace invtmfhd with 2 tables
			--inner join invtmfgr on invtmfhd.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD 
			inner join WAREHOUS on INVTMFGR.UNIQWH = WAREHOUS.UNIQWH
			-- 05/05/20 VL added parttype 
			-- 11/09/20 VL changed from INNER JOIN Parttype to LEFT OUTER JOIN Parttype because we allow part_type to be blank
			--INNER JOIN Parttype ON Inventor.part_class = Parttype.Part_class AND Inventor.Part_type = Parttype.Part_type 
			LEFT OUTER JOIN Parttype ON Inventor.part_class = Parttype.Part_class AND Inventor.Part_type = Parttype.Part_type 
			left outer join INVTLOT on INVTMFGR.W_KEY = INVTLOT.W_KEY AND LotQty - LotResQty <>0
			left outer join (select * from IPKEY where pkgBalance - qtyAllocatedTotal <> 0) K  ON INVTMFGR.W_KEY = K.W_KEY
			-- 05/05/20 VL added more criteria between Ipkey K and Invtlot
			AND K.LOTCODE = Invtlot.LOTCODE AND K.EXPDATE = Invtlot.Expdate AND K.Reference = Invtlot.Reference AND K.Ponum = Invtlot.Ponum
	WHERE	Invtmfgr.Is_Deleted=0
			and INVTMFGR.INSTORE = 0 
			and INVENTOR.PART_SOURC <> 'CONSG'
			--10/10/14 YS replace invtmfhd with 2 tables
			and L.is_deleted=0
			and m.is_deleted=0
			and warehous.is_deleted=0
			AND (@lcClass = '' OR exists (SELECT 1 FROM @PartClass pc WHERE PC.PART_CLASS=INVENTOR.PART_CLASS))
			and (@lcUniqWh = '' or EXISTS (SELECT 1 FROM @Whse wh WHERE WH.UNIQWH=WAREHOUS.UNIQWH))
			AND (part_no+revision BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)
			and (@lcSupZero = 'No' OR QTY_OH>0.00 )
			and inventor.STATUS = 'Active'	--05/21/2015 DRP:  Added	
			-- 05/05/20 VL added for lot
			AND Lotdetail = 1
			--ORDER BY INVENTOR.PART_NO OFFSET ((@PageNumber - 1) * @PageSize) ROWS Fetch next @PageSize ROWS ONLY -- 12/30/2018 Satyawan H. Added Offset paging	
			--and inventor.UNIQ_KEY = 'K6KTNW5H2Z'
			--and inventor.UNIQ_KEY = 'MW25ML0G27'
			--and inventor.uniq_key = 'KNBA7BA5CA'
-- 05/05/20 VL added non lot part
UNION ALL
	SELECT	INVENTOR.PART_NO, INVENTOR.Revision ,INVENTOR.CUSTNO,space(50) as CUSTNAME,
			Inventor.Part_sourc,Inventor.Part_class,Inventor.Part_type,Descript,Inventor.U_of_meas,Inventor.StdCost, CAST (Inventor.buyer_type as CHAR(20)) as buyer, 
			Inventor.Uniq_key,INVTMFGR.INSTORE,invtmfgr.w_key, WAREHOUS.WAREHOUSE,INVTMFGR.LOCATION, M.PARTMFGR, 
			M.MFGR_PT_NO, INVTMFGR.QTY_OH, INVTMFGR.RESERVED, INVTMFGR.QTY_OH - INVTMFGR.RESERVED as AvailQty, 
			SPACE(15) AS LOTCODE, NULL AS EXPDATE, SPACE(12) AS REFERENCE, 
			SPACE(15) AS PONUM, CAST(0.00 AS numeric(12,2)) AS LOTQTY, CAST(0.00 AS numeric(12,2)) AS LOTRESQTY, CAST(0.00 AS numeric(12,2)) as LotAvailQty	,
			SPACE(10) AS UNIQ_LOT,'' as supname
			,K.IPKEYUNIQUE AS MTC, k.pkgBalance as pkgBalance,k.qtyAllocatedTotal as ReservedMtcQty,k.pkgBalance - k.qtyAllocatedTotal as AvailMtcQty
			,inventor.useipkey, 
			-- 11/09/20 VL added code to consider if parttype doesn't have associated record, then lotdetail will be null
			--lotdetail					
			ISNULL(lotdetail, 0) AS lotdetail
	from	INVENTOR INNER JOIN InvtMpnLink L On Inventor.Uniq_key=L.Uniq_key
			INNER JOIN  INVTMFGR ON INVTMFGR.UNIQMFGRHD=L.UNIQMFGRHD
			inner join MfgrMaster M on L.MfgrmasterId = M.MfgrmasterId 
			--	10/10/14 YS replace invtmfhd with 2 tables
			--inner join invtmfgr on invtmfhd.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD 
			inner join WAREHOUS on INVTMFGR.UNIQWH = WAREHOUS.UNIQWH
			-- 11/09/20 VL changed from INNER JOIN Parttype to LEFT OUTER JOIN Parttype because we allow part_type to be blank
			--INNER JOIN Parttype ON Inventor.part_class = Parttype.Part_class AND Inventor.Part_type = Parttype.Part_type 
			LEFT OUTER JOIN Parttype ON Inventor.part_class = Parttype.Part_class AND Inventor.Part_type = Parttype.Part_type 
			left outer join (select * from IPKEY where pkgBalance - qtyAllocatedTotal <> 0) K  ON INVTMFGR.W_KEY = K.W_KEY
	WHERE	Invtmfgr.Is_Deleted=0
			and INVTMFGR.INSTORE = 0 
			and INVENTOR.PART_SOURC <> 'CONSG'
			--10/10/14 YS replace invtmfhd with 2 tables
			and L.is_deleted=0
			and m.is_deleted=0
			and warehous.is_deleted=0
			AND (@lcClass = '' OR exists (SELECT 1 FROM @PartClass pc WHERE PC.PART_CLASS=INVENTOR.PART_CLASS))
			and (@lcUniqWh = '' or EXISTS (SELECT 1 FROM @Whse wh WHERE WH.UNIQWH=WAREHOUS.UNIQWH))
			AND (part_no+revision BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)
			and (@lcSupZero = 'No' OR QTY_OH>0.00 )
			and inventor.STATUS = 'Active'	--05/21/2015 DRP:  Added
			-- 11/09/20 VL added code to consider if parttype doesn't have associated record, then lotdetail will be null
			--AND Lotdetail = 0
			AND (LOTDETAIL = 0 OR LOTDETAIL IS NULL)
			--ORDER BY INVENTOR.PART_NO OFFSET ((@PageNumber - 1) * @PageSize) ROWS Fetch next @PageSize ROWS ONLY -- 12/30/2018 Satyawan H. Added Offset paging	
			--and inventor.UNIQ_KEY = 'K6KTNW5H2Z'
			--and inventor.UNIQ_KEY = 'MW25ML0G27'
			--and inventor.uniq_key = 'MW25ML0G27'
			

	)t1 
	end
	--SELECT * FROM @results

else if (@lcType = 'Consigned')
	Begin
	--05/05/19 YS added uniq_lot to add udf for the lot to the report
	--03/04/20 DRP added supname
--05/04/20 DRP added mtc and mtcQtyBalance and the IPKEY table
	insert into @results
	select	t1.part_no, t1.revision, t1.custno,t1.custname, t1.part_sourc, t1.part_class, t1.Part_type, t1.Descript, t1.u_of_meas, t1.stdcost, t1.buyer,
		t1.uniq_key, t1.instore, t1.w_key, t1.warehouse, t1.location, t1.partmfgr, t1.mfgr_pt_no, 
		CASE WHEN ROW_NUMBER() OVER(Partition by part_no, revision, Uniq_key,w_key Order by mfgr_pt_no)=1 Then t1.qty_oh else CAST(0.00 as Numeric(20,2)) END AS qty_oh,
		CASE WHEN ROW_NUMBER() OVER(Partition by part_no, revision, Uniq_key,w_key Order by mfgr_pt_no)=1 Then t1.reserved else CAST(0.00 as Numeric(20,2)) END AS reserved,
		CASE WHEN ROW_NUMBER() OVER(Partition by part_no, revision, Uniq_key,w_key Order by mfgr_pt_no)=1 Then t1.availqty else CAST(0.00 as Numeric(20,2)) END as availqty,
		t1.lotcode,t1.expdate, t1.reference, t1.ponum, t1.lotqty, t1.lotresqty, t1.lotavailqty,t1.uniq_lot,t1.supname
		,t1.mtc
		,t1.pkgBalance
		,t1.ReservedMtcQty
		,t1.AvailMtcQty
		,t1.useipkey

from (
--05/05/19 YS added uniq_lot to add udf for the lot to the report
--03/04/20 DRP added supname
--05/04/20 DRP added mtc and mtcQtyBalance and the IPKEY table
----05/05/20 VL: Changed the code, so it shows correct records with lot and ipkey on or off (4 different conditions), added lotdetail and union non lot and lot records
-- Lot coded parts
	SELECT	inventor.custpartno as Part_no,INVENTOR.CUSTREV as Revision,INVENTOR.CUSTNO,CUSTOMER.CUSTNAME,
				Inventor.Part_sourc,Inventor.Part_class,Inventor.Part_type,Descript,Inventor.U_of_meas,Inventor.StdCost, CAST (Inventor.buyer_type as CHAR(20)) as buyer, 
				Inventor.Uniq_key,INVTMFGR.INSTORE,invtmfgr.w_key,WAREHOUS.WAREHOUSE,INVTMFGR.LOCATION, M.PARTMFGR, 
				M.MFGR_PT_NO, INVTMFGR.QTY_OH, INVTMFGR.RESERVED, INVTMFGR.QTY_OH - INVTMFGR.RESERVED as AvailQty,
				INVTLOT.LOTCODE, INVTLOT.EXPDATE, INVTLOT.REFERENCE, INVTLOT.PONUM, INVTLOT.LOTQTY, INVTLOT.LOTRESQTY, INVTLOT.LOTQTY-INVTLOT.LOTRESQTY  as LotAvailQty,
				invtlot.UNIQ_LOT,'' as supname			
				,K.IPKEYUNIQUE AS MTC, k.pkgBalance as pkgBalance,k.qtyAllocatedTotal as ReservedMtcQty,k.pkgBalance - k.qtyAllocatedTotal as AvailMtcQty
			,inventor.useipkey, LOTDETAIL			
	from	INVENTOR 
			--	10/10/14 YS replace invtmfhd with 2 tables
			--left outer join INVTMFHD on INVTMFHD.UNIQ_KEY = INVENTOR.UNIQ_KEY 
			--inner join invtmfgr on invtmfhd.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD 
			 INNER JOIN InvtMpnLink L On Inventor.Uniq_key=L.Uniq_key
			INNER JOIN Invtmfgr ON INVTMFGR.UNIQMFGRHD=L.UNIQMFGRHD
			inner join MfgrMaster M on L.MfgrmasterId = M.MfgrmasterId 
			inner join WAREHOUS on INVTMFGR.UNIQWH = WAREHOUS.UNIQWH
			-- 05/05/20 VL added parttype 
			-- 11/09/20 VL changed from INNER JOIN Parttype to LEFT OUTER JOIN Parttype because we allow part_type to be blank
			--INNER JOIN Parttype ON Inventor.part_class = Parttype.Part_class AND Inventor.Part_type = Parttype.Part_type 
			LEFT OUTER JOIN Parttype ON Inventor.part_class = Parttype.Part_class AND Inventor.Part_type = Parttype.Part_type 
			left outer join INVTLOT on INVTMFGR.W_KEY = INVTLOT.W_KEY AND LotQty - LotResQty <>0
			inner join CUSTOMER on INVENTOR.CUSTNO = CUSTOMER.CUSTNO
			INNER JOIN @Customer C ON C.Custno=Customer.Custno
			--left outer join IPKEY K ON INVTMFGR.W_KEY = K.W_KEY
			left outer join (select * from IPKEY where pkgBalance - qtyAllocatedTotal <> 0) K  ON INVTMFGR.W_KEY = K.W_KEY
			-- 05/05/20 VL added more criteria between Ipkey K and Invtlot
			AND K.LOTCODE = Invtlot.LOTCODE AND K.EXPDATE = Invtlot.Expdate AND K.Reference = Invtlot.Reference AND K.Ponum = Invtlot.Ponum

	WHERE	
			Invtmfgr.Is_Deleted=0
			and L.is_deleted=0
			and m.is_deleted=0
			and INVTMFGR.INSTORE = 0 
			and INVENTOR.PART_SOURC = 'CONSG'
			and warehous.is_deleted=0
			AND (@lcClass = '' OR exists (SELECT 1 FROM @PartClass pc WHERE PC.PART_CLASS=INVENTOR.PART_CLASS))
			and (@lcUniqWh = '' or EXISTS (SELECT 1 FROM @Whse wh WHERE WH.UNIQWH=WAREHOUS.UNIQWH))
			AND (CUSTPARTNO+custrev BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)
			and (@lcSupZero = 'No' OR QTY_OH>0.00 )
			and inventor.STATUS = 'Active'	--05/21/2015 DRP:  Added	
			-- 05/05/20 VL added for lot
			AND Lotdetail = 1
-- 05/05/20 VL added no lot code part
UNION ALL
	SELECT	inventor.custpartno as Part_no,INVENTOR.CUSTREV as Revision,INVENTOR.CUSTNO,CUSTOMER.CUSTNAME,
				Inventor.Part_sourc,Inventor.Part_class,Inventor.Part_type,Descript,Inventor.U_of_meas,Inventor.StdCost, CAST (Inventor.buyer_type as CHAR(20)) as buyer, 
				Inventor.Uniq_key,INVTMFGR.INSTORE,invtmfgr.w_key,WAREHOUS.WAREHOUSE,INVTMFGR.LOCATION, M.PARTMFGR, 
				M.MFGR_PT_NO, INVTMFGR.QTY_OH, INVTMFGR.RESERVED, INVTMFGR.QTY_OH - INVTMFGR.RESERVED as AvailQty,
				SPACE(15) AS LOTCODE, NULL AS EXPDATE, SPACE(12) AS REFERENCE, 
				SPACE(15) AS PONUM, CAST(0.00 AS numeric(12,2)) AS LOTQTY, CAST(0.00 AS numeric(12,2)) AS LOTRESQTY, CAST(0.00 AS numeric(12,2)) as LotAvailQty	,
				SPACE(10) AS UNIQ_LOT, '' as supname			
				,K.IPKEYUNIQUE AS MTC, k.pkgBalance as pkgBalance,k.qtyAllocatedTotal as ReservedMtcQty,k.pkgBalance - k.qtyAllocatedTotal as AvailMtcQty
			,inventor.useipkey, 
			-- 11/09/20 VL added code to consider if parttype doesn't have associated record, then lotdetail will be null
			--LOTDETAIL					
			ISNULL(lotdetail, 0) AS LOTDETAIL
						
	from	INVENTOR 
			--	10/10/14 YS replace invtmfhd with 2 tables
			--left outer join INVTMFHD on INVTMFHD.UNIQ_KEY = INVENTOR.UNIQ_KEY 
			--inner join invtmfgr on invtmfhd.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD 
			 INNER JOIN InvtMpnLink L On Inventor.Uniq_key=L.Uniq_key
			INNER JOIN Invtmfgr ON INVTMFGR.UNIQMFGRHD=L.UNIQMFGRHD
			inner join MfgrMaster M on L.MfgrmasterId = M.MfgrmasterId 
			inner join WAREHOUS on INVTMFGR.UNIQWH = WAREHOUS.UNIQWH
			-- 05/05/20 VL added parttype 
			-- 11/09/20 VL changed from INNER JOIN Parttype to LEFT OUTER JOIN Parttype because we allow part_type to be blank
			--INNER JOIN Parttype ON Inventor.part_class = Parttype.Part_class AND Inventor.Part_type = Parttype.Part_type 
			LEFT OUTER JOIN Parttype ON Inventor.part_class = Parttype.Part_class AND Inventor.Part_type = Parttype.Part_type 
			inner join CUSTOMER on INVENTOR.CUSTNO = CUSTOMER.CUSTNO
			INNER JOIN @Customer C ON C.Custno=Customer.Custno
			--left outer join IPKEY K ON INVTMFGR.W_KEY = K.W_KEY
			left outer join (select * from IPKEY where pkgBalance - qtyAllocatedTotal <> 0) K  ON INVTMFGR.W_KEY = K.W_KEY
	WHERE	
			Invtmfgr.Is_Deleted=0
			and L.is_deleted=0
			and m.is_deleted=0
			and INVTMFGR.INSTORE = 0 
			and INVENTOR.PART_SOURC = 'CONSG'
			and warehous.is_deleted=0
			AND (@lcClass = '' OR exists (SELECT 1 FROM @PartClass pc WHERE PC.PART_CLASS=INVENTOR.PART_CLASS))
			and (@lcUniqWh = '' or EXISTS (SELECT 1 FROM @Whse wh WHERE WH.UNIQWH=WAREHOUS.UNIQWH))
			AND (CUSTPARTNO+custrev BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)
			and (@lcSupZero = 'No' OR QTY_OH>0.00 )
			and inventor.STATUS = 'Active'	--05/21/2015 DRP:  Added	
			-- 05/05/20 VL added for lot
			-- 11/09/20 VL added code to consider if parttype doesn't have associated record, then lotdetail will be null
			--AND Lotdetail = 0
			AND (LOTDETAIL = 0 OR LOTDETAIL IS NULL)

		)t1 			
	end
		--select * from @results				
else if (@lcType = 'In Store')
	Begin
	--05/05/19 YS added uniq_lot to add udf for the lot to the report
	--03/04/20 DRP added supname
	--05/04/20 DRP added mtc and mtcQtyBalance and the IPKEY table
	insert into @results
		select	t1.part_no, t1.revision, t1.custno,t1.custname, t1.part_sourc, t1.part_class, t1.Part_type, t1.Descript, t1.u_of_meas, t1.stdcost, t1.buyer,
				t1.uniq_key, t1.instore, t1.w_key, t1.warehouse, t1.location, t1.partmfgr, t1.mfgr_pt_no,
				CASE WHEN ROW_NUMBER() OVER(Partition by part_no, revision, Uniq_key,w_key Order by mfgr_pt_no)=1 Then t1.qty_oh else CAST(0.00 as Numeric(20,2)) END AS qty_oh,
				CASE WHEN ROW_NUMBER() OVER(Partition by part_no, revision, Uniq_key,w_key Order by mfgr_pt_no)=1 Then t1.reserved else CAST(0.00 as Numeric(20,2)) END AS reserved,
				CASE WHEN ROW_NUMBER() OVER(Partition by part_no, revision, Uniq_key,w_key Order by mfgr_pt_no)=1 Then t1.availqty else CAST(0.00 as Numeric(20,2)) END as availqty,
				t1.lotcode,t1.expdate, t1.reference, t1.ponum, t1.lotqty, t1.lotresqty, t1.lotavailqty,t1.UNIQ_LOT,t1.supname
				,t1.mtc
				,t1.pkgBalance
				,t1.ReservedMtcQty
				,t1.AvailMtcQty
				,t1.useipkey

		from (
				-- 07/16/18 VL changed custname from char(35) to char(50)
				--05/05/19 YS added uniq_lot to add udf for the lot to the report
				--03/04/20 DRP added supname
				--05/04/20 DRP added mtc and mtcQtyBalance and the IPKEY table
				--05/05/20 VL: Changed the code, so it shows correct records with lot and ipkey on or off (4 different conditions), added lotdetail and union non lot and lot records
				-- Lot coded parts
				SELECT	TOP (100) PERCENT INVENTOR.PART_NO, INVENTOR.Revision ,INVENTOR.CUSTNO,space(50) as custname,
						Inventor.Part_sourc,Inventor.Part_class,Inventor.Part_type,Descript,Inventor.U_of_meas,Inventor.StdCost, CAST (Inventor.buyer_type as CHAR(20)) as buyer, 
						Inventor.Uniq_key,INVTMFGR.INSTORE,invtmfgr.w_key,WAREHOUS.WAREHOUSE,INVTMFGR.LOCATION, m.PARTMFGR, 
						m.MFGR_PT_NO, INVTMFGR.QTY_OH, INVTMFGR.RESERVED, INVTMFGR.QTY_OH - INVTMFGR.RESERVED as AvailQty,
						INVTLOT.LOTCODE, INVTLOT.EXPDATE, INVTLOT.REFERENCE, INVTLOT.PONUM, 
						INVTLOT.LOTQTY, INVTLOT.LOTRESQTY, INVTLOT.LOTQTY-INVTLOT.LOTRESQTY  as LotAvailQty,
						INVTLOT.UNIQ_LOT
						,supname 
						,K.IPKEYUNIQUE AS MTC, k.pkgBalance as pkgBalance,k.qtyAllocatedTotal as ReservedMtcQty,k.pkgBalance - k.qtyAllocatedTotal as AvailMtcQty
			,inventor.useipkey, lotdetail			
										
				from	inventor 
					--	10/10/14 YS replace invtmfhd with 2 tables
					--03/04/20 DRP added supinfo
					inner join Invtmpnlink L on Inventor.Uniq_key=l.Uniq_key
					inner join Mfgrmaster M On m.mfgrmasterid=L.mfgrmasterid
					inner join Invtmfgr On Invtmfgr.uniqmfgrhd=L.uniqmfgrhd
						--inner join INVTMFHD on INVTMFHD.UNIQ_KEY = INVENTOR.UNIQ_KEY 
						--inner join invtmfgr on invtmfhd.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD 
						inner join WAREHOUS on INVTMFGR.UNIQWH = WAREHOUS.UNIQWH
						-- 05/05/20 VL added parttype 
						-- 11/09/20 VL changed from INNER JOIN Parttype to LEFT OUTER JOIN Parttype because we allow part_type to be blank
						--INNER JOIN Parttype ON Inventor.part_class = Parttype.Part_class AND Inventor.Part_type = Parttype.Part_type 
						LEFT OUTER JOIN Parttype ON Inventor.part_class = Parttype.Part_class AND Inventor.Part_type = Parttype.Part_type 
						left outer join INVTLOT on INVTMFGR.W_KEY = INVTLOT.W_KEY AND LotQty - LotResQty <>0
						left outer join supinfo on invtmfgr.uniqsupno = supinfo.UNIQSUPNO
						left outer join (select * from IPKEY where pkgBalance - qtyAllocatedTotal <> 0) K  ON INVTMFGR.W_KEY = K.W_KEY
						--left outer join IPKEY K ON INVTMFGR.W_KEY = K.W_KEY
						-- 05/05/20 VL added more criteria between Ipkey K and Invtlot
						AND K.LOTCODE = Invtlot.LOTCODE AND K.EXPDATE = Invtlot.Expdate AND K.Reference = Invtlot.Reference AND K.Ponum = Invtlot.Ponum						
				WHERE	Invtmfgr.Is_Deleted=0
						--	10/10/14 YS replace invtmfhd with 2 tables
						and m.is_deleted=0
						and l.is_deleted=0
						and inventor.part_sourc<>'CONSG'
						and INVTMFGR.INSTORE = 1
						and warehous.is_deleted=0
						and (@lcClass = '' OR exists (SELECT 1 FROM @PartClass pc WHERE PC.PART_CLASS=INVENTOR.PART_CLASS))
						and (@lcUniqWh = '' or EXISTS (SELECT 1 FROM @Whse wh WHERE WH.UNIQWH=WAREHOUS.UNIQWH)) 
						and (@lcSupZero = 'No' OR QTY_OH>0.00 )	
						AND (Part_no+Revision BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)
						and inventor.STATUS = 'Active'	--05/21/2015 DRP:  Added
						-- 05/05/20 VL added for lot
						AND Lotdetail = 1
-- 05/05/20 VL added non lot code part
		UNION ALL
				SELECT	TOP (100) PERCENT INVENTOR.PART_NO, INVENTOR.Revision ,INVENTOR.CUSTNO,space(50) as custname,
						Inventor.Part_sourc,Inventor.Part_class,Inventor.Part_type,Descript,Inventor.U_of_meas,Inventor.StdCost, CAST (Inventor.buyer_type as CHAR(20)) as buyer, 
						Inventor.Uniq_key,INVTMFGR.INSTORE,invtmfgr.w_key,WAREHOUS.WAREHOUSE,INVTMFGR.LOCATION, m.PARTMFGR, 
						m.MFGR_PT_NO, INVTMFGR.QTY_OH, INVTMFGR.RESERVED, INVTMFGR.QTY_OH - INVTMFGR.RESERVED as AvailQty,
						SPACE(15) AS LOTCODE, NULL AS EXPDATE, SPACE(12) AS REFERENCE, 
						SPACE(15) AS PONUM, CAST(0.00 AS numeric(12,2)) AS LOTQTY, CAST(0.00 AS numeric(12,2)) AS LOTRESQTY, CAST(0.00 AS numeric(12,2)) as LotAvailQty	,
						SPACE(10) AS UNIQ_LOT,supname 
						,K.IPKEYUNIQUE AS MTC, k.pkgBalance as pkgBalance,k.qtyAllocatedTotal as ReservedMtcQty,k.pkgBalance - k.qtyAllocatedTotal as AvailMtcQty
			,inventor.useipkey, 			
			-- 11/09/20 VL added code to consider if parttype doesn't have associated record, then lotdetail will be null
			--lotdetail					
			ISNULL(lotdetail, 0) AS lotdetail										
				from	inventor 
					--	10/10/14 YS replace invtmfhd with 2 tables
					--03/04/20 DRP added supinfo
					inner join Invtmpnlink L on Inventor.Uniq_key=l.Uniq_key
					inner join Mfgrmaster M On m.mfgrmasterid=L.mfgrmasterid
					inner join Invtmfgr On Invtmfgr.uniqmfgrhd=L.uniqmfgrhd
						--inner join INVTMFHD on INVTMFHD.UNIQ_KEY = INVENTOR.UNIQ_KEY 
						--inner join invtmfgr on invtmfhd.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD 
						inner join WAREHOUS on INVTMFGR.UNIQWH = WAREHOUS.UNIQWH
						-- 05/05/20 VL added parttype 
						-- 11/09/20 VL changed from INNER JOIN Parttype to LEFT OUTER JOIN Parttype because we allow part_type to be blank
						--INNER JOIN Parttype ON Inventor.part_class = Parttype.Part_class AND Inventor.Part_type = Parttype.Part_type 
						LEFT OUTER JOIN Parttype ON Inventor.part_class = Parttype.Part_class AND Inventor.Part_type = Parttype.Part_type 
						left outer join supinfo on invtmfgr.uniqsupno = supinfo.UNIQSUPNO
						left outer join (select * from IPKEY where pkgBalance - qtyAllocatedTotal <> 0) K  ON INVTMFGR.W_KEY = K.W_KEY
						--left outer join IPKEY K ON INVTMFGR.W_KEY = K.W_KEY
				WHERE	Invtmfgr.Is_Deleted=0
						--	10/10/14 YS replace invtmfhd with 2 tables
						and m.is_deleted=0
						and l.is_deleted=0
						and inventor.part_sourc<>'CONSG'
						and INVTMFGR.INSTORE = 1
						and warehous.is_deleted=0
						and (@lcClass = '' OR exists (SELECT 1 FROM @PartClass pc WHERE PC.PART_CLASS=INVENTOR.PART_CLASS))
						and (@lcUniqWh = '' or EXISTS (SELECT 1 FROM @Whse wh WHERE WH.UNIQWH=WAREHOUS.UNIQWH)) 
						and (@lcSupZero = 'No' OR QTY_OH>0.00 )	
						AND (Part_no+Revision BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)
						and inventor.STATUS = 'Active'	--05/21/2015 DRP:  Added
						-- 05/05/20 VL added for lot
						-- 11/09/20 VL added code to consider if parttype doesn't have associated record, then lotdetail will be null
						--AND Lotdetail = 0
						AND (LOTDETAIL = 0 OR LOTDETAIL IS NULL)
					
			)t1 
	end
						
else if (@lcType = 'Internal & In Store')
	begin
	--05/05/19 YS added uniq_lot to add udf for the lot to the report
	--03/04/20 DRP added supname
	--05/04/20 DRP added mtc and mtcQtyBalance and the IPKEY table
	insert into @results
		select	t1.part_no, t1.revision, t1.custno,t1.custname, t1.part_sourc, t1.part_class, t1.Part_type, t1.Descript, t1.u_of_meas, t1.stdcost, t1.buyer,
			t1.uniq_key, t1.instore, t1.w_key, t1.warehouse, t1.location, t1.partmfgr, t1.mfgr_pt_no,
			CASE WHEN ROW_NUMBER() OVER(Partition by part_no, revision, Uniq_key,w_key Order by mfgr_pt_no)=1 Then t1.qty_oh else CAST(0.00 as Numeric(20,2)) END AS qty_oh,
			CASE WHEN ROW_NUMBER() OVER(Partition by part_no, revision, Uniq_key,w_key Order by mfgr_pt_no)=1 Then t1.reserved else CAST(0.00 as Numeric(20,2)) END AS reserved,
			CASE WHEN ROW_NUMBER() OVER(Partition by part_no, revision, Uniq_key,w_key Order by mfgr_pt_no)=1 Then t1.availqty else CAST(0.00 as Numeric(20,2)) END as availqty,
			t1.lotcode,t1.expdate, t1.reference, t1.ponum, t1.lotqty, t1.lotresqty, t1.lotavailqty,t1.UNIQ_LOT,t1.supname
			,t1.mtc
			,t1.pkgBalance
			,t1.ReservedMtcQty
			,t1.AvailMtcQty
			,t1.useipkey

		from (
		--05/05/19 YS added uniq_lot to add udf for the lot to the report
		--03/04/20 DRP added supname
		--05/04/20 DRP added mtc and mtcQtyBalance and the IPKEY table
		----05/05/20 VL: Changed the code, so it shows correct records with lot and ipkey on or off (4 different conditions), added lotdetail and union non lot and lot records
		-- Lot coded parts
			SELECT	INVENTOR.PART_NO, INVENTOR.Revision,INVENTOR.CUSTNO,CUSTOMER.CUSTNAME,
						Inventor.Part_sourc,Inventor.Part_class,Inventor.Part_type,Descript,Inventor.U_of_meas,Inventor.StdCost, CAST (Inventor.buyer_type as CHAR(20)) as buyer, 
						Inventor.Uniq_key,INVTMFGR.INSTORE,invtmfgr.w_key,WAREHOUS.WAREHOUSE,INVTMFGR.LOCATION, M.PARTMFGR, 
						M.MFGR_PT_NO, INVTMFGR.QTY_OH, INVTMFGR.RESERVED, INVTMFGR.QTY_OH - INVTMFGR.RESERVED as AvailQty,
						INVTLOT.LOTCODE, INVTLOT.EXPDATE, INVTLOT.REFERENCE, INVTLOT.PONUM, 
						INVTLOT.LOTQTY, INVTLOT.LOTRESQTY, INVTLOT.LOTQTY-INVTLOT.LOTRESQTY  as LotAvailQty,
						invtlot.UNIQ_LOT
						,supinfo.supname		
						,K.IPKEYUNIQUE AS MTC, k.pkgBalance as pkgBalance,k.qtyAllocatedTotal as ReservedMtcQty,k.pkgBalance - k.qtyAllocatedTotal as AvailMtcQty
			,inventor.useipkey, LOTDETAIL				
			from	INVENTOR 
				
					--	10/10/14 YS replace invtmfhd with 2 tables
					--left outer join INVTMFHD on INVTMFHD.UNIQ_KEY = INVENTOR.UNIQ_KEY 
					--left outer join invtmfgr on invtmfhd.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD 
					--03/04/20 DRP added supinfo
					left outer join (select Uniq_key, Partmfgr,mfgr_pt_no,Uniqmfgrhd 
						from Mfgrmaster inner join Invtmpnlink ON mfgrmaster.mfgrmasterid=invtmpnlink.mfgrmasterid where mfgrmaster.is_deleted=0 and invtmpnlink.is_deleted=0) M
						on INVENTOR.UNIQ_KEY=M.Uniq_key 
						left outer join invtmfgr on m.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD 
					left outer join WAREHOUS on INVTMFGR.UNIQWH = WAREHOUS.UNIQWH
					-- 05/05/20 VL added parttype 
					-- 11/09/20 VL changed from INNER JOIN Parttype to LEFT OUTER JOIN Parttype because we allow part_type to be blank
					--INNER JOIN Parttype ON Inventor.part_class = Parttype.Part_class AND Inventor.Part_type = Parttype.Part_type 
					LEFT OUTER JOIN Parttype ON Inventor.part_class = Parttype.Part_class AND Inventor.Part_type = Parttype.Part_type 
					left outer join INVTLOT on INVTMFGR.W_KEY = INVTLOT.W_KEY AND LotQty - LotResQty <>0
					left outer join CUSTOMER on INVENTOR.CUSTNO = CUSTOMER.CUSTNO
					left outer join supinfo on invtmfgr.uniqsupno = supinfo.UNIQSUPNO
					left outer join (select * from IPKEY where pkgBalance - qtyAllocatedTotal <> 0) K  ON INVTMFGR.W_KEY = K.W_KEY
					--left outer join IPKEY K ON INVTMFGR.W_KEY = K.W_KEY
					-- 05/05/20 VL added more criteria between Ipkey K and Invtlot
					AND K.LOTCODE = Invtlot.LOTCODE AND K.EXPDATE = Invtlot.Expdate AND K.Reference = Invtlot.Reference AND K.Ponum = Invtlot.Ponum

			WHERE	Invtmfgr.Is_Deleted=0
						and inventor.part_sourc<>'CONSG'
						and (warehous.is_deleted=0 or warehous.is_deleted is null)
						and (@lcClass = '' OR exists (SELECT 1 FROM @PartClass pc WHERE PC.PART_CLASS=INVENTOR.PART_CLASS))
						and (@lcUniqWh = '' or EXISTS (SELECT 1 FROM @Whse wh WHERE WH.UNIQWH=WAREHOUS.UNIQWH)) 
						and (@lcSupZero = 'No' OR QTY_OH>0.00 )	
						AND (Part_no+Revision BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)
						and inventor.STATUS = 'Active'	--05/21/2015 DRP:  Added
						-- 05/05/20 VL added for lot
						AND Lotdetail = 1			
-- 05/05/20 VL added non lot code part
	UNION ALL
			SELECT	INVENTOR.PART_NO, INVENTOR.Revision,INVENTOR.CUSTNO,CUSTOMER.CUSTNAME,
						Inventor.Part_sourc,Inventor.Part_class,Inventor.Part_type,Descript,Inventor.U_of_meas,Inventor.StdCost, CAST (Inventor.buyer_type as CHAR(20)) as buyer, 
						Inventor.Uniq_key,INVTMFGR.INSTORE,invtmfgr.w_key,WAREHOUS.WAREHOUSE,INVTMFGR.LOCATION, M.PARTMFGR, 
						M.MFGR_PT_NO, INVTMFGR.QTY_OH, INVTMFGR.RESERVED, INVTMFGR.QTY_OH - INVTMFGR.RESERVED as AvailQty,
						SPACE(15) AS LOTCODE, NULL AS EXPDATE, SPACE(12) AS REFERENCE, 
						SPACE(15) AS PONUM, CAST(0.00 AS numeric(12,2)) AS LOTQTY, CAST(0.00 AS numeric(12,2)) AS LOTRESQTY, CAST(0.00 AS numeric(12,2)) as LotAvailQty	,
						SPACE(10) AS UNIQ_LOT
						,supinfo.supname		
						,K.IPKEYUNIQUE AS MTC, k.pkgBalance as pkgBalance,k.qtyAllocatedTotal as ReservedMtcQty,k.pkgBalance - k.qtyAllocatedTotal as AvailMtcQty
			,inventor.useipkey, 
			-- 11/09/20 VL added code to consider if parttype doesn't have associated record, then lotdetail will be null
			--LOTDETAIL					
			ISNULL(lotdetail, 0) AS LOTDETAIL							
							
			from	INVENTOR 
				
					--	10/10/14 YS replace invtmfhd with 2 tables
					--left outer join INVTMFHD on INVTMFHD.UNIQ_KEY = INVENTOR.UNIQ_KEY 
					--left outer join invtmfgr on invtmfhd.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD 
					--03/04/20 DRP added supinfo
					left outer join (select Uniq_key, Partmfgr,mfgr_pt_no,Uniqmfgrhd 
						from Mfgrmaster inner join Invtmpnlink ON mfgrmaster.mfgrmasterid=invtmpnlink.mfgrmasterid where mfgrmaster.is_deleted=0 and invtmpnlink.is_deleted=0) M
						on INVENTOR.UNIQ_KEY=M.Uniq_key 
						left outer join invtmfgr on m.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD 
					left outer join WAREHOUS on INVTMFGR.UNIQWH = WAREHOUS.UNIQWH
					-- 05/05/20 VL added parttype 
					-- 11/09/20 VL changed from INNER JOIN Parttype to LEFT OUTER JOIN Parttype because we allow part_type to be blank
					--INNER JOIN Parttype ON Inventor.part_class = Parttype.Part_class AND Inventor.Part_type = Parttype.Part_type 
					LEFT OUTER JOIN Parttype ON Inventor.part_class = Parttype.Part_class AND Inventor.Part_type = Parttype.Part_type 
					left outer join CUSTOMER on INVENTOR.CUSTNO = CUSTOMER.CUSTNO
					left outer join supinfo on invtmfgr.uniqsupno = supinfo.UNIQSUPNO
					left outer join (select * from IPKEY where pkgBalance - qtyAllocatedTotal <> 0) K  ON INVTMFGR.W_KEY = K.W_KEY
					--left outer join IPKEY K ON INVTMFGR.W_KEY = K.W_KEY
			WHERE	Invtmfgr.Is_Deleted=0
						and inventor.part_sourc<>'CONSG'
						and (warehous.is_deleted=0 or warehous.is_deleted is null)
						and (@lcClass = '' OR exists (SELECT 1 FROM @PartClass pc WHERE PC.PART_CLASS=INVENTOR.PART_CLASS))
						and (@lcUniqWh = '' or EXISTS (SELECT 1 FROM @Whse wh WHERE WH.UNIQWH=WAREHOUS.UNIQWH)) 
						and (@lcSupZero = 'No' OR QTY_OH>0.00 )	
						AND (Part_no+Revision BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)
						and inventor.STATUS = 'Active'	--05/21/2015 DRP:  Added
						-- 05/05/20 VL added for lot
						-- 11/09/20 VL added code to consider if parttype doesn't have associated record, then lotdetail will be null
						--AND Lotdetail = 0
						AND (LOTDETAIL = 0 OR LOTDETAIL IS NULL)

			)t1 
								
	end
--	select * from @results

-- 06/15/20 VL added UDF code back(copied from rptInvtOnHandWM)
--05/05/19 add lot udf if exists  
/* start add dynamic udf columns */  
  
if object_ID('tempdb..##tudfStr') is not null  
drop table ##tudfStr  
declare @vsSQL nvarchar(max)  
select @vsSql='CREATE TABLE ##tudfStr '+ char(10) + '(' + char(10)  
  
;with udfStr  
as  
(  
 select distinct sc.Name as columnName,  
st.Name as TypeName,  
---04/13/20 YS was missing nvarchar, had varchar twice  
max(case when st.Name in ('varchar','nvarchar','char','nchar') then '(' + cast(sc.Length as varchar) + ') ' else ' ' end) as columnLength,  
--04/13/20 YS allow null for all UDF columns. Since this is a report and not dataentry, and we can have tables that will not have all the udf columns and have to allow null  
--case when sc.IsNullable = 1 then 'NULL' else 'NOT NULL' end as isNullable  
'NULL' as isNullable  
from sysobjects so  
join syscolumns sc on sc.id = so.id  
join systypes st on st.xusertype = sc.xusertype  
where so.name  like 'udfInvtLot%'   
and sc.name<>'udfid'  
group by sc.name,st.name,sc.IsNullable  
)  
--04/15/2020 Satyawan H: If column length is negative (-1) then change it to (MAX)
--select @vsSql= @vsSql+ ' '+columnName+' '+TypeName+columnLength+' '+isNullable+', '
select @vsSql= @vsSql+ ' '+columnName+' '+TypeName+IIF(columnLength='(-1)','(MAX)',columnLength)+' '+isNullable+', '    
from udfStr  
  
  
--- make sure that any udf lot table exists, if not assign null to @vsSql  
select @vsSQL=case when len(@vsSql)=26 then null else substring(@vsSQL,1,len(@vsSQL) - 1) + char(10) + ')' end  
--select @vsSQL  
--CREATE TABLE ##tudfStr  (  Bin varchar(4)  NULL,  Comments varchar(30)  NULL,  Design varchar(20)  NULL,  fkUNIQ_LOT char(10)  NOT NULL,  Hermi varchar(20)  NULL,  MassLoad varchar(30)  NULL,  Packaging varchar(20)  NULL,  Probe_spec varchar(20)  NULL,
  --Project varchar(30)  NULL,  Purpose varchar(30)  NULL,  udfId uniqueidentifier  NOT NULL )  
if @vsSQL is not null  
BEGIN  
 exec sp_sqlexec  @vsSQL  
  
  
 --- populate with all the data  
 declare @udfTbaleName nvarchar(50),@udfclass char(10)='',@columnNames nvarchar(max)='',@SqlCommand nvarchar(max)  
 DECLARE eachUdfT CURSOR LOCAL FAST_FORWARD  
  FOR  
   select distinct substring(t.name, charindex('_', t.name) +1,   
   len(t.name) - charindex('_', t.name)) as part_class,  
   t.name as udfTbaleName  
   from sys.tables t  
   inner join sys.columns tc on tc.object_id=t.object_id  
  where t.type='U' and t.name like 'udfInvtLot%'   
  OPEN eachUdfT;  
   
  FETCH NEXT FROM eachUdfT INTO @udfClass,@udfTbaleName ;  
  WHILE @@FETCH_STATUS = 0  
  BEGIN  
  --- get column names  
  ;with  
  tclass  
  as  
  (  
  select substring(t.name, charindex('_', t.name) +1,   
   len(t.name) - charindex('_', t.name)) as part_class, t.name as udfTbaleName,t.object_id as tableid ,  
   tc.name  as columnname  
   from sys.tables t  
   inner join sys.columns tc on tc.object_id=t.object_id  
  where t.type='U' and t.name like 'udfInvtLot%'   
  and substring(t.name, charindex('_', t.name) +1,   
   len(t.name) - charindex('_', t.name)) =@udfClass  
  )  
  SELECT @columnNames = STUFF((  
    SELECT ',' + columnname  
    FROM tclass  
    where columnname<>'udfId'  
    FOR XML PATH('')  
    ), 1, 1, '')  
   
   
   
   SELECT @SqlCommand='Insert into ##tudfStr ('+@columnNames+') SELECT '+@columnNames +' FROM '+@udfTbaleName  
   --print @sqlcommand  
   execute sp_executesql @SqlCommand  
   FETCH NEXT FROM eachUdfT INTO @udfClass ,@udfTbaleName;  
  END --WHILE @@FETCH_STATUS = 0  
  CLOSE eachUdfT;  
  DEALLOCATE eachUdfT;  
END --- if @vsSql is not null  
/* end add dynamic udf columns */  
-- 06/15/20 VL End}

-- 01/22/18 Satyawan H: Added condition to Check @PageSize for download excel file from report and gets all the records. 
IF(@PageSize =50)
   BEGIN
		SELECT @PageSize =Count(uniq_key) from @results
	END

IF (@lcSort = 'Part Number')
	BEGIN --Part Number Sort Begin 
	-- 06/15/20 VL added if UDF exists
	--- 05/01/19 YS added udf lot columns if exists  
	--05/10/19 YS check if udf table exists  
	if @vsSQL is not null 
		-- 05/11/20 VL comment out part_no count and serialitems columns
		SELECT --COUNT(PART_NO) OVER()
		--,r.*
		--,'' as SERIALITEMS
		--, '' AS PackingListNo
		--, 'BEGINNING RAW MATL. INV.' AS Reason,'' as WayBill, '' as Carrier
		--,
		part_sourc
		,case when @lcType = 'Consigned' then '' else r.part_no end as part_no
		,case when @lcType = 'Consigned' then '' else r.revision end as revision,r.partmfgr,r.mfgr_pt_no
		,r.warehouse
		,r.location
		,r.instore
		,isnull(r.lotcode,'') as lotcode
		-- 06/01/20 VL changed to show expdate, don't understand why use '' as expdate
		--,'' as expdate
		,expdate
		,isnull(r.reference,'') as reference,ponum
		--'5470000-00-00' as AccountNo
		,r.custname as CompanyName
		,case when @lcType = 'Consigned' then r.part_no else '' end as custpartno
		,case when @lcType = 'Consigned' then r.revision else '' end as custrev
		--,'' as Contractno
		, r.stdcost as Price
		--,'UDF' as UDF      
		,mtc
		-- 05/05/20 VL added @lcDisplayQty to consider if need to show qty or not
		--,case when useipkey = 1 then AvailMtcQty else availqty  end as countQty
		--,case when useipkey = 1 then AvailMtcQty else 0 end as QtyPerPackage
		,CASE WHEN @lcDisplayQty = 'Yes' THEN case when useipkey = 1 then AvailMtcQty else availqty end ELSE 0.00 END as countQty
		,CASE WHEN @lcDisplayQty = 'Yes' THEN case when useipkey = 1 then AvailMtcQty else 0 end ELSE 0.00 END as QtyPerPackage
		-- 05/05/20 VL added for LotQty because countQty only show invtmfgr level
		-- 05/05/20 VL added @lcDisplayQty to consider if need to show qty or not
		,CASE WHEN @lcDisplayQty = 'Yes' THEN lotqty ELSE 0.00 END AS lotQty
		-- 06/15/20 VL added to join UDF
		,U.*   
		--FROM @results r 
		FROM @results r left outer join ##tudfStr u on r.uniq_lot=u.fkuniq_lot  
		ORDER BY r.PART_NO, r.REVISION,partmfgr,mfgr_pt_no 
		OFFSET ((@PageNumber - 1) * @PageSize) ROWS FETCH NEXT @PageSize ROWS ONLY -- 29/12/18 Satyawan H: Implemented Pagination on SP RESULT
	-- 06/15/20 VL added ELSE
	ELSE
		-- 05/11/20 VL comment out part_no count and serialitems columns
		SELECT --COUNT(PART_NO) OVER()
		--,r.*
		--,'' as SERIALITEMS
		--, '' AS PackingListNo
		--, 'BEGINNING RAW MATL. INV.' AS Reason,'' as WayBill, '' as Carrier
		--,
		part_sourc
		,case when @lcType = 'Consigned' then '' else r.part_no end as part_no
		,case when @lcType = 'Consigned' then '' else r.revision end as revision,r.partmfgr,r.mfgr_pt_no
		,r.warehouse
		,r.location
		,r.instore
		,isnull(r.lotcode,'') as lotcode
		-- 06/01/20 VL changed to show expdate, don't understand why use '' as expdate
		--,'' as expdate
		,expdate
		,isnull(r.reference,'') as reference,ponum
		--'5470000-00-00' as AccountNo
		,r.custname as CompanyName
		,case when @lcType = 'Consigned' then r.part_no else '' end as custpartno
		,case when @lcType = 'Consigned' then r.revision else '' end as custrev
		--,'' as Contractno
		, r.stdcost as Price
		--,'UDF' as UDF      
		,mtc
		-- 05/05/20 VL added @lcDisplayQty to consider if need to show qty or not
		--,case when useipkey = 1 then AvailMtcQty else availqty  end as countQty
		--,case when useipkey = 1 then AvailMtcQty else 0 end as QtyPerPackage
		,CASE WHEN @lcDisplayQty = 'Yes' THEN case when useipkey = 1 then AvailMtcQty else availqty end ELSE 0.00 END as countQty
		,CASE WHEN @lcDisplayQty = 'Yes' THEN case when useipkey = 1 then AvailMtcQty else 0 end ELSE 0.00 END as QtyPerPackage
		-- 05/05/20 VL added for LotQty because countQty only show invtmfgr level
		-- 05/05/20 VL added @lcDisplayQty to consider if need to show qty or not
		,CASE WHEN @lcDisplayQty = 'Yes' THEN lotqty ELSE 0.00 END AS lotQty
		FROM @results r 

		ORDER BY r.PART_NO, r.REVISION,partmfgr,mfgr_pt_no 
		OFFSET ((@PageNumber - 1) * @PageSize) ROWS FETCH NEXT @PageSize ROWS ONLY -- 29/12/18 Satyawan H: Implemented Pagination on SP RESULT
	END	--Part number Sort End
ELSE IF (@lcSort = 'warehouse')
	BEGIN --warehouse  Sort Begin
	-- 06/15/20 VL added if UDF exists
	--- 05/01/19 YS added udf lot columns if exists  
	--05/10/19 YS check if udf table exists  
	if @vsSQL is not null 
	--- 05/01/19 YS added udf lot columns if exists
		-- 05/11/20 VL comment out part_no count and serialitems columns
		--SELECT -- COUNT(PART_NO) OVER(),
		--05/13/20 VL added all the columns, not just r.*
		SELECT 
		--COUNT(PART_NO) OVER()
		--,'' as SERIALITEMS
		--, '' AS PackingListNo
		--, 'BEGINNING RAW MATL. INV.' AS Reason,'' as WayBill, '' as Carrier
		--,
		part_sourc
		,case when @lcType = 'Consigned' then '' else r.part_no end as part_no
		,case when @lcType = 'Consigned' then '' else r.revision end as revision,r.partmfgr,r.mfgr_pt_no
		,r.warehouse
		,r.location
		,r.instore
		,isnull(r.lotcode,'') as lotcode
		-- 06/01/20 VL changed to show expdate, don't understand why use '' as expdate
		--,'' as expdate
		,expdate
		,isnull(r.reference,'') as reference,ponum
		--'5470000-00-00' as AccountNo
		,r.custname as CompanyName
		,case when @lcType = 'Consigned' then r.part_no else '' end as custpartno
		,case when @lcType = 'Consigned' then r.revision else '' end as custrev
		--,'' as Contractno
		, r.stdcost as Price
		--,'UDF' as UDF      
		,mtc
		-- 05/05/20 VL added @lcDisplayQty to consider if need to show qty or not
		--,case when useipkey = 1 then AvailMtcQty else availqty  end as countQty
		--,case when useipkey = 1 then AvailMtcQty else 0 end as QtyPerPackage
		,CASE WHEN @lcDisplayQty = 'Yes' THEN case when useipkey = 1 then AvailMtcQty else availqty end ELSE 0.00 END as countQty
		,CASE WHEN @lcDisplayQty = 'Yes' THEN case when useipkey = 1 then AvailMtcQty else 0 end ELSE 0.00 END as QtyPerPackage
		-- 05/05/20 VL added for LotQty because countQty only show invtmfgr level
		-- 05/05/20 VL added @lcDisplayQty to consider if need to show qty or not
		,CASE WHEN @lcDisplayQty = 'Yes' THEN lotqty ELSE 0.00 END AS lotQty	
		--r.*
		-- 06/15/20 VL added to join UDF
		,U.*   
		--FROM @results r 
		FROM @results r left outer join ##tudfStr u on r.uniq_lot=u.fkuniq_lot  
		ORDER BY r.WAREHOUSE, r.PART_NO, r.REVISION 
		OFFSET ((@PageNumber - 1) * @PageSize) ROWS FETCH NEXT @PageSize ROWS ONLY -- 29/12/18 Satyawan H: Implemented Pagination on SP RESULT
	-- 06/15/20 VL added ELSE
	ELSE
		SELECT 
		--COUNT(PART_NO) OVER()
		--,'' as SERIALITEMS
		--, '' AS PackingListNo
		--, 'BEGINNING RAW MATL. INV.' AS Reason,'' as WayBill, '' as Carrier
		--,
		part_sourc
		,case when @lcType = 'Consigned' then '' else r.part_no end as part_no
		,case when @lcType = 'Consigned' then '' else r.revision end as revision,r.partmfgr,r.mfgr_pt_no
		,r.warehouse
		,r.location
		,r.instore
		,isnull(r.lotcode,'') as lotcode
		-- 06/01/20 VL changed to show expdate, don't understand why use '' as expdate
		--,'' as expdate
		,expdate
		,isnull(r.reference,'') as reference,ponum
		--'5470000-00-00' as AccountNo
		,r.custname as CompanyName
		,case when @lcType = 'Consigned' then r.part_no else '' end as custpartno
		,case when @lcType = 'Consigned' then r.revision else '' end as custrev
		--,'' as Contractno
		, r.stdcost as Price
		--,'UDF' as UDF      
		,mtc
		-- 05/05/20 VL added @lcDisplayQty to consider if need to show qty or not
		--,case when useipkey = 1 then AvailMtcQty else availqty  end as countQty
		--,case when useipkey = 1 then AvailMtcQty else 0 end as QtyPerPackage
		,CASE WHEN @lcDisplayQty = 'Yes' THEN case when useipkey = 1 then AvailMtcQty else availqty end ELSE 0.00 END as countQty
		,CASE WHEN @lcDisplayQty = 'Yes' THEN case when useipkey = 1 then AvailMtcQty else 0 end ELSE 0.00 END as QtyPerPackage
		-- 05/05/20 VL added for LotQty because countQty only show invtmfgr level
		-- 05/05/20 VL added @lcDisplayQty to consider if need to show qty or not
		,CASE WHEN @lcDisplayQty = 'Yes' THEN lotqty ELSE 0.00 END AS lotQty	
		--r.*
		FROM @results r 
		ORDER BY r.WAREHOUSE, r.PART_NO, r.REVISION 
		OFFSET ((@PageNumber - 1) * @PageSize) ROWS FETCH NEXT @PageSize ROWS ONLY -- 29/12/18 Satyawan H: Implemented Pagination on SP RESULT

	END	--Warehouse Sort End


END