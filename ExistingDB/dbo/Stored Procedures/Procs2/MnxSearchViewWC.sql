-- =============================================
-- Author:		David Sharp
-- Create date: 11/06/14
-- Description:	get WC details
-- =============================================
CREATE PROCEDURE [dbo].[MnxSearchViewWC]
	-- Add the parameters for the stored procedure here
	@searchTerm varchar(MAX),
	@searchType int,
	@userId uniqueidentifier,
	@tCustomers UserCompanyPermissions READONLY,
	@tSupplier UserCompanyPermissions READONLY,
	@fullResult bit = 0,
	@activeMonthLimit int = 0,
	@tSearchId tSearchId READONLY,
	@ExternalEmp bit = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF @ExternalEmp=0
	BEGIN
		DECLARE @thisTerm varchar(MAX) = '%' + @searchTerm + '%'
		DECLARE @count int
		--select * from INVTSER
    		SELECT DISTINCT TOP 15 
    			'MnxSearchViewSerialNumber' AS searchProc,
    			SERIALUNIQ AS id, 
    			'SerilNumbers' AS [group], 
    			'serialNumber_f' AS [table], 
				'/Reports/QV/51DFA14315?lcSerialUniq=' + CAST(SERIALUNIQ AS varchar(50)) AS [link], 
				SUBSTRING(SERIALNO,PATINDEX('%[^0]%', SERIALNO+'.'),LEN(SERIALNO)) AS serialNumber_f, 
				PART_NO + CASE WHEN REVISION <> '' THEN ' | ' + REVISION ELSE '' END AS partNumber_f,
				SUBSTRING(s.WONO,PATINDEX('%[^0]%', s.WONO+'.'),LEN(s.WONO))  AS WO_a,
				d.DEPT_ID AS WC_a
			FROM INVTSER s INNER JOIN INVENTOR i ON i.uniq_key=s.uniq_key
				INNER JOIN DEPT_QTY d ON s.id_value = d.deptkey AND s.wono=d.wono
			WHERE PATINDEX(@thisTerm,SERIALNO+'  '+PART_NO+' '+d.DEPT_ID+' '+PART_NO+' '+SERIALNO)>0
				AND NOT SERIALUNIQ IN (SELECT id FROM @tSearchId)
	END

END