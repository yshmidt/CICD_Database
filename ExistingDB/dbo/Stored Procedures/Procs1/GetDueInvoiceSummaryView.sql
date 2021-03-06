﻿-- =============================================
-- Author:		<Nilesh Sa>
-- Create date: <24/01/2018>
-- Description:	Get Due Invoice Summary 
-- exec [dbo].[GetDueInvoiceSummaryView] '0000000001'
-- 2/7/2018 Nilesh Added parameter for functional Currency
-- Nilesh Sa 1/22/2019  Added Exchange rate calculation
-- Nilesh Sa 3/06/2018 Check for trans balance first
-- Nilesh Sa 6/27/2019 Update initial to username
-- Nitesh B 12/03/2019 Get TERMS, InvoiceType, PlType from PlMAIN table
-- Nitesh B 01/09/2020 Get PlType from PlMAIN table
-- Shivshankar P: 03/24/2020 Rename columns name 'LastStmtSent' as 'LastInvoiceSent' and 'LastStmtSentUserId' as 'LastInvoiceSentUserId'
-- Shivshnakar P: 04/15/2020 Get IS_INPRINT AS IsInvPrint from PLMAIN to show invoice printed or not on UI
-- Shivshankar P: 08/07/2020 Apply default grid sorting by DueDate ASC then InvoiceNumber ASC
-- =============================================
CREATE PROCEDURE [dbo].[GetDueInvoiceSummaryView]
	--DECLARE
	@custNo char(10) = '',
	@startRecord int = 0,
      @endRecord int = 150,  
      @sortExpression nvarchar(1000) = null,
      @filter nvarchar(1000) = null,
	-- 2/7/2018 Nilesh Added parameter for functional Currency
	@currencyType CHAR(10) ='', -- Empty - Functional Currency, P - Presentation Currency, F - Multi Currency
	@lLatestRate BIT = 0,
	@fcUsedUniq CHAR(10)=null 
AS
BEGIN
 SET NOCOUNT ON;

	DECLARE @SQL nvarchar(max), @today DATE = GETDATE()	,@lFCInstalled bit;
	DECLARE @dueInvoiceTable TABLE(InvoiceAmt NUMERIC(20,2),DueDate SMALLDATETIME,
		InvoiceNumber CHAR(10),PayTerms CHAR(15),Applied NUMERIC(20,2),Balance NUMERIC(20,2),DaysPast INT
	    ,InvoiceDate SMALLDATETIME,UniqueAr CHAR(10),NoteCount INT,PackListNo CHAR(10), InvoiceType CHAR(20),PlType CHAR(20),LastStmtSent DATETIME2(7)
		, Initials VARCHAR(512) -- Nilesh Sa 6/27/2019 Update initial to username  -- Nitesh B 01/09/2020 Get PlType from PlMAIN table
		, IsInvPrint BIT -- Shivshnakar P: 04/15/2020 Get IS_INPRINT AS IsInvPrint from PLMAIN to show invoice printed or not on UI
	    );   

      -- Nilesh Sa 01/22/2019 Created a table to store FCUsedView  
      DECLARE @fcUsedViewTable TABLE(FcUsedUniq CHAR(10),Country VARCHAR(60),CURRENCY VARCHAR(40), Symbol VARCHAR(3) ,Prefix VARCHAR(7),UNIT VARCHAR(10),Subunit VARCHAR(10),  
      Thou_sep VARCHAR(1),Deci_Sep VARCHAR(1),Deci_no NUMERIC(2,0),AskPrice NUMERIC(13,5),AskPricePR NUMERIC(13,5),FcHist_key CHAR(10),FcdateTime SMALLDATETIME);   
     
	-- Shivshankar P: 08/07/2020 Apply default grid sorting by DueDate ASC then InvoiceNumber ASC
	IF(@sortExpression = NULL OR @sortExpression = '')
	BEGIN
		SET @sortExpression = 'DueDate ASC, InvoiceNumber ASC'
	END
	SELECT @lFCInstalled = dbo.fn_IsFCInstalled();


	IF @lFCInstalled = 1 AND @currencyType = 'P'
		BEGIN
			 IF @lLatestRate = 0   
			 BEGIN
				 INSERT INTO @dueInvoiceTable
				 SELECT 
					  CAST(CASE WHEN ISNULL(INVTOTALFC,0) = 0 THEN 0.00 ELSE (INVTOTALPR) END AS NUMERIC(20,2)) AS InvoiceAmt
					 ,DUE_DATE AS DueDate
					 ,dbo.fRemoveLeadingZeros(INVNO) AS InvoiceNumber
					 ,CASE WHEN PackListInfo.TERMS <>'' AND PackListInfo.TERMS IS NOT NULL THEN PackListInfo.TERMS ELSE CUSTOMERINFO.TERMS END AS PayTerms
					 ,CAST(CASE WHEN ISNULL(ARCREDITSFC,0) = 0 THEN 0.00 ELSE (ARCREDITSPR) END AS NUMERIC(20,2)) AS Applied
					 ,CAST(CASE WHEN ISNULL((Acctsrec.InvtotalFC-Acctsrec.ArcreditsFC),0) = 0 THEN 0.00 ELSE (Acctsrec.InvtotalPR-Acctsrec.ArcreditsPR) END AS NUMERIC(20,2)) AS Balance
					 ,DATEDIFF(Day,DUE_DATE,@today) AS DaysPast
					 ,ACCTSREC.INVDATE AS InvoiceDate 
					 ,ACCTSREC.UNIQUEAR
					 ,ISNULL(NoteDetails.NoteCount,0) AS NoteCount  
					 ,PackListInfo.PACKLISTNO AS PackListNo
					 ,ISNULL(PackListInfo.INVOICETYPE, '') AS InvoiceType
					 ,ISNULL(PackListInfo.PLTYPE, '') AS PlType  -- Nitesh B 01/09/2020 Get PlType from PlMAIN table
					 ,ACCTSREC.LastInvoiceSent AS LastStmtSent  -- Shivshankar P: 03/24/2020 Rename columns name 'LastStmtSent' as 'LastInvoiceSent' and 'LastStmtSentUserId' as 'LastInvoiceSentUserId'
					 ,ISNULL(aspnet_users.UserName,'') AS Initials
					 ,ISNULL(PackListInfo.IS_INPRINT, 0) AS IsInvPrint  -- Shivshnakar P: 04/15/2020 Get IS_INPRINT AS IsInvPrint from PLMAIN to show invoice printed or not on UI
				 FROM ACCTSREC 
				 --LEFT JOIN  aspnet_profile ON ACCTSREC.LastStmtSentUserId = aspnet_profile.UserId 
				 -- Nilesh Sa 6/27/2019 Update initial to username
				 -- Shivshankar P: 03/24/2020 Rename columns name 'LastStmtSent' as 'LastInvoiceSent' and 'LastStmtSentUserId' as 'LastInvoiceSentUserId'
				 LEFT JOIN  aspnet_users ON ACCTSREC.LastInvoiceSentUserId = aspnet_users.UserId 
				 OUTER APPLY (
						  SELECT CUSTNAME,TERMS FROM CUSTOMER WHERE CUSTNO=@custNo
						) AS CUSTOMERINFO
				 OUTER APPLY (SELECT COUNT(wmNoteRelationship.NoteRelationshipId) As NoteCount  
					  FROM WmNotes   
					  LEFT JOIN wmNoteRelationship ON wmNotes.NoteID = wmNoteRelationship.FkNoteId  
					  WHERE wmNotes.RecordType='AcctsRec' AND wmNotes.RecordId = ACCTSREC.uniquear  
				 ) NoteDetails  
				 OUTER APPLY(
						SELECT PACKLISTNO, TERMS,PLTYPE, INVOICETYPE, IS_INPRINT FROM PLMAIN WHERE INVOICENO = ACCTSREC.INVNO
				 ) AS PackListInfo -- Nitesh B 12/03/2019 Get TERMS, InvoiceType, PlType from PlMAIN table
				 WHERE DUE_DATE IS NOT NULL AND ACCTSREC.CUSTNO = @custNo AND lPrepay = 0 AND (INVTOTALPR-ARCREDITSPR) > 0 AND ISMANUALCM = 0  
                     END
                ELSE
		         BEGIN
				  -- Fetch FCUsed data and inserting to temp table  
				  INSERT INTO @fcUsedViewTable  EXEC FcUsedView ;  
				  -- Nilesh Sa 1/22/2019  Added Exchange rate calculation
				  INSERT INTO @dueInvoiceTable
				  SELECT 
				      CAST(INVTOTALFC/fc.AskPricePR AS numeric(20,2)) AS InvoiceAmt
				     ,DUE_DATE AS DueDate 
				     ,dbo.fRemoveLeadingZeros(INVNO) AS InvoiceNumber
				     ,CASE WHEN PackListInfo.TERMS <>'' AND PackListInfo.TERMS IS NOT NULL THEN PackListInfo.TERMS ELSE CUSTOMER.TERMS END AS PayTerms
				     ,CAST(ARCREDITSFC/fc.AskPricePR AS numeric(20,2))  AS Applied
				     ,CAST((INVTOTALFC-ARCREDITSFC)/fc.AskPricePR AS numeric(20,2)) AS Balance
				     ,DATEDIFF(Day,DUE_DATE,@today) AS DaysPast
				     ,ACCTSREC.INVDATE AS InvoiceDate
				     ,ACCTSREC.UNIQUEAR 
				     ,ISNULL(NoteDetails.NoteCount,0) AS NoteCount  
				     ,PackListInfo.PACKLISTNO AS PackListNo
					 ,ISNULL(PackListInfo.INVOICETYPE, '') AS InvoiceType
					 ,ISNULL(PackListInfo.PLTYPE, '') AS PlType  -- Nitesh B 01/09/2020 Get PlType from PlMAIN table	
				     ,ACCTSREC.LastInvoiceSent AS LastStmtSent  -- Shivshankar P: 03/24/2020 Rename columns name 'LastStmtSent' as 'LastInvoiceSent' and 'LastStmtSentUserId' as 'LastInvoiceSentUserId'
					 ,ISNULL(aspnet_users.UserName,'') AS Initials
					 ,ISNULL(PackListInfo.IS_INPRINT, 0) AS IsInvPrint  -- Shivshnakar P: 04/15/2020 Get IS_INPRINT AS IsInvPrint from PLMAIN to show invoice printed or not on UI
				  FROM ACCTSREC 
				  JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO
				  LEFT OUTER JOIN @fcUsedViewTable fc ON CUSTOMER.FCUSED_UNIQ = fc.FcUsedUniq  
				  --LEFT JOIN  aspnet_profile ON ACCTSREC.LastStmtSentUserId = aspnet_profile.UserId 
				 -- Nilesh Sa 6/27/2019 Update initial to username
				 -- Shivshankar P: 03/24/2020 Rename columns name 'LastStmtSent' as 'LastInvoiceSent' and 'LastStmtSentUserId' as 'LastInvoiceSentUserId'
				 LEFT JOIN  aspnet_users ON ACCTSREC.LastInvoiceSentUserId = aspnet_users.UserId 
				  OUTER APPLY (SELECT COUNT(wmNoteRelationship.NoteRelationshipId) As NoteCount  
				    FROM WmNotes   
				    LEFT JOIN wmNoteRelationship ON wmNotes.NoteID = wmNoteRelationship.FkNoteId  
				    WHERE wmNotes.RecordType='AcctsRec' AND wmNotes.RecordId = ACCTSREC.uniquear  
				  ) NoteDetails  
				  OUTER APPLY(
				  		SELECT PACKLISTNO, TERMS,PLTYPE, INVOICETYPE, IS_INPRINT FROM PLMAIN WHERE INVOICENO = ACCTSREC.INVNO
				  ) AS PackListInfo -- Nitesh B 12/03/2019 Get TERMS, InvoiceType, PlType from PlMAIN table
				  WHERE DUE_DATE IS NOT NULL AND ACCTSREC.CUSTNO = @custNo 
				  AND lPrepay = 0  AND (INVTOTALFC-ARCREDITSFC) > 0 AND ISMANUALCM = 0 
			   END
		END
    ELSE IF @lFCInstalled = 1 AND @currencyType = 'F'
		BEGIN 
		-- Nilesh Sa 1/22/2018 removed Exchange rate condition 
		  INSERT INTO @dueInvoiceTable
		  SELECT 
			 CAST((INVTOTALFC) AS NUMERIC(20,2)) AS InvoiceAmt
			,DUE_DATE AS DueDate 
			,dbo.fRemoveLeadingZeros(INVNO) AS InvoiceNumber
			,CASE WHEN PackListInfo.TERMS <>'' AND PackListInfo.TERMS IS NOT NULL THEN PackListInfo.TERMS ELSE CUSTOMERINFO.TERMS END AS PayTerms
			,CAST((ARCREDITSFC) AS NUMERIC(20,2)) AS Applied
			,CAST((Acctsrec.INVTOTALFC-Acctsrec.ARCREDITSFC) AS NUMERIC(20,2)) AS Balance
			,DATEDIFF(Day,DUE_DATE,@today) AS DaysPast
			,ACCTSREC.INVDATE AS InvoiceDate
			,ACCTSREC.UNIQUEAR 
			,ISNULL(NoteDetails.NoteCount,0) AS NoteCount  
			,PackListInfo.PACKLISTNO AS PackListNo
			,ISNULL(PackListInfo.INVOICETYPE, '') AS InvoiceType
			,ISNULL(PackListInfo.PLTYPE, '') AS PlType  -- Nitesh B 01/09/2020 Get PlType from PlMAIN table	
			,ACCTSREC.LastInvoiceSent AS LastStmtSent -- Shivshankar P: 03/24/2020 Rename columns name 'LastStmtSent' as 'LastInvoiceSent' and 'LastStmtSentUserId' as 'LastInvoiceSentUserId'
			,ISNULL(aspnet_users.UserName,'') AS Initials
			,ISNULL(PackListInfo.IS_INPRINT, 0) AS IsInvPrint -- Shivshnakar P: 04/15/2020 Get IS_INPRINT AS IsInvPrint from PLMAIN to show invoice printed or not on UI
		  FROM ACCTSREC 
		  --LEFT JOIN  aspnet_profile ON ACCTSREC.LastStmtSentUserId = aspnet_profile.UserId 
				 -- Nilesh Sa 6/27/2019 Update initial to username
				 -- Shivshankar P: 03/24/2020 Rename columns name 'LastStmtSent' as 'LastInvoiceSent' and 'LastStmtSentUserId' as 'LastInvoiceSentUserId'
				 LEFT JOIN  aspnet_users ON ACCTSREC.LastInvoiceSentUserId = aspnet_users.UserId 
		  OUTER APPLY (
				  SELECT CUSTNAME,TERMS FROM CUSTOMER WHERE CUSTNO=@custNo AND FCUSED_UNIQ = ISNULL(@fcUsedUniq,FCUSED_UNIQ)
				) AS CUSTOMERINFO
		  OUTER APPLY (SELECT COUNT(wmNoteRelationship.NoteRelationshipId) As NoteCount  
			  FROM WmNotes   
			  LEFT JOIN wmNoteRelationship ON wmNotes.NoteID = wmNoteRelationship.FkNoteId  
			  WHERE wmNotes.RecordType='AcctsRec' AND wmNotes.RecordId = ACCTSREC.uniquear  
		  ) NoteDetails  
		  OUTER APPLY(
				SELECT PACKLISTNO, TERMS,PLTYPE, INVOICETYPE, IS_INPRINT FROM PLMAIN WHERE INVOICENO = ACCTSREC.INVNO
		  ) AS PackListInfo -- Nitesh B 12/03/2019 Get TERMS, InvoiceType, PlType from PlMAIN table
		  WHERE DUE_DATE IS NOT NULL AND ACCTSREC.CUSTNO = @custNo AND lPrepay = 0 AND (INVTOTALFC-ARCREDITSFC) > 0 AND ISMANUALCM = 0
		END
    ELSE
        IF @lLatestRate = 0   
		 BEGIN
			INSERT INTO @dueInvoiceTable
			SELECT 
			      INVTOTAL AS InvoiceAmt
			     ,DUE_DATE AS DueDate 
			     ,dbo.fRemoveLeadingZeros(INVNO) AS InvoiceNumber
			     ,CASE WHEN PackListInfo.TERMS <>'' AND PackListInfo.TERMS IS NOT NULL THEN PackListInfo.TERMS ELSE CUSTOMERINFO.TERMS END AS PayTerms
			     ,ARCREDITS AS Applied
			     ,(INVTOTAL-ARCREDITS) AS Balance
			     ,DATEDIFF(Day,DUE_DATE,@today) AS DaysPast
			     ,ACCTSREC.INVDATE AS InvoiceDate
			     ,ACCTSREC.UNIQUEAR 
			     ,ISNULL(NoteDetails.NoteCount,0) AS NoteCount  
			     ,PackListInfo.PACKLISTNO AS PackListNo
				 ,ISNULL(PackListInfo.INVOICETYPE, '') AS InvoiceType 
				 ,ISNULL(PackListInfo.PLTYPE, '') AS PlType 	-- Nitesh B 01/09/2020 Get PlType from PlMAIN table
			     ,ACCTSREC.LastInvoiceSent AS LastStmtSent  -- Shivshankar P: 03/24/2020 Rename columns name 'LastStmtSent' as 'LastInvoiceSent' and 'LastStmtSentUserId' as 'LastInvoiceSentUserId'
				 ,ISNULL(aspnet_users.UserName,'') AS Initials
				 ,ISNULL(PackListInfo.IS_INPRINT, 0) AS IsInvPrint  -- Shivshnakar P: 04/15/2020 Get IS_INPRINT AS IsInvPrint from PLMAIN to show invoice printed or not on UI
			FROM ACCTSREC 
			--LEFT JOIN  aspnet_profile ON ACCTSREC.LastStmtSentUserId = aspnet_profile.UserId 
				 -- Nilesh Sa 6/27/2019 Update initial to username
				 -- Shivshankar P: 03/24/2020 Rename columns name 'LastStmtSent' as 'LastInvoiceSent' and 'LastStmtSentUserId' as 'LastInvoiceSentUserId'
				 LEFT JOIN  aspnet_users ON ACCTSREC.LastInvoiceSentUserId = aspnet_users.UserId 
			OUTER APPLY (
				  SELECT CUSTNAME,TERMS FROM CUSTOMER WHERE CUSTNO=@custNo
				) AS CUSTOMERINFO
			OUTER APPLY (SELECT COUNT(wmNoteRelationship.NoteRelationshipId) As NoteCount  
			  FROM WmNotes   
			  LEFT JOIN wmNoteRelationship ON wmNotes.NoteID = wmNoteRelationship.FkNoteId  
			  WHERE wmNotes.RecordType='AcctsRec' AND wmNotes.RecordId = ACCTSREC.uniquear  
			) NoteDetails  
			OUTER APPLY(
					SELECT PACKLISTNO, TERMS,PLTYPE, INVOICETYPE, IS_INPRINT FROM PLMAIN WHERE INVOICENO = ACCTSREC.INVNO
			) AS PackListInfo -- Nitesh B 12/03/2019 Get TERMS, InvoiceType, PlType from PlMAIN table
			WHERE DUE_DATE IS NOT NULL AND ACCTSREC.CUSTNO = @custNo AND lPrepay = 0  AND (INVTOTAL-ARCREDITS) > 0 AND ISMANUALCM = 0
		 END
         ELSE
	       BEGIN
		      -- Fetch FCUsed data and inserting to temp table  
                  INSERT INTO @fcUsedViewTable  EXEC FcUsedView ;  
			-- Nilesh Sa 1/22/2019  Added Exchange rate calculation
			INSERT INTO @dueInvoiceTable
			SELECT 
			CAST(INVTOTALFC/fc.AskPrice AS numeric(20,2)) AS InvoiceAmt
			   ,DUE_DATE AS DueDate, 
			   dbo.fRemoveLeadingZeros(INVNO) AS InvoiceNumber
			   ,CASE WHEN PackListInfo.TERMS <>'' AND PackListInfo.TERMS IS NOT NULL THEN PackListInfo.TERMS ELSE CUSTOMER.TERMS END AS PayTerms
			   ,CAST(ARCREDITSFC/fc.AskPrice AS numeric(20,2))  AS Applied
			   ,CAST((INVTOTALFC-ARCREDITSFC)/fc.AskPrice AS numeric(20,2)) AS Balance
			   ,DATEDIFF(Day,DUE_DATE,@today) AS DaysPast
			   ,ACCTSREC.INVDATE AS InvoiceDate
			   ,ACCTSREC.UNIQUEAR 
			   ,ISNULL(NoteDetails.NoteCount,0) AS NoteCount  
			   ,PackListInfo.PACKLISTNO AS PackListNo
			   ,ISNULL(PackListInfo.INVOICETYPE, '') AS InvoiceType
			   ,ISNULL(PackListInfo.PLTYPE, '') AS PlType  	  -- Nitesh B 01/09/2020 Get PlType from PlMAIN table
			   ,ACCTSREC.LastInvoiceSent AS LastStmtSent -- Shivshankar P: 03/24/2020 Rename columns name 'LastStmtSent' as 'LastInvoiceSent' and 'LastStmtSentUserId' as 'LastInvoiceSentUserId'
			   ,ISNULL(aspnet_users.UserName,'') AS Initials 
			   ,ISNULL(PackListInfo.IS_INPRINT, 0) AS IsInvPrint -- Shivshnakar P: 04/15/2020 Get IS_INPRINT AS IsInvPrint from PLMAIN to show invoice printed or not on UI
			FROM ACCTSREC 
			JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO
			--LEFT JOIN  aspnet_profile ON ACCTSREC.LastStmtSentUserId = aspnet_profile.UserId 
				 -- Nilesh Sa 6/27/2019 Update initial to username
				 -- Shivshankar P: 03/24/2020 Rename columns name 'LastStmtSent' as 'LastInvoiceSent' and 'LastStmtSentUserId' as 'LastInvoiceSentUserId'
				 LEFT JOIN  aspnet_users ON ACCTSREC.LastInvoiceSentUserId = aspnet_users.UserId 
			LEFT OUTER JOIN @fcUsedViewTable fc ON CUSTOMER.FCUSED_UNIQ = fc.FcUsedUniq  
			OUTER APPLY (SELECT COUNT(wmNoteRelationship.NoteRelationshipId) As NoteCount  
			  FROM WmNotes   
			  LEFT JOIN wmNoteRelationship ON wmNotes.NoteID = wmNoteRelationship.FkNoteId  
			  WHERE wmNotes.RecordType='AcctsRec' AND wmNotes.RecordId = ACCTSREC.uniquear  
			) NoteDetails  
			OUTER APPLY(
					SELECT PACKLISTNO, TERMS,PLTYPE, INVOICETYPE, IS_INPRINT FROM PLMAIN WHERE INVOICENO = ACCTSREC.INVNO
			) AS PackListInfo -- Nitesh B 12/03/2019 Get TERMS, InvoiceType, PlType from PlMAIN table
			WHERE DUE_DATE IS NOT NULL AND ACCTSREC.CUSTNO = @custNo AND lPrepay = 0  AND (INVTOTALFC-ARCREDITSFC) > 0 AND ISMANUALCM = 0 
		 END

	SELECT IDENTITY(INT,1,1) AS RowNumber,*INTO #TEMP FROM @dueInvoiceTable

	IF @filter <> '' AND @sortExpression <> ''
		  BEGIN
		   SET @SQL=N'SELECT  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE '+@filter
			   +' ORDER BY '+ @SortExpression+''+ ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'
		   END
		  ELSE IF @filter = '' AND @sortExpression <> ''
		  BEGIN
			SET @SQL=N'SELECT  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t '  
			+' ORDER BY '+ @sortExpression+'' + ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;' 
			END
	ELSE 
	    IF @filter <> '' AND @sortExpression = ''
		  BEGIN
			  SET @SQL=N'SELECT  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE  '+@filter+'' 
			  + ' ORDER BY DaysPast DESC OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;' 
		  END
		ELSE
		  BEGIN
			  SET @SQL=N'SELECT  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t'
			   + ' ORDER BY DaysPast DESC OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'
		  END
	EXEC SP_EXECUTESQL @SQL
END