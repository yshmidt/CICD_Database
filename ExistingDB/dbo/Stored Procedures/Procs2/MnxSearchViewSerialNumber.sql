-- =============================================
-- Author:		David Sharp
-- Create date: 11/15/2013
-- Description:	get SN details
-- 05/07/14 DS Added ExternalEmp param
-- 11/06/14 DS Added WC to results, removed leading 0's from WO, and enabled users to search for WO WC
-- 09/08/15 YS left outer join with WC 
-- 09/09/15 YS insert record into reportinstance for each record in the search 
-- =============================================
CREATE PROCEDURE [dbo].[MnxSearchViewSerialNumber]
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
		--DECLARE @terms TABLE(strings varchar(200))
		--INSERT INTO @terms SELECT id from dbo.fn_simpleVarcharlistToTable(@searchTerm,' ')
		--DECLARE @searchCount int
		--SELECT @searchCount = count(*) FROM @terms
		-- 09/08/15 YS left outer join with WC 
		DECLARE @count int
		--select * from INVTSER
		DECLARE @resultSet as Table (searchProc varchar(40),ID char(10),[group] varchar(20),
		[table] varchar(20),[link] varchar(250),serialNumber_f varchar(30),partNumber_f varchar(50),
		WO_A varchar(10),[Location] varchar(15)) ;

		INSERT INTO @ResultSet	
			(searchProc ,
				ID ,
				[group] ,
				[table],
				[link] ,
				serialNumber_f ,
				partNumber_f ,
				WO_A ,[Location]) 
			SELECT DISTINCT TOP 15 
    			'MnxSearchViewSerialNumber' AS searchProc,
    			SERIALUNIQ AS id, 
    			'SerilNumbers' AS [group], 
    			'serialNumber_f' AS [table], 
				-- 09/09/15 YS generate newid() to insert later into reportsInstance
				'/Reports/QV/51DFA14315/'+CAST(NEWID() as varchar(36)) as [link],
				--?lcSerialUniq=' + CAST(SERIALUNIQ AS varchar(50)) AS [link], 
				SUBSTRING(SERIALNO,PATINDEX('%[^0]%', SERIALNO+'.'),LEN(SERIALNO)) AS serialNumber_f, 
				PART_NO + CASE WHEN REVISION <> '' THEN ' | ' + REVISION ELSE '' END AS partNumber_f,
				SUBSTRING(s.WONO,PATINDEX('%[^0]%', s.WONO+'.'),LEN(s.WONO))  AS WO_a,
				-- 09/08/15 YS left outer join with WC show packing list number or WC or Stock
				CASE WHEN S.ID_KEY='DEPTKEY' THEN CAST('WC:'+ISNULL(d.DEPT_ID,space(4)) as varchar(15))
				WHEN S.ID_KEY='PACKLISTNO' THEN cast('PL:'+S.Id_value as varchar(15))
				WHEN S.Id_key='W_KEY' THEN cast('IN Stock' as varchar(15)) 
				ELSE space(15) END AS [Location]
			FROM INVTSER s INNER JOIN INVENTOR i ON i.uniq_key=s.uniq_key
				LEFT OUTER JOIN DEPT_QTY d ON s.id_value = d.deptkey AND s.wono=d.wono
			WHERE  			
				(
					PATINDEX(@thisTerm,SERIALNO+' '+RTRIM(PART_NO)+' '+SERIALNO)>0
					OR
					PATINDEX(@thisTerm,s.WONO+' '+d.DEPT_ID+' '+SUBSTRING(s.WONO,PATINDEX('%[^0]%', s.WONO+'.'),LEN(s.WONO))+' '+d.DEPT_ID+' '+s.WONO)>0
				)
				AND NOT SERIALUNIQ IN (SELECT id FROM @tSearchId)
		-- 09/09/15 YS insert each record into  reportsInstance, using id generated above
		INSERT INTO reportsInstance (instanceID,params)
			SELECT	REVERSE(substring(REVERSE([Link]),1,charindex('/',REVERSE([Link]),1)-1)),
					'lcSerialuniq='+R.Id
			FROM @resultSEt R
		SELECT * from @resultSEt


	END

END