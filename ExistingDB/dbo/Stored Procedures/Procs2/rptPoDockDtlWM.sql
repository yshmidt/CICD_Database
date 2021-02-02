
-- =============================================
-- Author:		<Debbie>
-- Create date: <12/02/2011>
-- Description:	<Compiles the detailed information for the PO Dock Reports>
-- Used On:     <Crystal Report {podockin.rpt}, {podckinw.rpt}, {podock01.rpt} and {podock02.rpt} 
-- Modified:	10/19/2012 DRP:  Through testing found that I was missing code for situation that the users are not using PODOCK within the system.
--								Vicky provided the suggestion to look within the PODEFLTS table to determine if they use PODOCK or not.  Then based off of that it will run through the specified code. 
--			03/18/2015 DRP:  Per request we needed to add the parameter back (@lcPoNum) into this procedure to allow the users to either select multiple purchase orders or a single Purchase Order from the list. 
--							 Added the /*SUPPLIER LIST*/	
--- 04/14/15 YS change "location" column length to 256	
--			12/07/15 DRP:	  updated the first section of the code to use the Recvdate instead of casting todays date
-- 02/02/17 YS we are changing the PO receiving procedure. When done new reports will have to be generated					
-- 07/10/2019 Rajendra K : Added join with receiverDetail and receiverHeader to get inspection info. and added isinspReq , isinspCompleted in selection list.  
--  [dbo].[rptPoDockDtlWM] 'ALL','2EE8060A-56A2-40FC-9F74-4D7567785F9A'  
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================
CREATE PROCEDURE [dbo].[rptPoDockDtlWM]

--declare 
		@lcPoNum as varchar (max) = null
		, @userId uniqueidentifier= null


as
begin

/*SUPPLIER LIST*/	
-- get list of approved suppliers for this user
DECLARE @tSupplier tSupplier
DECLARE @tSupNo AS TABLE (Uniqsupno CHAR (10))    

INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, 'All';
--SELECT * FROM @tSupplier

  --/*PO LIST*/    
DECLARE  @tPoNum AS TABLE (PoNum CHAR (15))    
 DECLARE @PoNum TABLE(PoNum CHAR(15))    
 INSERT INTO @tPoNum SELECT ponum FROM pomain WHERE postatus = 'OPEN'    
     
  IF @lcPoNum IS NOT NULL AND @lcPoNum <>'' AND @lcPoNum<>'All'    
   INSERT INTO @PoNum SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcPoNum,',')    
     WHERE CAST (id AS CHAR(15)) IN (SELECT PoNum FROM @tPoNum)    
  ELSE    
    
  IF  @lcPoNum='All'     
  BEGIN    
   INSERT INTO @PoNum SELECT PoNum FROM @tPoNum    
  END    
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
DECLARE @results AS TABLE (PoNum char(15),SupName char (30),dDate DATE,uniqlnno CHAR (10),itemno CHAR(3),Balance NUMERIC(12,2),porecpkno CHAR(15)    
       ,RecvQty NUMERIC (12,2),ReceiverNo CHAR(10),isinspReq BIT,isinspCompleted BIT,Part_no CHAR(35),Rev CHAR(8),Descript CHAR(45),Part_Class CHAR(8)    
       ,Part_Type CHAR(8),Pur_UofM CHAR(4),QualSpec CHAR(10),PartMfgr CHAR(8),Mfgr_Pt_No CHAR(30),Insp_Req BIT,Schd_date SMALLDATETIME    
       ,Requestor CHAR(40),Warehouse CHAR(6),Location VARCHAR(256),ReqAlloc CHAR(25))    
	
INSERT INTO @results   
 SELECT poitems.ponum,Supinfo.supname,PORECDTL.RECVDATE AS dDate    
   ,Poitems.uniqlnno,Poitems.itemno,Poitems.ord_qty-Poitems.acpt_qty AS balance    
   ,porecdtl.porecpkno,porecdtl.ReceivedQty,porecdtl.receiverno  
   ,RD.isinspReq,RD.isinspCompleted  -- 07/10/2019 Rajendra K : Added join with receiverDetail and receiverHeader to get inspection info. and added isinspReq , isinspCompleted in selection list.  
   ,CASE WHEN poitems.POITTYPE = 'MRO' or poitems.POITTYPE ='Services' THEN poitems.PART_NO ELSE Inventor.PART_NO END AS Part_no    
   ,CASE WHEN poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' THEN poitems.REVISION ELSE inventor.REVISION END AS Rev    
   ,CASE WHEN poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' THEN poitems.DESCRIPT ELSE inventor.DESCRIPT END AS Descript    
   ,CASE WHEN poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' THEN poitems.PART_CLASS ELSE inventor.PART_CLASS END AS Part_Class    
   ,CASE WHEN POITEMS.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' THEN POITEMs.PART_TYPE ELSE inventor.PART_TYPE END AS part_type    
   ,poitems.PUR_UOFM,CASE WHEN POITEMS.POITTYPE = 'Invt Part' THEN CAST (SUPPORT.TEXT4 AS CHAR(10)) ELSE CAST ('' AS CHAR(10)) END AS QualSpec    
   ,poitems.PARTMFGR,poitems.MFGR_PT_NO,inventor.INSP_REQ,POITSCHD.SCHD_DATE,requestor,WAREHOUSE,LOCATION    
   ,CASE WHEN POITSCHD.requesttp = 'WO Alloc' THEN CAST ('WO Alloc:  ' + WOPRJNUMBER AS CHAR (25))     
    ELSE CASE WHEN poitschd.REQUESTTP = 'Prj Alloc' THEN CAST ('Prj Alloc:  ' + WOPRJNUMBER AS CHAR(25)) ELSE CAST ('' AS CHAR(25)) END END AS ReqAlloc      

  FROM PORECDTL   
   INNER JOIN receiverDetail RD ON  PORECDTL.receiverdetId = RD.receiverDetId -- 07/10/2019 Rajendra K : Added join with receiverDetail and receiverHeader to get inspection info. and added isinspReq , isinspCompleted in selection list.  
   INNER JOIN receiverHeader RH ON RD.receiverHdrId = RH.receiverHdrId AND RH.inspectionSource = 'P'  
   INNER JOIN POITEMS ON PORECDTL.UNIQLNNO = poitems.UNIQLNNO    
   LEFT OUTER JOIN INVENTOR ON poitems.UNIQ_KEY = inventor.UNIQ_KEY    
   LEFT OUTER JOIN SUPPORT ON INVENTOR.PART_CLASS = SUPPORT.TEXT2    
   INNER JOIN POMAIN ON POITEMS.PONUM = pomain.PONUM    
   INNER JOIN SUPINFO ON pomain.UNIQSUPNO = supinfo.UNIQSUPNO    
   LEFT OUTER JOIN POITSCHD ON PORECDTL.uniqlnno = POITSCHD.UNIQLNNO    
   LEFT OUTER JOIN WAREHOUS ON poitschd.UNIQWH = WAREHOUS.UNIQWH    


  WHERE Poitems.lcancel <> 1    
      AND  Postatus= 'OPEN'    
      AND BALANCE > 0   
   AND EXISTS (SELECT 1 FROM @tSupplier t  WHERE t.uniqsupno=pomain.uniqsupno)    
   AND EXISTS (SELECT 1 FROM @PoNum p  WHERE p.ponum=pomain.ponum)   

  select * from @results   
--/*SELECT STATEMENT*/

--DECLARE @lIsDock bit

--SELECT @lIsDock = IsDock FROM PoDeflts
----- 04/14/15 YS change "location" column length to 256
--declare @results as table	(PoNum char(15),SupName char (30),dDate date,uniqlnno char (10),itemno char(3),Balance numeric(12,2),porecpkno char(15)
--							,RecvQty numeric (12,2),ReceiverNo char(10),Dock_Uniq char(10),Part_no char(25),Rev char(8),Descript char(45),Part_Class char(8)
--							,Part_Type char(8),Pur_UofM char(4),QualSpec char(10),PartMfgr char(8),Mfgr_Pt_No char(30),Insp_Req bit,Schd_date smalldatetime
--							,Requestor char(40),Warehouse char(6),Location varchar(256),ReqAlloc char(25))

--IF @lIsDock = 0
--insert into @results
--	SELECT	poitems.ponum,Supinfo.supname,PORECDTL.RECVDATE as dDate	--, cast(getdate() as DATE) AS dDate	--12/07/15 DRP:  changed it to populate with the recvdate
--			,Poitems.uniqlnno,Poitems.itemno,Poitems.ord_qty-Poitems.acpt_qty AS balance
--			,porecdtl.porecpkno,porecdtl.recvqty,porecdtl.receiverno,porecdtl.dock_uniq
--			,case when poitems.POITTYPE = 'MRO' or poitems.POITTYPE ='Services' then poitems.PART_NO else Inventor.PART_NO end as Part_no
--			,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.REVISION else inventor.REVISION end as Rev
--			,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.DESCRIPT else inventor.DESCRIPT end as Descript
--			,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.PART_CLASS else inventor.PART_CLASS end as Part_Class
--			,case when POITEMS.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then POITEMs.PART_TYPE else inventor.PART_TYPE end as part_type
--			,poitems.PUR_UOFM,CASE WHEN POITEMS.POITTYPE = 'Invt Part' then cast (SUPPORT.TEXT4 as CHAR(10)) else CAST ('' as CHAR(10)) end as QualSpec
--			,poitems.PARTMFGR,poitems.MFGR_PT_NO,inventor.INSP_REQ,POITSCHD.SCHD_DATE,requestor,WAREHOUSE,LOCATION
--			,case when POITSCHD.requesttp = 'WO Alloc' then CAST ('WO Alloc:  ' + WOPRJNUMBER as CHAR (25)) 
--				else case when poitschd.REQUESTTP = 'Prj Alloc' then CAST ('Prj Alloc:  ' + WOPRJNUMBER as CHAR(25)) else CAST ('' as CHAR(25)) end end as ReqAlloc  
				
			
--	 FROM	PORECDTL 
--			inner join POITEMS on PORECDTL.UNIQLNNO = poitems.UNIQLNNO
--			left outer join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY
--			LEFT OUTER JOIN SUPPORT ON INVENTOR.PART_CLASS = SUPPORT.TEXT2
--			inner join POMAIN on POITEMS.PONUM = pomain.PONUM
--			inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO
--			LEFT OUTER JOIN POITSCHD ON PORECDTL.uniqlnno = POITSCHD.UNIQLNNO
--			left outer join WAREHOUS on poitschd.UNIQWH = WAREHOUS.UNIQWH
			
			
--	 WHERE	Poitems.lcancel <> 1
--	   		AND  Postatus= 'OPEN'
--   			and BALANCE > 0
--			and exists (select 1 from @tSupplier t  where t.uniqsupno=pomain.uniqsupno)
--			and  exists (select 1 from @PoNum p  where p.ponum=pomain.ponum)
	

--else
--insert into @results
--	select	podock.PONUM,SUPINFO.SUPNAME,podock.dDockDate,podock.UNIQLNNO,poitems.ITEMNO,Poitems.ord_qty-Poitems.acpt_qty AS balance
--			,PODOCK.PORECPKNO,PODOCK.QTY_REC as recvqty,PODOCK.RECEIVERNO,PODOCK.DOCK_UNIQ
--			,case when poitems.POITTYPE = 'MRO' or poitems.POITTYPE ='Services' then poitems.PART_NO else Inventor.PART_NO end as Part_no
--			,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.REVISION else inventor.REVISION end as Rev
--			,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.DESCRIPT else inventor.DESCRIPT end as Descript
--			,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.PART_CLASS else inventor.PART_CLASS end as Part_Class
--			,case when POITEMS.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then POITEMs.PART_TYPE else inventor.PART_TYPE end as part_type
--			,poitems.PUR_UOFM
--			,CASE WHEN POITEMS.POITTYPE = 'Invt Part' then cast (SUPPORT.TEXT4 as CHAR(10)) else CAST ('' as CHAR(10)) end as QualSpec
--			,poitems.PARTMFGR
--			,poitems.MFGR_PT_NO
--			,inventor.INSP_REQ
--			,POITSCHD.SCHD_DATE
--			,requestor,WAREHOUSE,LOCATION
--			,case when POITSCHD.requesttp = 'WO Alloc' then CAST ('WO Alloc:  ' + WOPRJNUMBER as CHAR (25)) 
--				else case when poitschd.REQUESTTP = 'Prj Alloc' then CAST ('Prj Alloc:  ' + WOPRJNUMBER as CHAR(25)) else CAST ('' as CHAR(25)) end end as ReqAlloc  
			
--	from	PODOCK
--			inner join POITEMS on podock.UNIQLNNO = poitems.UNIQLNNO
--			left outer join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY
--			LEFT OUTER JOIN SUPPORT ON INVENTOR.PART_CLASS = SUPPORT.TEXT2
--			inner join POMAIN on podock.PONUM = pomain.PONUM
--			inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO
--			LEFT OUTER JOIN POITSCHD ON podock.uniqlnno = POITSCHD.UNIQLNNO
--			left outer join WAREHOUS on poitschd.UNIQWH = WAREHOUS.UNIQWH
			
--	where	PODOCK.COMPDATE is null
--			and Poitems.lcancel <> 1
--			and BALANCE > 0.00
--			and exists (select 1 from @tSupplier t  where t.uniqsupno=pomain.uniqsupno)
--			and  exists (select 1 from @PoNum p  where p.ponum=pomain.ponum)
			
--select * from @results
end