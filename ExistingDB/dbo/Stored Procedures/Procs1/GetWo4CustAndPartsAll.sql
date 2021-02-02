 --=============================================
 --Author:		Yelena Shmidt
 --Create date: 08/14/2013
 --Description:	List of work orders for selected customers and / or parts.  
 --Modified:	09/03/2013 YS modified the code, had problems with all the selections
	--			11/25/2013 YS modified the default value for the @lcCustomer and @lcPartNumber to be 'All' 
	--			12/03/2013 YS empty or null customer or part number means no selection were made
	--			12/05/2013 DP: added order by wono at the end so that the parameter would list the wo #'s in order on screen
	--			12/09/15 DRP:	added ,@paramFilter and @top so this procedure would be able to handle bigdata
	--			09/12/16 DRP:   changed the default value for the @openWo from 0 to 1 so that it will only list open work orders in the parameter listings.
	--			02/27/17 DRP:	created this copy to pull all Open and Closed work orders to the parameter list.  Copied this procedure from "GetWo4CustAndPart"  This procedure will pull all work orders except "cancelled"
 --=============================================
create PROCEDURE [dbo].[GetWo4CustAndPartsAll]
--declare 
	 @UserId uniqueidentifier = null,
	 @lcCustomer varchar(max)='All' 		-- if 'All' will select based on @lcPartNumber, @lcCustomer could have a single value for a custno or a CSV
	,@lcPartNumber varchar(max) = 'All' 	-- if 'All will select based on @lcCustomer, @lcPartNumber could have a single value for a uniq_key or a CSV
	,@defaultEmpty bit =0				-- if  @defaultEmpty=0 and @lcCustomer=null and @lcPartNumber= null then all work orders will be returned
										-- if  @defaultEmpty=1 and @lcCustomer=null and @lcPartNumber= null then none of the work orders will be returned	
	,@customerStatus varchar (20) = 'All'
	--,@openWo bit = 1					-- default to select make parts with open jobs only, if 0 select parts with any job status	--02/27/17 DRP:  removed 

	,@paramFilter varchar(200) = ''		--- first 3+ characters entered by the user		12/09/15 DRP:  Added
	,@top int = null					-- if not null return number of rows indicated	12/09/15 DRP: Added


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @tCustomer tCustomer
	DECLARE @tCustno tCustno ;
	declare @tInvt as tUniq_key
	declare @tWo as tWono
	
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
	-- list all given parts if any
	IF @lcPartNumber is not null and @lcPartNumber <>'' and @lcPartNumber <>'All'
		INSERT INTO @tInvt SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcPartNumber,',')
	
	--09/03/13 YS chenged the code below
	--	if @defaultEmpty 0 or 1 and part number is not provided and customer provided when @defaultEmpty is 1
	--11/25/13 YS check for 'All' to select all
	--IF (@defaultEmpty=0 AND (@lcPartNumber is null or @lcPartNumber ='')) or (@defaultEmpty=1 and @lcCustomer is not null and  @lcCustomer<>''  AND (@lcPartNumber is null or @lcPartNumber =''))
	IF (@defaultEmpty=0 AND @lcPartNumber ='All') or (@defaultEmpty=1 and  @lcCustomer<>'All'  AND @lcPartNumber  ='All')	
		INSERT INTO @tWo 
				SELECT W.Wono 
			FROM Woentry W 
			INNER JOIN @tCustno C ON W.CUSTNO=C.Custno
			--WHERE 1=CASE WHEN @OpenWo=0 OR (@OpenWo=1 AND OpenClos<>'Closed' and OpenClos<>'Cancel') THEN 1 ELSE 0 END  --02/27/16 DRP:  replaced with the below
			WHERE 1= case when openclos = 'Cancel' then 0 else 1 end 
			
			
	
	--- if @defaultEmpty 0 or 1 and part number is provided and customer is provided or not
	--IF ((@defaultEmpty=0 or @defaultEmpty=1) and @lcPartNumber is NOT null and @lcPartNumber <>'')
	--11/25/13 YS check for 'All' to select all

		IF ((@defaultEmpty=0 or @defaultEmpty=1) and @lcPartNumber  <>'All')
		BEGIN	
		  -- tcustno will have information even if @lcCustomer is not given (all customers for the given userid)
		  INSERT INTO @tWo 
			SELECT DISTINCT W.Wono 
				FROM Woentry W INNER JOIN @tInvt I on W.Uniq_key=I.UNIQ_KEY 
				INNER JOIN @tCustno C ON W.CUSTNO=C.Custno
				--WHERE 1=CASE WHEN @OpenWo=0 OR (@OpenWo=1 AND OpenClos<>'Closed' and OpenClos<>'Cancel') THEN 1 ELSE 0 END  --02/27/17 DRP:  replaced with the below
				WHERE 1= case when openclos = 'Cancel' then 0 else 1 end
		END	----IF (@lcCustomer is not null and @lcCustomer <>'') AND  (@lcPartNumber is not null and @lcPartNumber <>'')

--12/05/2013 DP:  added the order by wono
--12/09/15 DRP:  implemented the if statement below to work with bigdata				
	if (@top is not null)
		select top(@top) WONO as Value, SUBSTRING(WONO,PATINDEX('%[^0]%',WONO + ' '),LEN(WONO))  AS Text 
		from	@tWo T 	
		WHERE	1 = case when @paramFilter is null then 1 else case when WONO like '%'+@paramFilter+ '%' then 1 else 0 end end
		ORDER BY Wono
			
	else
		select	WONO as Value, SUBSTRING(WONO,PATINDEX('%[^0]%',WONO + ' '),LEN(WONO)) AS Text 
		from	@tWo T
		WHERE	1 = case when @paramFilter is null then 1 else case when WONO like '%'+@paramFilter+ '%' then 1 else 0 end end
				
		ORDER BY WONO
END