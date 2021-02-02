
-- ==========================================================================================  
-- Author:  <Nilesh Sa>  
-- Create date: <01/08/2018>  
-- Description: Get Prepay And Credit Memo Details by Customer
-- exec [dbo].[GetPrepayAndCreditMemoView] '0000TCFSRM',0,150,'',''
-- Modified 2/21/2019 :Changed inner join to left join
-- ==========================================================================================  
CREATE PROCEDURE [dbo].[GetPrepayAndCreditMemoView]  
    --DECLARE  
	@custNo CHAR(10)= '',
      @startRecord INT = 0,  
      @endRecord INT = 150,   
      @sortExpression NVARCHAR(1000) = NULL,
	@filter NVARCHAR(1000) = NULL
AS  
BEGIN  
	SET NOCOUNT ON;  
	DECLARE @SQL nvarchar(MAX),@lFCInstalled bit;
	SELECT @lFCInstalled = dbo.fn_IsFCInstalled();
	DECLARE @prepayAndCMDetails TABLE(Type CHAR(100),Reference CHAR(10),Balance NUMERIC(12,2),ReceiveDate SMALLDATETIME
	,InvoiceNumber CHAR(10),UniqueAr CHAR(10),Applied NUMERIC(20,2),CustNo CHAR(10),NoteCount INT,BankUniq CHAR(10));

	IF(@sortExpression = NULL OR @sortExpression = '')
	BEGIN
		SET @sortExpression = 'ReceiveDate asc'
	END
	IF @lFCInstalled = 0 
		BEGIN
			INSERT INTO @prepayAndCMDetails
				SELECT 'Prepay' AS Type,ac.INVNO AS Reference,ar.ARCREDITS AS Balance, ac.REC_DATE As ReceiveDate 
				,ac.INVNO AS InvoiceNumber
                ,ac.UNIQUEAR AS UniqueAr
				,CAST(0.00 AS NUMERIC(20,2)) AS Applied
				,ac.CUSTNO as CustNo
				,ISNULL(NoteDetails.NoteCount,0) AS NoteCount
				,'' AS BankUniq
				FROM ARCREDIT ac
				JOIN ACCTSREC ar ON ac.uniquear = ar.UNIQUEAR
				LEFT JOIN wmNotes ON wmNotes.RecordType='AcctsRec' AND wmNotes.RecordId = ac.uniquear
				LEFT JOIN wmNoteRelationship ON wmNotes.NoteID = wmNoteRelationship.FkNoteId
				OUTER APPLY (SELECT COUNT(wmNoteRelationship.NoteRelationshipId) As NoteCount
						FROM WmNotes 
						LEFT JOIN wmNoteRelationship ON wmNotes.NoteID = wmNoteRelationship.FkNoteId
						WHERE wmNotes.RecordType='AcctsRec' AND wmNotes.RecordId = ar.uniquear
				) NoteDetails
				WHERE ar.lPrepay = 1 
				AND ac.REC_TYPE ='PrePay'
				AND ar.ARCREDITS > 0 
				AND ar.CUSTNO = @custNo
				UNION
				SELECT 'Credit Memo' AS Type,ac.INVNO AS Reference,ar.ARCREDITS AS Balance, ac.REC_DATE As ReceiveDate 
				,ac.INVNO AS InvoiceNumber
				,ac.UNIQUEAR AS UniqueAr
				,CAST(0.00 AS NUMERIC(20,2)) AS Applied
				,ac.CUSTNO as CustNo	
				,ISNULL(NoteDetails.NoteCount,0) AS NoteCount
				,'' AS BankUniq
				FROM ARCREDIT ac
				JOIN ACCTSREC ar ON ac.uniquear = ar.UNIQUEAR
				OUTER APPLY (SELECT COUNT(wmNoteRelationship.NoteRelationshipId) As NoteCount
						FROM WmNotes 
						LEFT JOIN wmNoteRelationship ON wmNotes.NoteID = wmNoteRelationship.FkNoteId
						WHERE wmNotes.RecordType='AcctsRec' AND wmNotes.RecordId = ar.uniquear
				) NoteDetails
				WHERE ar.isManualCm = 1 
				AND ac.REC_TYPE ='Credit Memo'
				AND ar.ARCREDITS > 0
				AND ar.CUSTNO = @custNo
		END
	ELSE
		BEGIN
			INSERT INTO @prepayAndCMDetails
				SELECT 'Prepay' AS Type,ac.REC_ADVICE AS Reference,ar.ARCREDITSFC AS Balance, ac.REC_DATE As ReceiveDate 
				,ac.INVNO AS InvoiceNumber
				,ac.UNIQUEAR AS UniqueAr
				,CAST(0.00 AS NUMERIC(20,2)) AS Applied
				,ac.CUSTNO as CustNo	
				,ISNULL(NoteDetails.NoteCount,0) AS NoteCount
				,dep.BK_UNIQ AS BankUniq
				FROM ARCREDIT ac
				JOIN ACCTSREC ar ON ac.uniquear = ar.UNIQUEAR
				JOIN DEPOSITS dep ON dep.DEP_NO = ac.DEP_NO
				OUTER APPLY (SELECT COUNT(wmNoteRelationship.NoteRelationshipId) As NoteCount
						FROM WmNotes 
						LEFT JOIN wmNoteRelationship ON wmNotes.NoteID = wmNoteRelationship.FkNoteId
						WHERE wmNotes.RecordType='AcctsRec' AND wmNotes.RecordId = ar.uniquear
				) NoteDetails
				WHERE ar.lPrepay = 1 
				AND ac.REC_TYPE ='PrePay'
				AND ar.ARCREDITSFC > 0 
				AND ar.CUSTNO = @custNo
				UNION
				SELECT 'Credit Memo' AS Type,ac.REC_ADVICE AS Reference,ar.ARCREDITSFC AS Balance, ac.REC_DATE As ReceiveDate 
				,ac.INVNO AS InvoiceNumber
				,ac.UNIQUEAR AS UniqueAr
				,CAST(0.00 AS NUMERIC(20,2)) AS Applied
				,ac.CUSTNO as CustNo
				,ISNULL(NoteDetails.NoteCount,0) AS NoteCount
				,dep.BK_UNIQ AS BankUniq
				FROM ARCREDIT ac
				JOIN ACCTSREC ar ON ac.uniquear = ar.UNIQUEAR
				LEFT JOIN DEPOSITS dep ON dep.DEP_NO = ac.DEP_NO -- Modified 2/21/2019 :Changed inner join to left join
				OUTER APPLY (SELECT COUNT(wmNoteRelationship.NoteRelationshipId) As NoteCount
						FROM WmNotes 
						LEFT JOIN wmNoteRelationship ON wmNotes.NoteID = wmNoteRelationship.FkNoteId
						WHERE wmNotes.RecordType='AcctsRec' AND wmNotes.RecordId = ar.uniquear
				) NoteDetails
				WHERE ar.isManualCm = 1 
				AND ac.REC_TYPE ='Credit Memo'
				AND ar.ARCREDITSFC > 0
				AND ar.CUSTNO = @custNo
		END

	SELECT IDENTITY(INT,1,1) AS RowNumber,*INTO #TEMP FROM @prepayAndCMDetails

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
	ELSE IF @filter <> '' AND @sortExpression = ''
			BEGIN
				  SET @SQL=N'SELECT  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE  '+@filter+'' 
				  + ' ORDER BY ReceiveDate OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;' 
			END
		 ELSE
			BEGIN
					  SET @SQL=N'SELECT  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t'
					   + ' ORDER BY ReceiveDate OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'
			END
	EXEC SP_EXECUTESQL @SQL
END