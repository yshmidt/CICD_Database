-- =============================================
-- Author:		Debbie
-- Create date: 05/13/2014
-- Description:	Get list of all customers that selected user allowed to see and that have existing records within the QAINSP tables
--				used as a source for 'wo4Qa' sourcename in mnxParamSources  (rptQaDefectLogHist - QAHIST)
-- Modification:	08/14/2014 DRP:  needed to add @paramFilter and @top in order to prevent JSON error on BigData
--				Also changed to selection statement to work with the new parameters and re-arranged the Customer Selection List, Part Number list, etc . . 
--				01/06/2015 DRP:  Added @customerStatus Filter
-- =============================================
CREATE PROCEDURE [dbo].[GetWo4Qa]

	 @UserId uniqueidentifier = null,
	 @lcCustomer varchar(max)='All' 		-- if 'All' will select based on @lcPartNumber, @lcCustomer could have a single value for a custno or a CSV
	,@lcPartNumber varchar(max) = 'All' 	-- if 'All will select based on @lcCustomer, @lcPartNumber could have a single value for a uniq_key or a CSV
	,@defaultEmpty bit =0				-- if  @defaultEmpty=0 and @lcCustomer=null and @lcPartNumber= null then all work orders will be returned
										-- if  @defaultEmpty=1 and @lcCustomer=null and @lcPartNumber= null then none of the work orders will be returned	
	,@openWo bit = 0					-- default 1 to select make parts with open jobs only, if 0 select parts with any job status
	,@paramFilter varchar(200) = ''		--- first 3+ characters entered by the user --08/14/2014 DRP Added
	,@customerStatus varchar (20) = 'All'
	,@top int = null							-- if not null return number of rows indicated --08/14/2014 DRP Added

AS
BEGIN
/*CUSTOMER SELECTION LIST*/
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @tCustomer tCustomer
	DECLARE @tCustno tCustno ;
	-- get list of customers for @userid with access
	-- even if @lcCustomer is not empty we cannot assume that the user has rights to those customers. They might just know the codes of the customers that they have no rights to
	INSERT INTO @tCustomer EXEC [aspmnxSP_GetCustomers4User] @userid,null,@customerStatus ;
	
    -- Insert statements for procedure here
    -- list all given customers if any
	IF @lcCustomer is not null and @lcCustomer <>'' and @lcCustomer<>'All'
		INSERT INTO @tCustno SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcCustomer,',')
			WHERE cast(ID as char(10)) IN (SELECT Custno from @tCustomer)
	ELSE
	---- 12/03/2013 YS empty or null customer or part number means no selection were made
	IF  @lcCustomer='All'	
		BEGIN
		-- get all the customers to which @userid has accees
		-- selct from the list of all customers for which @userid has acceess
		INSERT INTO @tCustno SELECT Custno FROM @tCustomer	
	END
	
/*PART NUMBER LIST*/	
	-- list all given parts if any
	declare @tInvt as tUniq_key
	
	IF @lcPartNumber is not null and @lcPartNumber <>'' and @lcPartNumber <>'All'
		INSERT INTO @tInvt SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcPartNumber,',')

/*WORK ORDER LIST*/	
	--09/03/13 YS chenged the code below
	--	if @defaultEmpty 0 or 1 and part number is not provided and customer provided when @defaultEmpty is 1
	--11/25/13 YS check for 'All' to select all
	--IF (@defaultEmpty=0 AND (@lcPartNumber is null or @lcPartNumber ='')) or (@defaultEmpty=1 and @lcCustomer is not null and  @lcCustomer<>''  AND (@lcPartNumber is null or @lcPartNumber =''))
	declare @tWo as tWono
	
	IF (@defaultEmpty=0 AND @lcPartNumber ='All') or (@defaultEmpty=1 and  @lcCustomer<>'All'  AND @lcPartNumber  ='All')	
		INSERT INTO @tWo 
				SELECT W.Wono 
			FROM View_Wo4Qa W
				INNER JOIN @tCustno C ON W.CUSTNO=C.Custno
			WHERE 1=CASE WHEN @OpenWo=0 OR (@OpenWo=1 AND W.OpenClos<>'Closed' and W.OpenClos<>'Cancel') THEN 1 ELSE 0 END  

/*SELECT STATEMENT*/			
--12/05/2013 DP:  added the order by wono				
--08/14/2014 DRP:  REPLACED THIS SELECT STATEMENT IN ORDER TO PREVENT JSON ERROR WITH BIGDATA	
	--SELECT distinct Wono FROM @tWo order by wono

 	if (@top is not null)
		select  top(@top) WONO as Value, SUBSTRING(Wono,PATINDEX('%[^0]%',Wono + ' '),LEN(Wono)) AS Text 
		from	@tWo 
		WHERe	1 = case when @paramFilter is null then 1 else case when Wono like '%'+ @paramFilter+ '%' then 1 else 0 end end
		ORDER BY WONO
	else
		select distinct	WONO as Value, SUBSTRING(Wono,PATINDEX('%[^0]%',Wono + ' '),LEN(Wono)) AS Text 
		from	@tWo 
		WHERe	1 = case when @paramFilter is null then 1 else case when Wono like '%'+ @paramFilter+ '%' then 1 else 0 end end
		ORDER BY WONO

END

