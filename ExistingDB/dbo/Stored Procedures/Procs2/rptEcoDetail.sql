--USE [MANEX]              
--GO              
--/****** Object:  StoredProcedure [dbo].[rptEcoDetail]    Script Date: 03/18/2013 13:33:14 ******/              
--SET ANSI_NULLS ON              
--GO              
--SET QUOTED_IDENTIFIER ON              
--GO              
              
-- =============================================              
-- Author:   Debbie               
-- Create date:  03/18/2013              
-- Description:  Created for the ECO Detailed Reportr              
-- Reports:   ecoreprt.rpt               
-- Modifications: 06/13/18 YS got an error Column name or number of supplied values does not match table definition. when inserting into @eco              
--- will use temp table to avoid the error.              
-- 07/17/18 YS tools AND fixtures moved FROM the support table          
-- 09/17/19 Vijay G Modified the code AS per current requirement                
-- 09/18/20 VL Added missing product number information and fixed the issue that part_no showing product number information
--exec [rptEcoDetail] @lcEcoNo='00000000000000001371',@userId='49F80792-E15E-4B62-B720-21B360E3108A'             
---- =============================================              
          
CREATE  PROCEDURE  [dbo].[rptEcoDetail]                             
 @lcEcoNo AS char (20) = '', --This will be single entry parameter.  Vicky will default the ECO # that is open ON screen to the report parameter, but the users will have the optiON to change if needed.                            
 @userId uniqueidentifier=NULL               
AS              
begin              
              
SET @lcEcoNo=dbo.PADL(@lcEcoNo,20,'0')              
              
--06/13/18 YS got an error Column name or number of supplied values does not match table definition. when inserting into @eco              
--- will use temp table to avoid the error.               
--declare @ECO AS table (TYPE CHAR(10),UNIQECNO char(10),ECONO char(20),BOMCUSTNO char(10),PROD_UNIQ_KEY char(10),CHANGETYPE char(10),ECSTATUS char(10),PURPOSE text,ECDESCRIPT text              
--      ,OUNITCOST NUMERIC(13,5),NUNITCOST NUMERIC(13,5),FGIBAL NUMERIC(10,2),FGIUPDATE NUMERIC(10,2),WIPUPDATE NUMERIC(10,2),TOTMATL NUMERIC(13,5),TOTLABOR NUMERIC(13,5)              
--      ,TOTMISC NUMERIC(13,5),NETMATLCHG NUMERIC(13,5),EXPDATE SMALLDATETIME,TOTRWKMATL NUMERIC(10,2),TOTRWKLAB NUMERIC(10,2),TOTRWKMISC NUMERIC(13,5),RWKMATLEA NUMERIC(13,5)              
--      ,RWKMATLQTY NUMERIC(10,2),RWKLABEA NUMERIC(13,5),RWKLABQTY NUMERIC(10,2),TOTRWKCOST NUMERIC(10,2),CHGSTDCOST bit,NEWSTDCOST NUMERIC(13,5),CHGLBCOST bit              
--      ,NEWLBCOST NUMERIC(13,5),CHGPRODNO bit,NEWPRODNO char(25),CHGREV bit,NEWREV char(8),CHGDESCR bit,NEWDESCR char(45),CHGSERNO bit,NEWSERNO bit,COPYPHANT bit              
--      ,COPYABC bit,COPYORDPOL bit,COPYLEADTM bit,COPYNOTE bit,COPYSPEC bit,COPYWKCTRS bit,COPYWOLIST bit,COPYTOOL bit,COPYOUTS bit,COPYDOCS bit,COPYINST bit              
--      ,COPYCKLIST bit,COPYSSNO bit,ENGINEER char(18),COPYBMNOTE bit,COPYEFFDTS bit,COPYREFDES bit,COPYALTPTS bit,OPENDATE SMALLDATETIME,UPDATEDDT SMALLDATETIME              
--      ,ECOREF char(15),CHGCUST bit,NEWCUSTNO char(10),TOTRWKWCST NUMERIC(10,2),TOTRWKFCST NUMERIC(10,2),NEWMATLCST NUMERIC(13,5),BOM_NOTE text,ECOFILE char(200)              
--      ,ECOSOURCE char(10),EFFECTIVEDT SMALLDATETIME,ECOLOCK bit,ECOLOCKINT char(8),ECOLOCKDT SMALLDATETIME,SAVEDT SMALLDATETIME,SAVEINT char(8),ORIGINDOC char(200)              
--      ,UPDSOPRICE bit,ECOITEMARC bit,COPYOTHPRC bit,lCopySupplier bit,lUpdateMPN bit,Prod_no char(25),Prod_Rev char(8),Prod_Descript char(45),Prod_class char(8)              
--      ,Prod_Type char(8),Matl_Cost NUMERIC(13,5),LaborCost NUMERIC(13,5),CustName char(35),NewCustName char(35),TotalCosts NUMERIC(13,5),Dept char(25),Init char(8)              
--      ,AprvDate SMALLDATETIME,uniqecdet char(10),Item_no NUMERIC(4,0),uniq_key char(10),Part_no char(25),RevisiON char(8),Descript char(45),Part_class char(8)              
--      ,Part_type char(8),Part_Sourc char(10),CustPartno char(25),CustRev char(8),DetStatus char(10),OldQty NUMERIC(9,2),NewQty NUMERIC(9,2),ToolDesc text              
--      ,CostAmt NUMERIC(13,5),ChargeAmt NUMERIC(13,5),NreEffectDt SMALLDATETIME,NreTerminatDt SMALLDATETIME,SoNo char(10),Line_no char(7),SoBalance NUMERIC(9,2)              
--      ,WoNo char(10),WoBalance NUMERIC(9,2),MiscDesc char(60),MiscCost NUMERIC(13,5),MiscType char(3))               
              
--06/13/18 YS got an error Column name or number of supplied values does not match table definition. when inserting into @eco              
--- will use temp table to avoid the error.              
IF OBJECT_ID('tempdb..#tempEco') is not NULL              
DROP TABLE #tempEco              
              
declare @lcUniqEcNo AS char(10) = ''              
SELECT @lcUniqEcNo = ecmain.Uniqecno FROM ECMAIN  WHERE @lcEcoNo = ecmain.econo              
              
--********************  --&&&BEGIN HEADER INFO              
  --this will gather the eco header informatiON FROM the ECMAIN table AND also the Approvals              
  -- 09/17/19 Vijay G Modified the code AS per current requirement                        
 ;with Zeco AS (               
  --SELECT ecmain.*,  
  SELECT UNIQECNO, ECONO, ecmain.BOMCUSTNO, ecmain.UNIQ_KEY, CHANGETYPE, ECSTATUS, PURPOSE, ECDESCRIPT, OUNITCOST, NUNITCOST, 
  FGIBAL, FGIUPDATE, WIPUPDATE, TOTMATL, TOTLABOR, TOTMISC, NETMATLCHG, EXPDATE, TOTRWKMATL, TOTRWKLAB, TOTRWKMISC, RWKMATLEA, 
  RWKMATLQTY, RWKLABEA, RWKLABQTY, TOTRWKCOST, CHGSTDCOST, NEWSTDCOST, CHGLBCOST, NEWLBCOST, CHGPRODNO, NEWPRODNO, CHGREV, NEWREV,
  CHGDESCR, NEWDESCR ,CHGSERNO ,NEWSERNO, COPYPHANT, COPYABC, COPYORDPOL, COPYLEADTM ,COPYNOTE, COPYSPEC, COPYWKCTRS, COPYWOLIST, 
  COPYTOOL,COPYOUTS, COPYDOCS, COPYINST, COPYCKLIST, COPYSSNO, COPYBMNOTE, COPYEFFDTS, COPYREFDES, COPYALTPTS, OPENDATE, UPDATEDDT, 
  ECOREF, CHGCUST, NEWCUSTNO, TOTRWKWCST, TOTRWKFCST, NEWMATLCST, ecmain.BOM_NOTE, ECOFILE, ECOSOURCE, EFFECTIVEDT, ECOLOCK, ECOLOCKINT,
  ECOLOCKDT, SAVEDT, SAVEINT ,ORIGINDOC, UPDSOPRICE, ECOITEMARC, COPYOTHPRC, lCopySupplier, lUpdateMPN,
  NEWSTDCOSTPR, OUNITCOSTPR, 
  NUNITCOSTPR, TOTMATLPR,TOTLABORPR, TOTMISCPR, NETMATLCHGPR, TOTRWKMATLPR, TOTRWKLABPR, TOTRWKMISCPR, RWKMATLEAPR, RWKLABEAPR, 
  TOTRWKCOSTPR, NEWLBCOSTPR, TOTRWKWCSTPR,TOTRWKFCSTPR, NEWMATLCSTPR, ecmain.PRFCUSED_UNIQ, ecmain.FUNCFCUSED_UNIQ, Uniquerout, NewBOMCUSTNO,         
  aspnet_Users.UserName AS ENGINEER,aspBuyerReadyForApproval, IsApproveProcess,part_no,revision,Descript,Part_class,Part_type,Matl_cost,            
  LaborCost,ISNULL(customer.custname, 'None') AS CustName,
  CASE WHEN newcustno = '' AND ecmain.bomcustno = '' THEN 'None' ELSE CASE WHEN newcustno = '' AND ecmain.bomcustno <> '' THEN c3.custname ELSE C2.CUSTNAME END END  AS NEWCUSTNAME              
    ,netmatlchg+totlabor AS TotalCosts              
    FROM ECMAIN              
    INNER JOIN inventor ON ecmain.uniq_key = inventor.uniq_key          
    INNER JOIN aspnet_Users ON ecmain.ENGINEER = aspnet_Users.UserId              
    LEFT OUTER JOIN  customer ON inventor.bomcustno = customer.custno              
    LEFT OUTER JOIN  customer C2 ON ecmain.newcustno = c2.custno              
    LEFT OUTER JOIN  customer c3 ON ecmain.bomcustno = c3.custno                
     WHERE @lcEcoNo = ecmain.econo              
  )              
              
  --06/13/18 YS got an error Column name or number of supplied values does not match table definition. when inserting into @eco              
--- will use temp table to avoid the error.                 
  ---Insert into @ECO   
-- 09/17/19 Vijay G Modified the code AS per current requirement               
   SELECT CAST('1_Header' AS CHAR(10)) AS TYPE,            
   --z1.*,            
    z1.UNIQECNO, z1.ECONO, z1.BOMCUSTNO, z1.UNIQ_KEY, z1.CHANGETYPE, z1.ECSTATUS, z1.PURPOSE, z1.ECDESCRIPT, z1.OUNITCOST, z1.NUNITCOST,            
   z1.FGIBAL, z1.FGIUPDATE, z1.WIPUPDATE, z1.TOTMATL, z1.TOTLABOR, z1.TOTMISC, z1.NETMATLCHG, z1.EXPDATE, z1.TOTRWKMATL, z1.TOTRWKLAB, z1.TOTRWKMISC,             
   z1.RWKMATLEA, z1.RWKMATLQTY, z1.RWKLABEA, z1.RWKLABQTY, z1.TOTRWKCOST, z1.CHGSTDCOST, z1.NEWSTDCOST, z1.CHGLBCOST, z1.NEWLBCOST, z1.CHGPRODNO,            
    z1.NEWPRODNO, z1.CHGREV, z1.NEWREV ,z1.CHGDESCR, z1.NEWDESCR ,z1.CHGSERNO ,z1.NEWSERNO, z1.COPYPHANT, z1.COPYABC, z1.COPYORDPOL, z1.COPYLEADTM,
	z1.COPYNOTE, z1.COPYSPEC, z1.COPYWKCTRS, z1.COPYWOLIST, z1.COPYTOOL, z1.COPYOUTS, z1.COPYDOCS, z1.COPYINST, z1.COPYCKLIST, z1.COPYSSNO,             
 z1.COPYBMNOTE, z1.COPYEFFDTS, z1.COPYREFDES, z1.COPYALTPTS, z1.OPENDATE, z1.UPDATEDDT, z1.ECOREF, z1.CHGCUST, z1.NEWCUSTNO, z1.TOTRWKWCST,             
 z1.TOTRWKFCST, z1.NEWMATLCST, z1.BOM_NOTE, z1.ECOFILE, z1.ECOSOURCE, z1.EFFECTIVEDT, z1.ECOLOCK, z1.ECOLOCKINT,z1.ECOLOCKDT, z1.SAVEDT, 
 z1.SAVEINT ,z1.ORIGINDOC, z1.UPDSOPRICE, z1.ECOITEMARC, z1.COPYOTHPRC, z1.lCopySupplier, z1.lUpdateMPN,
 -- 09/18/20 VL found product number information was missing
 Part_no AS Prod_no, Revision AS Prod_rev, Descript AS Prod_descript, Part_class AS Prod_class, Part_type AS Prod_type
 , z1.NEWSTDCOSTPR, z1.OUNITCOSTPR, 
 z1.NUNITCOSTPR, z1.TOTMATLPR,z1.TOTLABORPR, z1.TOTMISCPR, z1.NETMATLCHGPR, z1.TOTRWKMATLPR, z1.TOTRWKLABPR, z1.TOTRWKMISCPR, z1.RWKMATLEAPR, 
 z1.RWKLABEAPR, z1.TOTRWKCOSTPR, z1.NEWLBCOSTPR, z1.TOTRWKWCSTPR,z1.TOTRWKFCSTPR, z1.NEWMATLCSTPR, z1.PRFCUSED_UNIQ, z1.FUNCFCUSED_UNIQ, z1.Uniquerout, 
 z1.NewBOMCUSTNO,z1.ENGINEER, aspBuyerReadyForApproval, IsApproveProcess            
   ,CAST('' AS CHAR(50)) AS Dept            
   ,CAST('' AS CHAR(8))AS [init]            
   ,CAST('' AS SMALLDATETIME) AS AprvDate              
   ,CAST('' AS CHAR(10))AS uniqecdet            
   ,CAST(NULL AS NUMERIC(4,0))AS Item_no--,CAST('' AS CHAR(10))AS uniq_key            
  ,CAST('' AS CHAR(25)) AS Part_no,CAST('' AS CHAR(8)) AS Revision,CAST('' AS CHAR(45)) AS Descript              
   ,CAST('' AS CHAR(8)) AS Part_class,CAST('' AS CHAR(8)) AS Part_type              
   ,CAST('' AS CHAR(10)) AS Part_Sourc,Matl_cost            
   ,LaborCost            
   ,ISNULL(custname, 'None') AS CustName              
      ,CASE WHEN z1.newcustno = '' AND z1.bomcustno = '' THEN 'None' ELSE               
       CASE WHEN z1.newcustno = '' AND z1.bomcustno <> '' THEN custname              
        ELSE custname END END  AS NewCustName              
      ,z1.netmatlchg+z1.totlabor AS TotalCosts            
          
  ,CAST('' AS CHAR(25)) AS CustPartNo            
  ,CAST('' AS CHAR(8)) AS CustRev            
  ,CAST('' AS CHAR(10)) AS DetStatus              
     ,CAST(0.00 AS NUMERIC(9,2)) AS OldQty            
  ,CAST (0.00 AS NUMERIC(9,2)) AS NewQty            
  ,CAST('' AS text) AS ToolDesc            
  ,CAST (0.00 AS NUMERIC(13,5)) AS CostAmt              
     ,CAST (0.00 AS NUMERIC(13,5)) AS ChargeAmt            
  ,CAST(NULL AS SMALLDATETIME) AS NreEffectDt            
  ,CAST (NULL AS SMALLDATETIME) AS NreTerminatDt            
  ,CAST('' AS CHAR(10)) AS SoNo              
     ,CAST('' AS CHAR(7)) AS Line_no            
  ,CAST (0.00 AS NUMERIC(9,2)) AS SoBalance            
  ,CAST('' AS CHAR(10)) AS WoNo            
  ,CAST(0.00 AS NUMERIC(9,2)) AS WoBalance              
     ,CAST('' AS CHAR(60)) AS MiscDesc            
  ,CAST (0.00 AS NUMERIC(13,5)) AS MiscCost            
  ,CAST('' AS CHAR(3)) AS MiscType              
   INTO #tempEco              
   FROM Zeco Z1 ;            
          
          
          
 ;     
-- 09/17/19 Vijay G Modified the code AS per current requirement            
  WITH ZApprov as(              
  --SELECT ecmain.*     
  SELECT ecmain.UNIQECNO, ECONO, ecmain.BOMCUSTNO, ecmain.UNIQ_KEY, CHANGETYPE, ECSTATUS, PURPOSE, ECDESCRIPT, OUNITCOST, NUNITCOST, FGIBAL, FGIUPDATE,             
	WIPUPDATE, TOTMATL, TOTLABOR, TOTMISC, NETMATLCHG, EXPDATE, TOTRWKMATL, TOTRWKLAB, TOTRWKMISC, RWKMATLEA, RWKMATLQTY, RWKLABEA, RWKLABQTY,            
	TOTRWKCOST, CHGSTDCOST, NEWSTDCOST, CHGLBCOST, NEWLBCOST, CHGPRODNO, NEWPRODNO, CHGREV, NEWREV ,CHGDESCR, NEWDESCR ,CHGSERNO ,NEWSERNO,             
	COPYPHANT, COPYABC, COPYORDPOL, COPYLEADTM ,COPYNOTE, COPYSPEC, COPYWKCTRS, COPYWOLIST, COPYTOOL, COPYOUTS, COPYDOCS, COPYINST,             
	COPYCKLIST, COPYSSNO, COPYBMNOTE, COPYEFFDTS, COPYREFDES, COPYALTPTS, OPENDATE, UPDATEDDT, ECOREF, CHGCUST, NEWCUSTNO, TOTRWKWCST,            
	TOTRWKFCST, NEWMATLCST, ecmain.BOM_NOTE, ECOFILE, ECOSOURCE, EFFECTIVEDT, ECOLOCK, ECOLOCKINT,ECOLOCKDT, SAVEDT, SAVEINT ,ORIGINDOC,
	UPDSOPRICE, ECOITEMARC, COPYOTHPRC, lCopySupplier, lUpdateMPN, NEWSTDCOSTPR, OUNITCOSTPR, NUNITCOSTPR, TOTMATLPR,             
	TOTLABORPR, TOTMISCPR, NETMATLCHGPR, TOTRWKMATLPR, TOTRWKLABPR, TOTRWKMISCPR, RWKMATLEAPR, RWKLABEAPR, TOTRWKCOSTPR, NEWLBCOSTPR, TOTRWKWCSTPR,             
	TOTRWKFCSTPR, NEWMATLCSTPR, ecmain.PRFCUSED_UNIQ, ecmain.FUNCFCUSED_UNIQ, Uniquerout, NewBOMCUSTNO, ENGINEER, aspBuyerReadyForApproval, IsApproveProcess,
	Dept, INIT, DATE               
    FROM ECMAIN,EcApprov               
    WHERE ECMAIN.UNIQECNO = ECAPPROV.UNIQECNO              
    AND ecapprov.UniqEcNo = @lcUniqEcNo              
  )              
    --06/13/18 YS got an error Column name or number of supplied values does not match table definition. when inserting into @eco              
--- will use temp table to avoid the error.                
  --insert into @eco  (Type,UNIQECNO,ECONO,BOMCUSTNO,PROD_UNIQ_KEY,CHANGETYPE,ECSTATUS,PURPOSE,ECDESCRIPT,OUNITCOST,NUNITCOST,FGIBAL,FGIUPDATE,WIPUPDATE,TOTMATL,TOTLABOR,TOTMISC              
  --   ,NETMATLCHG,EXPDATE,TOTRWKMATL,TOTRWKLAB,TOTRWKMISC,RWKMATLEA,RWKMATLQTY,RWKLABEA,RWKLABQTY,TOTRWKCOST,CHGSTDCOST,NEWSTDCOST,CHGLBCOST              
  --   ,NEWLBCOST,CHGPRODNO,NEWPRODNO,CHGREV,NEWREV,CHGDESCR,NEWDESCR,CHGSERNO,NEWSERNO,COPYPHANT,COPYABC,COPYORDPOL,COPYLEADTM,COPYNOTE,COPYSPEC,COPYWKCTRS              
  --   ,COPYWOLIST,COPYTOOL,COPYOUTS,COPYDOCS,COPYINST,COPYCKLIST,COPYSSNO,ENGINEER,COPYBMNOTE,COPYEFFDTS,COPYREFDES,COPYALTPTS,OPENDATE,UPDATEDDT              
  --   ,ECOREF,CHGCUST,NEWCUSTNO,TOTRWKWCST,TOTRWKFCST,NEWMATLCST,BOM_NOTE,ECOFILE,ECOSOURCE,EFFECTIVEDT,ECOLOCK,ECOLOCKINT,ECOLOCKDT,SAVEDT,SAVEINt,ORIGINDOC              
  --   ,UPDSOPRICE,ECOITEMARC,COPYOTHPRC,lCopySupplier,lUpdateMPN,Prod_no,Prod_Rev,Prod_Descript,Prod_class,Prod_Type,Matl_Cost,LaborCost,CustName,NewCustName              
  --   ,TotalCosts,Dept,Init,AprvDate,UniqEcDet,Item_no,uniq_key,Part_no,Revision,Descript,Part_class,Part_type,Part_Sourc,CustPartNo,CustRev,detstatus,oldqty,newqty              
  --   ,ToolDesc,CostAmt,ChargeAmt,NreEffectDt,NreTerminatDt,SoNo,Line_no,SoBalance,WoNo,WoBalance,MiscDesc,MiscCost,MiscType)               
   INSERT INTO #tempEco    
-- 09/17/19 Vijay G Modified the code AS per current requirement          
  --SELECT CAST('2_APPRV' AS CHAR(10)) AS TYPE,                    
  --e2.UNIQECNO,e2.ECONO,e2.BOMCUSTNO,e2.UNIQ_KEY,e2.CHANGETYPE,e2.ECSTATUS,e2.PURPOSE,e2.ECDESCRIPT,e2.OUNITCOST,e2.NUNITCOST              
  --    ,e2.FGIBAL,e2.FGIUPDATE,e2.WIPUPDATE,e2.TOTMATL,e2.TOTLABOR,e2.TOTMISC,e2.NETMATLCHG,e2.EXPDATE,e2.TOTRWKMATL,e2.TOTRWKLAB,e2.TOTRWKMISC,e2.RWKMATLEA              
  --    ,e2.RWKMATLQTY,e2.RWKLABEA,e2.RWKLABQTY,e2.TOTRWKCOST,e2.CHGSTDCOST,e2.NEWSTDCOST,e2.CHGLBCOST,e2.NEWLBCOST,e2.CHGPRODNO,e2.NEWPRODNO,e2.CHGREV,e2.NEWREV              
  --    ,e2.CHGDESCR,e2.NEWDESCR,e2.CHGSERNO,e2.NEWSERNO,e2.COPYPHANT,e2.COPYABC,e2.COPYORDPOL,e2.COPYLEADTM,e2.COPYNOTE,e2.COPYSPEC,e2.COPYWKCTRS,e2.COPYWOLIST              
  --    ,e2.COPYTOOL,e2.COPYOUTS,e2.COPYDOCS,e2.COPYINST,e2.COPYCKLIST,e2.COPYSSNO,e2.ENGINEER,e2.COPYBMNOTE,e2.COPYEFFDTS,e2.COPYREFDES,e2.COPYALTPTS,e2.OPENDATE              
  --    ,e2.UPDATEDDT,e2.ECOREF,e2.CHGCUST,e2.NEWCUSTNO,e2.TOTRWKWCST,e2.TOTRWKFCST,e2.NEWMATLCST,e2.BOM_NOTE,e2.ECOFILE,e2.ECOSOURCE,e2.EFFECTIVEDT,e2.ECOLOCK              
  --    ,e2.ECOLOCKINT,e2.ECOLOCKDT,e2.SAVEDT,e2.SAVEINt,e2.ORIGINDOC,e2.UPDSOPRICE,e2.ECOITEMARC,e2.COPYOTHPRC,e2.lCopySupplier,e2.lUpdateMPN            
   SELECT CAST('2_APPRV' AS CHAR(10)) AS TYPE,z1.UNIQECNO, z1.ECONO, z1.BOMCUSTNO, z1.UNIQ_KEY, z1.CHANGETYPE, z1.ECSTATUS, z1.PURPOSE,
    z1.ECDESCRIPT, z1.OUNITCOST, z1.NUNITCOST,z1.FGIBAL, z1.FGIUPDATE, z1.WIPUPDATE, z1.TOTMATL, z1.TOTLABOR, z1.TOTMISC, z1.NETMATLCHG, 
	z1.EXPDATE, z1.TOTRWKMATL, z1.TOTRWKLAB, z1.TOTRWKMISC,z1.RWKMATLEA, z1.RWKMATLQTY, z1.RWKLABEA, z1.RWKLABQTY, z1.TOTRWKCOST, 
	z1.CHGSTDCOST, z1.NEWSTDCOST, z1.CHGLBCOST, z1.NEWLBCOST, z1.CHGPRODNO,z1.NEWPRODNO, z1.CHGREV, z1.NEWREV ,z1.CHGDESCR, z1.NEWDESCR,
	z1.CHGSERNO ,z1.NEWSERNO, z1.COPYPHANT, z1.COPYABC, z1.COPYORDPOL, z1.COPYLEADTM,z1.COPYNOTE, z1.COPYSPEC, z1.COPYWKCTRS, z1.COPYWOLIST,
	z1.COPYTOOL, z1.COPYOUTS, z1.COPYDOCS, z1.COPYINST, z1.COPYCKLIST, z1.COPYSSNO,z1.COPYBMNOTE, z1.COPYEFFDTS, z1.COPYREFDES, z1.COPYALTPTS,
	z1.OPENDATE, z1.UPDATEDDT, z1.ECOREF, z1.CHGCUST, z1.NEWCUSTNO, z1.TOTRWKWCST,z1.TOTRWKFCST, z1.NEWMATLCST, z1.BOM_NOTE, z1.ECOFILE,
	z1.ECOSOURCE, z1.EFFECTIVEDT, z1.ECOLOCK, z1.ECOLOCKINT,z1.ECOLOCKDT, z1.SAVEDT, z1.SAVEINT ,z1.ORIGINDOC, z1.UPDSOPRICE, z1.ECOITEMARC,
	z1.COPYOTHPRC, z1.lCopySupplier, z1.lUpdateMPN, 
	-- 09/18/20 VL found product number information was missing
	Inventor.Part_no AS Prod_no, Inventor.Revision AS Prod_rev, Inventor.Descript AS Prod_descript, Inventor.Part_class AS Prod_class, Inventor.Part_type AS Prod_type,
	z1.NEWSTDCOSTPR, z1.OUNITCOSTPR, z1.NUNITCOSTPR, z1.TOTMATLPR,z1.TOTLABORPR, z1.TOTMISCPR,
	z1.NETMATLCHGPR, z1.TOTRWKMATLPR, z1.TOTRWKLABPR, z1.TOTRWKMISCPR, z1.RWKMATLEAPR, z1.RWKLABEAPR, z1.TOTRWKCOSTPR, z1.NEWLBCOSTPR, 
	z1.TOTRWKWCSTPR,z1.TOTRWKFCSTPR, z1.NEWMATLCSTPR, z1.PRFCUSED_UNIQ, z1.FUNCFCUSED_UNIQ, z1.Uniquerout, z1.NewBOMCUSTNO, a.UserName AS ENGINEER,
	z1.aspBuyerReadyForApproval, z1.IsApproveProcess,zapprov.Dept,zapprov.[init],zapprov.[date] AS AprvDate,CAST('' AS CHAR(10)) AS uniqecdet,
	CAST (0 AS NUMERIC(4,0)) AS Item_no,
	-- 09/18/20 VL changed the component part number should be empty here, inventor saves product number info
	--inventor.part_no,inventor.revision,inventor.Descript,inventor.Part_class,inventor.Part_type,
	CAST('' as char(25)) AS Part_no, CAST('' as char(8)) AS Revision,CAST('' as char(45)) as Descript, CAST('' as char(8)) as Part_class, CAST('' as char(8)) as Part_type,
	CAST('' AS CHAR(10)) AS Part_Sourc,inventor.Matl_cost,inventor.LaborCost,ISNULL(customer.custname, 'None') AS CustName,
	CASE WHEN z1.newcustno = '' AND z1.bomcustno = '' THEN 'None' ELSE CASE WHEN z1.newcustno = '' AND z1.bomcustno <> '' THEN c3.custname ELSE c2.custname END END AS NewCustName,
	z1.netmatlchg+z1.totlabor AS TotalCosts,CAST('' AS CHAR(25)) AS CustPartNo,CAST('' AS CHAR(8)) AS CustRev,CAST('' AS CHAR(10)) AS detstatus,
	CAST(0.00 AS NUMERIC(9,2)) AS oldqty,CAST(0.00 AS NUMERIC(9,2)) AS newqty,CAST('' AS text) AS ToolDesc,CAST (0.00 AS NUMERIC(13,5)) AS CostAmt,
	CAST (0.00 AS NUMERIC(13,5)) AS ChargeAmt,CAST(NULL AS SMALLDATETIME) AS NreEffectDt,CAST (NULL AS SMALLDATETIME) AS NreTerminatDt,
	CAST('' AS CHAR(10)) AS SoNo,CAST('' AS CHAR(7)) AS Line_no,CAST (0.00 AS NUMERIC(9,2)) AS SoBalance,CAST('' AS CHAR(10)) AS WoNo,
	CAST(0.00 AS NUMERIC(9,2)) AS WoBalance,CAST('' AS CHAR(60)) AS MiscDesc,CAST (0.00 AS NUMERIC(13,5)) AS MiscCost,CAST('' AS CHAR(3)) AS MiscType                              
  FROM ecmain z1               
    INNER JOIN aspnet_Users a ON z1.ENGINEER = a.UserId              
    INNER JOIN zapprov zapprov ON z1.uniqecno = zapprov.uniqecno              
    INNER JOIN inventor ON z1.uniq_key = inventor.uniq_key              
    LEFT OUTER JOIN  customer ON inventor.bomcustno = customer.custno              
    LEFT OUTER JOIN  customer C2 ON z1.newcustno = c2.custno              
    LEFT OUTER JOIN  customer c3 ON z1.bomcustno = c3.custno            
           
             
--&&&END APPROVAL DETAIL              
--********************              
--********************                 
--&&&BEGIN ECO CHANGE COMPONENT INFO       
-- 09/17/19 Vijay G Modified the code AS per current requirement          
 ;with ZEcDtl AS (              
  --SELECT --ecmain.*,                   
 SELECT ecmain.UNIQECNO, ECONO, ecmain.BOMCUSTNO, ecmain.UNIQ_KEY, CHANGETYPE, ECSTATUS, PURPOSE, ECDESCRIPT, OUNITCOST, NUNITCOST, FGIBAL, FGIUPDATE,             
	WIPUPDATE, TOTMATL, TOTLABOR, TOTMISC, NETMATLCHG, EXPDATE, TOTRWKMATL, TOTRWKLAB, TOTRWKMISC, RWKMATLEA, RWKMATLQTY, RWKLABEA, RWKLABQTY,            
	TOTRWKCOST, CHGSTDCOST, NEWSTDCOST, CHGLBCOST, NEWLBCOST, CHGPRODNO, NEWPRODNO, CHGREV, NEWREV ,CHGDESCR, NEWDESCR ,CHGSERNO ,NEWSERNO,             
	COPYPHANT, COPYABC, COPYORDPOL, COPYLEADTM ,COPYNOTE, COPYSPEC, COPYWKCTRS, COPYWOLIST, COPYTOOL, COPYOUTS, COPYDOCS, COPYINST,             
	COPYCKLIST, COPYSSNO, COPYBMNOTE, COPYEFFDTS, COPYREFDES, COPYALTPTS, OPENDATE, UPDATEDDT, ECOREF, CHGCUST, NEWCUSTNO, TOTRWKWCST,            
	TOTRWKFCST, NEWMATLCST, ecmain.BOM_NOTE, ECOFILE, ECOSOURCE, EFFECTIVEDT, ECOLOCK, ECOLOCKINT,            
	ECOLOCKDT, SAVEDT, SAVEINT ,ORIGINDOC, UPDSOPRICE, ECOITEMARC, COPYOTHPRC, lCopySupplier, lUpdateMPN, NEWSTDCOSTPR, OUNITCOSTPR, NUNITCOSTPR, TOTMATLPR,             
	TOTLABORPR, TOTMISCPR, NETMATLCHGPR, TOTRWKMATLPR, TOTRWKLABPR, TOTRWKMISCPR, RWKMATLEAPR, RWKLABEAPR, TOTRWKCOSTPR, NEWLBCOSTPR, TOTRWKWCSTPR,             
	TOTRWKFCSTPR, NEWMATLCSTPR, ecmain.PRFCUSED_UNIQ, ecmain.FUNCFCUSED_UNIQ, Uniquerout, NewBOMCUSTNO, ENGINEER, aspBuyerReadyForApproval, IsApproveProcess,             
	uniqecdet,ecdetl.uniq_key AS CompUniq_key,Part_no, Revision, LEFT(Descript,32) AS Descript, Part_Class, Part_Type,LEFT(Part_Sourc,6) AS Part_Sourc,
	CustPartNo, CustRev,DetStatus, Item_no, OldQty, NewQty               
 FROM ecmain,EcDetl,Inventor              
 WHERE ecmain.uniqecno = ecdetl.uniqecno AND EcDetl.Uniq_key = Inventor.Uniq_key AND ecdetl.UniqEcNo = @lcUniqEcNo              
    )              
              
    --06/13/18 YS got an error Column name or number of supplied values does not match table definition. when inserting into @eco              
--- will use temp table to avoid the error.              
  --insert into @eco  (Type,UNIQECNO,ECONO,BOMCUSTNO,PROD_UNIQ_KEY,CHANGETYPE,ECSTATUS,PURPOSE,ECDESCRIPT,OUNITCOST,NUNITCOST,FGIBAL,FGIUPDATE,WIPUPDATE,TOTMATL,TOTLABOR,TOTMISC              
  --     ,NETMATLCHG,EXPDATE,TOTRWKMATL,TOTRWKLAB,TOTRWKMISC,RWKMATLEA,RWKMATLQTY,RWKLABEA,RWKLABQTY,TOTRWKCOST,CHGSTDCOST,NEWSTDCOST,CHGLBCOST              
  --     ,NEWLBCOST,CHGPRODNO,NEWPRODNO,CHGREV,NEWREV,CHGDESCR,NEWDESCR,CHGSERNO,NEWSERNO,COPYPHANT,COPYABC,COPYORDPOL,COPYLEADTM,COPYNOTE,COPYSPEC,COPYWKCTRS              
  --     ,COPYWOLIST,COPYTOOL,COPYOUTS,COPYDOCS,COPYINST,COPYCKLIST,COPYSSNO,ENGINEER,COPYBMNOTE,COPYEFFDTS,COPYREFDES,COPYALTPTS,OPENDATE,UPDATEDDT              
  --     ,ECOREF,CHGCUST,NEWCUSTNO,TOTRWKWCST,TOTRWKFCST,NEWMATLCST,BOM_NOTE,ECOFILE,ECOSOURCE,EFFECTIVEDT,ECOLOCK,ECOLOCKINT,ECOLOCKDT,SAVEDT,SAVEINt,ORIGINDOC              
  --     ,UPDSOPRICE,ECOITEMARC,COPYOTHPRC,lCopySupplier,lUpdateMPN,Prod_no,Prod_Rev,Prod_Descript,Prod_class,Prod_Type,Matl_Cost,LaborCost,CustName,NewCustName              
  --     ,TotalCosts,Dept,Init,AprvDate,UniqEcDet,Item_no,uniq_key,Part_no,Revision,Descript,Part_class,Part_type,Part_Sourc,CustPartNo,CustRev,detstatus,oldqty,newqty              
  --     ,ToolDesc,CostAmt,ChargeAmt,NreEffectDt,NreTerminatDt,SoNo,Line_no,SoBalance,WoNo,WoBalance,MiscDesc,MiscCost,MiscType)               
  -- 09/17/19 Vijay G Modified the code AS per current requirement   
		 
		 --INSERT INTO #tempEco     
   -- SELECT  CAST('3_Detail' AS char(10))AS type,                    
	--e2.UNIQECNO,e2.ECONO,e2.BOMCUSTNO,e2.UNIQ_KEY,e2.CHANGETYPE,e2.ECSTATUS,e2.PURPOSE,e2.ECDESCRIPT,e2.OUNITCOST,e2.NUNITCOST              
	--     ,e2.FGIBAL,e2.FGIUPDATE,e2.WIPUPDATE,e2.TOTMATL,e2.TOTLABOR,e2.TOTMISC,e2.NETMATLCHG,e2.EXPDATE,e2.TOTRWKMATL,e2.TOTRWKLAB,e2.TOTRWKMISC,e2.RWKMATLEA              
	--     ,e2.RWKMATLQTY,e2.RWKLABEA,e2.RWKLABQTY,e2.TOTRWKCOST,e2.CHGSTDCOST,e2.NEWSTDCOST,e2.CHGLBCOST,e2.NEWLBCOST,e2.CHGPRODNO,e2.NEWPRODNO,e2.CHGREV,e2.NEWREV              
	--     ,e2.CHGDESCR,e2.NEWDESCR,e2.CHGSERNO,e2.NEWSERNO,e2.COPYPHANT,e2.COPYABC,e2.COPYORDPOL,e2.COPYLEADTM,e2.COPYNOTE,e2.COPYSPEC,e2.COPYWKCTRS,e2.COPYWOLIST              
	--     ,e2.COPYTOOL,e2.COPYOUTS,e2.COPYDOCS,e2.COPYINST,e2.COPYCKLIST,e2.COPYSSNO,e2.ENGINEER,e2.COPYBMNOTE,e2.COPYEFFDTS,e2.COPYREFDES,e2.COPYALTPTS,e2.OPENDATE     
	--     ,e2.UPDATEDDT,e2.ECOREF,e2.CHGCUST,e2.NEWCUSTNO,e2.TOTRWKWCST,e2.TOTRWKFCST,e2.NEWMATLCST,e2.BOM_NOTE,e2.ECOFILE,e2.ECOSOURCE,e2.EFFECTIVEDT,e2.ECOLOCK              
	--     ,e2.ECOLOCKINT,e2.ECOLOCKDT,e2.SAVEDT,e2.SAVEINt,e2.ORIGINDOC,e2.UPDSOPRICE,e2.ECOITEMARC,e2.COPYOTHPRC,e2.lCopySupplier,e2.lUpdateMPN            
               
   INSERT INTO #tempEco     
   SELECT  CAST('3_Detail' AS char(10))AS type,                 
    e3.UNIQECNO, e3.ECONO, e3.BOMCUSTNO, e3.UNIQ_KEY, e3.CHANGETYPE, e3.ECSTATUS, e3.PURPOSE, e3.ECDESCRIPT, e3.OUNITCOST, e3.NUNITCOST, e3.FGIBAL, e3.FGIUPDATE, e3.WIPUPDATE,            
	e3.TOTMATL, e3.TOTLABOR, e3.TOTMISC, e3.NETMATLCHG, e3.EXPDATE, e3.TOTRWKMATL, e3.TOTRWKLAB, e3.TOTRWKMISC, e3.RWKMATLEA, e3.RWKMATLQTY, e3.RWKLABEA, e3.RWKLABQTY, e3.TOTRWKCOST,             
	e3.CHGSTDCOST, e3.NEWSTDCOST, e3.CHGLBCOST, e3.NEWLBCOST, e3.CHGPRODNO, e3.NEWPRODNO, e3.CHGREV, e3.NEWREV ,e3.CHGDESCR, e3.NEWDESCR ,e3.CHGSERNO ,e3.NEWSERNO, e3.COPYPHANT, e3.COPYABC,             
	e3.COPYORDPOL, e3.COPYLEADTM ,e3.COPYNOTE, e3.COPYSPEC, e3.COPYWKCTRS, e3.COPYWOLIST, e3.COPYTOOL, e3.COPYOUTS, e3.COPYDOCS, e3.COPYINST, e3.COPYCKLIST, e3.COPYSSNO, e3.COPYBMNOTE,             
	e3.COPYEFFDTS, e3.COPYREFDES, e3.COPYALTPTS, e3.OPENDATE, e3.UPDATEDDT, e3.ECOREF, e3.CHGCUST, e3.NEWCUSTNO, e3.TOTRWKWCST, e3.TOTRWKFCST, e3.NEWMATLCST, e3.BOM_NOTE, e3.ECOFILE,             
	e3.ECOSOURCE, e3.EFFECTIVEDT, e3.ECOLOCK, e3.ECOLOCKINT, e3.ECOLOCKDT, e3.SAVEDT, e3.SAVEINT ,e3.ORIGINDOC, e3.UPDSOPRICE, e3.ECOITEMARC, e3.COPYOTHPRC, e3.lCopySupplier,             
	e3.lUpdateMPN, 
	-- 09/18/20 VL found product number information was missing
	Inventor.Part_no AS Prod_no, Inventor.Revision AS Prod_rev, Inventor.Descript AS Prod_descript, Inventor.Part_class AS Prod_class, Inventor.Part_type AS Prod_type,
	e3.NEWSTDCOSTPR, e3.OUNITCOSTPR, e3.NUNITCOSTPR, e3.TOTMATLPR, e3.TOTLABORPR, e3.TOTMISCPR, e3.NETMATLCHGPR, e3.TOTRWKMATLPR, e3.TOTRWKLABPR,            
	e3.TOTRWKMISCPR, e3.RWKMATLEAPR, e3.RWKLABEAPR, e3.TOTRWKCOSTPR, e3.NEWLBCOSTPR, e3.TOTRWKWCSTPR, e3.TOTRWKFCSTPR, e3.NEWMATLCSTPR, e3.PRFCUSED_UNIQ,             
	e3.FUNCFCUSED_UNIQ, e3.Uniquerout, e3.NewBOMCUSTNO, a.UserName AS ENGINEER, e3.aspBuyerReadyForApproval, e3.IsApproveProcess,CAST('' AS CHAR(50)) AS Dept,
	CAST('' AS CHAR(8))AS init,CAST('' AS SMALLDATETIME) AS AprvDate,zecdtl.uniqecdet,zecdtl.Item_no
	-- 09/18/20 VL changed from inventor to i2
	--,inventor.part_no,inventor.revisiON,inventor.Descript,inventor.Part_class,inventor.Part_type,inventor.Part_Sourc,
	,i2.part_no,i2.revisiON,i2.Descript,i2.Part_class,i2.Part_type,i2.Part_Sourc,
	inventor.Matl_cost,inventor.LaborCost,ISNULL(customer.custname, 'None') AS CustName,
	CASE WHEN e3.newcustno = '' AND e3.bomcustno = '' THEN 'None' ELSE CASE WHEN e3.newcustno = '' AND e3.bomcustno <> '' THEN c3.custname ELSE c2.custname END END  AS NewCustName,
	e3.netmatlchg+e3.totlabor AS TotalCosts,i2.CustPartNo,i2.CustRev,zecdtl.detstatus,zecdtl.oldqty,zecdtl.newqty,CAST('' AS text) AS ToolDesc,
	CAST (0.00 AS NUMERIC(13,5)) AS CostAmt,CAST (0.00 AS NUMERIC(13,5)) AS ChargeAmt,CAST(NULL AS SMALLDATETIME) AS NreEffectDt,
	CAST (NULL AS SMALLDATETIME) AS NreTerminatDt,CAST('' AS CHAR(10)) AS SoNo,CAST('' AS CHAR(7)) AS Line_no,CAST (0.00 AS NUMERIC(9,2)) AS SoBalance,
	CAST('' AS CHAR(10)) AS WoNo,CAST(0.00 AS NUMERIC(9,2)) AS WoBalance,CAST('' AS CHAR(60)) AS MiscDesc,CAST (0.00 AS NUMERIC(13,5)) AS MiscCost,
	CAST('' AS CHAR(3)) AS MiscType                    
   FROM ecmain e3 INNER JOIN zecdtl ON e3.uniqecno = zecdtl.uniqecno           
   INNER JOIN aspnet_Users a ON e3.ENGINEER = a.UserId              
   INNER JOIN inventor ON e3.uniq_key = inventor.uniq_key              
   INNER JOIN inventor i2 ON zecdtl.compuniq_key = i2.uniq_key              
   LEFT OUTER JOIN  customer ON inventor.bomcustno = customer.custno              
   LEFT OUTER JOIN  customer C2 ON e3.newcustno = c2.custno              
   LEFT OUTER JOIN  customer c3 ON e3.bomcustno = c3.custno               
--&&&END ECO CHANGE COMPONENT INFO              
--********************              
--********************              
--&&&BEGIN NRE INFO              
-- 07/17/18 YS tools AND fixtures moved FROM the support table    
-- 09/17/19 Vijay G Modified the code AS per current requirement             
   ;with ZTool AS (              
  --SELECT ecmain.*   
  SELECT ecmain.UNIQECNO, ECONO, ecmain.BOMCUSTNO, ecmain.UNIQ_KEY, CHANGETYPE, ECSTATUS, PURPOSE, ECDESCRIPT, OUNITCOST, NUNITCOST, FGIBAL, FGIUPDATE,             
	WIPUPDATE, TOTMATL, TOTLABOR, TOTMISC, NETMATLCHG, EXPDATE, TOTRWKMATL, TOTRWKLAB, TOTRWKMISC, RWKMATLEA, RWKMATLQTY, RWKLABEA, RWKLABQTY,            
	TOTRWKCOST, CHGSTDCOST, NEWSTDCOST, CHGLBCOST, NEWLBCOST, CHGPRODNO, NEWPRODNO, CHGREV, NEWREV ,CHGDESCR, NEWDESCR ,CHGSERNO ,NEWSERNO,             
	COPYPHANT, COPYABC, COPYORDPOL, COPYLEADTM ,COPYNOTE, COPYSPEC, COPYWKCTRS, COPYWOLIST, COPYTOOL, COPYOUTS, COPYDOCS, COPYINST,             
	COPYCKLIST, COPYSSNO, COPYBMNOTE, COPYEFFDTS, COPYREFDES, COPYALTPTS, OPENDATE, UPDATEDDT, ECOREF, CHGCUST, NEWCUSTNO, TOTRWKWCST,            
	TOTRWKFCST, NEWMATLCST, ecmain.BOM_NOTE, ECOFILE, ECOSOURCE, ecmain.EFFECTIVEDT, ECOLOCK, ECOLOCKINT,            
	ECOLOCKDT, SAVEDT, SAVEINT ,ORIGINDOC, UPDSOPRICE, ECOITEMARC, COPYOTHPRC, lCopySupplier, lUpdateMPN, NEWSTDCOSTPR, OUNITCOSTPR, NUNITCOSTPR, TOTMATLPR,             
	TOTLABORPR, TOTMISCPR, NETMATLCHGPR, TOTRWKMATLPR, TOTRWKLABPR, TOTRWKMISCPR, RWKMATLEAPR, RWKLABEAPR, TOTRWKCOSTPR, NEWLBCOSTPR, TOTRWKWCSTPR,             
	TOTRWKFCSTPR, NEWMATLCSTPR, ecmain.PRFCUSED_UNIQ, ecmain.FUNCFCUSED_UNIQ, Uniquerout, NewBOMCUSTNO, ENGINEER, aspBuyerReadyForApproval, IsApproveProcess,
	CAST('' AS CHAR(10)) AS uniqecdet, CAST('' AS CHAR(25)) AS Part_no,CAST('' AS CHAR(8)) AS RevisiON,CAST('' AS CHAR(45)) AS Descript,
	CAST('' AS CHAR(8)) AS Part_Class,CAST('' AS CHAR(8)) AS Part_Type,CAST('' AS CHAR(8)) AS Part_Sourc, CAST('' AS CHAR(25)) AS CustPartNo,
	CAST('' AS CHAR(8)) AS CustRev,CAST('' AS CHAR(10)) AS DetStatus,CAST(0 AS NUMERIC(4,0)) AS Item_no,CAST (0.00 AS NUMERIC(9,2))AS OldQty,
	CAST(0.00 AS NUMERIC(9,2)) AS NewQty,ToolsAndFixtures.DescriptiON AS ToolDesc,CostAmt,ChargeAmt,ecnre.EffectiveDt AS NreEffectDt,TerminatDt,
	CAST('' AS CHAR(10)) AS SoNo,CAST('' AS CHAR(7)) AS Line_no,CAST (0.00 AS NUMERIC(9,2)) AS SoBalance,CAST('' AS CHAR(10)) AS WoNo ,CAST(0.00 AS NUMERIC(9,2)) AS WoBalance ,
	CAST('' AS CHAR(60)) AS MiscDesc,CAST (0.00 AS NUMERIC(13,5)) AS MiscCost,CAST('' AS CHAR(3)) AS MiscType              
   FROM ecmain,EcNre,ToolsAndFixtures            
   WHERE ecmain.uniqecno = ecnre.uniqecno AND ToolsAndFixtures.ToolsAndFixtureId = EcNre.ToolsAndFixtureId AND ecnre.UniqEcNo = @lcUniqEcNo               
      )              
      --06/13/18 YS got an error Column name or number of supplied values does not match table definition. when inserting into @eco              
--- will use temp table to avoid the error.              
  --insert into @eco  (Type,UNIQECNO,ECONO,BOMCUSTNO,PROD_UNIQ_KEY,CHANGETYPE,ECSTATUS,PURPOSE,ECDESCRIPT,OUNITCOST,NUNITCOST,FGIBAL,FGIUPDATE,WIPUPDATE,TOTMATL,TOTLABOR,TOTMISC              
  --       ,NETMATLCHG,EXPDATE,TOTRWKMATL,TOTRWKLAB,TOTRWKMISC,RWKMATLEA,RWKMATLQTY,RWKLABEA,RWKLABQTY,TOTRWKCOST,CHGSTDCOST,NEWSTDCOST,CHGLBCOST              
  --       ,NEWLBCOST,CHGPRODNO,NEWPRODNO,CHGREV,NEWREV,CHGDESCR,NEWDESCR,CHGSERNO,NEWSERNO,COPYPHANT,COPYABC,COPYORDPOL,COPYLEADTM,COPYNOTE,COPYSPEC,COPYWKCTRS              
  --       ,COPYWOLIST,COPYTOOL,COPYOUTS,COPYDOCS,COPYINST,COPYCKLIST,COPYSSNO,ENGINEER,COPYBMNOTE,COPYEFFDTS,COPYREFDES,COPYALTPTS,OPENDATE,UPDATEDDT              
  --       ,ECOREF,CHGCUST,NEWCUSTNO,TOTRWKWCST,TOTRWKFCST,NEWMATLCST,BOM_NOTE,ECOFILE,ECOSOURCE,EFFECTIVEDT,ECOLOCK,ECOLOCKINT,ECOLOCKDT,SAVEDT,SAVEINt,ORIGINDOC              
  --       ,UPDSOPRICE,ECOITEMARC,COPYOTHPRC,lCopySupplier,lUpdateMPN,Prod_no,Prod_Rev,Prod_Descript,Prod_class,Prod_Type,Matl_Cost,LaborCost,CustName,NewCustName              
  --       ,TotalCosts,Dept,Init,AprvDate,UniqEcDet,Item_no,uniq_key,Part_no,Revision,Descript,Part_class,Part_type,Part_Sourc,CustPartNo,CustRev,detstatus,oldqty,newqty              
  --       ,ToolDesc,CostAmt,ChargeAmt,NreEffectDt,NreTerminatDt,SoNo,Line_no,SoBalance,WoNo,WoBalance,MiscDesc,MiscCost,MiscType)               
   -- 09/17/19 Vijay G Modified the code AS per current requirement                       
   --INSERT INTO #tempEco          
   --SELECT  CAST('4_NRE' AS CHAR(10)) AS TYPE,                   
  --e3.UNIQECNO,e3.ECONO,e3.BOMCUSTNO,e3.UNIQ_KEY,e3.CHANGETYPE,e3.ECSTATUS,e3.PURPOSE,e3.ECDESCRIPT,e3.OUNITCOST,e3.NUNITCOST,e3.FGIBAL              
  --     ,e3.FGIUPDATE,e3.WIPUPDATE,e3.TOTMATL,e3.TOTLABOR,e3.TOTMISC,e3.NETMATLCHG,e3.EXPDATE,e3.TOTRWKMATL,e3.TOTRWKLAB,e3.TOTRWKMISC,e3.RWKMATLEA,e3.RWKMATLQTY              
  --     ,e3.RWKLABEA,e3.RWKLABQTY,e3.TOTRWKCOST,e3.CHGSTDCOST,e3.NEWSTDCOST,e3.CHGLBCOST,e3.NEWLBCOST,e3.CHGPRODNO,e3.NEWPRODNO,e3.CHGREV,e3.NEWREV,e3.CHGDESCR              
  --     ,e3.NEWDESCR,e3.CHGSERNO,e3.NEWSERNO,e3.COPYPHANT,e3.COPYABC,e3.COPYORDPOL,e3.COPYLEADTM,e3.COPYNOTE,e3.COPYSPEC,e3.COPYWKCTRS,e3.COPYWOLIST,e3.COPYTOOL              
  --     ,e3.COPYOUTS,e3.COPYDOCS,e3.COPYINST,e3.COPYCKLIST,e3.COPYSSNO,e3.ENGINEER,e3.COPYBMNOTE,e3.COPYEFFDTS,e3.COPYREFDES,e3.COPYALTPTS,e3.OPENDATE,e3.UPDATEDDT              
  --     ,e3.ECOREF,e3.CHGCUST,e3.NEWCUSTNO,e3.TOTRWKWCST,e3.TOTRWKFCST,e3.NEWMATLCST,e3.BOM_NOTE,e3.ECOFILE,e3.ECOSOURCE,e3.EFFECTIVEDT,e3.ECOLOCK,e3.ECOLOCKINT              
  --     ,e3.ECOLOCKDT,e3.SAVEDT,e3.SAVEINt,e3.ORIGINDOC,e3.UPDSOPRICE,e3.ECOITEMARC,e3.COPYOTHPRC,e3.lCopySupplier,e3.lUpdateMPN,                     
   INSERT INTO #tempEco          
   SELECT  CAST('4_NRE' AS CHAR(10)) AS TYPE,e3.UNIQECNO, e3.ECONO, e3.BOMCUSTNO, e3.UNIQ_KEY, e3.CHANGETYPE, e3.ECSTATUS, e3.PURPOSE, e3.ECDESCRIPT,
    e3.OUNITCOST, e3.NUNITCOST, e3.FGIBAL, e3.FGIUPDATE, e3.WIPUPDATE,e3.TOTMATL, e3.TOTLABOR, e3.TOTMISC, e3.NETMATLCHG, e3.EXPDATE, e3.TOTRWKMATL, 
	e3.TOTRWKLAB, e3.TOTRWKMISC, e3.RWKMATLEA, e3.RWKMATLQTY, e3.RWKLABEA, e3.RWKLABQTY, e3.TOTRWKCOST,e3.CHGSTDCOST, e3.NEWSTDCOST, e3.CHGLBCOST, 
	e3.NEWLBCOST, e3.CHGPRODNO, e3.NEWPRODNO, e3.CHGREV, e3.NEWREV ,e3.CHGDESCR, e3.NEWDESCR ,e3.CHGSERNO ,e3.NEWSERNO, e3.COPYPHANT, e3.COPYABC,
	e3.COPYORDPOL, e3.COPYLEADTM ,e3.COPYNOTE, e3.COPYSPEC, e3.COPYWKCTRS, e3.COPYWOLIST, e3.COPYTOOL, e3.COPYOUTS, e3.COPYDOCS, e3.COPYINST, 
	e3.COPYCKLIST, e3.COPYSSNO, e3.COPYBMNOTE,e3.COPYEFFDTS, e3.COPYREFDES, e3.COPYALTPTS, e3.OPENDATE, e3.UPDATEDDT, e3.ECOREF, e3.CHGCUST,
	e3.NEWCUSTNO, e3.TOTRWKWCST, e3.TOTRWKFCST, e3.NEWMATLCST, e3.BOM_NOTE, e3.ECOFILE,e3.ECOSOURCE, e3.EFFECTIVEDT, e3.ECOLOCK, e3.ECOLOCKINT,
	e3.ECOLOCKDT, e3.SAVEDT, e3.SAVEINT ,e3.ORIGINDOC, e3.UPDSOPRICE, e3.ECOITEMARC, e3.COPYOTHPRC, e3.lCopySupplier,e3.lUpdateMPN, 
	-- 09/18/20 VL found product number information was missing
	Inventor.Part_no AS Prod_no, Inventor.Revision AS Prod_rev, Inventor.Descript AS Prod_descript, Inventor.Part_class AS Prod_class, Inventor.Part_type AS Prod_type,
	e3.NEWSTDCOSTPR,
	e3.OUNITCOSTPR, e3.NUNITCOSTPR, e3.TOTMATLPR, e3.TOTLABORPR, e3.TOTMISCPR, e3.NETMATLCHGPR, e3.TOTRWKMATLPR, e3.TOTRWKLABPR,            
	e3.TOTRWKMISCPR, e3.RWKMATLEAPR, e3.RWKLABEAPR, e3.TOTRWKCOSTPR, e3.NEWLBCOSTPR, e3.TOTRWKWCSTPR, e3.TOTRWKFCSTPR, e3.NEWMATLCSTPR, e3.PRFCUSED_UNIQ,             
	e3.FUNCFCUSED_UNIQ, e3.Uniquerout, e3.NewBOMCUSTNO, a.UserName AS ENGINEER, e3.aspBuyerReadyForApproval, e3.IsApproveProcess,                   
    CAST('' AS CHAR(50)) AS Dept,CAST('' AS CHAR(8))AS init,CAST('' AS SMALLDATETIME) AS AprvDate,CAST('' AS CHAR(10)) AS uniqecdet,
	CAST (0 AS NUMERIC(4,0)) AS Item_no,
	-- 09/18/20 change to use ztool which is empty part_no
	--inventor.part_no,inventor.revisiON,inventor.Descript,inventor.Part_class,inventor.Part_type,
	ztool.part_no,ztool.revisiON,ztool.Descript,ztool.Part_class,ztool.Part_type,
	CAST('' AS CHAR(10)) AS Part_Sourc,inventor.Matl_cost,inventor.LaborCost,ISNULL(customer.custname, 'None') AS CustName,
	CASE WHEN e3.newcustno = '' AND e3.bomcustno = '' THEN 'None' ELSE CASE WHEN e3.newcustno = '' AND e3.bomcustno <> '' THEN c3.custname ELSE c2.custname END END  AS NewCustName,
	e3.netmatlchg+e3.totlabor AS TotalCosts,CAST('' AS CHAR(25)) AS CustPartNo,CAST('' AS CHAR(8)) AS CustRev,CAST('' AS CHAR(10)) AS detstatus,
	CAST(0.00 AS NUMERIC(9,2)) AS oldqty,CAST(0.00 AS NUMERIC(9,2)) AS newqty,ToolDesc,CostAmt,ChargeAmt,ztool.EffectiveDt AS  NreEffectDt,
	ztool.TerminatDt AS NreTerminatDt,CAST('' AS CHAR(10)) AS SoNo,CAST('' AS CHAR(7)) AS Line_no,CAST (0.00 AS NUMERIC(9,2)) AS SoBalance,
	CAST('' AS CHAR(10)) AS WoNo,CAST(0.00 AS NUMERIC(9,2)) AS WoBalance,CAST('' AS CHAR(60)) AS MiscDesc,CAST (0.00 AS NUMERIC(13,5)) AS MiscCost,CAST('' AS CHAR(3)) AS MiscType
  FROM ecmain E3 INNER JOIN ztool ON e3.uniqecno = ztool.uniqecno         
  INNER JOIN aspnet_Users a ON E3.ENGINEER = a.UserId             
  INNER JOIN inventor ON e3.uniq_key = inventor.uniq_key              
  LEFT OUTER JOIN  customer ON inventor.bomcustno = customer.custno              
  LEFT OUTER JOIN  customer C2 ON e3.newcustno = c2.custno              
  LEFT OUTER JOIN  customer c3 ON e3.bomcustno = c3.custno               
          
--&&&END NRE INFO              
--********************              
--********************              
--&&&BEGIN SONO INFO   
-- 09/17/19 Vijay G Modified the code AS per current requirement              
  ;WITH ZSoNo AS (              
      --SELECT ecmain.*,            
   SELECT ecmain.UNIQECNO, ECONO, ecmain.BOMCUSTNO, ecmain.UNIQ_KEY, CHANGETYPE, ECSTATUS, PURPOSE, ECDESCRIPT, OUNITCOST, NUNITCOST, FGIBAL, FGIUPDATE, WIPUPDATE,            
	TOTMATL, TOTLABOR, TOTMISC, NETMATLCHG, EXPDATE, TOTRWKMATL, TOTRWKLAB, TOTRWKMISC, RWKMATLEA, RWKMATLQTY, RWKLABEA, RWKLABQTY, TOTRWKCOST,             
	CHGSTDCOST, NEWSTDCOST, CHGLBCOST, NEWLBCOST, CHGPRODNO, NEWPRODNO, CHGREV, NEWREV ,CHGDESCR, NEWDESCR ,CHGSERNO ,NEWSERNO, COPYPHANT, COPYABC,             
	COPYORDPOL, COPYLEADTM ,COPYNOTE, COPYSPEC, COPYWKCTRS, COPYWOLIST, COPYTOOL, COPYOUTS, COPYDOCS, COPYINST, COPYCKLIST, COPYSSNO, COPYBMNOTE,             
	COPYEFFDTS, COPYREFDES, COPYALTPTS, OPENDATE, UPDATEDDT, ECOREF, CHGCUST, NEWCUSTNO, TOTRWKWCST, TOTRWKFCST, NEWMATLCST, ecmain.BOM_NOTE, ECOFILE,             
	ECOSOURCE, EFFECTIVEDT, ECOLOCK, ECOLOCKINT, ECOLOCKDT, SAVEDT, SAVEINT ,ORIGINDOC, UPDSOPRICE, ECOITEMARC, COPYOTHPRC, lCopySupplier,             
	lUpdateMPN, NEWSTDCOSTPR, OUNITCOSTPR, NUNITCOSTPR, TOTMATLPR, TOTLABORPR, TOTMISCPR, NETMATLCHGPR, TOTRWKMATLPR, TOTRWKLABPR,            
	TOTRWKMISCPR, RWKMATLEAPR, RWKLABEAPR, TOTRWKCOSTPR, NEWLBCOSTPR, TOTRWKWCSTPR, TOTRWKFCSTPR, NEWMATLCSTPR, ecmain.PRFCUSED_UNIQ,             
	ecmain.FUNCFCUSED_UNIQ, Uniquerout, NewBOMCUSTNO, ENGINEER, aspBuyerReadyForApproval, IsApproveProcess,CAST('' AS CHAR(10)) AS uniqecdet,            
	CAST('' AS CHAR(25)) AS Part_no,CAST('' AS CHAR(8)) AS Revision,CAST('' AS CHAR(45)) AS Descript,CAST('' AS CHAR(8)) AS Part_Class,CAST('' AS CHAR(8)) AS Part_Type,
	CAST('' AS CHAR(8)) AS Part_Sourc, CAST('' AS CHAR(25)) AS CustPartNo,CAST('' AS CHAR(8)) AS CustRev,CAST('' AS CHAR(10)) AS DetStatus,
	CAST(0 AS NUMERIC(4,0)) AS Item_no,CAST (0.00 AS NUMERIC(9,2))AS OldQty,CAST(0.00 AS NUMERIC(9,2)) AS NewQty,CAST('' AS text) AS ToolDesc,
	CAST (0.00 AS NUMERIC(13,5)) AS CostAmt,CAST (0.00 AS NUMERIC(13,5)) AS ChargeAmt,CAST(NULL AS SMALLDATETIME) AS NreEffectDt,
	CAST (NULL AS SMALLDATETIME) AS NreTerminatDt,ecso.SoNo,ecso.line_no,ecso.Balance,CAST('' AS CHAR(10)) AS WoNo,
	CAST(0.00 AS NUMERIC(9,2)) AS WoBalance,CAST('' AS CHAR(60)) AS MiscDesc,CAST (0.00 AS NUMERIC(13,5)) AS MiscCost,CAST('' AS CHAR(3)) AS MiscType              
   FROM ecmain,EcSo              
   WHERE ecmain.uniqecno = ecso.uniqecno AND ecso.UniqEcNo = @lcUniqEcNo AND ECSO.CHANGE <> 0              
      )              
      --06/13/18 YS got an error Column name or number of supplied values does not match table definition. when inserting into @eco  
              
--- will use temp table to avoid the error.              
  --insert into @eco  (Type,UNIQECNO,ECONO,BOMCUSTNO,PROD_UNIQ_KEY,CHANGETYPE,ECSTATUS,PURPOSE,ECDESCRIPT,OUNITCOST,NUNITCOST,FGIBAL,FGIUPDATE,WIPUPDATE,TOTMATL,TOTLABOR,TOTMISC              
  --     ,NETMATLCHG,EXPDATE,TOTRWKMATL,TOTRWKLAB,TOTRWKMISC,RWKMATLEA,RWKMATLQTY,RWKLABEA,RWKLABQTY,TOTRWKCOST,CHGSTDCOST,NEWSTDCOST,CHGLBCOST              
  --     ,NEWLBCOST,CHGPRODNO,NEWPRODNO,CHGREV,NEWREV,CHGDESCR,NEWDESCR,CHGSERNO,NEWSERNO,COPYPHANT,COPYABC,COPYORDPOL,COPYLEADTM,COPYNOTE,COPYSPEC,COPYWKCTRS              
  --     ,COPYWOLIST,COPYTOOL,COPYOUTS,COPYDOCS,COPYINST,COPYCKLIST,COPYSSNO,ENGINEER,COPYBMNOTE,COPYEFFDTS,COPYREFDES,COPYALTPTS,OPENDATE,UPDATEDDT              
  --     ,ECOREF,CHGCUST,NEWCUSTNO,TOTRWKWCST,TOTRWKFCST,NEWMATLCST,BOM_NOTE,ECOFILE,ECOSOURCE,EFFECTIVEDT,ECOLOCK,ECOLOCKINT,ECOLOCKDT,SAVEDT,SAVEINt,ORIGINDOC              
  --     ,UPDSOPRICE,ECOITEMARC,COPYOTHPRC,lCopySupplier,lUpdateMPN,Prod_no,Prod_Rev,Prod_Descript,Prod_class,Prod_Type,Matl_Cost,LaborCost,CustName,NewCustName              
  --     ,TotalCosts,Dept,Init,AprvDate,UniqEcDet,Item_no,uniq_key,Part_no,Revision,Descript,Part_class,Part_type,Part_Sourc,CustPartNo,CustRev,detstatus,oldqty,newqty              
  --     ,ToolDesc,CostAmt,ChargeAmt,NreEffectDt,NreTerminatDt,SoNo,Line_no,SoBalance,WoNo,WoBalance,MiscDesc,MiscCost,MiscType)               
      INSERT INTO #tempEco    
-- 09/17/19 Vijay G Modified the code AS per current requirement       
 --   SELECT              
 --CAST('5_SONO' AS char(10))AS type,            
 --My change            
 --e3.UNIQECNO,e3.ECONO,e3.BOMCUSTNO,e3.UNIQ_KEY,e3.CHANGETYPE,e3.ECSTATUS,e3.PURPOSE,e3.ECDESCRIPT,e3.OUNITCOST,e3.NUNITCOST,e3.FGIBAL              
 --      ,e3.FGIUPDATE,e3.WIPUPDATE,e3.TOTMATL,e3.TOTLABOR,e3.TOTMISC,e3.NETMATLCHG,e3.EXPDATE,e3.TOTRWKMATL,e3.TOTRWKLAB,e3.TOTRWKMISC,e3.RWKMATLEA,e3.RWKMATLQTY              
 --      ,e3.RWKLABEA,e3.RWKLABQTY,e3.TOTRWKCOST,e3.CHGSTDCOST,e3.NEWSTDCOST,e3.CHGLBCOST,e3.NEWLBCOST,e3.CHGPRODNO,e3.NEWPRODNO,e3.CHGREV,e3.NEWREV,e3.CHGDESCR              
 --      ,e3.NEWDESCR,e3.CHGSERNO,e3.NEWSERNO,e3.COPYPHANT,e3.COPYABC,e3.COPYORDPOL,e3.COPYLEADTM,e3.COPYNOTE,e3.COPYSPEC,e3.COPYWKCTRS,e3.COPYWOLIST,e3.COPYTOOL              
 --      ,e3.COPYOUTS,e3.COPYDOCS,e3.COPYINST,e3.COPYCKLIST,e3.COPYSSNO,e3.ENGINEER,e3.COPYBMNOTE,e3.COPYEFFDTS,e3.COPYREFDES,e3.COPYALTPTS,e3.OPENDATE,e3.UPDATEDDT              
 --      ,e3.ECOREF,e3.CHGCUST,e3.NEWCUSTNO,e3.TOTRWKWCST,e3.TOTRWKFCST,e3.NEWMATLCST,e3.BOM_NOTE,e3.ECOFILE,e3.ECOSOURCE,e3.EFFECTIVEDT,e3.ECOLOCK,e3.ECOLOCKINT              
 --      ,e3.ECOLOCKDT,e3.SAVEDT,e3.SAVEINt,e3.ORIGINDOC,e3.UPDSOPRICE,e3.ECOITEMARC,e3.COPYOTHPRC,e3.lCopySupplier,e3.lUpdateMPN            
  SELECT CAST('5_SONO' AS char(10))AS type,e3.UNIQECNO, e3.ECONO, e3.BOMCUSTNO, e3.UNIQ_KEY, e3.CHANGETYPE, e3.ECSTATUS, e3.PURPOSE, e3.ECDESCRIPT, 
	e3.OUNITCOST, e3.NUNITCOST, e3.FGIBAL, e3.FGIUPDATE, e3.WIPUPDATE,e3.TOTMATL, e3.TOTLABOR, e3.TOTMISC, e3.NETMATLCHG, e3.EXPDATE, e3.TOTRWKMATL, 
	e3.TOTRWKLAB, e3.TOTRWKMISC, e3.RWKMATLEA, e3.RWKMATLQTY,e3.RWKLABEA, e3.RWKLABQTY, e3.TOTRWKCOST,e3.CHGSTDCOST, e3.NEWSTDCOST, e3.CHGLBCOST, 
	e3.NEWLBCOST, e3.CHGPRODNO, e3.NEWPRODNO, e3.CHGREV, e3.NEWREV ,e3.CHGDESCR, e3.NEWDESCR ,e3.CHGSERNO ,e3.NEWSERNO, e3.COPYPHANT, e3.COPYABC,             
	e3.COPYORDPOL, e3.COPYLEADTM ,e3.COPYNOTE, e3.COPYSPEC, e3.COPYWKCTRS, e3.COPYWOLIST, e3.COPYTOOL, e3.COPYOUTS, e3.COPYDOCS, e3.COPYINST, 
	e3.COPYCKLIST, e3.COPYSSNO, e3.COPYBMNOTE,e3.COPYEFFDTS, e3.COPYREFDES, e3.COPYALTPTS, e3.OPENDATE, e3.UPDATEDDT, e3.ECOREF, e3.CHGCUST, 
	e3.NEWCUSTNO, e3.TOTRWKWCST, e3.TOTRWKFCST, e3.NEWMATLCST, e3.BOM_NOTE, e3.ECOFILE,e3.ECOSOURCE, e3.EFFECTIVEDT, e3.ECOLOCK, e3.ECOLOCKINT, 
	e3.ECOLOCKDT, e3.SAVEDT, e3.SAVEINT ,e3.ORIGINDOC, e3.UPDSOPRICE, e3.ECOITEMARC, e3.COPYOTHPRC, e3.lCopySupplier,             
	e3.lUpdateMPN, 
	-- 09/18/20 VL found product number information was missing
	Inventor.Part_no AS Prod_no, Inventor.Revision AS Prod_rev, Inventor.Descript AS Prod_descript, Inventor.Part_class AS Prod_class, Inventor.Part_type AS Prod_type,
	e3.NEWSTDCOSTPR, e3.OUNITCOSTPR, e3.NUNITCOSTPR, e3.TOTMATLPR, e3.TOTLABORPR, e3.TOTMISCPR, e3.NETMATLCHGPR, e3.TOTRWKMATLPR,
	e3.TOTRWKLABPR,e3.TOTRWKMISCPR, e3.RWKMATLEAPR, e3.RWKLABEAPR, e3.TOTRWKCOSTPR, e3.NEWLBCOSTPR, e3.TOTRWKWCSTPR, e3.TOTRWKFCSTPR, e3.NEWMATLCSTPR,
	e3.PRFCUSED_UNIQ,e3.FUNCFCUSED_UNIQ, e3.Uniquerout, e3.NewBOMCUSTNO, a.UserName AS ENGINEER, e3.aspBuyerReadyForApproval, e3.IsApproveProcess,
	CAST('' AS CHAR(50)) AS Dept,CAST('' AS CHAR(8))AS init,CAST('' AS SMALLDATETIME) AS AprvDate,CAST('' AS CHAR(10)) AS uniqecdet,
	CAST (0 AS NUMERIC(4,0)) AS Item_no,
	-- 09/18/20 change to use zSONO which is empty part_no
	--inventor.part_no,inventor.revisiON,inventor.Descript,inventor.Part_class,inventor.Part_type,
	zSONO.part_no,zSONO.revisiON,zSONO.Descript,zSONO.Part_class,zSONO.Part_type,
	CAST('' AS CHAR(10)) AS Part_Sourc,inventor.Matl_cost,inventor.LaborCost,ISNULL(customer.custname, 'None') AS CustName,
	CASE WHEN e3.newcustno = '' AND e3.bomcustno = '' THEN 'None' ELSE CASE WHEN e3.newcustno = '' AND e3.bomcustno <> '' THEN c3.custname ELSE c2.custname END END  AS NewCustName,
	e3.netmatlchg+e3.totlabor AS TotalCosts,CAST('' AS CHAR(25)) AS CustPartNo,CAST('' AS CHAR(25)) AS CustRev,CAST('' AS CHAR(10)) AS detstatus,
	CAST(0.00 AS NUMERIC(9,2)) AS oldqty,CAST(0.00 AS NUMERIC(9,2)) AS newqty,CAST('' AS text) AS ToolDesc,CAST (0.00 AS NUMERIC(13,5)) AS CostAmt,
	CAST (0.00 AS NUMERIC(13,5)) AS ChargeAmt,CAST(NULL AS SMALLDATETIME) AS NreEffectDt,CAST (NULL AS SMALLDATETIME) AS NreTerminatDt,
	SoNo,Line_no,Balance,CAST('' AS CHAR(10)) AS WoNo,CAST(0.00 AS NUMERIC(9,2)) AS WoBalance,CAST('' AS CHAR(60)) AS MiscDesc,
	CAST (0.00 AS NUMERIC(13,5)) AS MiscCost,CAST('' AS CHAR(3)) AS MiscType              
 FROM ecmain E3 INNER JOIN zSONO ON e3.uniqecno = zSONO.uniqecno          
 INNER JOIN aspnet_Users a ON E3.ENGINEER = a.UserId             
 INNER JOIN inventor ON e3.uniq_key = inventor.uniq_key              
 LEFT OUTER JOIN  customer ON inventor.bomcustno = customer.custno              
 LEFT OUTER JOIN  customer C2 ON e3.newcustno = c2.custno              
 LEFT OUTER JOIN  customer c3 ON e3.bomcustno = c3.custno                 
                 
--&&&END SONO INFO              
--********************              
--********************              
--&&&BEGIN WONO INFO              
  ;WITH ZWoNo AS (     
-- 09/17/19 Vijay G Modified the code AS per current requirement          
    --SELECT ecmain.*, 
  SELECT ecmain.UNIQECNO, ECONO, ecmain.BOMCUSTNO, ecmain.UNIQ_KEY, CHANGETYPE, ECSTATUS, PURPOSE, ECDESCRIPT, OUNITCOST, NUNITCOST, FGIBAL, 
  FGIUPDATE, WIPUPDATE,TOTMATL, TOTLABOR, TOTMISC, NETMATLCHG, EXPDATE, TOTRWKMATL, TOTRWKLAB, TOTRWKMISC, RWKMATLEA, RWKMATLQTY, RWKLABEA, 
  RWKLABQTY, TOTRWKCOST,CHGSTDCOST, NEWSTDCOST, CHGLBCOST, NEWLBCOST, CHGPRODNO, NEWPRODNO, CHGREV, NEWREV ,CHGDESCR, NEWDESCR ,CHGSERNO ,
  NEWSERNO, COPYPHANT, COPYABC,COPYORDPOL, COPYLEADTM ,COPYNOTE, COPYSPEC, COPYWKCTRS, COPYWOLIST, COPYTOOL, COPYOUTS, COPYDOCS, COPYINST, 
  COPYCKLIST, COPYSSNO, COPYBMNOTE,COPYEFFDTS, COPYREFDES, COPYALTPTS, OPENDATE, UPDATEDDT, ECOREF, CHGCUST, NEWCUSTNO, TOTRWKWCST, TOTRWKFCST,
  NEWMATLCST, ecmain.BOM_NOTE, ECOFILE,ECOSOURCE, EFFECTIVEDT, ECOLOCK, ECOLOCKINT, ECOLOCKDT, SAVEDT, SAVEINT ,ORIGINDOC, UPDSOPRICE,
  ECOITEMARC, COPYOTHPRC, lCopySupplier,lUpdateMPN, NEWSTDCOSTPR, OUNITCOSTPR, NUNITCOSTPR, TOTMATLPR, TOTLABORPR, TOTMISCPR, NETMATLCHGPR, 
  TOTRWKMATLPR, TOTRWKLABPR,TOTRWKMISCPR, RWKMATLEAPR, RWKLABEAPR, TOTRWKCOSTPR, NEWLBCOSTPR, TOTRWKWCSTPR, TOTRWKFCSTPR, NEWMATLCSTPR, ecmain.PRFCUSED_UNIQ,             
  ecmain.FUNCFCUSED_UNIQ, Uniquerout, NewBOMCUSTNO, ENGINEER, aspBuyerReadyForApproval, IsApproveProcess,           
   CAST('' AS CHAR(10)) AS uniqecdet,            
              CAST('' AS CHAR(25)) AS Part_no,CAST('' AS CHAR(8)) AS Revision,CAST('' AS CHAR(45)) AS Descript              
        ,CAST('' AS CHAR(8)) AS Part_Class,CAST('' AS CHAR(8)) AS Part_Type            
              
              
  ,CAST('' AS CHAR(8)) AS Part_Sourc          
  , CAST('' AS CHAR(25)) AS CustPartNo              
        ,CAST('' AS CHAR(8)) AS CustRev          
  ,CAST('' AS CHAR(10)) AS DetStatus          
  ,CAST(0 AS NUMERIC(4,0)) AS Item_no          
  ,CAST (0.00 AS NUMERIC(9,2))AS OldQty              
        ,CAST(0.00 AS NUMERIC(9,2)) AS NewQty          
  ,CAST('' AS text) AS ToolDesc          
  ,CAST (0.00 AS NUMERIC(13,5)) AS CostAmt          
  ,CAST (0.00 AS NUMERIC(13,5)) AS ChargeAmt              
        ,CAST(NULL AS SMALLDATETIME) AS NreEffectDt          
  ,CAST (NULL AS SMALLDATETIME) AS NreTerminatDt          
  ,CAST('' AS CHAR(10)) AS SoNo          
  ,CAST('' AS CHAR(7)) AS Line_no              
        ,CAST (0.00 AS NUMERIC(9,2)) AS SoBalance,wono          
  ,balance AS WoBalance          
  ,CAST('' AS CHAR(60)) AS MiscDesc          
  ,CAST (0.00 AS NUMERIC(13,5)) AS MiscCost              
        ,CAST('' AS CHAR(3)) AS MiscType              
          
      FROM ecmain,Ecwo              
       WHERE ecmain.uniqecno = ecwo.uniqecno              
        AND ecwo.UniqEcNo = @lcUniqEcNo              
 AND ECwo.CHANGE <> 0               
      )              
      --06/13/18 YS got an error Column name or number of supplied values does not match table definition. when inserting into @eco              
--- will use temp table to avoid the error.              
  --insert into @eco  (Type,UNIQECNO,ECONO,BOMCUSTNO,PROD_UNIQ_KEY,CHANGETYPE,ECSTATUS,PURPOSE,ECDESCRIPT,OUNITCOST,NUNITCOST,FGIBAL,FGIUPDATE,WIPUPDATE,TOTMATL,TOTLABOR,TOTMISC              
  --     ,NETMATLCHG,EXPDATE,TOTRWKMATL,TOTRWKLAB,TOTRWKMISC,RWKMATLEA,RWKMATLQTY,RWKLABEA,RWKLABQTY,TOTRWKCOST,CHGSTDCOST,NEWSTDCOST,CHGLBCOST              
  --     ,NEWLBCOST,CHGPRODNO,NEWPRODNO,CHGREV,NEWREV,CHGDESCR,NEWDESCR,CHGSERNO,NEWSERNO,COPYPHANT,COPYABC,COPYORDPOL,COPYLEADTM,COPYNOTE,COPYSPEC,COPYWKCTRS              
  --     ,COPYWOLIST,COPYTOOL,COPYOUTS,COPYDOCS,COPYINST,COPYCKLIST,COPYSSNO,ENGINEER,COPYBMNOTE,COPYEFFDTS,COPYREFDES,COPYALTPTS,OPENDATE,UPDATEDDT              
  --     ,ECOREF,CHGCUST,NEWCUSTNO,TOTRWKWCST,TOTRWKFCST,NEWMATLCST,BOM_NOTE,ECOFILE,ECOSOURCE,EFFECTIVEDT,ECOLOCK,ECOLOCKINT,ECOLOCKDT,SAVEDT,SAVEINt,ORIGINDOC              
  --     ,UPDSOPRICE,ECOITEMARC,COPYOTHPRC,lCopySupplier,lUpdateMPN,Prod_no,Prod_Rev,Prod_Descript,Prod_class,Prod_Type,Matl_Cost,LaborCost,CustName,NewCustName              
  --     ,TotalCosts,Dept,Init,AprvDate,UniqEcDet,Item_no,uniq_key,Part_no,Revision,Descript,Part_class,Part_type,Part_Sourc,CustPartNo,CustRev,detstatus,oldqty,newqty              
  --     ,ToolDesc,CostAmt,ChargeAmt,NreEffectDt,NreTerminatDt,SoNo,Line_no,SoBalance,WoNo,WoBalance,MiscDesc,MiscCost,MiscType)              
         INSERT INTO #tempEco
-- 09/17/19 Vijay G Modified the code AS per current requirement              
    SELECT  CAST('6_WONO' AS CHAR(10)) AS TYPE,                        
 --e3.UNIQECNO,e3.ECONO,e3.BOMCUSTNO,e3.UNIQ_KEY,e3.CHANGETYPE,e3.ECSTATUS,e3.PURPOSE,e3.ECDESCRIPT,e3.OUNITCOST,e3.NUNITCOST,e3.FGIBAL              
 --      ,e3.FGIUPDATE,e3.WIPUPDATE,e3.TOTMATL,e3.TOTLABOR,e3.TOTMISC,e3.NETMATLCHG,e3.EXPDATE,e3.TOTRWKMATL,e3.TOTRWKLAB,e3.TOTRWKMISC,e3.RWKMATLEA,e3.RWKMATLQTY              
 --      ,e3.RWKLABEA,e3.RWKLABQTY,e3.TOTRWKCOST,e3.CHGSTDCOST,e3.NEWSTDCOST,e3.CHGLBCOST,e3.NEWLBCOST,e3.CHGPRODNO,e3.NEWPRODNO,e3.CHGREV,e3.NEWREV,e3.CHGDESCR              
 --      ,e3.NEWDESCR,e3.CHGSERNO,e3.NEWSERNO,e3.COPYPHANT,e3.COPYABC,e3.COPYORDPOL,e3.COPYLEADTM,e3.COPYNOTE,e3.COPYSPEC,e3.COPYWKCTRS,e3.COPYWOLIST,e3.COPYTOOL              
 --      ,e3.COPYOUTS,e3.COPYDOCS,e3.COPYINST,e3.COPYCKLIST,e3.COPYSSNO,e3.ENGINEER,e3.COPYBMNOTE,e3.COPYEFFDTS,e3.COPYREFDES,e3.COPYALTPTS,e3.OPENDATE,e3.UPDATEDDT              
 --      ,e3.ECOREF,e3.CHGCUST,e3.NEWCUSTNO,e3.TOTRWKWCST,e3.TOTRWKFCST,e3.NEWMATLCST,e3.BOM_NOTE,e3.ECOFILE,e3.ECOSOURCE,e3.EFFECTIVEDT,e3.ECOLOCK,e3.ECOLOCKINT              
 --      ,e3.ECOLOCKDT,e3.SAVEDT,e3.SAVEINt,e3.ORIGINDOC,e3.UPDSOPRICE,e3.ECOITEMARC,e3.COPYOTHPRC,e3.lCopySupplier,e3.lUpdateMPN,                        
     e3.UNIQECNO, e3.ECONO, e3.BOMCUSTNO, e3.UNIQ_KEY, e3.CHANGETYPE, e3.ECSTATUS, e3.PURPOSE, e3.ECDESCRIPT, e3.OUNITCOST, e3.NUNITCOST, e3.FGIBAL, e3.FGIUPDATE, e3.WIPUPDATE,            
     e3.TOTMATL, e3.TOTLABOR, e3.TOTMISC, e3.NETMATLCHG, e3.EXPDATE, e3.TOTRWKMATL, e3.TOTRWKLAB, e3.TOTRWKMISC, e3.RWKMATLEA, e3.RWKMATLQTY, e3.RWKLABEA, e3.RWKLABQTY, e3.TOTRWKCOST,             
  e3.CHGSTDCOST, e3.NEWSTDCOST, e3.CHGLBCOST, e3.NEWLBCOST, e3.CHGPRODNO, e3.NEWPRODNO, e3.CHGREV, e3.NEWREV ,e3.CHGDESCR, e3.NEWDESCR ,e3.CHGSERNO ,e3.NEWSERNO, e3.COPYPHANT, e3.COPYABC,             
  e3.COPYORDPOL, e3.COPYLEADTM ,e3.COPYNOTE, e3.COPYSPEC, e3.COPYWKCTRS, e3.COPYWOLIST, e3.COPYTOOL, e3.COPYOUTS, e3.COPYDOCS, e3.COPYINST, e3.COPYCKLIST, e3.COPYSSNO, e3.COPYBMNOTE,             
  e3.COPYEFFDTS, e3.COPYREFDES, e3.COPYALTPTS, e3.OPENDATE, e3.UPDATEDDT, e3.ECOREF, e3.CHGCUST, e3.NEWCUSTNO, e3.TOTRWKWCST, e3.TOTRWKFCST, e3.NEWMATLCST, e3.BOM_NOTE, e3.ECOFILE,             
  e3.ECOSOURCE, e3.EFFECTIVEDT, e3.ECOLOCK, e3.ECOLOCKINT, e3.ECOLOCKDT, e3.SAVEDT, e3.SAVEINT ,e3.ORIGINDOC, e3.UPDSOPRICE, e3.ECOITEMARC, e3.COPYOTHPRC, e3.lCopySupplier,             
  e3.lUpdateMPN, 
  -- 09/18/20 VL found product number information was missing
  Inventor.Part_no AS Prod_no, Inventor.Revision AS Prod_rev, Inventor.Descript AS Prod_descript, Inventor.Part_class AS Prod_class, Inventor.Part_type AS Prod_type,
  
  e3.NEWSTDCOSTPR, e3.OUNITCOSTPR, e3.NUNITCOSTPR, e3.TOTMATLPR, e3.TOTLABORPR, e3.TOTMISCPR, e3.NETMATLCHGPR, e3.TOTRWKMATLPR, e3.TOTRWKLABPR,            
  e3.TOTRWKMISCPR, e3.RWKMATLEAPR, e3.RWKLABEAPR, e3.TOTRWKCOSTPR, e3.NEWLBCOSTPR, e3.TOTRWKWCSTPR, e3.TOTRWKFCSTPR, e3.NEWMATLCSTPR, e3.PRFCUSED_UNIQ,             
  e3.FUNCFCUSED_UNIQ, e3.Uniquerout, e3.NewBOMCUSTNO, a.UserName AS ENGINEER, e3.aspBuyerReadyForApproval, e3.IsApproveProcess        
       ,CAST('' AS CHAR(50)) AS Dept          
    ,CAST('' AS CHAR(8))AS init          
    ,CAST('' AS SMALLDATETIME) AS AprvDate              
       ,CAST('' AS CHAR(10)) AS uniqecdet          
    ,CAST (0 AS NUMERIC(4,0)) AS Item_no            
	-- 09/18/20 change to use zWONO which is empty part_no                
 --   ,inventor.part_no          
	--,inventor.revisiON              
 --   ,inventor.Descript          
 --   ,inventor.Part_class          
 --   ,inventor.Part_type          
     ,zWONO.part_no          
	,zWONO.revisiON              
    ,zWONO.Descript          
    ,zWONO.Part_class          
    ,zWONO.Part_type          
    ,CAST('' AS CHAR(10)) AS Part_Sourc          
    ,inventor.Matl_cost          
    ,inventor.LaborCost          
    ,ISNULL(customer.custname, 'None') AS CustName              
       ,CASE WHEN e3.newcustno = '' AND e3.bomcustno = '' THEN 'None' ELSE               
        CASE WHEN e3.newcustno = '' AND e3.bomcustno <> '' THEN c3.custname              
         ELSE c2.custname END END  AS NewCustName              
       ,e3.netmatlchg+e3.totlabor AS TotalCosts                       
    --CAST('' AS CHAR(10))uniq_key,CAST('' AS CHAR(25)) AS Part_no              
    --   ,CAST('' AS CHAR(8)) AS Revision,CAST('' AS CHAR(45)) AS Descript,CAST('' AS CHAR(8)) AS Part_class,CAST('' AS CHAR(8)) AS Part_type            
           
    ,CAST('' AS CHAR(25)) AS CustPartNo          
    ,CAST('' AS CHAR(10)) AS CustRev          
    ,CAST('' AS CHAR(10)) AS detstatus              
       ,CAST(0.00 AS NUMERIC(9,2)) AS oldqty          
    ,CAST(0.00 AS NUMERIC(9,2)) AS newqty          
    ,CAST('' AS text) AS ToolDesc          
    ,CAST (0.00 AS NUMERIC(13,5)) AS CostAmt              
       ,CAST (0.00 AS NUMERIC(13,5)) AS ChargeAmt          
    ,CAST(NULL AS SMALLDATETIME) AS NreEffectDt          
    ,CAST (NULL AS SMALLDATETIME) AS NreTerminatDt              
       ,CAST('' AS CHAR(10)) AS SoNo          
    ,CAST('' AS CHAR(9)) AS Line_no          
    ,CAST(0.00 AS NUMERIC(9,2)) AS Balance,WoNo,WoBalance              
       ,CAST('' AS CHAR(60)) AS MiscDesc          
    ,CAST (0.00 AS NUMERIC(13,5)) AS MiscCost          
    ,CAST('' AS CHAR(3)) AS MiscType              
          
    FROM ecmain E3 INNER JOIN zWONO ON e3.uniqecno = zwONO.uniqecno           
  INNER JOIN aspnet_Users a ON E3.ENGINEER = a.UserId             
            
       INNER JOIN inventor ON e3.uniq_key = inventor.uniq_key              
       LEFT OUTER JOIN  customer ON inventor.bomcustno = customer.custno              
       LEFT OUTER JOIN  customer C2 ON e3.newcustno = c2.custno              
       LEFT OUTER JOIN  customer c3 ON e3.bomcustno = c3.custno                           
--&&&END WONO INFO              
--********************              
--********************              
--&&&BEGIN MISC INFO 
-- 09/17/19 Vijay G Modified the code AS per current requirement              
  ;WITH ZMisc AS (              
      SELECT                            
   --ecmain.*,            
    ecmain.UNIQECNO, ECONO, ecmain.BOMCUSTNO, ecmain.UNIQ_KEY, CHANGETYPE, ECSTATUS, PURPOSE, ECDESCRIPT, OUNITCOST, NUNITCOST, FGIBAL, FGIUPDATE, WIPUPDATE,            
     TOTMATL, TOTLABOR, TOTMISC, NETMATLCHG, EXPDATE, TOTRWKMATL, TOTRWKLAB, TOTRWKMISC, RWKMATLEA, RWKMATLQTY, RWKLABEA, RWKLABQTY, TOTRWKCOST,             
  CHGSTDCOST, NEWSTDCOST, CHGLBCOST, NEWLBCOST, CHGPRODNO, NEWPRODNO, CHGREV, NEWREV ,CHGDESCR, NEWDESCR ,CHGSERNO ,NEWSERNO, COPYPHANT, COPYABC,             
  COPYORDPOL, COPYLEADTM ,COPYNOTE, COPYSPEC, COPYWKCTRS, COPYWOLIST, COPYTOOL, COPYOUTS, COPYDOCS, COPYINST, COPYCKLIST, COPYSSNO, COPYBMNOTE,             
  COPYEFFDTS, COPYREFDES, COPYALTPTS, OPENDATE, UPDATEDDT, ECOREF, CHGCUST, NEWCUSTNO, TOTRWKWCST, TOTRWKFCST, NEWMATLCST, ecmain.BOM_NOTE, ECOFILE,             
  ECOSOURCE, EFFECTIVEDT, ECOLOCK, ECOLOCKINT, ECOLOCKDT, SAVEDT, SAVEINT ,ORIGINDOC, UPDSOPRICE, ECOITEMARC, COPYOTHPRC, lCopySupplier,             
  lUpdateMPN, NEWSTDCOSTPR, OUNITCOSTPR, NUNITCOSTPR, TOTMATLPR, TOTLABORPR, TOTMISCPR, NETMATLCHGPR, TOTRWKMATLPR, TOTRWKLABPR,            
  TOTRWKMISCPR, RWKMATLEAPR, RWKLABEAPR, TOTRWKCOSTPR, NEWLBCOSTPR, TOTRWKWCSTPR, TOTRWKFCSTPR, NEWMATLCSTPR, ecmain.PRFCUSED_UNIQ,             
  ecmain.FUNCFCUSED_UNIQ, Uniquerout, NewBOMCUSTNO, ENGINEER, aspBuyerReadyForApproval, IsApproveProcess,             
            
    CAST('' AS CHAR(10)) AS uniqecdet                 
 ,CAST('' AS CHAR(25)) AS Part_no,CAST('' AS CHAR(8)) AS Revision,CAST('' AS CHAR(45)) AS Descript              
 ,CAST('' AS CHAR(8)) AS Part_Class,CAST('' AS CHAR(8)) AS Part_Type            
 ,CAST('' AS CHAR(8)) AS Part_Sourc, CAST('' AS CHAR(25)) AS CustPartNo              
 ,CAST('' AS CHAR(8)) AS CustRev,CAST('' AS CHAR(10)) AS DetStatus,CAST(0 AS NUMERIC(4,0)) AS Item_no,CAST (0.00 AS NUMERIC(9,2))AS OldQty              
 ,CAST(0.00 AS NUMERIC(9,2)) AS NewQty,CAST('' AS text) AS ToolDesc,CAST (0.00 AS NUMERIC(13,5)) AS CostAmt,CAST (0.00 AS NUMERIC(13,5)) AS ChargeAmt              
 ,CAST(NULL AS SMALLDATETIME) AS NreEffectDt,CAST (NULL AS SMALLDATETIME) AS NreTerminatDt,CAST('' AS CHAR(10)) AS SoNo,CAST('' AS CHAR(7)) AS Line_no              
 ,CAST (0.00 AS NUMERIC(9,2)) AS SoBalance,CAST('' AS CHAR(10)) AS wono,CAST (0.00 AS NUMERIC (9,2)) AS WoBalance,ecmisc.descript AS MiscDesc              
 ,ecmisc.cost AS MiscCost,ecmisc.type AS MiscType                   
    FROM ecmain,EcMisc                        
     WHERE ecmain.uniqecno = ecMisc.uniqecno              
    AND ecMisc.UniqEcNo = @lcUniqEcNo              
      )              
      --06/13/18 YS got an error Column name or number of supplied values does not match table definition. when inserting into @eco              
--- will use temp table to avoid the error.              
  --insert into @eco  (Type,UNIQECNO,ECONO,BOMCUSTNO,PROD_UNIQ_KEY,CHANGETYPE,ECSTATUS,PURPOSE,ECDESCRIPT,OUNITCOST,NUNITCOST,FGIBAL,FGIUPDATE,WIPUPDATE,TOTMATL,TOTLABOR,TOTMISC              
  --     ,NETMATLCHG,EXPDATE,TOTRWKMATL,TOTRWKLAB,TOTRWKMISC,RWKMATLEA,RWKMATLQTY,RWKLABEA,RWKLABQTY,TOTRWKCOST,CHGSTDCOST,NEWSTDCOST,CHGLBCOST              
  --     ,NEWLBCOST,CHGPRODNO,NEWPRODNO,CHGREV,NEWREV,CHGDESCR,NEWDESCR,CHGSERNO,NEWSERNO,COPYPHANT,COPYABC,COPYORDPOL,COPYLEADTM,COPYNOTE,COPYSPEC,COPYWKCTRS              
  --     ,COPYWOLIST,COPYTOOL,COPYOUTS,COPYDOCS,COPYINST,COPYCKLIST,COPYSSNO,ENGINEER,COPYBMNOTE,COPYEFFDTS,COPYREFDES,COPYALTPTS,OPENDATE,UPDATEDDT              
  --     ,ECOREF,CHGCUST,NEWCUSTNO,TOTRWKWCST,TOTRWKFCST,NEWMATLCST,BOM_NOTE,ECOFILE,ECOSOURCE,EFFECTIVEDT,ECOLOCK,ECOLOCKINT,ECOLOCKDT,SAVEDT,SAVEINt,ORIGINDOC              
  --     ,UPDSOPRICE,ECOITEMARC,COPYOTHPRC,lCopySupplier,lUpdateMPN,Prod_no,Prod_Rev,Prod_Descript,Prod_class,Prod_Type,Matl_Cost,LaborCost,CustName,NewCustName              
  --     ,TotalCosts,Dept,Init,AprvDate,UniqEcDet,Item_no,uniq_key,Part_no,Revision,Descript,Part_class,Part_type,Part_Sourc,CustPartNo,CustRev,detstatus,oldqty,newqty              
  --     ,ToolDesc,CostAmt,ChargeAmt,NreEffectDt,NreTerminatDt,SoNo,Line_no,SoBalance,WoNo,WoBalance,MiscDesc,MiscCost,MiscType)              
    -- 09/17/19 Vijay G Modified the code AS per current requirement 
    INSERT INTO #tempEco          
    SELECT  CAST(CASE WHEN MiscType = 'LAB' THEN '7_LAB' WHEN MiscType = 'RWK' THEN '8_RWK' END AS CHAR(10)) AS TYPE,                       
 --e3.UNIQECNO,e3.ECONO,e3.BOMCUSTNO,e3.UNIQ_KEY,e3.CHANGETYPE,e3.ECSTATUS,e3.PURPOSE,e3.ECDESCRIPT,e3.OUNITCOST,e3.NUNITCOST,e3.FGIBAL              
 --      ,e3.FGIUPDATE,e3.WIPUPDATE,e3.TOTMATL,e3.TOTLABOR,e3.TOTMISC,e3.NETMATLCHG,e3.EXPDATE,e3.TOTRWKMATL,e3.TOTRWKLAB,e3.TOTRWKMISC,e3.RWKMATLEA,e3.RWKMATLQTY              
 --      ,e3.RWKLABEA,e3.RWKLABQTY,e3.TOTRWKCOST,e3.CHGSTDCOST,e3.NEWSTDCOST,e3.CHGLBCOST,e3.NEWLBCOST,e3.CHGPRODNO,e3.NEWPRODNO,e3.CHGREV,e3.NEWREV,e3.CHGDESCR              
 --      ,e3.NEWDESCR,e3.CHGSERNO,e3.NEWSERNO,e3.COPYPHANT,e3.COPYABC,e3.COPYORDPOL,e3.COPYLEADTM,e3.COPYNOTE,e3.COPYSPEC,e3.COPYWKCTRS,e3.COPYWOLIST,e3.COPYTOOL              
 --      ,e3.COPYOUTS,e3.COPYDOCS,e3.COPYINST,e3.COPYCKLIST,e3.COPYSSNO,e3.ENGINEER,e3.COPYBMNOTE,e3.COPYEFFDTS,e3.COPYREFDES,e3.COPYALTPTS,e3.OPENDATE,e3.UPDATEDDT              
 --      ,e3.ECOREF,e3.CHGCUST,e3.NEWCUSTNO,e3.TOTRWKWCST,e3.TOTRWKFCST,e3.NEWMATLCST,e3.BOM_NOTE,e3.ECOFILE,e3.ECOSOURCE,e3.EFFECTIVEDT,e3.ECOLOCK,e3.ECOLOCKINT              
 --      ,e3.ECOLOCKDT,e3.SAVEDT,e3.SAVEINt,e3.ORIGINDOC,e3.UPDSOPRICE,e3.ECOITEMARC,e3.COPYOTHPRC,e3.lCopySupplier,e3.lUpdateMPN,            
                
                
     e3.UNIQECNO, e3.ECONO, e3.BOMCUSTNO, e3.UNIQ_KEY, e3.CHANGETYPE, e3.ECSTATUS, e3.PURPOSE, e3.ECDESCRIPT, e3.OUNITCOST, e3.NUNITCOST, e3.FGIBAL, e3.FGIUPDATE, e3.WIPUPDATE,            
     e3.TOTMATL, e3.TOTLABOR, e3.TOTMISC, e3.NETMATLCHG, e3.EXPDATE, e3.TOTRWKMATL, e3.TOTRWKLAB, e3.TOTRWKMISC, e3.RWKMATLEA, e3.RWKMATLQTY, e3.RWKLABEA, e3.RWKLABQTY, e3.TOTRWKCOST,             
  e3.CHGSTDCOST, e3.NEWSTDCOST, e3.CHGLBCOST, e3.NEWLBCOST, e3.CHGPRODNO, e3.NEWPRODNO, e3.CHGREV, e3.NEWREV ,e3.CHGDESCR, e3.NEWDESCR ,e3.CHGSERNO ,e3.NEWSERNO, e3.COPYPHANT, e3.COPYABC,             
  e3.COPYORDPOL, e3.COPYLEADTM ,e3.COPYNOTE, e3.COPYSPEC, e3.COPYWKCTRS, e3.COPYWOLIST, e3.COPYTOOL, e3.COPYOUTS, e3.COPYDOCS, e3.COPYINST, e3.COPYCKLIST, e3.COPYSSNO, e3.COPYBMNOTE,             
  e3.COPYEFFDTS, e3.COPYREFDES, e3.COPYALTPTS, e3.OPENDATE, e3.UPDATEDDT, e3.ECOREF, e3.CHGCUST, e3.NEWCUSTNO, e3.TOTRWKWCST, e3.TOTRWKFCST, e3.NEWMATLCST, e3.BOM_NOTE, e3.ECOFILE,             
  e3.ECOSOURCE, e3.EFFECTIVEDT, e3.ECOLOCK, e3.ECOLOCKINT, e3.ECOLOCKDT, e3.SAVEDT, e3.SAVEINT ,e3.ORIGINDOC, e3.UPDSOPRICE, e3.ECOITEMARC, e3.COPYOTHPRC, e3.lCopySupplier,             
  e3.lUpdateMPN, 
  -- 09/18/20 VL found product number information was missing
  Inventor.Part_no AS Prod_no, Inventor.Revision AS Prod_rev, Inventor.Descript AS Prod_descript, Inventor.Part_class AS Prod_class, Inventor.Part_type AS Prod_type,
  
  e3.NEWSTDCOSTPR, e3.OUNITCOSTPR, e3.NUNITCOSTPR, e3.TOTMATLPR, e3.TOTLABORPR, e3.TOTMISCPR, e3.NETMATLCHGPR, e3.TOTRWKMATLPR, e3.TOTRWKLABPR,            
  e3.TOTRWKMISCPR, e3.RWKMATLEAPR, e3.RWKLABEAPR, e3.TOTRWKCOSTPR, e3.NEWLBCOSTPR, e3.TOTRWKWCSTPR, e3.TOTRWKFCSTPR, e3.NEWMATLCSTPR, e3.PRFCUSED_UNIQ,             
  e3.FUNCFCUSED_UNIQ, e3.Uniquerout, e3.NewBOMCUSTNO,a.UserName AS ENGINEER, e3.aspBuyerReadyForApproval, e3.IsApproveProcess        
        ,CAST('' AS CHAR(50)) AS Dept          
    ,CAST('' AS CHAR(8))AS init          
    ,CAST('' AS SMALLDATETIME) AS AprvDate              
       ,CAST('' AS CHAR(10)) AS uniqecdet          
    ,CAST (0 AS NUMERIC(4,0)) AS Item_no          
    -- 09/18/20 change to use zmisc which is empty part_no       
    --,inventor.part_no          
    --,inventor.revisiON              
    --,inventor.Descript          
    --,inventor.Part_class          
    --,inventor.Part_type          
	,zmisc.part_no          
    ,zmisc.revisiON              
    ,zmisc.Descript          
    ,zmisc.Part_class          
    ,zmisc.Part_type          
    ,CAST('' AS CHAR(10)) AS Part_Sourc          
    ,inventor.Matl_cost          
    ,inventor.LaborCost          
    ,ISNULL(customer.custname, 'None') AS CustName              
       ,CASE WHEN e3.newcustno = '' AND e3.bomcustno = '' THEN 'None' ELSE               
        CASE WHEN e3.newcustno = '' AND e3.bomcustno <> '' THEN c3.custname              
         ELSE c2.custname END END  AS NewCustName              
       ,e3.netmatlchg+e3.totlabor AS TotalCosts          
              
          
    ,CAST('' AS CHAR(25)) AS CustPartNo          
    ,CAST('' AS CHAR(8)) AS CustRev          
    ,CAST('' AS CHAR(10)) asdetstatus              
       ,CAST(0.00 AS NUMERIC(9,2)) AS oldqty          
    ,CAST(0.00 AS NUMERIC(9,2)) AS newqty          
    ,CAST('' AS text) AS ToolDesc          
    ,CAST (0.00 AS NUMERIC(13,5)) AS CostAmt              
       ,CAST (0.00 AS NUMERIC(13,5)) AS ChargeAmt          
    ,CAST(NULL AS SMALLDATETIME) AS NreEffectDt          
    ,CAST (NULL AS SMALLDATETIME) AS NreTerminatDt              
       ,CAST('' AS CHAR(10)) AS SoNo          
    ,CAST('' AS CHAR(9)) AS Line_no          
    ,CAST(0.00 AS NUMERIC(9,2)) AS Balance          
    ,WoNo,WoBalance,MiscDesc,MiscCost,MiscType              
    FROM ecmain E3 INNER JOIN zmisc ON e3.uniqecno = zmisc.uniqecno           
  INNER JOIN aspnet_Users a ON E3.ENGINEER = a.UserId             
            
       INNER JOIN inventor ON e3.uniq_key = inventor.uniq_key              
       LEFT OUTER JOIN  customer ON inventor.bomcustno = customer.custno              
       LEFT OUTER JOIN  customer C2 ON e3.newcustno = c2.custno              
       LEFT OUTER JOIN  customer c3 ON e3.bomcustno = c3.custno                
              
--&&&END MISC INFO              
--********************              
--06/13/18 YS got an error Column name or number of supplied values does not match table definition. when inserting into @eco              
--- will use temp table to avoid the error.              
--SELECT E.*,micssys.lic_name FROM @eco E  cross join micssys  ORDER BY 1              
SELECT E.*,micssys.lic_name FROM #tempEco E  cross join micssys  ORDER BY 1              
IF OBJECT_ID('tempdb..#tempEco') is not NULL              
 DROP TABLE #tempEco              
end