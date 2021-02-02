-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 06/05/2012
-- Description:	Create PO List from MP action results
-- Modified: 10/27/13 YS change parameter to be table valued
--			10/30/13 YS added Mfgrs colunm to extract all approved avl
-- return multiple data sets
-- 01/24/14-01/27/14 YS more changes working towards creating PO from MRP 
-- 04/25/14 YS contr_no has to be 20 characters
-- 09/23/14 YS use new tables in place of invtmfhd
-- 08/04/16 YS "package" column is 15 char (not 10)
---02/01/17 YS contract tables are modified
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 06/15/17 YS some times there was more spaces between MFGR and MPN saved in the prefavl column. If MPN is full 30 characters the vallue will be trimmed by the number of extra spaces
--- change the parsing code to get rid of extra spaces but leave a single space . If MPN has a single space that will work. But if MPN have double space we may still see a problem.
-- 08/01/17 YS use mfgrmaster value that was matched with prefavl from mrpaction table
-- 07/12/18 YS supname field name encreased 30 to 50
-- 04/24/19 VL tried to fix an issue that if mfgr_pt_no contains " (", the code didn't work, it remove the space.  Eg '3M       DP420NS-BLACK (50ML/1.69OZ)    ' will return 'DP420NS-BLACK(50ML/1.69OZ)    ' for mfgr_pt_no
-- 01/30/20 YS moved package to mfgrmaster table
-- =============================================
CREATE PROCEDURE [dbo].[MrpPoListView]
	-- Add the parameters for the stored procedure here
	--- comma separated values of UniqMrpAct 
	--10/27/13 YS change parameter to be table valued
	--@lCSVUniqMrpAct varchar(max) =' '
	@tMrpAct as tMrpActUniq READONLY
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    -- 08/04/16 YS "package" column is 15 char (not 10)
	declare @mrpPoActionList Table 
		(YesNo bit default 1,
		 lSelected bit default 0,
		 --- 03/28/17 YS changed length of the part_no column from 25 to 35
		 Part_no char(35), 
		 Revision char(8), 
		 Part_Class char(8),
		 Part_Type char(8),
		 Descript char(45), 
		 PartMfgr char(8),
		 Mfgr_pt_no char(30),
		 UniqMfgrhd char(10),
		 PrefAvl varchar(40),
		 CostEach numeric(12,6),
		 Schd_qty numeric(9,0), 
		 ReqDate smalldatetime,
		 DtTakeAct smalldatetime,
		 Uniq_key char(10),
		 UniqSupno char(10),
		 -- 07/12/18 YS supname field name encreased 30 to 50
		 SupName char(50),
		 Supid char(10),
		 UNIQMFSP char(10),
		 cmethodnm char(35),
		 buyer_type char(3),
		 lPriced bit,
		 PoUniqLnno char(10),
		 Ponum char(15),
		 UniqMrpAct char(10),
		 U_of_meas char(4),
		 Pur_uofm char(4),
		-- 08/04/16 YS "package" column is 15 char (not 10)
		 package char(15),
		 Mfgrs varchar(max) 
		 --01/27/14 YS added material cost and target price column 	
		 ,Matl_cost numeric(13,5)
		 ,targetPrice numeric(13,5)
		 --02/02/14 YS added lDisallowbuy
		 ,lDisallowbuy bit
		)
    -- 01/24/14 YS added contract information if any
    --01/28/14 YS remove supplier information from All AVLs, use separate table
   -- declare @mrpPOActAllAvls table (uniqmrpact char(10),uniq_key char(10),Prefavl varchar(50), TotalQtyByMPN numeric(12,2),PartMfgr char(8),mfgr_pt_no char(30),
			--uniqmfgrhd char(10),uniqmfsp char(10),uniqsupno char(10),Supname char(30),supid char(10) )	
	declare @mrpPOActAllAvls table (uniqmrpact char(10),uniq_key char(10),Prefavl varchar(50), TotalQtyByMPN numeric(12,2),PartMfgr char(8),mfgr_pt_no char(30),
			uniqmfgrhd char(10))			
			
	--01/24/14 YS added contract supplier information
	-- 04/25/14 YS contr_no has to be 20 characters		
	-- 07/12/18 YS supname field name encreased 30 to 50
	declare @mrpPOActAllAvlsWithContract table (uniqmrpact char(10),uniq_key char(10),PartMfgr char(8),mfgr_pt_no char(30),
			uniqmfgrhd char(10),uniqsupno char(10),Supname char(50),supid char(10),contr_uniq char(10),Contr_no char(20),
			startdate smalldatetime,[expiredate] smalldatetime ,mfgr_uniq char(10))
						
    
    -- 01/28/14 YS get all mpns with assigned suppliers (default or not default)
    DECLARE @tUniqmfgrhd tUniqMfgrHd  
	
		
		

			
    
    declare @t table (uniqmrpact char(10),uniq_key char(10),ReqQty numeric(10,2),Prefavl varchar(50),MfgrsXml xml)	
    --01/28/14 YS remove join with supinfo and invtmfsp table. Use separate result for all assigned suppliers
 --  	INSERT INTO  @mrpPoActionList  SELECT CAST(1 as Bit) as YesNo, CAST(0 as Bit) as lSelected,Inventor.Part_no, Inventor.Revision, 
	--	Inventor.Part_Class, Inventor.Part_Type, Inventor.Descript, 
	--	dbo.PADR(RTRIM(SUBSTRING(MrpAct.PrefAvl,1,CHARINDEX(' ',MrpAct.PrefAvl))),8,' ') AS PartMfgr, 
	--	CAST(LTRIM(RTRIM(SUBSTRING(MrpAct.PrefAvl,CHARINDEX(' ',MrpAct.PrefAvl)+1,30))) as char(30)) as Mfr_pt_no,
	--	Invtmfhd.UniqMfgrhd,MrpAct.PrefAvl,CAST(0.00 as numeric(12,6)) as CostEach,MrpAct.ReqQty as Schd_qty, 
	--	MrpAct.ReqDate,MrpAct.DtTakeAct,MrpAct.Uniq_key,ISNULL(Invtmfsp.UniqSupno,SPACE(10)) as UniqSupno,
	--	ISNULL(Supinfo.Supname,SPACE(30)) as SupName,
	--	ISNULL(Supinfo.Supid,SPACE(10)) as Supid,
	--	ISNULL(Invtmfsp.UNIQMFSP,SPACE(10)) as UniqMfSp,
	--	SPACE(35) as cmethodnm,Inventor.buyer_type,CAST(0 as bit) as lPriced,PoUniqLnno,SPACE(15) as Ponum,
	--	MrpAct.UniqMrpAct,Inventor.U_of_meas,Inventor.Pur_uofm,MRPACT.Mfgrs ,
	--	Inventor.MATL_COST ,Inventor.TARGETPRICE  
	--FROM MrpAct INNER JOIN Inventor ON Inventor.Uniq_key = MrpAct.Uniq_key 
	--INNER JOIN Invtmfhd ON Invtmfhd.Uniq_key=MrpAct.Uniq_key
	--	AND Invtmfhd.PartMfgr=dbo.PADR(RTRIM(SUBSTRING(MrpAct.PrefAvl,1,CHARINDEX(' ',MrpAct.PrefAvl))),8,' ')
	--	AND Invtmfhd.Mfgr_pt_no=CAST(LTRIM(RTRIM(SUBSTRING(MrpAct.PrefAvl,CHARINDEX(' ',MrpAct.PrefAvl)+1,30))) as char(30))
	--LEFT OUTER JOIN Invtmfsp ON Invtmfhd.Uniqmfgrhd=Invtmfsp.Uniqmfgrhd and Invtmfsp.IS_DELETED =0 and Invtmfsp.pfDSupl=1
	--LEFT OUTER JOIN SUPINFO ON Invtmfsp.uniqsupno=Supinfo.UNIQSUPNO and Invtmfsp.pfDSupl=1
	--	--10/27/13 YS use table valued parameter
	--	WHERE MrpAct.UNIQMRPACT IN (select  UNIQMRPACT  from @tMrpAct)
	--	--WHERE MrpAct.UNIQMRPACT IN (select * from fn_simpleVarcharlistToTable(@lCSVUniqMrpAct,','))
	--	AND MrpAct.Action = 'Release PO' and MrpAct.PoUniqLnno=' '
	--	AND Invtmfhd.Is_deleted =0
	--	AND Invtmfhd.lDisallowbuy=0
	
	-- 02/02/14 YS add lDisallowbuy column and remove the filter, when partmfgr is not allowed to be bought replace with empty, user will see that there is a buy action
	-- 09/23/14 YS use new tables instead of invtmfhd
	INSERT INTO  @mrpPoActionList  SELECT CAST(1 as Bit) as YesNo, CAST(0 as Bit) as lSelected,Inventor.Part_no, Inventor.Revision, 
		Inventor.Part_Class, Inventor.Part_Type, Inventor.Descript, 
		-- 08/01/17 YS use mfgrmaster value that was matched with prefavl from mrpaction table
		--dbo.PADR(RTRIM(SUBSTRING(MrpAct.PrefAvl,1,CHARINDEX(' ',MrpAct.PrefAvl))),8,' ') AS PartMfgr, 
		--CAST(LTRIM(RTRIM(SUBSTRING(MrpAct.PrefAvl,CHARINDEX(' ',MrpAct.PrefAvl)+1,30))) as char(30)) as Mfr_pt_no,
		M.partmfgr,M.Mfgr_pt_no as mfr_pt_no,
		L.UniqMfgrhd,MrpAct.PrefAvl,CAST(0.00 as numeric(12,6)) as CostEach,MrpAct.ReqQty as Schd_qty, 
		MrpAct.ReqDate,MrpAct.DtTakeAct,MrpAct.Uniq_key,SPACE(10) as UniqSupno,
		-- 07/12/18 YS supname field name encreased 30 to 50
		SPACE(50) as SupName,SPACE(10) as Supid,SPACE(10) as UniqMfSp,
		SPACE(35) as cmethodnm,Inventor.buyer_type,CAST(0 as bit) as lPriced,PoUniqLnno,SPACE(15) as Ponum,
		-- 01/30/20 YS moved package to mfgrmaster table
		MrpAct.UniqMrpAct,Inventor.U_of_meas,Inventor.Pur_uofm,
		--Inventor.PACKAGE  
		M.part_pkg as Package,
		MRPACT.Mfgrs ,
		Inventor.MATL_COST ,Inventor.TARGETPRICE , lDisallowbuy
	FROM MrpAct INNER JOIN Inventor ON Inventor.Uniq_key = MrpAct.Uniq_key 
	INNER JOIN InvtMpnLink L on l.Uniq_key=mrpAct.uniq_key
	--INNER JOIN Invtmfhd ON Invtmfhd.Uniq_key=MrpAct.Uniq_key
	INNER JOIN MfgrMaster M ON m.MfgrMasterId=L.mfgrMasterId
		AND M.PartMfgr=dbo.PADR(RTRIM(SUBSTRING(MrpAct.PrefAvl,1,CHARINDEX(' ',MrpAct.PrefAvl))),8,' ')
		--AND M.Mfgr_pt_no=CAST(LTRIM(RTRIM(SUBSTRING(MrpAct.PrefAvl,CHARINDEX(' ',MrpAct.PrefAvl)+1,30))) as char(30))
		-- 06/15/17 YS some times there was more spaces between MFGR and MPN saved in the prefavl column. If MPN is full 30 characters the vallue will be trimmed by the number of extra spaces
--- change the parsing code to get rid of extra spaces but leave a single space . If MPN has a single space that will work. But if MPN have double space we may still see a problem.
		-- 04/24/19 VL tried to fix an issue that if mfgr_pt_no contains " (", the code didn't work, it remove the space.  Eg '3M       DP420NS-BLACK (50ML/1.69OZ)    ' will return 'DP420NS-BLACK(50ML/1.69OZ)    ' for mfgr_pt_no
		-- try to replace '(' with '~', then replace back
		--AND M.mfgr_pt_no=CAST(LTRIM(RTRIM(SUBSTRING(replace(replace(replace(mrpact.prefavl,char(32),'()'),')(',''),'()',char(32)),
		--CHARINDEX(' ',replace(replace(replace(mrpact.prefavl,char(32),'()'),')(',''),'()',char(32)))+1,30))) as char(30))
		AND M.mfgr_pt_no=CAST(LTRIM(RTRIM(SUBSTRING(replace(replace(replace(replace(replace(mrpact.prefavl,'(',char(96)),char(32),'()'),')(',''),'()',char(32)),char(96),'('),
		CHARINDEX(' ',replace(replace(replace(replace(mrpact.prefavl,'(',char(96)),char(32),'()'),')(',''),'()',char(32)))+1,30))) as char(30))

		--10/27/13 YS use table valued parameter
		WHERE MrpAct.UNIQMRPACT IN (select  UNIQMRPACT  from @tMrpAct)
		--WHERE MrpAct.UNIQMRPACT IN (select * from fn_simpleVarcharlistToTable(@lCSVUniqMrpAct,','))
		AND MrpAct.Action = 'Release PO' and MrpAct.PoUniqLnno=' '
		AND L.Is_deleted =0
		--AND Invtmfhd.lDisallowbuy=0
	
	
	
		-- get all avls nopt just prefered
		-- for the debugging convenience split the sql
		-- first create xml then replace (otherwise values like 'T&I' will generate an error 
		INSERT INTO @t 
		SELECT uniqmrpact,uniq_key,ReqQty,PREFAVL,convert(xml,replace(convert(varchar(max),(Select Mfgrs
				FOR XML PATH)),'`','</Mfgrs><Mfgrs>')) as MfgrsXml
		from MRPACT 
		where MrpAct.UNIQMRPACT IN (select  UNIQMRPACT  from @tMrpAct)
		AND [Action]= 'Release PO'  and MrpAct.PoUniqLnno=' '

		;WITH ParseMfgr
		as(
		SELECT t.uniqmrpact,t.UNIQ_KEY,t.Prefavl,t.ReqQty, t2.m.value('.','varchar(100)') as Newmfgr
		FROM   @t T
		CROSS APPLY MfgrsXml.nodes('/row/Mfgrs') as T2(m) 	
		),
		SplitNewMfgr as
		(
		select p.uniqmrpact,p.uniq_key,p.ReqQty, p.Prefavl,p.Newmfgr ,
		case when CHARINDEX(' ',p.Newmfgr)=0 THEN CAST(p.Newmfgr as CHAR(8)) ELSE
			CAST(SUBSTRING(p.Newmfgr,1,CHARINDEX(' ',p.Newmfgr)) as char(8)) END as PartMfgr,
		case when CHARINDEX(' ',p.Newmfgr)=0 THEN CAST('' as varchar(35)) ELSE
			CAST(LTRIM(STUFF(p.Newmfgr,1,CHARINDEX(' ',p.Newmfgr),'')) as varchar(35)) END as Mfgr_pt_no
		from ParseMfgr P )
		
		
		 --01/28/14 YS remove join with supinfo and invtmfsp table. Use separate result for all assigned suppliers
		--INSERT INTO @mrpPOActAllAvls (uniqmrpact ,uniq_key ,Prefavl , TotalQtyByMPN,PartMfgr,mfgr_pt_no,uniqmfgrhd,uniqmfsp ,uniqsupno ,Supname,supid )
		--	SELECT S.uniqmrpact ,S.uniq_key ,S.Prefavl,SUM(S.ReqQty) OVER(partition by h.uniqmfgrhd) as TotalQtyByMPN,  S.PartMfgr,S.Mfgr_pt_no ,H.UNIQMFGRHD,
		--	ISNULL(ms.uniqmfsp,space(10)) as uniqmfsp,  
		--	ISNULL(ms.uniqsupno,space(10)) as uniqsupno ,
		--	ISNULL(supinfo.supname,SPACE(30)) as Supname,
		--	ISNULL(supinfo.supid,space(10)) as Supid
		--	FROM SplitNewMfgr S INNER JOIN INVTMFHD H on 
		--		S.uniq_key=h.UNIQ_KEY 
		--		and S.PartMfgr =h.PARTMFGR 
		--		and s.Mfgr_pt_no =h.MFGR_PT_NO 
		--		left outer join INVTMFSP MS on h.UNIQMFGRHD =MS.UNIQMFGRHD and ms.PFDSUPL =1 and ms.IS_DELETED =0
		--		left outer join SUPINFO on ms.uniqsupno =SUPINFO.UNIQSUPNO 
		--	WHERE H.Is_deleted =0
		--	AND H.lDisallowbuy=0	
		--09/23/14 YS use new tables
		INSERT INTO @mrpPOActAllAvls (uniqmrpact ,uniq_key ,Prefavl , TotalQtyByMPN,PartMfgr,mfgr_pt_no,uniqmfgrhd)
			SELECT S.uniqmrpact ,S.uniq_key ,S.Prefavl,SUM(S.ReqQty) OVER(partition by l.uniqmfgrhd) as TotalQtyByMPN,  S.PartMfgr,S.Mfgr_pt_no ,l.UNIQMFGRHD
			FROM SplitNewMfgr S 
				--INNER JOIN INVTMFHD H on 
				INNER JOIN InvtMpnLink L on 
				S.uniq_key=l.UNIQ_KEY 
				INNER JOIN MfgrMaster M ON L.mfgrMasterId=m.MfgrMasterId
				and S.PartMfgr =m.PARTMFGR 
				and s.Mfgr_pt_no =m.MFGR_PT_NO 
			WHERE l.Is_deleted =0
			AND m.lDisallowbuy=0
		
		
			
		INSERT INTO @mrpPOActAllAvlsWithContract 
			select a.uniqmrpact,a.uniq_key,a.PartMfgr,a.mfgr_pt_no,a.uniqmfgrhd,
				c.uniqsupno,C.supname ,c.supid,
			c.CONTR_UNIQ,c.Contr_no,c.STARTDATE ,c.[EXPIREDATE] ,c.mfgr_uniq from @mrpPOActAllAvls A inner JOIN 
			(SELECT c.CONTR_UNIQ,  Ch.contr_no,c.Uniq_key,Ch.UniqSupno,s.supid,M.Partmfgr,M.mfgr_pt_no,m.MFGR_UNIQ,  s.Supname,ch.STARTDATE ,ch.[EXPIREDATE]
				---02/01/17 YS contract tables are modified
				from ContractHeader CH inner join 
				CONTRACT C ON CH.ContractH_unique=C.Contracth_unique
				inner join CONTMFGR M on c.CONTR_UNIQ =m.CONTR_UNIQ 
				inner join SUPINFO S on ch.UniqSupno =s.UNIQSUPNO ) C on A.uniq_key = c.UNIQ_KEY and a.PartMfgr =c.PARTMFGR and a.mfgr_pt_no =c.MFGR_PT_NO 
		--01/27/14 MrpPoListView - return request list	
		select * from @mrpPoActionList	order by UniqMrpAct 
		--01/27/14 MrpPoListView1 - return all AVLS for each uniqmrpact
		select * from @mrpPOActAllAvls	order by UniqMrpAct
		
		-- 01/27/14 MrpPoListView2 - return all contracts 
		select * from @mrpPOActAllAvlsWithContract order by uniqmrpact 
		
		-- 01/27/14 MrpPoListView3 - return contract price info 
		-- 01/29/14 YS show beginning and end qty for the price breake, if change qty to the max number for the last price breake.
		;with pricebrake
		as(
		select PRIC_UNIQ, MFGR_UNIQ,CONTPRIC.QUANTITY,Price ,ROW_NUMBER() over (partition by mfgr_uniq order by quantity desc) as nrowdesc  
			from CONTPRIC WHERE mfgr_uniq IN (SELECT mfgr_uniq from @mrpPOActAllAvlsWithContract)
		)
		select C.*,CP.PRIC_UNIQ,cp.PRICE,isnull(cpBegin.QUANTITY+1,CAST(0 as Numeric(10,0))) as begQty , 
			case when cp.nrowdesc=1 THEN 9999999999 ELSE cp.QUANTITY END as endQty 
			from @mrpPOActAllAvlsWithContract C INNER JOIN pricebrake CP ON C.mfgr_uniq = cp.MFGR_UNIQ 
			OUTER APPLY (select MFGR_UNIQ,PRIC_UNIQ,quantity FROM  contpric P WHERE p.MFGR_UNIQ =cp.MFGR_UNIQ and p.QUANTITY <cp.QUANTITY ) cpBegin
			order by c.uniqmrpact,c.uniq_key,c.Contr_no,isnull(cpBegin.QUANTITY,CAST(0 as Numeric(10,0)))   
			
		--01/27/14 MrpPoListView4 - return latest PO based on VerDate created in the last 6 month
		;with latestPO
		as
		(
		SELECT distinct Ph.VerDate ,S.Supname,s.UNIQSUPNO,s.supid ,Ph.Ponum ,A.PartMfgr,
		Pd.Costeach ,Pd.Ord_qty ,Ph.Podate ,A.Mfgr_pt_no,A.Uniq_key,Pd.UniqLnNo,a.uniqmfgrhd,
		ROW_NUMBER() OVER (PARTITION BY A.Uniq_key,S.uniqsupno ORDER BY Ph.verdate desc) as NPO
		FROM @mrpPOActAllAvls A INNER JOIN poitems PD ON A.uniq_key =Pd.UNIQ_KEY
		and A.uniqmfgrhd  =Pd.UNIQMFGRHD  
		INNER JOIN pomain PH on pd.PONUM=ph.ponum
		INNER JOIN SUPINFO S on ph.UNIQSUPNO=s.UNIQSUPNO 
		where Pd.lCancel=0
		AND (ph.PoStatus='OPEN' OR ph.PoStatus='CLOSED') 
		And datediff(MONTH,VERDATE,GETDATE())<=6 
		)
		select * from latestPO where NPO =1
		ORDER BY UNIQ_KEY 
		-- 01/28/14 YS MrpPoListView5 added all suppliers assigned in the Item Master to MPNs
		-- 01/28/14 YS get all mpns with assigned suppliers (default or not default)
		INSERT INTO @tUniqmfgrhd 
		SELECT DISTINCT Uniqmfgrhd FROM @mrpPOActAllAvls 
		EXEC GetInvtMfsp4GivenMPNs @tUniqmfgrhd
		
END