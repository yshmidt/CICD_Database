-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <08/19/2011>
-- Description:	<Get All From GLRELEASED. 
-- For now I think that get all records to send the result to the front end 
-- is more afficient then get one transaction type at a time
-- may create a different SP for getting one at a time if needed
-- Modified:  10/23/13 YS same problem as JE with checks. No time saved for transaction date
--			  09/24/15 VL added AtdUniq_key that will be update with 'TAX0' if tax rate is 0 for FC
--			 07/20/16 YS when releaseing invt_rec or invt_isu or invt_trns have to rank by source table and csubdrill then Trans_dt. for these tables cSubdrill is a uniq_key and we do not want to pack different uniq_key into the same transaction even if the time is exactly the same
--			08/03/16 YS Penang reported  another transaction, 'PURCH' type that grouped transactions from different invoices together. I am changing all the trnasactions accept invenotry to group by cdrill. Inventory by cdrill and cSubdrill
--			12/21/16 VL added functional and presentation currency fields and separate FC and non-FC
-- =============================================
CREATE PROCEDURE [dbo].[GetAllGlReleased]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
-- 12/21/16 VL added to check if FC is installed or not, if yes, need to get the exchange rate variance calculated
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
	BEGIN 

    -- Insert statements for procedure here
    -- 07/09/12 YS for JE group by cDrill, not trans date, Really want to have transaction per JE. Transaction date will not have time. Maybe need to change that also.
    -- 10/23/13 YS same problem as JE with checks. No time saved for transaction date
	--			08/03/16 YS Penang reported  another transaction, 'PURCH' type that grouped transactions from different invoices together. I am changing all the trnasactions accept invenotry to group by cdrill. Inventory by cdrill and cSubdrill

	SELECT [GLRELUNIQUE]
--			08/03/16 YS Penang reported  another transaction, 'PURCH' type that grouped transactions from different invoices together. I am changing all the trnasactions accept invenotry to group by cdrill. Inventory by cdrill and cSubdrill
      ,RANKN= CASE WHEN TransactionType IN ('INVTREC', 'INVTISU', 'INVTTRNS') THEN DENSE_RANK () OVER (order by transactiontype,sourcetable,CSubDrill,Trans_dt) 
	   ELSE DENSE_RANK () OVER (order by transactiontype,sourcetable,CDrill) 
	   -- WHEN TransactionType='JE' or TransactionType='CHECKS' THEN DENSE_RANK () OVER (order by transactiontype,sourcetable,CDrill) 
		-- 07/20/16 YS add case for INVTREC, INVTISU, INVTTRNS.   When releaseing invt_rec or invt_isu or invt_trns have to rank by source table and csubdrill then Trans_dt. for these tables cSubdrill is a uniq_key and we do not want to pack different uniq_key into the same transaction even if the time is exactly the same  
	  	  --ELSE DENSE_RANK () OVER (order by transactiontype,sourcetable,Trans_dt) 
	  END
--			08/03/16 YS Penang reported  another transaction, 'PURCH' type that grouped transactions from different invoices together. I am changing all the trnasactions accept invenotry to group by cdrill. Inventory by cdrill and cSubdrill
      ,[TrGroupIdNumber]=CASE WHEN TransactionType IN ('INVTREC', 'INVTISU', 'INVTTRNS') THEN ROW_NUMBER () OVER (partition by transactiontype,sourcetable,CSubDrill,Trans_dt order by cdrill,[GroupIdNumber]) 
		ELSE ROW_NUMBER () OVER (partition by transactiontype,sourcetable,cDrill order by [GroupIdNumber]) 
		--WHEN  TransactionType='JE' THEN ROW_NUMBER () OVER (partition by transactiontype,sourcetable,cDrill order by [GroupIdNumber]) 
		-- 07/20/16 YS add case for INVTREC, INVTISU, INVTTRNS.   When releaseing invt_rec or invt_isu or invt_trns have to rank by source table and csubdrill then Trans_dt. for these tables cSubdrill is a uniq_key and we do not want to pack different uniq_key into the same transaction even if the time is exactly the same  
	   --ELSE ROW_NUMBER () OVER (partition by transactiontype,sourcetable,Trans_dt order by cdrill) 
	  END
      ,[TRANS_DT]
      ,[PERIOD]
      ,[FY]
      ,Glreleased.GL_NBR
      ,Gl_nbrs.GL_DESCR
      ,[DEBIT]
      ,[CREDIT]
      ,[SAVEINIT]
      ,[CIDENTIFIER]
      ,[LPOSTEDTOGL]
      ,[CDRILL]
      ,[TransactionType]
      ,[SourceTable]
      ,[SourceSubTable]
      ,[cSubIdentifier]
      ,[cSubDrill]
      ,[fk_fydtluniq]
      ,[GroupIdNumber]
      ,CAST(0 as Bit) as lSelect
      ,ISNULL(CASE WHEN TransactionType = 'APPREPAY' THEN (SELECT CAST(Apmaster.Reason as varchar(50)) FROM APMASTER where Apmaster.UNIQAPHEAD=RTRIM(glreleased.CSubDRILL))  
      WHEN TransactionType = 'ARPREPAY' THEN (SELECT CAST(ACCTSREC.INVNO as varchar(50)) FROM ACCTSREC WHERE ACCTSREC.UNIQUEAR =RTRIM(glreleased.CSubDRILL))  
      WHEN TransactionType = 'ARWO' THEN (SELECT CAST('Invoice Number: '+acctsrec.INVNO as varchar(50)) FROM ACCTSREC where acctsrec.uniquear=RTRIM(glreleased.CSubDRILL))  
      WHEN TransactionType = 'CHECKS' THEN (SELECT CAST('Check Number: '+checkno as varchar(50)) FROM APCHKMST WHERE apchkmst.APCHK_UNIQ =RTRIM(glreleased.CDRILL))
      WHEN TransactionType = 'CM' THEN (SELECT cast(cMemoNo as varchar(50)) FROM CMMAIN  WHERE CMMAIN.CMUNIQUE  =RTRIM(glreleased.CDRILL))
      WHEN TransactionType = 'CONFGVAR' THEN (SELECT CAST('Work Order: '+Confgvar.wono+' '+CAST(glreleased.trans_dt as CHAR(17)) as varchar(50)) FROm CONFGVAR where Confgvar.UNIQCONF=RTRIM(glreleased.CDRILL))
      WHEN TransactionType = 'COSTADJ' THEN (SELECT  CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) FROm Inventor where Inventor.UNIQ_KEY =RTRIM(glreleased.CSubDRILL))
      WHEN TransactionType = 'DEP' THEN CAST('Deposit Number: '+RTRIM(cDrill) as varchar(50))
      WHEN TransactionType = 'DM' THEN (SELECT cast(Dmemono as varchar(50)) FROM dmemos  WHERE DMEMOS.UNIQDMHEAD  =RTRIM(glreleased.CDRILL))
      WHEN TransactionType = 'INVTCOSTS' THEN (SELECT CAST(RTRIM(confgvar.VarType)+' Cost '+RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) FROm Inventor,confgvar where ConfgVar.UNIQCONF =RTRIM(glreleased.cDrill) and Inventor.UNIQ_KEY =RTRIM(glreleased.CSubDRILL))
      WHEN TransactionType = 'INVTISU' THEN (SELECT  CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) FROm Inventor where Inventor.UNIQ_KEY =RTRIM(glreleased.CSubDRILL))
      WHEN TransactionType = 'INVTREC' THEN (SELECT  CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) FROm Inventor where Inventor.UNIQ_KEY =RTRIM(glreleased.CSubDRILL))
      WHEN TransactionType = 'INVTTRNS' THEN (SELECT  CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) FROm Inventor where Inventor.UNIQ_KEY =RTRIM(glreleased.CSubDRILL))
      WHEN TransactionType = 'JE' THEN (SELECT 'JE #: '+cast(gljehdro.JE_NO as varchar(50)) FROM  gljehdro WHERE gljehdro.JEOHKEY =RTRIM(glreleased.CDRILL))
      WHEN TransactionType = 'MFGRVAR' THEN (SELECT CAST('Work Order: '+MfgrVar.wono+' '+CAST(glreleased.trans_dt as CHAR(17)) as varchar(50)) FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=RTRIM(glreleased.CDRILL))
      WHEN TransactionType = 'NSF' THEN (SELECT CAST('Deposit Number: '+Dep_no as varchar(50)) FROM ARRETCK WHERE ARRETCK.UNIQRETNO =RTRIM(glreleased.CDRILL))
      WHEN TransactionType = 'PURCH' THEN (SELECT  CAST('Supplier: '+RTRIM(Supname)+', '+'Invoice Number: ' +INVNO as varchar(50)) FROM Apmaster inner join Supinfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO where apmaster.UNIQAPHEAD =RTRIM(glreleased.CDRILL))  
      WHEN TransactionType = 'PURVAR' THEN (SELECT CAST('Receiver No: '+Sinvoice.receiverno as varchar(50)) FROM SINVOICE where Sinvoice.SINV_UNIQ =RTRIM(glreleased.cSubDrill))       
      WHEN TransactionType = 'ROUNDVAR' THEN (SELECT CAST('Rounding Variance for WO #: '+mfgrvar.WONO  as varchar(50)) FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=RTRIM(glreleased.CDRILL))
      WHEN TransactionType = 'SALES' THEN (SELECT  CAST('Customer: '+RTRIM(CustName)+', Invoice: '+InvoiceNo as varchar(50)) FROM Plmain inner join Customer on Plmain.custno = customer.CUSTNO where plmain.PACKLISTNO =RTRIM(glreleased.CDRILL))  
      WHEN TransactionType = 'SCRAP' THEN (SELECT CAST('Work Order: '+SCRAPREL.wono as varchar(50)) FROM SCRAPREL  where ScrapRel.TRANS_NO=RTRIM(glreleased.CDRILL))
      WHEN TransactionType = 'UNRECREC' THEN (SELECT CAST('Receiver Number: '+Porecloc.RECEIVERNO  as varchar(50)) FROM porecrelgl INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ where PorecRelGl.UNIQRECREL =RTRIM(glreleased.CDRILL))
      ELSE  CAST(' ' as varchar(50)) END,CAST('Cannot Link back to source' as varchar(50))) as DisplayValue,
	  Atduniq_key
	  FROM [dbo].[GLRELEASED] INNER JOIN GL_NBRS ON GLRELEASED.GL_NBR=GL_NBRS.GL_NBR 
	END
ELSE
	BEGIN
   -- Insert statements for procedure here
    -- 07/09/12 YS for JE group by cDrill, not trans date, Really want to have transaction per JE. Transaction date will not have time. Maybe need to change that also.
    -- 10/23/13 YS same problem as JE with checks. No time saved for transaction date
	--			08/03/16 YS Penang reported  another transaction, 'PURCH' type that grouped transactions from different invoices together. I am changing all the trnasactions accept invenotry to group by cdrill. Inventory by cdrill and cSubdrill

	SELECT [GLRELUNIQUE]
--			08/03/16 YS Penang reported  another transaction, 'PURCH' type that grouped transactions from different invoices together. I am changing all the trnasactions accept invenotry to group by cdrill. Inventory by cdrill and cSubdrill
      ,RANKN= CASE WHEN TransactionType IN ('INVTREC', 'INVTISU', 'INVTTRNS') THEN DENSE_RANK () OVER (order by transactiontype,sourcetable,CSubDrill,Trans_dt) 
	   ELSE DENSE_RANK () OVER (order by transactiontype,sourcetable,CDrill) 
	   -- WHEN TransactionType='JE' or TransactionType='CHECKS' THEN DENSE_RANK () OVER (order by transactiontype,sourcetable,CDrill) 
		-- 07/20/16 YS add case for INVTREC, INVTISU, INVTTRNS.   When releaseing invt_rec or invt_isu or invt_trns have to rank by source table and csubdrill then Trans_dt. for these tables cSubdrill is a uniq_key and we do not want to pack different uniq_key into the same transaction even if the time is exactly the same  
	  	  --ELSE DENSE_RANK () OVER (order by transactiontype,sourcetable,Trans_dt) 
	  END
--			08/03/16 YS Penang reported  another transaction, 'PURCH' type that grouped transactions from different invoices together. I am changing all the trnasactions accept invenotry to group by cdrill. Inventory by cdrill and cSubdrill
      ,[TrGroupIdNumber]=CASE WHEN TransactionType IN ('INVTREC', 'INVTISU', 'INVTTRNS') THEN ROW_NUMBER () OVER (partition by transactiontype,sourcetable,CSubDrill,Trans_dt order by cdrill,[GroupIdNumber]) 
		ELSE ROW_NUMBER () OVER (partition by transactiontype,sourcetable,cDrill order by [GroupIdNumber]) 
		--WHEN  TransactionType='JE' THEN ROW_NUMBER () OVER (partition by transactiontype,sourcetable,cDrill order by [GroupIdNumber]) 
		-- 07/20/16 YS add case for INVTREC, INVTISU, INVTTRNS.   When releaseing invt_rec or invt_isu or invt_trns have to rank by source table and csubdrill then Trans_dt. for these tables cSubdrill is a uniq_key and we do not want to pack different uniq_key into the same transaction even if the time is exactly the same  
	   --ELSE ROW_NUMBER () OVER (partition by transactiontype,sourcetable,Trans_dt order by cdrill) 
	  END
      ,[TRANS_DT]
      ,[PERIOD]
      ,[FY]
      ,Glreleased.GL_NBR
      ,Gl_nbrs.GL_DESCR
      ,[DEBIT]
      ,[CREDIT]
      ,[SAVEINIT]
      ,[CIDENTIFIER]
      ,[LPOSTEDTOGL]
      ,[CDRILL]
      ,[TransactionType]
      ,[SourceTable]
      ,[SourceSubTable]
      ,[cSubIdentifier]
      ,[cSubDrill]
      ,[fk_fydtluniq]
      ,[GroupIdNumber]
      ,CAST(0 as Bit) as lSelect
      ,ISNULL(CASE WHEN TransactionType = 'APPREPAY' THEN (SELECT CAST(Apmaster.Reason as varchar(50)) FROM APMASTER where Apmaster.UNIQAPHEAD=RTRIM(glreleased.CSubDRILL))  
      WHEN TransactionType = 'ARPREPAY' THEN (SELECT CAST(ACCTSREC.INVNO as varchar(50)) FROM ACCTSREC WHERE ACCTSREC.UNIQUEAR =RTRIM(glreleased.CSubDRILL))  
      WHEN TransactionType = 'ARWO' THEN (SELECT CAST('Invoice Number: '+acctsrec.INVNO as varchar(50)) FROM ACCTSREC where acctsrec.uniquear=RTRIM(glreleased.CSubDRILL))  
      WHEN TransactionType = 'CHECKS' THEN (SELECT CAST('Check Number: '+checkno as varchar(50)) FROM APCHKMST WHERE apchkmst.APCHK_UNIQ =RTRIM(glreleased.CDRILL))
      WHEN TransactionType = 'CM' THEN (SELECT cast(cMemoNo as varchar(50)) FROM CMMAIN  WHERE CMMAIN.CMUNIQUE  =RTRIM(glreleased.CDRILL))
      WHEN TransactionType = 'CONFGVAR' THEN (SELECT CAST('Work Order: '+Confgvar.wono+' '+CAST(glreleased.trans_dt as CHAR(17)) as varchar(50)) FROm CONFGVAR where Confgvar.UNIQCONF=RTRIM(glreleased.CDRILL))
      WHEN TransactionType = 'COSTADJ' THEN (SELECT  CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) FROm Inventor where Inventor.UNIQ_KEY =RTRIM(glreleased.CSubDRILL))
      WHEN TransactionType = 'DEP' THEN CAST('Deposit Number: '+RTRIM(cDrill) as varchar(50))
      WHEN TransactionType = 'DM' THEN (SELECT cast(Dmemono as varchar(50)) FROM dmemos  WHERE DMEMOS.UNIQDMHEAD  =RTRIM(glreleased.CDRILL))
      WHEN TransactionType = 'INVTCOSTS' THEN (SELECT CAST(RTRIM(confgvar.VarType)+' Cost '+RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) FROm Inventor,confgvar where ConfgVar.UNIQCONF =RTRIM(glreleased.cDrill) and Inventor.UNIQ_KEY =RTRIM(glreleased.CSubDRILL))
      WHEN TransactionType = 'INVTISU' THEN (SELECT  CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) FROm Inventor where Inventor.UNIQ_KEY =RTRIM(glreleased.CSubDRILL))
      WHEN TransactionType = 'INVTREC' THEN (SELECT  CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) FROm Inventor where Inventor.UNIQ_KEY =RTRIM(glreleased.CSubDRILL))
      WHEN TransactionType = 'INVTTRNS' THEN (SELECT  CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) FROm Inventor where Inventor.UNIQ_KEY =RTRIM(glreleased.CSubDRILL))
      WHEN TransactionType = 'JE' THEN (SELECT 'JE #: '+cast(gljehdro.JE_NO as varchar(50)) FROM  gljehdro WHERE gljehdro.JEOHKEY =RTRIM(glreleased.CDRILL))
      WHEN TransactionType = 'MFGRVAR' THEN (SELECT CAST('Work Order: '+MfgrVar.wono+' '+CAST(glreleased.trans_dt as CHAR(17)) as varchar(50)) FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=RTRIM(glreleased.CDRILL))
      WHEN TransactionType = 'NSF' THEN (SELECT CAST('Deposit Number: '+Dep_no as varchar(50)) FROM ARRETCK WHERE ARRETCK.UNIQRETNO =RTRIM(glreleased.CDRILL))
      WHEN TransactionType = 'PURCH' THEN (SELECT  CAST('Supplier: '+RTRIM(Supname)+', '+'Invoice Number: ' +INVNO as varchar(50)) FROM Apmaster inner join Supinfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO where apmaster.UNIQAPHEAD =RTRIM(glreleased.CDRILL))  
      WHEN TransactionType = 'PURVAR' THEN (SELECT CAST('Receiver No: '+Sinvoice.receiverno as varchar(50)) FROM SINVOICE where Sinvoice.SINV_UNIQ =RTRIM(glreleased.cSubDrill))       
      WHEN TransactionType = 'ROUNDVAR' THEN (SELECT CAST('Rounding Variance for WO #: '+mfgrvar.WONO  as varchar(50)) FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=RTRIM(glreleased.CDRILL))
      WHEN TransactionType = 'SALES' THEN (SELECT  CAST('Customer: '+RTRIM(CustName)+', Invoice: '+InvoiceNo as varchar(50)) FROM Plmain inner join Customer on Plmain.custno = customer.CUSTNO where plmain.PACKLISTNO =RTRIM(glreleased.CDRILL))  
      WHEN TransactionType = 'SCRAP' THEN (SELECT CAST('Work Order: '+SCRAPREL.wono as varchar(50)) FROM SCRAPREL  where ScrapRel.TRANS_NO=RTRIM(glreleased.CDRILL))
      WHEN TransactionType = 'UNRECREC' THEN (SELECT CAST('Receiver Number: '+Porecloc.RECEIVERNO  as varchar(50)) FROM porecrelgl INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ where PorecRelGl.UNIQRECREL =RTRIM(glreleased.CDRILL))
      ELSE  CAST(' ' as varchar(50)) END,CAST('Cannot Link back to source' as varchar(50))) as DisplayValue,
	  Atduniq_key, 
	  DebitPR, CreditPR, PRFcused_uniq, FuncFcused_uniq,
	  FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency 
      FROM [dbo].[GLRELEASED] 
	  	INNER JOIN Fcused PF ON GLRELEASED.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON GLRELEASED.FuncFcused_uniq = FF.Fcused_uniq
		INNER JOIN GL_NBRS ON GLRELEASED.GL_NBR=GL_NBRS.GL_NBR 
	END
  
END